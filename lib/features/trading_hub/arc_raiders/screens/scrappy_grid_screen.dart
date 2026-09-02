import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
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
  final Set<String> _expandedSections = <String>{};

  ArcScrappyFilter _selectedFilter = ArcScrappyFilter.all;
  late ArcScrappyTrackerMode _mode;
  bool _showFeedScrappy = false;
  int _trackerCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void didUpdateWidget(covariant ScrappyGridScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
      _selectedFilter = ArcScrappyFilter.all;
      _showFeedScrappy = false;
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

  String get _headerDescription {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'Track Scrappy upgrade items by tier in a compact operations board.';
      case ArcScrappyTrackerMode.bench:
        return 'Track bench materials by station and tier in a compact operations board.';
      case ArcScrappyTrackerMode.quest:
        return 'Track quest collection items by status using a live progress board.';
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear ${item.name}: $e')),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not reset tracker: $e')));
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

        if (items.length == 1) {
          return Center(child: tileFor(items.first, panelWidth));
        }

        final halfWidth = ((panelWidth - spacing) / 2)
            .clamp(112.0, 180.0)
            .toDouble();

        if (items.length == 2) {
          return Center(
            child: SizedBox(
              width: panelWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tileFor(items[0], halfWidth),
                  const SizedBox(width: spacing),
                  tileFor(items[1], halfWidth),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not complete $title: $e')));
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

  // ignore: unused_element
  Widget _buildScrappyList(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    final tierGroups = <ArcScrappyTier, List<ArcScrappyItem>>{};
    for (final item in filtered) {
      tierGroups.putIfAbsent(item.tier, () => <ArcScrappyItem>[]).add(item);
    }

    final cards = <Widget>[
      for (final tier in ArcScrappyTier.values)
        if ((tierGroups[tier] ?? const <ArcScrappyItem>[]).isNotEmpty)
          _buildExpansionSection(
            id: 'scrappy-${tier.name}',
            title: _tierLabel(tier),
            color: _tierColor(tier),
            items: tierGroups[tier] ?? const <ArcScrappyItem>[],
            states: states,
          ),
    ];

    final maxItemCount = tierGroups.values.fold<int>(
      0,
      (max, items) => items.length > max ? items.length : max,
    );

    return _buildTrackerCarousel(cards, maxItemCount: maxItemCount);
  }

  Widget _buildScrappyBoard(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    final tierGroups = <ArcScrappyTier, List<ArcScrappyItem>>{};
    for (final item in filtered) {
      tierGroups.putIfAbsent(item.tier, () => <ArcScrappyItem>[]).add(item);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = width >= 1040;
        final tablet = width >= 700;
        final columnWidth = desktop
            ? (width - 36) / 4
            : tablet
            ? (width - 12) / 2
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tier in ArcScrappyTier.values)
              if ((tierGroups[tier] ?? const <ArcScrappyItem>[]).isNotEmpty)
                SizedBox(
                  width: columnWidth,
                  child: _scrappyTierColumn(
                    tier: tier,
                    items: tierGroups[tier] ?? const <ArcScrappyItem>[],
                    states: states,
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _scrappyTierColumn({
    required ArcScrappyTier tier,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
  }) {
    final color = _tierColor(tier);
    final complete = _completedCount(items, states);
    final totalNeeded = items.fold<int>(
      0,
      (sum, item) => sum + item.neededCount,
    );
    final totalCollected = items.fold<int>(0, (sum, item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return sum + state.collectedCount.clamp(0, item.neededCount);
    });

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusM,
        accent: color,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: ArcUiTokens.surfaceDecoration(
                  role: ArcSurfaceRole.interactive,
                  radius: ArcUiTokens.radiusS,
                  accent: color,
                  borderOpacity: 0.34,
                ),
                child: Text(
                  '${tier.index + 1}',
                  style: ArcUiTokens.cardTitle(color: color, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tierLabel(tier).toUpperCase(),
                      style: ArcUiTokens.label(color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$complete/${items.length} upgrades ready',
                      style: ArcUiTokens.metadata(
                        color: ArcUiTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _ProgressPill(text: '$totalCollected/$totalNeeded', color: color),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalNeeded == 0 ? 0 : totalCollected / totalNeeded,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            _scrappyInventoryRow(
              item,
              states[item.id] ?? ArcScrappyState.empty(item.id),
              color,
            ),
        ],
      ),
    );
  }

  Widget _scrappyInventoryRow(
    ArcScrappyItem item,
    ArcScrappyState state,
    Color color,
  ) {
    final needed = item.neededCount <= 0 ? 1 : item.neededCount;
    final collected = state.collectedCount.clamp(0, needed);
    final complete = state.ownedFor(item.neededCount);
    final surplus = state.surplusFor(item.neededCount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
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
            borderOpacity: complete ? 0.28 : 0.12,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: ArcUiTokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.inventory_2_rounded,
                    color: color.withValues(alpha: 0.65),
                    size: 20,
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
                    const SizedBox(height: 3),
                    Text(
                      complete ? 'READY' : 'NEED ${needed - collected}',
                      style: ArcUiTokens.metadata(
                        color: complete
                            ? ArcUiTokens.success
                            : ArcUiTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$collected/$needed',
                    style: ArcUiTokens.label(
                      color: complete ? ArcUiTokens.success : color,
                    ),
                  ),
                  if (surplus > 0)
                    Text(
                      '+$surplus spare',
                      style: ArcUiTokens.metadata(
                        color: ArcUiTokens.attentionAccent,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    final grouped = <String, List<ArcScrappyItem>>{};

    for (final item in filtered) {
      final key = '${item.category}|||${item.group}';
      grouped.putIfAbsent(key, () => <ArcScrappyItem>[]).add(item);
    }

    final cards = <Widget>[
      for (final entry in grouped.entries)
        _buildExpansionSection(
          id: '${_mode.name}-${entry.key}',
          title: _mode == ArcScrappyTrackerMode.quest
              ? (entry.value.first.group.trim().isEmpty
                    ? 'Quest Items'
                    : entry.value.first.group)
              : '${entry.value.first.category} - ${_displayGroupTitle(entry.value.first.category, entry.value.first.group)}',
          color: _mode == ArcScrappyTrackerMode.quest
              ? Colors.amberAccent
              : _groupColor(entry.value, entry.value.first.group),
          items: entry.value,
          states: states,
          subtitle: _mode == ArcScrappyTrackerMode.quest
              ? '${entry.value.length} collection items'
              : '${entry.value.length} upgrade materials',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = width >= 1080
            ? 3
            : width >= 700
            ? 2
            : 1;
        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
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
        final columnWidth = width >= 900
            ? ((width - 24) / 3).clamp(248.0, 360.0)
            : 258.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _questColumn(
                title: 'Needed',
                color: ArcUiTokens.secondaryAccent,
                items: needed,
                states: states,
                width: columnWidth,
              ),
              const SizedBox(width: 12),
              _questColumn(
                title: 'In Progress',
                color: ArcUiTokens.primaryAccent,
                items: inProgress,
                states: states,
                width: columnWidth,
              ),
              const SizedBox(width: 12),
              _questColumn(
                title: 'Complete',
                color: ArcUiTokens.success,
                items: complete,
                states: states,
                width: columnWidth,
              ),
            ],
          ),
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
                'No quest items here.',
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
          padding: const EdgeInsets.all(8),
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
                width: 46,
                height: 46,
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
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.cardTitle(fontSize: 12.5),
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
                    const SizedBox(height: 7),
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
                              : 'BLOCKED',
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
      bottomNavigationBar: ArcCompanionBottomDock(
        activeLabel: _mode == ArcScrappyTrackerMode.quest
            ? 'Quest Tracker'
            : 'Scrappy Intel',
      ),
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _modeTitle,
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
        actions: [ScrappyActionsMenu(onResetGrid: _confirmResetGrid)],
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: StreamBuilder<Map<String, ArcScrappyState>>(
          stream: _repository.watchMyScrappyStateMap(),
          builder: (context, snapshot) {
            final states = snapshot.data ?? <String, ArcScrappyState>{};
            final filtered = _applyFilter(allItems, states);
            final counts = _buildCounts(allItems, states);
            final ownedCount = counts[ArcScrappyFilter.owned] ?? 0;
            final completion = allItems.isEmpty
                ? 0.0
                : ownedCount / allItems.length;
            final landscape =
                MediaQuery.of(context).orientation == Orientation.landscape;

            return ArcRaidersPageList(
              maxWidth: 1220,
              children: [
                _buildScrappyFeedTabs(),
                if (_mode == ArcScrappyTrackerMode.scrappy)
                  const SizedBox(height: AppTheme.spaceM),
                if (_mode == ArcScrappyTrackerMode.scrappy &&
                    _showFeedScrappy) ...[
                  const ScrappyFeedQueueSection(),
                  const SizedBox(height: AppTheme.spaceS),
                  ScrappyProgressHeader(
                    completion: completion,
                    ownedCount: ownedCount,
                    totalCount: allItems.length,
                    landscape: landscape,
                    title: 'ARC Raiders Feed Scrappy',
                    description:
                        'Food queue items and quick location hints for feeding Scrappy.',
                    footer:
                        'Feed Scrappy is kept separate from tracker completion so food queue items do not affect upgrade totals.',
                    accentColor: AppTheme.neonPink,
                  ),
                  const SizedBox(height: 74),
                ] else ...[
                  ScrappyFilterBar(
                    selectedFilter: _selectedFilter,
                    counts: counts,
                    onFilterSelected: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  _mode == ArcScrappyTrackerMode.scrappy
                      ? _buildScrappyBoard(filtered, states)
                      : _mode == ArcScrappyTrackerMode.quest
                      ? _buildQuestKanban(filtered, states)
                      : _buildGroupedList(filtered, states),
                  const SizedBox(height: AppTheme.spaceS),
                  ScrappyProgressHeader(
                    completion: completion,
                    ownedCount: ownedCount,
                    totalCount: allItems.length,
                    landscape: landscape,
                    title: _headerTitle,
                    description: _headerDescription,
                    footer: switch (_mode) {
                      ArcScrappyTrackerMode.scrappy =>
                        'Food queue and Scrappy upgrades stay separate from bench and quest totals.',
                      ArcScrappyTrackerMode.bench =>
                        'Bench materials are grouped into compact station and tier boards.',
                      ArcScrappyTrackerMode.quest =>
                        'Regular collection items only. Quest-only fixed-location objects are excluded by design.',
                    },
                    accentColor: _modeAccent(),
                  ),
                  const SizedBox(height: 74),
                ],
                const SizedBox(height: AppTheme.spaceXL),
              ],
            );
          },
        ),
      ),
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
