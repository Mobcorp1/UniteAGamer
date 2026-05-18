import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_filter.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/arc_scrappy_item_sheet.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/missing_scrappy_dialog.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/scrappy_actions_menu.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/scrappy_feed_queue_section.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/scrappy_filter_bar.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/scrappy_progress_header.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/scrappy_tile.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

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
  final Set<String> _expandedSections = <String>{};

  ArcScrappyFilter _selectedFilter = ArcScrappyFilter.all;
  late ArcScrappyTrackerMode _mode;

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
        return 'Scrappy Tracker';
      case ArcScrappyTrackerMode.bench:
        return 'Bench Tracker';
      case ArcScrappyTrackerMode.quest:
        return 'Quest Tracker';
    }
  }

  String get _headerTitle {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'ARC Raiders Scrappy Tracker';
      case ArcScrappyTrackerMode.bench:
        return 'ARC Raiders Bench Tracker';
      case ArcScrappyTrackerMode.quest:
        return 'ARC Raiders Quest Tracker';
    }
  }

  String get _headerDescription {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'Track Scrappy upgrade items by tier. Expand only the tier you are working on to keep the screen clean.';
      case ArcScrappyTrackerMode.bench:
        return 'Track materials by exact station and tier. Scrappy upgrade items are excluded from this view.';
      case ArcScrappyTrackerMode.quest:
        return 'Track regular quest collection items by trader and quest. Fixed-location special quest items are excluded.';
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
    return '$completed / ${items.length} complete • $totalRequired total needed';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.32)),
          ),
          title: Text(
            'Clear ${item.name}?',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: Colors.redAccent,
            ),
          ),
          content: Text(
            'This will remove the collected amount for this ${_modeWord()} item and reset it back to zero.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.32)),
          ),
          title: Text(
            'Reset $_modeTitle?',
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: Colors.redAccent,
            ),
          ),
          content: Text(switch (_mode) {
            ArcScrappyTrackerMode.scrappy =>
              'This will remove all collected Scrappy progress and surplus from the Scrappy tracker only.',
            ArcScrappyTrackerMode.bench =>
              'This will remove all collected bench upgrade material progress from the Bench tracker only.',
            ArcScrappyTrackerMode.quest =>
              'This will remove all collected quest item progress from the Quest tracker only.',
          }, style: const TextStyle(color: Colors.white70, height: 1.45)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm Reset'),
            ),
          ],
        );
      },
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

  Widget _buildModeNavigation() {
    Widget button({
      required ArcScrappyTrackerMode mode,
      required String label,
      required IconData icon,
      required String routeName,
    }) {
      final selected = _mode == mode;
      final color = selected ? AppTheme.neonPink : AppTheme.neonCyan;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: selected
              ? null
              : () => Navigator.pushReplacementNamed(context, routeName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceS,
              vertical: AppTheme.spaceM,
            ),
            decoration: AppTheme.tradingCardDecoration(
              radius: 16,
              borderColor: color.withValues(alpha: selected ? 0.64 : 0.20),
              backgroundColor: selected
                  ? AppTheme.cardBackgroundAlt
                  : AppTheme.cardBackgroundDeep,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
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
        button(
          mode: ArcScrappyTrackerMode.scrappy,
          label: 'Scrappy',
          icon: Icons.pets_rounded,
          routeName: ScrappyGridScreen.routeName,
        ),
        const SizedBox(width: AppTheme.spaceS),
        button(
          mode: ArcScrappyTrackerMode.bench,
          label: 'Bench',
          icon: Icons.handyman_rounded,
          routeName: ScrappyGridScreen.benchRouteName,
        ),
        const SizedBox(width: AppTheme.spaceS),
        button(
          mode: ArcScrappyTrackerMode.quest,
          label: 'Quests',
          icon: Icons.assignment_turned_in_rounded,
          routeName: ScrappyGridScreen.questRouteName,
        ),
      ],
    );
  }

  Widget _buildAdaptiveTileWrap(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxTileWidth = isLandscape ? 124.0 : 118.0;
    final minTileWidth = isLandscape ? 104.0 : 96.0;
    const spacing = AppTheme.spaceS;

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = isLandscape ? 116.0 : 108.0;
        final rawColumns = (constraints.maxWidth / targetWidth).floor();
        final columns = rawColumns.clamp(2, isLandscape ? 6 : 3);
        final usableWidth = constraints.maxWidth - (spacing * (columns - 1));
        final tileWidth = (usableWidth / columns).clamp(
          minTileWidth,
          maxTileWidth,
        );

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: ScrappyTile(
                  item: item,
                  state: states[item.id] ?? ArcScrappyState.empty(item.id),
                  landscape: isLandscape,
                  tierColor: _tierColor(item.tier),
                  onTap: () {
                    final state =
                        states[item.id] ?? ArcScrappyState.empty(item.id);
                    if (state.collectedCount > 0) {
                      _openItemEditor(item, state);
                    } else {
                      _showMissingItemInfo(item, state);
                    }
                  },
                  onLongPress: () {
                    final state =
                        states[item.id] ?? ArcScrappyState.empty(item.id);
                    _openItemEditor(item, state);
                  },
                ),
              ),
          ],
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

    final expanded = _expandedSections.contains(id);
    final completed = _completedCount(items, states);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: color.withValues(alpha: expanded ? 0.42 : 0.20),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(id),
          initiallyExpanded: expanded,
          onExpansionChanged: (value) {
            setState(() {
              if (value) {
                _expandedSections
                  ..clear()
                  ..add(id);
              } else {
                _expandedSections.remove(id);
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceM,
            vertical: AppTheme.spaceXS,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTheme.spaceM,
            0,
            AppTheme.spaceM,
            AppTheme.spaceM,
          ),
          iconColor: color,
          collapsedIconColor: color,
          title: Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 19, color: color),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              subtitle ?? _sectionSubtitle(items, states),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProgressPill(text: '$completed / ${items.length}', color: color),
              const SizedBox(width: 4),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: color,
              ),
            ],
          ),
          children: [child ?? _buildAdaptiveTileWrap(items, states)],
        ),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tier in ArcScrappyTier.values)
          _buildExpansionSection(
            id: 'scrappy-${tier.name}',
            title: _tierLabel(tier),
            color: _tierColor(tier),
            items: tierGroups[tier] ?? const <ArcScrappyItem>[],
            states: states,
          ),
      ],
    );
  }

  Widget _buildGroupedList(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    final categories = <String>[];
    for (final item in filtered) {
      if (!categories.contains(item.category)) categories.add(item.category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in categories)
          _buildCategorySection(
            category: category,
            items: filtered
                .where((item) => item.category == category)
                .toList(growable: false),
            states: states,
          ),
      ],
    );
  }

  Widget _buildCategorySection({
    required String category,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
  }) {
    final color = _mode == ArcScrappyTrackerMode.quest
        ? Colors.amberAccent
        : AppTheme.neonCyan;
    final groups = <String>[];
    for (final item in items) {
      if (!groups.contains(item.group)) groups.add(item.group);
    }

    return _buildExpansionSection(
      id: '${_mode.name}-category-$category',
      title: category,
      color: color,
      items: items,
      states: states,
      subtitle: _mode == ArcScrappyTrackerMode.quest
          ? '${items.length} tracked items across ${groups.length} quests'
          : '${items.length} materials across ${groups.length} tiers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups)
            _buildExpansionSection(
              id: '${_mode.name}-$category-$group',
              title: _displayGroupTitle(category, group),
              color: _groupColor(items, group),
              items: items
                  .where((item) => item.group == group)
                  .toList(growable: false),
              states: states,
              subtitle: _mode == ArcScrappyTrackerMode.quest
                  ? 'Quest collection items'
                  : '$category upgrade materials',
            ),
        ],
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
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(_modeTitle, style: AppTheme.tradingHeading(fontSize: 25)),
        actions: [ScrappyActionsMenu(onResetGrid: _confirmResetGrid)],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<Map<String, ArcScrappyState>>(
              stream: _repository.watchMyScrappyStates(),
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

                return ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    _buildModeNavigation(),
                    const SizedBox(height: AppTheme.spaceL),
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
                          'Bench materials are grouped by station then tier. Expand only the station you are upgrading.',
                        ArcScrappyTrackerMode.quest =>
                          'Regular collection items only. Quest-only fixed-location objects are excluded by design.',
                      },
                      accentColor: _modeAccent(),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    ScrappyFilterBar(
                      selectedFilter: _selectedFilter,
                      counts: counts,
                      onFilterSelected: (filter) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    _mode == ArcScrappyTrackerMode.scrappy
                        ? _buildScrappyList(filtered, states)
                        : _buildGroupedList(filtered, states),
                    if (_mode == ArcScrappyTrackerMode.scrappy) ...[
                      const SizedBox(height: AppTheme.spaceL),
                      const ScrappyFeedQueueSection(),
                    ],
                    const SizedBox(height: AppTheme.spaceXL),
                  ],
                );
              },
            ),
          ),
        ],
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
