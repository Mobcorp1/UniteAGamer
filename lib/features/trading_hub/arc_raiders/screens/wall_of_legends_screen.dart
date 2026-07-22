import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_wall_of_legends_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class WallOfLegendsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/wall-of-legends';

  const WallOfLegendsScreen({super.key});

  @override
  State<WallOfLegendsScreen> createState() => _WallOfLegendsScreenState();
}

class _WallOfLegendsScreenState extends State<WallOfLegendsScreen> {
  final ArcWallOfLegendsRepository _repository = ArcWallOfLegendsRepository();

  ArcWallOfLegendsCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Wall of Legends',
          style: AppTheme.neonTextStyle(
            fontSize: 24,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: StreamBuilder<List<ArcWallOfLegendsEntry>>(
          stream: _repository.watchEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _statePanel(
                icon: Icons.error_outline_rounded,
                title: 'Could not load legends',
                copy: '${snapshot.error}',
                accent: Colors.redAccent,
              );
            }

            final entries = snapshot.data ?? const <ArcWallOfLegendsEntry>[];
            final filtered = _selectedCategory == null
                ? entries
                : entries
                      .where((entry) => entry.category == _selectedCategory)
                      .toList(growable: false);

            return ArcRaidersPageList(
              maxWidth: 1120,
              children: [
                ArcRaidersPageHeader(
                  title: 'Wall of Legends',
                  subtitle:
                      'Admin-curated recognition for founders, beta Raiders, trusted traders, guardians, creators and community heroes.',
                  icon: Icons.emoji_events_rounded,
                  accent: AppTheme.neonCyan,
                ),
                const SizedBox(height: AppTheme.spaceM),
                _categoryFilters(),
                const SizedBox(height: AppTheme.spaceM),
                if (entries.isEmpty)
                  _statePanel(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Legends are awaiting admin curation',
                    copy:
                        'This read-only beta surface appears when approved historical entries are published.',
                    accent: AppTheme.neonCyan,
                  )
                else if (filtered.isEmpty)
                  _statePanel(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'No legends in this category yet',
                    copy:
                        'Try another category or check back after the next community update.',
                    accent: AppTheme.neonPink,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 680;
                      return Wrap(
                        spacing: AppTheme.spaceM,
                        runSpacing: AppTheme.spaceM,
                        children: filtered
                            .map(
                              (entry) => SizedBox(
                                width: compact
                                    ? double.infinity
                                    : (constraints.maxWidth - AppTheme.spaceM) /
                                          2,
                                child: _legendCard(entry),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _categoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(label: 'All', selected: _selectedCategory == null),
          for (final category in ArcWallOfLegendsCategory.values)
            _filterChip(
              label: category.label,
              selected: _selectedCategory == category,
              onSelected: () => setState(() => _selectedCategory = category),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    VoidCallback? onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spaceS),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: AppTheme.neonCyan.withValues(alpha: 0.20),
        side: BorderSide(
          color: selected
              ? AppTheme.neonCyan
              : Colors.white.withValues(alpha: 0.16),
        ),
        onSelected: (_) {
          if (onSelected != null) {
            onSelected();
          } else {
            setState(() => _selectedCategory = null);
          }
        },
      ),
    );
  }

  Widget _legendCard(ArcWallOfLegendsEntry entry) {
    final accent = _categoryAccent(entry.category);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: accent.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                child: Icon(Icons.emoji_events_rounded, color: accent),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tradingHeading(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _pill(entry.category.label, accent),
              if (entry.uagId.isNotEmpty) _pill(entry.uagId, AppTheme.neonCyan),
              if (entry.seasonId.isNotEmpty)
                _pill(entry.seasonId, Colors.amberAccent),
            ],
          ),
          if (entry.reason.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceM),
            Text(
              entry.reason,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceS,
        vertical: 6,
      ),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 12, color: color, isBold: true),
      ),
    );
  }

  Widget _statePanel({
    required IconData icon,
    required String title,
    required String copy,
    required Color accent,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: accent.withValues(alpha: 0.24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 34),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.tradingHeading(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              copy,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryAccent(ArcWallOfLegendsCategory category) {
    return switch (category) {
      ArcWallOfLegendsCategory.founders => Colors.amberAccent,
      ArcWallOfLegendsCategory.closedBetaRaiders => AppTheme.neonCyan,
      ArcWallOfLegendsCategory.communityHeroes => Colors.lightGreenAccent,
      ArcWallOfLegendsCategory.guardians => Colors.lightGreenAccent,
      ArcWallOfLegendsCategory.trustedTraders => AppTheme.neonPink,
      ArcWallOfLegendsCategory.topIntelContributors => Colors.amberAccent,
      ArcWallOfLegendsCategory.creators => AppTheme.neonPink,
      ArcWallOfLegendsCategory.competitionWinners => AppTheme.neonCyan,
    };
  }
}
