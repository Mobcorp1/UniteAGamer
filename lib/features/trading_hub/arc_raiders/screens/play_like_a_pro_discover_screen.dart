import 'dart:async';

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_guide.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/play_like_a_pro_guide_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_guide_detail_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class PlayLikeAProDiscoverScreen extends StatefulWidget {
  const PlayLikeAProDiscoverScreen({super.key, this.onOpenSessionCoach});

  final VoidCallback? onOpenSessionCoach;

  @override
  State<PlayLikeAProDiscoverScreen> createState() =>
      _PlayLikeAProDiscoverScreenState();
}

class _PlayLikeAProDiscoverScreenState
    extends State<PlayLikeAProDiscoverScreen> {
  final _repository = const PlayLikeAProGuideRepository();
  final _personalisationRepository = ArcUserPersonalisationRepository();
  final _loadoutRepository = ArcSavedLoadoutRepository();
  final _engine = const PlayLikeAProRecommendationEngine();
  final _searchController = TextEditingController();

  late Future<List<PlayLikeAProGuide>> _guidesFuture;
  StreamSubscription<ArcUserPersonalisationProfile>?
  _personalisationSubscription;
  StreamSubscription<ArcSavedLoadout?>? _loadoutSubscription;
  ArcUserPersonalisationProfile _personalisation =
      ArcUserPersonalisationProfile.defaults;
  ArcSavedLoadout? _favouriteLoadout;
  PlayLikeAProCategory? _category;
  PlayLikeAProSkillLevel? _skillLevel;
  PlayLikeAProSquadScope? _squadScope;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _guidesFuture = _repository.loadPublishedGuides();
    _personalisationSubscription = _personalisationRepository
        .watchProfile()
        .listen((profile) {
          if (mounted) {
            setState(() => _personalisation = profile);
          }
        });
    _loadoutSubscription = _loadoutRepository.watchFavouriteLoadout().listen((
      loadout,
    ) {
      if (mounted) {
        setState(() => _favouriteLoadout = loadout);
      }
    });
  }

  @override
  void dispose() {
    _personalisationSubscription?.cancel();
    _loadoutSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _retry() =>
      setState(() => _guidesFuture = _repository.loadPublishedGuides());

  void _openGuide(PlayLikeAProGuide guide, List<PlayLikeAProGuide> allGuides) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayLikeAProGuideDetailScreen(
          guide: guide,
          allGuides: allGuides,
          onOpenGuide: (next) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayLikeAProGuideDetailScreen(
                  guide: next,
                  allGuides: allGuides,
                  onOpenGuide: (related) => _openGuide(related, allGuides),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArcRaidersPageScaffold(
      maxWidth: 1180,
      child: FutureBuilder<List<PlayLikeAProGuide>>(
        future: _guidesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                decoration: AppTheme.tradingCardDecoration(
                  borderColor: Colors.redAccent.withValues(alpha: .35),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 38,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    const Text(
                      'Guidance could not be loaded.',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final guides = snapshot.data ?? const <PlayLikeAProGuide>[];
          final filtered = guides
              .where((guide) {
                if (_category != null && guide.category != _category) {
                  return false;
                }
                if (_skillLevel != null && guide.skillLevel != _skillLevel) {
                  return false;
                }
                if (_squadScope != null &&
                    guide.squadScope != _squadScope &&
                    guide.squadScope != PlayLikeAProSquadScope.any) {
                  return false;
                }
                return guide.matchesQuery(_query);
              })
              .toList(growable: false);
          final recommendations = _engine.rank(
            guides: guides,
            personalisation: _personalisation,
            favouriteLoadout: _favouriteLoadout,
            limit: 5,
          );
          return ListView(
            children: [
              _hero(),
              const SizedBox(height: AppTheme.spaceM),
              _searchAndFilters(),
              const SizedBox(height: AppTheme.spaceL),
              if (_query.isEmpty &&
                  _category == null &&
                  _skillLevel == null &&
                  _squadScope == null &&
                  recommendations.isNotEmpty) ...[
                Text(
                  'Recommended for you',
                  style: AppTheme.tradingHeading(fontSize: 24),
                ),
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  _favouriteLoadout == null
                      ? 'Ranked from your onboarding goals and squad preference.'
                      : 'Ranked from your goals, squad preference and Favourite Loadout.',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _responsiveCards(
                  recommendations
                      .map(
                        (item) => _GuideCard(
                          guide: item.guide,
                          reason: item.reasons.isEmpty
                              ? 'Featured UAG guidance'
                              : item.reasons.first,
                          onTap: () => _openGuide(item.guide, guides),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppTheme.spaceXL),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Guidance library',
                      style: AppTheme.tradingHeading(fontSize: 24),
                    ),
                  ),
                  Text(
                    '${filtered.length} guides',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXL),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.tradingSoftBorder,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.manage_search_rounded,
                        size: 42,
                        color: AppTheme.neonCyan,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      const Text(
                        'No guidance matches those filters.',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                )
              else
                _responsiveCards(
                  filtered
                      .map(
                        (guide) => _GuideCard(
                          guide: guide,
                          onTap: () => _openGuide(guide, guides),
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: AppTheme.spaceXL),
            ],
          );
        },
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(AppTheme.spaceL),
    decoration: AppTheme.tradingCardDecoration(
      borderColor: AppTheme.neonCyan.withValues(alpha: .32),
      radius: 24,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 700;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLAY LIKE A PRO',
              style: AppTheme.tradingHeading(
                fontSize: 28,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            const Text(
              'Practical ARC guidance connected to how you actually play.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            const Text(
              'Browse combat, extraction, routes, loadouts, solo and squad decision-making. UAG personalises the order using your saved goals and build.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        );
        final coach = OutlinedButton.icon(
          onPressed: widget.onOpenSessionCoach,
          icon: const Icon(Icons.psychology_alt_rounded),
          label: const Text('Session Coach'),
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: AppTheme.spaceM),
              coach,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: AppTheme.spaceL),
            coach,
          ],
        );
      },
    ),
  );

  Widget _searchAndFilters() => Container(
    padding: const EdgeInsets.all(AppTheme.spaceM),
    decoration: AppTheme.tradingCardDecoration(
      borderColor: AppTheme.tradingSoftBorder,
    ),
    child: Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration:
              AppTheme.tradingInputDecoration(
                label: 'Search tactics, maps, weapons or situations',
              ).copyWith(
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        Wrap(
          spacing: AppTheme.spaceS,
          runSpacing: AppTheme.spaceS,
          children: [
            _filterMenu<PlayLikeAProCategory>(
              'Category',
              _category,
              PlayLikeAProCategory.values,
              (item) => item.label,
              (value) => setState(() => _category = value),
            ),
            _filterMenu<PlayLikeAProSkillLevel>(
              'Skill',
              _skillLevel,
              PlayLikeAProSkillLevel.values,
              (item) => item.label,
              (value) => setState(() => _skillLevel = value),
            ),
            _filterMenu<PlayLikeAProSquadScope>(
              'Squad',
              _squadScope,
              PlayLikeAProSquadScope.values
                  .where((item) => item != PlayLikeAProSquadScope.any)
                  .toList(),
              (item) => item.label,
              (value) => setState(() => _squadScope = value),
            ),
            if (_category != null ||
                _skillLevel != null ||
                _squadScope != null ||
                _query.isNotEmpty)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear'),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _filterMenu<T>(
    String label,
    T? value,
    List<T> values,
    String Function(T) labelFor,
    ValueChanged<T?> onChanged,
  ) {
    return PopupMenuButton<T?>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(value: null, child: Text('All $label')),
        ...values.map(
          (item) => PopupMenuItem<T?>(value: item, child: Text(labelFor(item))),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceS,
        ),
        decoration: AppTheme.tradingPillDecoration(
          color: value == null ? AppTheme.tradingMutedText : AppTheme.neonCyan,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == null ? label : labelFor(value),
              style: TextStyle(
                color: value == null ? Colors.white70 : AppTheme.neonCyan,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveCards(List<Widget> cards) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 650
          ? 2
          : 1;
      if (columns == 1) {
        return Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                  child: card,
                ),
              )
              .toList(),
        );
      }
      final rows = <Widget>[];
      for (var i = 0; i < cards.length; i += columns) {
        final row = cards.skip(i).take(columns).toList();
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      child: j < row.length ? row[j] : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
      return Column(children: rows);
    },
  );

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _skillLevel = null;
      _squadScope = null;
    });
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide, required this.onTap, this.reason});

  final PlayLikeAProGuide guide;
  final VoidCallback onTap;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: guide.featured
              ? AppTheme.neonCyan.withValues(alpha: .30)
              : AppTheme.tradingSoftBorder,
          radius: 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _tag(guide.category.label, AppTheme.neonCyan),
                _tag(guide.skillLevel.label, AppTheme.neonPink),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              guide.title,
              style: AppTheme.tradingHeading(fontSize: 19, color: Colors.white),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              guide.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
            if (reason != null) ...[
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: AppTheme.tradingSuccess,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reason!,
                      style: TextStyle(
                        color: AppTheme.tradingSuccess,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            const SizedBox(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  child: Text(
                    guide.squadScope.label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.neonCyan,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: AppTheme.tradingPillDecoration(color: color),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}
