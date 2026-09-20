import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_tactical_banner_ad.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_progression_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_tracker_card_metrics.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_filter.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_scrappy_item_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/missing_scrappy_dialog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/scrappy_actions_menu.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/scrappy_feed_queue_section.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/scrappy_filter_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/scrappy_progress_header.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/scrappy_tile.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_dialogs.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_page_carousel.dart';

enum ArcScrappyTrackerMode { scrappy, bench, quest }

class ScrappyGridScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/scrappy';
  static const benchRouteName = '/trading-hub/arc-raiders/bench';
  static const questRouteName = '/trading-hub/arc-raiders/quests';

  const ScrappyGridScreen({
    super.key,
    this.initialMode = ArcScrappyTrackerMode.scrappy,
  });

  const ScrappyGridScreen.bench({super.key})
    : initialMode = ArcScrappyTrackerMode.bench;

  const ScrappyGridScreen.quest({super.key})
    : initialMode = ArcScrappyTrackerMode.quest;

  final ArcScrappyTrackerMode initialMode;

  @override
  State<ScrappyGridScreen> createState() => _ScrappyGridScreenState();
}

class _ScrappyGridScreenState extends State<ScrappyGridScreen> {
  final ArcScrappyRepository _repository = ArcScrappyRepository();
  final ArcProgressionRepository _progressionRepository =
      ArcProgressionRepository();
  final ArcProgressionEngine _progressionEngine = const ArcProgressionEngine();
  final ArcUserPersonalisationRepository _personalisationRepository =
      ArcUserPersonalisationRepository();
  final Set<String> _expandedSections = <String>{};

  late Stream<ArcScrappyRepositoryState<Map<String, ArcScrappyState>>>
  _scrappyStateStream;
  late Stream<ArcUserPersonalisationProfile> _personalisationStream;
  Map<String, ArcScrappyState> _lastScrappyStates =
      const <String, ArcScrappyState>{};

  ArcScrappyFilter _selectedFilter = ArcScrappyFilter.all;
  late ArcScrappyTrackerMode _mode;
  bool _showFeedScrappy = false;
  String _feedGoal = 'Overall';
  String? _selectedBenchCategory;
  int _trackerCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _scrappyStateStream = _repository.watchMyScrappyStates();
    _personalisationStream = _personalisationRepository.watchProfile();
  }

  void _retryTrackerSync() {
    setState(() {
      _scrappyStateStream = _repository.watchMyScrappyStates();
    });
  }

  @override
  void didUpdateWidget(covariant ScrappyGridScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
      _selectedFilter = ArcScrappyFilter.all;
      _showFeedScrappy = false;
      _selectedBenchCategory = null;
      _trackerCarouselIndex = 0;
      _expandedSections.clear();
    }
  }

  List<ArcScrappyItem> get _allItems {
    final items = switch (_mode) {
      ArcScrappyTrackerMode.scrappy =>
        ArcScrappySeedData.items.whereType<ArcScrappyItem>().toList(),
      ArcScrappyTrackerMode.bench =>
        ArcBenchUpgradeSeedData.items.whereType<ArcScrappyItem>().toList(),
      ArcScrappyTrackerMode.quest =>
        ArcQuestRequirementSeedData.items.whereType<ArcScrappyItem>().toList(),
    };
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  String get _modeTitle {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'Scrappy Intel';
      case ArcScrappyTrackerMode.bench:
        return 'Bench Operations';
      case ArcScrappyTrackerMode.quest:
        return 'Quest Tracker';
    }
  }

  String get _headerTitle {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'ARC Raiders Scrappy Intel';
      case ArcScrappyTrackerMode.bench:
        return 'ARC Raiders Bench Operations';
      case ArcScrappyTrackerMode.quest:
        return 'Quest Tracker';
    }
  }

  ArcProgressionWorkspace get _progressionWorkspace {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return ArcProgressionWorkspace.scrappy;
      case ArcScrappyTrackerMode.bench:
        return ArcProgressionWorkspace.bench;
      case ArcScrappyTrackerMode.quest:
        return ArcProgressionWorkspace.quest;
    }
  }

  String get _emptyMessage {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'No scrappy items match this filter yet.';
      case ArcScrappyTrackerMode.bench:
        return 'No bench upgrade materials match this filter yet.';
      case ArcScrappyTrackerMode.quest:
        return 'No quest collection items match this filter yet.';
    }
  }

  List<ArcScrappyItem> _applyFilter(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    return items.where((item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      switch (_selectedFilter) {
        case ArcScrappyFilter.all:
          return true;
        case ArcScrappyFilter.owned:
          return state.ownedFor(item.neededCount);
        case ArcScrappyFilter.missing:
          return !state.ownedFor(item.neededCount);
        case ArcScrappyFilter.duplicates:
          return state.hasDuplicatesFor(item.neededCount);
        case ArcScrappyFilter.wanted:
          return state.wantedFor(item.neededCount);
        case ArcScrappyFilter.tradeable:
          return state.availableToTradeFor(item.neededCount);
      }
    }).toList();
  }

  Map<ArcScrappyFilter, int> _buildCounts(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    int countWhere(
      bool Function(ArcScrappyItem item, ArcScrappyState state) predicate,
    ) {
      var count = 0;
      for (final item in items) {
        final state = states[item.id] ?? ArcScrappyState.empty(item.id);
        if (predicate(item, state)) count++;
      }
      return count;
    }

    final ownedCount = countWhere(
      (item, state) => state.ownedFor(item.neededCount),
    );

    return {
      ArcScrappyFilter.all: items.length,
      ArcScrappyFilter.owned: ownedCount,
      ArcScrappyFilter.missing: items.length - ownedCount,
      ArcScrappyFilter.duplicates: countWhere(
        (item, state) => state.hasDuplicatesFor(item.neededCount),
      ),
      ArcScrappyFilter.wanted: countWhere(
        (item, state) => state.wantedFor(item.neededCount),
      ),
      ArcScrappyFilter.tradeable: countWhere(
        (item, state) => state.availableToTradeFor(item.neededCount),
      ),
    };
  }

  Color _tierColor(ArcScrappyTier tier) {
    switch (tier) {
      case ArcScrappyTier.tier1:
        return Colors.white70;
      case ArcScrappyTier.tier2:
        return Colors.lightGreenAccent;
      case ArcScrappyTier.tier3:
        return AppTheme.neonCyan;
      case ArcScrappyTier.tier4:
        return AppTheme.neonPink;
    }
  }

  Color _modeAccent() {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return AppTheme.neonPink;
      case ArcScrappyTrackerMode.bench:
        return AppTheme.neonCyan;
      case ArcScrappyTrackerMode.quest:
        return Colors.amberAccent;
    }
  }

  String _sectionSubtitle(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    final completed = _completedCount(items, states);
    final totalRequired = items.fold<int>(
      0,
      (total, item) => total + item.neededCount,
    );
    return '$completed / ${items.length} complete - $totalRequired total needed';
  }

  int _completedCount(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    return items.where((item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return state.ownedFor(item.neededCount);
    }).length;
  }

  String _tierLabel(ArcScrappyTier tier) {
    switch (tier) {
      case ArcScrappyTier.tier1:
        return 'Tier 1';
      case ArcScrappyTier.tier2:
        return 'Tier 2';
      case ArcScrappyTier.tier3:
        return 'Tier 3';
      case ArcScrappyTier.tier4:
        return 'Tier 4';
    }
  }

  String _separator() => ' ${String.fromCharCode(0x2022)} ';

  Future<void> _confirmClearSingleItem(
    ArcScrappyItem item,
    ArcScrappyState currentState,
  ) async {
    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Clear ${item.name}?',
      message:
          'This will remove the collected amount for this ${_modeWord()} item and reset it back to zero.',
      titleColor: ArcUiTokens.danger,
      confirmLabel: 'Clear',
      confirmBackgroundColor: ArcUiTokens.danger,
      confirmForegroundColor: ArcUiTokens.background,
      borderColor: ArcUiTokens.danger,
    );

    if (confirmed != true) return;

    try {
      await _repository.saveScrappyState(
        currentState.copyWith(collectedCount: 0, updatedAt: DateTime.now()),
        neededCount: item.neededCount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} cleared.')));
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear ${item.name}. Try again.')),
      );
    }
  }

  String _modeWord() {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'scrappy';
      case ArcScrappyTrackerMode.bench:
        return 'bench';
      case ArcScrappyTrackerMode.quest:
        return 'quest';
    }
  }

  Future<void> _confirmResetGrid() async {
    final items = _allItems;
    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Reset $_modeTitle?',
      message: switch (_mode) {
        ArcScrappyTrackerMode.scrappy =>
          'This will remove all collected Scrappy progress and surplus from the Scrappy Intel only.',
        ArcScrappyTrackerMode.bench =>
          'This will remove all collected bench upgrade material progress from the Bench Operations only.',
        ArcScrappyTrackerMode.quest =>
          'This will remove all collected quest item progress from the Mission Operations only.',
      },
      titleColor: ArcUiTokens.danger,
      confirmLabel: 'Confirm Reset',
      confirmBackgroundColor: ArcUiTokens.danger,
      confirmForegroundColor: ArcUiTokens.background,
      borderColor: ArcUiTokens.danger,
    );

    if (confirmed != true) return;

    try {
      await _repository.resetAllScrappyStates(items.map((item) => item.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$_modeTitle reset.')));
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset tracker. Try again.')),
      );
    }
  }

  Future<void> _showMissingItemInfo(
    ArcScrappyItem item,
    ArcScrappyState currentState,
  ) async {
    final markedOwned = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MissingScrappyDialog(
          item: item,
          currentState: currentState,
          repository: _repository,
          tierColor: _tierColor(item.tier),
        );
      },
    );

    if (markedOwned == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} progress updated.')));
      setState(() {});
    }
  }

  Future<void> _openItemEditor(
    ArcScrappyItem item,
    ArcScrappyState initialState,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ArcScrappyItemSheet(
          item: item,
          initialState: initialState,
          repository: _repository,
          tierColor: _tierColor(item.tier),
          onSaved: () {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${item.name} saved.')));
            setState(() {});
          },
          onClear: () => _confirmClearSingleItem(item, initialState),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {});
    }
  }

  Widget _buildAdaptiveTileWrap(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    return _buildCompactSectionTileLayout(items, states);
  }

  Widget _buildCompactSectionTileLayout(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget tileFor(ArcScrappyItem item, double width) {
      return SizedBox(
        width: width,
        child: ScrappyTile(
          item: item,
          state: states[item.id] ?? ArcScrappyState.empty(item.id),
          landscape: isLandscape,
          tierColor: _tierColor(item.tier),
          onTap: () {
            final state = states[item.id] ?? ArcScrappyState.empty(item.id);
            if (state.collectedCount > 0) {
              _openItemEditor(item, state);
            } else {
              _showMissingItemInfo(item, state);
            }
          },
          onLongPress: () {
            final state = states[item.id] ?? ArcScrappyState.empty(item.id);
            _openItemEditor(item, state);
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final isWide = rawWidth >= 720;
        final panelWidth = rawWidth
            .clamp(252.0, isWide ? 560.0 : 372.0)
            .toDouble();
        const spacing = 5.0;

        final compactTileWidth = ((panelWidth - (spacing * 2)) / 3)
            .clamp(82.0, 148.0)
            .toDouble();

        if (items.length == 1) {
          return Center(child: tileFor(items.first, compactTileWidth));
        }

        if (items.length == 2) {
          return Center(
            child: SizedBox(
              width: panelWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tileFor(items[0], compactTileWidth),
                  const SizedBox(width: spacing),
                  tileFor(items[1], compactTileWidth),
                ],
              ),
            ),
          );
        }

        final columns = rawWidth >= 900
            ? 5
            : rawWidth >= 640
            ? 4
            : items.length <= 2
            ? 2
            : 3;
        final tileWidth = ((panelWidth - (spacing * (columns - 1))) / columns)
            .clamp(82.0, 148.0)
            .toDouble();

        return Center(
          child: SizedBox(
            width: panelWidth,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.center,
              children: [for (final item in items) tileFor(item, tileWidth)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
      ),
      child: Text(
        _emptyMessage,
        style: const TextStyle(color: Colors.white70, height: 1.35),
      ),
    );
  }

  Future<void> _markSectionComplete(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) async {
    for (final item in items) {
      final current = states[item.id] ?? ArcScrappyState.empty(item.id);
      if (current.collectedCount < item.neededCount) {
        await _repository.saveScrappyState(
          current.copyWith(collectedCount: item.neededCount),
          neededCount: item.neededCount,
        );
      }
    }
  }

  Map<String, ArcScrappyState> _statesWithSectionComplete(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    final updated = Map<String, ArcScrappyState>.from(states);
    for (final item in items) {
      final current = updated[item.id] ?? ArcScrappyState.empty(item.id);
      if (current.collectedCount < item.neededCount) {
        updated[item.id] = current.copyWith(
          collectedCount: item.neededCount,
          updatedAt: DateTime.now(),
        );
      }
    }
    return updated;
  }

  Future<void> _recordSectionProgression({
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> completedStates,
  }) async {
    switch (_mode) {
      case ArcScrappyTrackerMode.quest:
        final questId = _progressionEngine.questIdForItems(items);
        if (questId.isEmpty) return;
        await _progressionRepository.confirmQuestCompleted(
          questId: questId,
          scrappyStates: completedStates,
        );
        return;
      case ArcScrappyTrackerMode.scrappy:
        final level = _progressionEngine.scrappyLevelForItems(items);
        if (level <= 0) return;
        await _progressionRepository.confirmScrappyUpgrade(
          level: level,
          scrappyStates: completedStates,
        );
        return;
      case ArcScrappyTrackerMode.bench:
        if (items.isEmpty) return;
        final station = items.first.category;
        final level = _progressionEngine.benchLevelForItems(items);
        if (station.trim().isEmpty || level <= 0) return;
        await _progressionRepository.confirmBenchUpgrade(
          station: station,
          level: level,
          scrappyStates: completedStates,
        );
        return;
    }
  }

  Future<void> _confirmMarkSectionComplete({
    required String title,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
  }) async {
    final incompleteItems = items
        .where((item) {
          final current = states[item.id] ?? ArcScrappyState.empty(item.id);
          return current.collectedCount < item.neededCount;
        })
        .toList(growable: false);
    if (incompleteItems.isEmpty) return;

    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Complete $title?',
      message:
          'This will set ${incompleteItems.length} unfinished ${_modeWord()} item${incompleteItems.length == 1 ? '' : 's'} to their required target and persist the confirmation for this season.',
      titleColor: _modeAccent(),
      confirmLabel: 'Confirm Complete',
      confirmBackgroundColor: _modeAccent(),
      confirmForegroundColor: ArcUiTokens.background,
      borderColor: _modeAccent(),
    );

    if (confirmed != true) return;
    try {
      final completedStates = _statesWithSectionComplete(items, states);
      await _markSectionComplete(items, states);
      await _recordSectionProgression(
        items: items,
        completedStates: completedStates,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title completion saved.')));
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete $title. Try again.')),
      );
    }
  }

  Widget _buildExpansionSection({
    required String id,
    required String title,
    required Color color,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
    String? subtitle,
    Widget? child,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final completed = _completedCount(items, states);
    final neededTotal = items.fold<int>(
      0,
      (total, item) => total + item.neededCount,
    );
    final gotTotal = items.fold<int>(0, (total, item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return total + state.collectedCount.clamp(0, item.neededCount);
    });
    final wantedTotal = (neededTotal - gotTotal).clamp(0, neededTotal);
    final duplicateTotal = items.fold<int>(0, (total, item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return total + state.surplusFor(item.neededCount);
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.raised,
            accent: color,
            radius: ArcUiTokens.radiusXL,
            borderOpacity: 0.34,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  _ProgressPill(
                    text: '$completed / ${items.length}',
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle ?? _sectionSubtitle(items, states),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _ProgressPill(text: 'Need $neededTotal', color: color),
                    _ProgressPill(
                      text: 'Got $gotTotal',
                      color: ArcUiTokens.success,
                    ),
                    _ProgressPill(
                      text: 'Wanted $wantedTotal',
                      color: ArcUiTokens.secondaryAccent,
                    ),
                    if (duplicateTotal > 0)
                      _ProgressPill(
                        text: 'Dupes $duplicateTotal',
                        color: ArcUiTokens.warning,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: OutlinedButton.icon(
                    onPressed: wantedTotal == 0
                        ? null
                        : () => _confirmMarkSectionComplete(
                            title: title,
                            items: items,
                            states: states,
                          ),
                    icon: Icon(
                      wantedTotal == 0
                          ? Icons.check_circle_rounded
                          : Icons.task_alt_rounded,
                      size: 17,
                    ),
                    label: Text(wantedTotal == 0 ? 'DONE' : 'COMPLETE'),
                    style: ArcUiTokens.textButtonStyle(accent: color).copyWith(
                      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              child ?? _buildAdaptiveTileWrap(items, states),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrappyHero(Map<ArcScrappyFilter, int> counts) {
    final needed = counts[ArcScrappyFilter.missing] ?? 0;
    final ready = counts[ArcScrappyFilter.owned] ?? 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusM,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _showFeedScrappy
                    ? Icons.restaurant_rounded
                    : Icons.grid_view_rounded,
                size: 17,
                color: ArcUiTokens.primaryAccent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _showFeedScrappy
                      ? 'FEED PLAN'
                      : '$needed NEEDED${_separator()}$ready READY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.metadata(
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _buildScrappyFeedTabs(),
          const SizedBox(height: 6),
          if (_showFeedScrappy)
            _buildFeedGoalBar()
          else
            ScrappyFilterBar(
              selectedFilter: _selectedFilter,
              counts: counts,
              onFilterSelected: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeedGoalBar() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ScrappyFeedQueueSection.goals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final goal = ScrappyFeedQueueSection.goals[index];
          final selected = goal == _feedGoal;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            label: Text(goal.toUpperCase()),
            labelStyle: TextStyle(
              color: selected
                  ? ArcUiTokens.background
                  : ArcUiTokens.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: ArcUiTokens.primaryAccent,
            backgroundColor: Colors.black.withValues(alpha: 0.56),
            side: BorderSide(
              color: selected
                  ? ArcUiTokens.primaryAccent
                  : Colors.white.withValues(alpha: 0.12),
            ),
            onSelected: (_) => setState(() => _feedGoal = goal),
          );
        },
      ),
    );
  }

  Widget _buildScrappyFeedTabs() {
    if (_mode != ArcScrappyTrackerMode.scrappy) {
      return const SizedBox.shrink();
    }

    Widget tab({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      required IconData icon,
    }) {
      final color = selected
          ? ArcUiTokens.secondaryAccent
          : ArcUiTokens.primaryAccent;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM,
              vertical: AppTheme.spaceS,
            ),
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.interactive,
              accent: color,
              radius: ArcUiTokens.radiusXL,
              selected: selected,
              backgroundColor: selected
                  ? color.withValues(alpha: 0.13)
                  : ArcUiTokens.surfaceInteractive.withValues(alpha: 0.74),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(
          label: 'Tracker',
          icon: Icons.grid_view_rounded,
          selected: !_showFeedScrappy,
          onTap: () => setState(() {
            _showFeedScrappy = false;
            _trackerCarouselIndex = 0;
          }),
        ),
        const SizedBox(width: AppTheme.spaceS),
        tab(
          label: 'Feed Scrappy',
          icon: Icons.restaurant_rounded,
          selected: _showFeedScrappy,
          onTap: () => setState(() {
            _showFeedScrappy = true;
            _trackerCarouselIndex = 0;
          }),
        ),
      ],
    );
  }

  Widget _buildTrackerCarousel(
    List<Widget> cards, {
    required int maxItemCount,
  }) {
    if (cards.isEmpty) return _buildEmptyState();

    if (_trackerCarouselIndex >= cards.length) {
      _trackerCarouselIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageWidth = constraints.maxWidth;
        final centreHeight = ArcCompactTrackerCardMetrics.centreHeight(
          stageWidth: stageWidth,
          maxItemCount: maxItemCount,
        );

        return SizedBox(
          height: centreHeight + 42,
          child: UagPageCarousel(
            key: ValueKey(
              'tracker-carousel-${_mode.name}-${cards.length}-$maxItemCount',
            ),
            viewportFraction: 0.90,
            tabletViewportFraction: 0.66,
            webViewportFraction: stageWidth >= 1180 ? 0.42 : 0.52,
            padEnds: true,
            enable3d: cards.length > 1,
            sideScale: 0.90,
            outerScale: 0.78,
            maxSideLift: 8,
            maxSideRotation: 0.08,
            onPageChanged: (index) {
              setState(() => _trackerCarouselIndex = index);
            },
            pages: [
              for (var i = 0; i < cards.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SingleChildScrollView(
                    physics: i == _trackerCarouselIndex
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: cards[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrappyList(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    final tierGroups = <ArcScrappyTier, List<ArcScrappyItem>>{};
    for (final item in filtered) {
      tierGroups.putIfAbsent(item.tier, () => <ArcScrappyItem>[]).add(item);
    }

    ArcScrappyTier? activeTier;
    for (final tier in ArcScrappyTier.values) {
      final tierItems = _allItems.where((item) => item.tier == tier).toList();
      if (tierItems.isNotEmpty &&
          _completedCount(tierItems, states) < tierItems.length) {
        activeTier = tier;
        break;
      }
    }

    final visibleTiers = ArcScrappyTier.values
        .where(
          (tier) => (tierGroups[tier] ?? const <ArcScrappyItem>[]).isNotEmpty,
        )
        .toList();
    if (activeTier != null && visibleTiers.remove(activeTier)) {
      visibleTiers.insert(0, activeTier);
    }

    final cards = <Widget>[
      for (final tier in visibleTiers)
        Builder(
          builder: (context) {
            final tierItems = tierGroups[tier] ?? const <ArcScrappyItem>[];
            final isActive = tier == activeTier;
            final isComplete =
                _completedCount(tierItems, states) == tierItems.length;
            final card = _buildExpansionSection(
              id: 'scrappy-${tier.name}',
              title: isActive
                  ? 'CURRENT${_separator()}${_tierLabel(tier)}'
                  : isComplete
                  ? 'COMPLETE${_separator()}${_tierLabel(tier)}'
                  : 'PLAN AHEAD${_separator()}${_tierLabel(tier)}',
              color: isActive ? ArcUiTokens.primaryAccent : _tierColor(tier),
              items: tierItems,
              states: states,
            );
            return isActive
                ? _ElectricActiveTierCard(child: card)
                : Opacity(opacity: isComplete ? .72 : .90, child: card);
          },
        ),
    ];

    final maxItemCount = tierGroups.values.fold<int>(
      0,
      (max, items) => items.length > max ? items.length : max,
    );
    final allComplete = activeTier == null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                allComplete
                    ? 'ALL SCRAPPY TIERS COMPLETE'
                    : 'SWIPE TO PLAN AHEAD${_separator()}ACTIVE TIER IS ELECTRIFIED',
                style: ArcUiTokens.metadata(
                  color: allComplete
                      ? ArcUiTokens.success
                      : ArcUiTokens.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: allComplete
                    ? null
                    : () => _confirmMarkSectionComplete(
                        title: 'all Scrappy tiers',
                        items: _allItems,
                        states: states,
                      ),
                icon: const Icon(Icons.done_all_rounded, size: 15),
                label: const Text('COMPLETE ALL'),
                style:
                    ArcUiTokens.textButtonStyle(
                      accent: ArcUiTokens.secondaryAccent,
                    ).copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 9),
                      ),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildTrackerCarousel(
          cards,
          maxItemCount: maxItemCount < 3 ? 3 : maxItemCount,
        ),
      ],
    );
  }

  List<String> _benchCategories(List<ArcScrappyItem> items) {
    final categories = <String>[];
    for (final item in items) {
      if (!categories.contains(item.category)) {
        categories.add(item.category);
      }
    }
    return categories;
  }

  Widget _buildBenchHero(
    List<ArcScrappyItem> allItems,
    Map<String, ArcScrappyState> states,
  ) {
    final categories = _benchCategories(allItems);
    if (categories.isNotEmpty &&
        (_selectedBenchCategory == null ||
            !categories.contains(_selectedBenchCategory))) {
      _selectedBenchCategory = categories.first;
    }
    final selected = _selectedBenchCategory;
    final stationItems = selected == null
        ? const <ArcScrappyItem>[]
        : allItems.where((item) => item.category == selected).toList();
    final complete = stationItems.where((item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return state.ownedFor(item.neededCount);
    }).length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusM,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handyman_rounded,
                size: 17,
                color: ArcUiTokens.primaryAccent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  selected == null
                      ? 'CHOOSE A BENCH'
                      : '$selected${_separator()}$complete / ${stationItems.length} READY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.metadata(
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, index) {
                final category = categories[index];
                final isSelected = category == selected;
                return ChoiceChip(
                  selected: isSelected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  label: Text(category.toUpperCase()),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? ArcUiTokens.background
                        : ArcUiTokens.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  selectedColor: ArcUiTokens.primaryAccent,
                  backgroundColor: ArcUiTokens.surfaceInteractive,
                  side: BorderSide(
                    color: isSelected
                        ? ArcUiTokens.primaryAccent
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                  onSelected: (_) => setState(() {
                    _selectedBenchCategory = category;
                    _trackerCarouselIndex = 0;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchCarousel(
    List<ArcScrappyItem> allItems,
    Map<String, ArcScrappyState> states,
  ) {
    final categories = _benchCategories(allItems);
    final selected =
        (_selectedBenchCategory != null &&
            categories.contains(_selectedBenchCategory))
        ? _selectedBenchCategory!
        : (categories.isEmpty ? '' : categories.first);
    if (selected.isEmpty) return _buildEmptyState();

    final stationItems = allItems
        .where((item) => item.category == selected)
        .toList();
    final tiers = <String, List<ArcScrappyItem>>{};
    for (final item in stationItems) {
      final tier = _displayGroupTitle(item.category, item.group);
      tiers.putIfAbsent(tier, () => <ArcScrappyItem>[]).add(item);
    }

    String? activeTier;
    for (final entry in tiers.entries) {
      final complete = entry.value.every((item) {
        final state = states[item.id] ?? ArcScrappyState.empty(item.id);
        return state.ownedFor(item.neededCount);
      });
      if (!complete) {
        activeTier = entry.key;
        break;
      }
    }

    final visibleTiers = tiers.keys.toList();
    if (activeTier != null && visibleTiers.remove(activeTier)) {
      visibleTiers.insert(0, activeTier);
    }

    final cards = <Widget>[
      for (final tier in visibleTiers)
        Builder(
          builder: (context) {
            final items = tiers[tier] ?? const <ArcScrappyItem>[];
            final isActive = tier == activeTier;
            final isComplete = items.every((item) {
              final state = states[item.id] ?? ArcScrappyState.empty(item.id);
              return state.ownedFor(item.neededCount);
            });
            final card = _buildExpansionSection(
              id: 'bench-$selected-$tier',
              title: isActive
                  ? 'CURRENT${_separator()}$tier'
                  : isComplete
                  ? 'COMPLETE${_separator()}$tier'
                  : 'PLAN AHEAD${_separator()}$tier',
              color: isActive
                  ? ArcUiTokens.primaryAccent
                  : _groupColor(items, items.first.group),
              items: items,
              states: states,
              subtitle: '${items.length} upgrade materials',
            );
            return isActive
                ? _ElectricActiveTierCard(child: card)
                : Opacity(opacity: isComplete ? .72 : .90, child: card);
          },
        ),
    ];

    final maxItemCount = tiers.values.fold<int>(
      0,
      (max, items) => items.length > max ? items.length : max,
    );
    final allComplete = activeTier == null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                allComplete
                    ? '$selected COMPLETE'
                    : 'SWIPE TIERS${_separator()}CURRENT TIER IS ELECTRIFIED',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.metadata(
                  color: allComplete
                      ? ArcUiTokens.success
                      : ArcUiTokens.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: allComplete
                    ? null
                    : () => _confirmMarkSectionComplete(
                        title: '$selected bench',
                        items: stationItems,
                        states: states,
                      ),
                icon: const Icon(Icons.done_all_rounded, size: 15),
                label: const Text('COMPLETE ALL'),
                style:
                    ArcUiTokens.textButtonStyle(
                      accent: ArcUiTokens.secondaryAccent,
                    ).copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 9),
                      ),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildTrackerCarousel(
          cards,
          maxItemCount: maxItemCount < 3 ? 3 : maxItemCount,
        ),
      ],
    );
  }

  String _questProgressContextLabel(ArcQuestProgressState state) {
    switch (state) {
      case ArcQuestProgressState.startingOrReset:
        return 'START / RESET';
      case ArcQuestProgressState.continuing:
        return 'CONTINUING';
      case ArcQuestProgressState.unsure:
        return 'NOT SET';
    }
  }

  String _questProgressContextMessage(ArcQuestProgressState state) {
    switch (state) {
      case ArcQuestProgressState.startingOrReset:
        return 'UAG will treat this Expedition as a fresh quest run.';
      case ArcQuestProgressState.continuing:
        return 'UAG will treat your existing quest progression as current.';
      case ArcQuestProgressState.unsure:
        return 'Set whether this Expedition is restarting or continuing quests.';
    }
  }

  Future<void> _saveQuestProgressContext(
    ArcUserPersonalisationProfile profile,
    ArcQuestProgressState state,
  ) async {
    if (profile.questProgress == state) return;
    try {
      await _personalisationRepository.saveProfile(
        profile.copyWith(questProgress: state),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quest plan set to ${_questProgressContextLabel(state)}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update quest plan. Try again.'),
        ),
      );
    }
  }

  Widget _buildQuestProgressContext() {
    return StreamBuilder<ArcUserPersonalisationProfile>(
      stream: _personalisationStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const ArcRaidersStatePanel(
            title: 'Loading quest plan',
            message: 'Checking your Expedition quest preference.',
            icon: Icons.sync_rounded,
            accent: ArcUiTokens.warning,
            compact: true,
          );
        }

        final profile =
            snapshot.data ?? ArcUserPersonalisationProfile.defaults;
        final current = profile.questProgress;

        Widget option(ArcQuestProgressState state, String label) {
          final selected = current == state;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            label: Text(label),
            selectedColor: ArcUiTokens.warning,
            backgroundColor: ArcUiTokens.surfaceInteractive,
            side: BorderSide(
              color: selected
                  ? ArcUiTokens.warning
                  : Colors.white.withValues(alpha: 0.12),
            ),
            labelStyle: TextStyle(
              color: selected
                  ? ArcUiTokens.background
                  : ArcUiTokens.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
            onSelected: (_) => _saveQuestProgressContext(profile, state),
          );
        }

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.panel,
            radius: ArcUiTokens.radiusM,
            accent: ArcUiTokens.warning,
            borderOpacity: 0.20,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 560;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        color: ArcUiTokens.warning,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'EXPEDITION QUEST PLAN${_separator()}${_questProgressContextLabel(current)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArcUiTokens.metadata(
                            color: ArcUiTokens.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _questProgressContextMessage(current),
                    style: ArcUiTokens.metadata(
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Context only - changing this does not erase Quest Tracker progress.',
                    style: ArcUiTokens.metadata(
                      color: ArcUiTokens.textTertiary,
                    ),
                  ),
                ],
              );

              final choices = Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  option(
                    ArcQuestProgressState.startingOrReset,
                    'START / RESET',
                  ),
                  option(ArcQuestProgressState.continuing, 'CONTINUE'),
                ],
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copy,
                    const SizedBox(height: 8),
                    choices,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 12),
                  choices,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuestKanban(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    if (items.isEmpty) return _buildEmptyState();

    final needed = <ArcScrappyItem>[];
    final inProgress = <ArcScrappyItem>[];
    final complete = <ArcScrappyItem>[];

    for (final item in items) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      if (state.ownedFor(item.neededCount)) {
        complete.add(item);
      } else if (state.collectedCount > 0) {
        inProgress.add(item);
      } else {
        needed.add(item);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final useColumns = width >= 720;

        if (!useColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _questColumn(
                title: 'Needed',
                color: ArcUiTokens.secondaryAccent,
                items: needed,
                states: states,
                width: width,
              ),
              const SizedBox(height: 8),
              _questColumn(
                title: 'In Progress',
                color: ArcUiTokens.primaryAccent,
                items: inProgress,
                states: states,
                width: width,
              ),
              const SizedBox(height: 8),
              _questColumn(
                title: 'Complete',
                color: ArcUiTokens.success,
                items: complete,
                states: states,
                width: width,
              ),
            ],
          );
        }

        final columnWidth = ((width - 24) / 3).clamp(210.0, 420.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _questColumn(
                title: 'Needed',
                color: ArcUiTokens.secondaryAccent,
                items: needed,
                states: states,
                width: columnWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _questColumn(
                title: 'In Progress',
                color: ArcUiTokens.primaryAccent,
                items: inProgress,
                states: states,
                width: columnWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _questColumn(
                title: 'Complete',
                color: ArcUiTokens.success,
                items: complete,
                states: states,
                width: columnWidth,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _questColumn({
    required String title,
    required Color color,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: ArcUiTokens.compactPanelPadding,
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.panel,
          radius: ArcUiTokens.radiusM,
          accent: color,
          borderOpacity: 0.20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: ArcUiTokens.label(color: color),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'Clear.',
                style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
              )
            else
              ...items.map((item) {
                final state = states[item.id] ?? ArcScrappyState.empty(item.id);
                return _questKanbanCard(item, state, color);
              }),
          ],
        ),
      ),
    );
  }

  Widget _questKanbanCard(
    ArcScrappyItem item,
    ArcScrappyState state,
    Color color,
  ) {
    final needed = item.neededCount <= 0 ? 1 : item.neededCount;
    final collected = state.collectedCount.clamp(0, needed);
    final progress = collected / needed;
    final complete = state.ownedFor(item.neededCount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        onTap: () => state.collectedCount > 0
            ? _openItemEditor(item, state)
            : _showMissingItemInfo(item, state),
        onLongPress: () => _openItemEditor(item, state),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.interactive,
            radius: ArcUiTokens.radiusS,
            accent: complete ? ArcUiTokens.success : color,
            borderOpacity: complete ? 0.26 : 0.14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: ArcUiTokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.assignment_rounded,
                    color: color.withValues(alpha: 0.65),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.cardTitle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayGroupTitle(item.category, item.group),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.metadata(
                        color: ArcUiTokens.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.07),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          complete ? ArcUiTokens.success : color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$collected / $needed',
                          style: ArcUiTokens.metadata(
                            color: complete ? ArcUiTokens.success : color,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          complete
                              ? 'COMPLETE'
                              : collected > 0
                              ? 'ACTIVE'
                              : 'NEEDED',
                          style: ArcUiTokens.metadata(
                            color: complete ? ArcUiTokens.success : color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _groupColor(List<ArcScrappyItem> items, String group) {
    final groupItem = items.firstWhere(
      (item) => item.group == group,
      orElse: () => items.first,
    );
    return _mode == ArcScrappyTrackerMode.quest
        ? Colors.amberAccent
        : _tierColor(groupItem.tier);
  }

  String _displayGroupTitle(String category, String group) {
    if (_mode == ArcScrappyTrackerMode.bench) {
      return group
          .replaceFirst('$category Lv.', 'Tier ')
          .replaceFirst('$category Tier ', 'Tier ');
    }
    return group;
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _allItems;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: UagEntitledAdAwareBottomDock(
        child: ArcCompanionBottomDock(
          activeLabel: _mode == ArcScrappyTrackerMode.quest
              ? 'Quest Tracker'
              : 'Scrappy Intel',
        ),
      ),
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: ArcUiTokens.background.withValues(alpha: 0.98),
        title: Text(
          _modeTitle,
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
        actions: [ScrappyActionsMenu(onResetGrid: _confirmResetGrid)],
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: StreamBuilder<
          ArcScrappyRepositoryState<Map<String, ArcScrappyState>>
        >(
          stream: _scrappyStateStream,
          builder: (context, snapshot) {
            final repositoryState = snapshot.data;
            final status =
                repositoryState?.status ??
                ArcScrappyRepositoryStateStatus.restoring;
            final incomingStates = repositoryState?.data;
            if (incomingStates != null) {
              _lastScrappyStates = incomingStates;
            } else if (status == ArcScrappyRepositoryStateStatus.empty ||
                status == ArcScrappyRepositoryStateStatus.unauthenticated) {
              _lastScrappyStates = const <String, ArcScrappyState>{};
            }

            final states =
                incomingStates ??
                (_lastScrappyStates.isNotEmpty
                    ? _lastScrappyStates
                    : const <String, ArcScrappyState>{});

            if ((status == ArcScrappyRepositoryStateStatus.restoring ||
                    status == ArcScrappyRepositoryStateStatus.loading) &&
                states.isEmpty) {
              return ArcRaidersPageList(
                maxWidth: 1220,
                bottomPadding: 120,
                children: [
                  ArcProgressionWorkspaceBar(
                    current: _progressionWorkspace,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  const ArcRaidersStatePanel(
                    title: 'Restoring tracker progress',
                    message:
                        'Loading your saved Scrappy, bench and quest material state.',
                    icon: Icons.sync_rounded,
                    compact: true,
                  ),
                ],
              );
            }

            if (status == ArcScrappyRepositoryStateStatus.unauthenticated &&
                states.isEmpty) {
              return ArcRaidersPageList(
                maxWidth: 1220,
                bottomPadding: 120,
                children: [
                  ArcProgressionWorkspaceBar(
                    current: _progressionWorkspace,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  const ArcRaidersStatePanel(
                    title: 'Sign in to sync progress',
                    message:
                        'Tracker progression is saved against your UAG account.',
                    icon: Icons.lock_outline_rounded,
                    accent: ArcUiTokens.warning,
                    compact: true,
                  ),
                ],
              );
            }

            if (status == ArcScrappyRepositoryStateStatus.error &&
                states.isEmpty) {
              return ArcRaidersPageList(
                maxWidth: 1220,
                bottomPadding: 120,
                children: [
                  ArcProgressionWorkspaceBar(
                    current: _progressionWorkspace,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  ArcRaidersStatePanel(
                    title: 'Tracker sync unavailable',
                    message:
                        'UAG could not load your saved tracker progress. No empty progress has been assumed.',
                    icon: Icons.cloud_off_rounded,
                    accent: ArcUiTokens.warning,
                    compact: true,
                    action: TextButton.icon(
                      onPressed: _retryTrackerSync,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }

            final filtered = _applyFilter(allItems, states);
            final counts = _buildCounts(allItems, states);
            final progressItems =
                _mode == ArcScrappyTrackerMode.bench &&
                    _selectedBenchCategory != null
                ? allItems
                      .where((item) => item.category == _selectedBenchCategory)
                      .toList(growable: false)
                : allItems;
            final ownedCount = progressItems.where((item) {
              final state = states[item.id] ?? ArcScrappyState.empty(item.id);
              return state.ownedFor(item.neededCount);
            }).length;
            final completion = progressItems.isEmpty
                ? 0.0
                : ownedCount / progressItems.length;
            final landscape =
                MediaQuery.of(context).orientation == Orientation.landscape;

            return ArcRaidersPageList(
              maxWidth: 1220,
              bottomPadding: 120,
              children: [
                ArcProgressionWorkspaceBar(
                  current: _progressionWorkspace,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppTheme.spaceS),
                if (status == ArcScrappyRepositoryStateStatus.error &&
                    states.isNotEmpty) ...[
                  ArcRaidersStatePanel(
                    title: 'Live sync paused',
                    message:
                        'Showing your last loaded tracker progress while UAG reconnects.',
                    icon: Icons.cloud_off_rounded,
                    accent: ArcUiTokens.warning,
                    compact: true,
                    action: TextButton.icon(
                      onPressed: _retryTrackerSync,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                ],
                if (_mode == ArcScrappyTrackerMode.scrappy) ...[
                  _buildScrappyHero(counts),
                  const SizedBox(height: 6),
                  ScrappyProgressHeader(
                    completion: completion,
                    ownedCount: ownedCount,
                    totalCount: progressItems.length,
                    landscape: landscape,
                    title: _showFeedScrappy
                        ? 'Scrappy upgrade progress'
                        : 'Scrappy tracker progress',
                    description: _showFeedScrappy
                        ? 'Upgrade progress stays visible while feed recommendations change.'
                        : 'Live completion across Scrappy upgrade materials.',
                    accentColor: _showFeedScrappy
                        ? AppTheme.neonPink
                        : _modeAccent(),
                  ),
                  const SizedBox(height: 6),
                ],
                if (_mode == ArcScrappyTrackerMode.bench) ...[
                  _buildBenchHero(allItems, states),
                  const SizedBox(height: 6),
                  ScrappyProgressHeader(
                    completion: completion,
                    ownedCount: ownedCount,
                    totalCount: progressItems.length,
                    landscape: landscape,
                    title: _selectedBenchCategory == null
                        ? 'Bench progress'
                        : '${_selectedBenchCategory!} progress',
                    description:
                        'Current station material completion and upgrade readiness.',
                    accentColor: _modeAccent(),
                  ),
                  const SizedBox(height: 6),
                ],
                if (_mode == ArcScrappyTrackerMode.scrappy &&
                    _showFeedScrappy) ...[
                  ScrappyFeedQueueSection(
                    goal: _feedGoal,
                    onGoalChanged: (goal) => setState(() => _feedGoal = goal),
                    showGoalBar: false,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                ] else ...[
                  if (_mode == ArcScrappyTrackerMode.quest) ...[
                    _buildQuestProgressContext(),
                    const SizedBox(height: 6),
                    ScrappyProgressHeader(
                      completion: completion,
                      ownedCount: ownedCount,
                      totalCount: progressItems.length,
                      landscape: landscape,
                      title: _headerTitle,
                      description: 'Needed / active / complete mission board.',
                      footer: 'Fixed-location quest objects stay excluded.',
                      accentColor: _modeAccent(),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                  ],
                  _mode == ArcScrappyTrackerMode.scrappy
                      ? _buildScrappyList(filtered, states)
                      : _mode == ArcScrappyTrackerMode.quest
                      ? _buildQuestKanban(filtered, states)
                      : _buildBenchCarousel(allItems, states),
                  const SizedBox(height: AppTheme.spaceS),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ElectricActiveTierCard extends StatefulWidget {
  const _ElectricActiveTierCard({required this.child});
  final Widget child;

  @override
  State<_ElectricActiveTierCard> createState() =>
      _ElectricActiveTierCardState();
}

class _ElectricActiveTierCardState extends State<_ElectricActiveTierCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final phase = _controller.value;
        return Container(
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL + 2),
            gradient: SweepGradient(
              transform: GradientRotation(phase * 6.283185307179586),
              colors: [
                ArcUiTokens.primaryAccent.withValues(alpha: .18),
                ArcUiTokens.primaryAccent.withValues(alpha: .95),
                Colors.white.withValues(alpha: .72),
                ArcUiTokens.secondaryAccent.withValues(alpha: .55),
                ArcUiTokens.primaryAccent.withValues(alpha: .18),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: ArcUiTokens.primaryAccent.withValues(alpha: .20),
                blurRadius: 18,
                spreadRadius: .5,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
