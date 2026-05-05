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

  const ScrappyGridScreen({super.key});

  @override
  State<ScrappyGridScreen> createState() => _ScrappyGridScreenState();
}

class _ScrappyGridScreenState extends State<ScrappyGridScreen> {
  final ArcScrappyRepository _repository = ArcScrappyRepository();
  ArcScrappyFilter _selectedFilter = ArcScrappyFilter.missing;
  ArcScrappyTrackerMode _mode = ArcScrappyTrackerMode.scrappy;

  List<ArcScrappyItem> get _allItems {
    final items = switch (_mode) {
      ArcScrappyTrackerMode.scrappy => [...ArcScrappySeedData.items],
      ArcScrappyTrackerMode.bench => [...ArcBenchUpgradeSeedData.items],
      ArcScrappyTrackerMode.quest => [...ArcQuestRequirementSeedData.items],
    };
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  String get _modeTitle {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'Scrappy Tracker';
      case ArcScrappyTrackerMode.bench:
        return 'Bench Upgrade Tracker';
      case ArcScrappyTrackerMode.quest:
        return 'Quest Item Tracker';
    }
  }

  String get _headerTitle {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'ARC Raiders Scrappy Tracker';
      case ArcScrappyTrackerMode.bench:
        return 'ARC Raiders Bench Upgrade Tracker';
      case ArcScrappyTrackerMode.quest:
        return 'ARC Raiders Quest Item Tracker';
    }
  }

  String get _headerDescription {
    switch (_mode) {
      case ArcScrappyTrackerMode.scrappy:
        return 'Track Scrappy training materials, completion progress, and surplus items for future trading.';
      case ArcScrappyTrackerMode.bench:
        return 'Track every material needed by exact station and tier across Gunsmith, Gear Bench, Medical Lab, Explosives Station, Utility Station, and Refiner.';
      case ArcScrappyTrackerMode.quest:
        return 'Track regular quest collection items by trader and quest. Fixed-location special quest items are intentionally excluded because they only appear when the quest is active.';
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

    return <ArcScrappyFilter, int>{
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

  String _tierLabel(ArcScrappyTier tier) {
    if (_mode == ArcScrappyTrackerMode.bench) {
      switch (tier) {
        case ArcScrappyTier.tier1:
          return 'Bench Level 1 Materials';
        case ArcScrappyTier.tier2:
          return 'Bench Level 2 Materials';
        case ArcScrappyTier.tier3:
          return 'Bench Level 3 Materials';
        case ArcScrappyTier.tier4:
          return 'Final Upgrade Materials';
      }
    }

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
            'This will remove the collected amount for this single ${switch (_mode) { ArcScrappyTrackerMode.scrappy => 'scrappy', ArcScrappyTrackerMode.bench => 'bench', ArcScrappyTrackerMode.quest => 'quest' }} item and reset it back to zero.',
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
          content: Text(
            switch (_mode) {
              ArcScrappyTrackerMode.scrappy => 'This will remove all collected scrappy progress and surplus from the Scrappy tracker only.',
              ArcScrappyTrackerMode.bench => 'This will remove all collected bench upgrade material progress from the Bench tracker only.',
              ArcScrappyTrackerMode.quest => 'This will remove all collected quest item progress from the Quest tracker only.',
            },
            style: const TextStyle(color: Colors.white70, height: 1.45),
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

  Widget _buildModeToggle() {
    Widget button({
      required ArcScrappyTrackerMode mode,
      required String label,
      required IconData icon,
    }) {
      final selected = _mode == mode;
      final color = selected ? AppTheme.neonPink : AppTheme.neonCyan;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_mode == mode) return;
            setState(() {
              _mode = mode;
              _selectedFilter = ArcScrappyFilter.missing;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM,
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
                const SizedBox(width: 8),
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
        ),
        const SizedBox(width: AppTheme.spaceM),
        button(
          mode: ArcScrappyTrackerMode.bench,
          label: 'Bench',
          icon: Icons.handyman_rounded,
        ),
        const SizedBox(width: AppTheme.spaceM),
        button(
          mode: ArcScrappyTrackerMode.quest,
          label: 'Quests',
          icon: Icons.assignment_turned_in_rounded,
        ),
      ],
    );
  }

  Widget _buildTierHeader(
    ArcScrappyTier tier,
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    final color = _tierColor(tier);
    final completedCount = items.where((item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return state.ownedFor(item.neededCount);
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceM,
      ),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: color.withValues(alpha: 0.22),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _tierLabel(tier),
              style: AppTheme.tradingHeading(fontSize: 20, color: color),
            ),
          ),
          Text(
            '$completedCount / ${items.length}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierGrid(
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 5 : 3;
    final childAspectRatio = isLandscape ? 0.86 : 0.64;

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.spaceM,
        mainAxisSpacing: AppTheme.spaceM,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final state = states[item.id] ?? ArcScrappyState.empty(item.id);

        return ScrappyTile(
          item: item,
          state: state,
          landscape: isLandscape,
          tierColor: _tierColor(item.tier),
          onTap: () {
            if (state.collectedCount > 0) {
              _openItemEditor(item, state);
            } else {
              _showMissingItemInfo(item, state);
            }
          },
          onLongPress: () => _openItemEditor(item, state),
        );
      },
    );
  }

  Widget _buildTierSection(
    ArcScrappyTier tier,
    List<ArcScrappyItem> items,
    Map<String, ArcScrappyState> states,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTierHeader(tier, items, states),
        _buildTierGrid(items, states),
        const SizedBox(height: AppTheme.spaceL),
      ],
    );
  }

  Widget _buildTieredList(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) {
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

    final tier1Items = filtered
        .where((item) => item.tier == ArcScrappyTier.tier1)
        .toList(growable: false);
    final tier2Items = filtered
        .where((item) => item.tier == ArcScrappyTier.tier2)
        .toList(growable: false);
    final tier3Items = filtered
        .where((item) => item.tier == ArcScrappyTier.tier3)
        .toList(growable: false);
    final tier4Items = filtered
        .where((item) => item.tier == ArcScrappyTier.tier4)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTierSection(ArcScrappyTier.tier1, tier1Items, states),
        _buildTierSection(ArcScrappyTier.tier2, tier2Items, states),
        _buildTierSection(ArcScrappyTier.tier3, tier3Items, states),
        _buildTierSection(ArcScrappyTier.tier4, tier4Items, states),
      ],
    );
  }


  Widget _buildGroupHeader({
    required String title,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
    required Color color,
    String? subtitle,
  }) {
    final completedCount = items.where((item) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      return state.ownedFor(item.neededCount);
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceM,
      ),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: color.withValues(alpha: 0.24),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.tradingHeading(fontSize: 20, color: color),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$completedCount / ${items.length}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    List<ArcScrappyItem> filtered,
    Map<String, ArcScrappyState> states,
  ) {
    if (filtered.isEmpty) {
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

    final categories = <String>[];
    for (final item in filtered) {
      if (!categories.contains(item.category)) categories.add(item.category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in categories) ...[
          _buildStationOrTraderSection(
            category: category,
            items: filtered
                .where((item) => item.category == category)
                .toList(growable: false),
            states: states,
          ),
          const SizedBox(height: AppTheme.spaceL),
        ],
      ],
    );
  }

  Widget _buildStationOrTraderSection({
    required String category,
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
  }) {
    final sectionColor = _mode == ArcScrappyTrackerMode.quest
        ? Colors.amberAccent
        : AppTheme.neonCyan;

    final groups = <String>[];
    for (final item in items) {
      if (!groups.contains(item.group)) groups.add(item.group);
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 22,
        borderColor: sectionColor.withValues(alpha: 0.18),
        backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: AppTheme.tradingHeading(fontSize: 25, color: sectionColor),
          ),
          const SizedBox(height: AppTheme.spaceM),
          for (final group in groups) ...[
            Builder(
              builder: (context) {
                final groupItems = items
                    .where((item) => item.group == group)
                    .toList(growable: false);
                final displayTitle = _mode == ArcScrappyTrackerMode.bench
                    ? group.replaceFirst('$category Lv.', 'Tier ')
                    : group;
                final subtitle = _mode == ArcScrappyTrackerMode.bench
                    ? '$category upgrade materials'
                    : '$category quest collection items';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupHeader(
                      title: displayTitle,
                      subtitle: subtitle,
                      items: groupItems,
                      states: states,
                      color: _mode == ArcScrappyTrackerMode.quest
                          ? Colors.amberAccent
                          : _tierColor(groupItems.first.tier),
                    ),
                    _buildTierGrid(groupItems, states),
                    const SizedBox(height: AppTheme.spaceL),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _allItems;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          _modeTitle,
          style: AppTheme.tradingHeading(fontSize: 25),
        ),
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
                    _buildModeToggle(),
                    const SizedBox(height: AppTheme.spaceL),
                    ScrappyProgressHeader(
                      completion: completion,
                      ownedCount: ownedCount,
                      totalCount: allItems.length,
                      landscape: landscape,
                      title: _headerTitle,
                      description: _headerDescription,
                      footer: switch (_mode) {
                        ArcScrappyTrackerMode.scrappy => 'Scrappy materials stay separate from bench and quest totals, but surplus can feed future resource trading.',
                        ArcScrappyTrackerMode.bench => 'Bench materials are split by exact station and tier so you know what to keep before selling or trading spares.',
                        ArcScrappyTrackerMode.quest => 'Quest tracker includes regular collection items only. Special fixed-location quest items are excluded by design.',
                      },
                      accentColor: switch (_mode) {
                        ArcScrappyTrackerMode.scrappy => AppTheme.neonPink,
                        ArcScrappyTrackerMode.bench => AppTheme.neonCyan,
                        ArcScrappyTrackerMode.quest => Colors.amberAccent,
                      },
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
                        ? _buildTieredList(filtered, states)
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
