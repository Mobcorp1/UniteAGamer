import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_filter.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/blueprint_actions_menu.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/blueprint_filter_bar.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/blueprint_progress_header.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintGridScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/blueprints';

  const BlueprintGridScreen({super.key});

  @override
  State<BlueprintGridScreen> createState() => _BlueprintGridScreenState();
}

class _BlueprintGridScreenState extends State<BlueprintGridScreen> {
  final ArcBlueprintRepository _repository = ArcBlueprintRepository();
  final TextEditingController _searchController = TextEditingController();

  ArcBlueprintFilter _selectedFilter = ArcBlueprintFilter.missing;
  bool _selectionMode = false;
  bool _showTrackerHeader = true;
  final Set<String> _selectedBlueprintIds = <String>{};
  String _searchQuery = '';

  static const int _gridColumns = 10;
  static const double _landscapeSpacing = 6;
  static const double _portraitSpacing = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ArcBlueprint> _applyFilter(
    List<ArcBlueprint> blueprints,
    Map<String, ArcBlueprintState> states,
  ) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return blueprints.where((blueprint) {
      final state = states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);

      final matchesFilter = switch (_selectedFilter) {
        ArcBlueprintFilter.all => true,
        ArcBlueprintFilter.owned => state.owned,
        ArcBlueprintFilter.missing => !state.owned,
        ArcBlueprintFilter.duplicates => state.hasDuplicates,
      };

      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        blueprint.name,
        blueprint.category,
        blueprint.group,
        blueprint.rarityLabel,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList(growable: false);
  }

  Map<ArcBlueprintFilter, int> _buildCounts(
    List<ArcBlueprint> blueprints,
    Map<String, ArcBlueprintState> states,
  ) {
    int countWhere(bool Function(ArcBlueprintState state) predicate) {
      var count = 0;
      for (final blueprint in blueprints) {
        final state = states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
        if (predicate(state)) count++;
      }
      return count;
    }

    final ownedCount = countWhere((state) => state.owned);

    return <ArcBlueprintFilter, int>{
      ArcBlueprintFilter.all: blueprints.length,
      ArcBlueprintFilter.owned: ownedCount,
      ArcBlueprintFilter.missing: blueprints.length - ownedCount,
      ArcBlueprintFilter.duplicates: countWhere((state) => state.hasDuplicates),
    };
  }

  Color _rarityColor(ArcBlueprintRarity rarity) {
    switch (rarity) {
      case ArcBlueprintRarity.common:
        return Colors.white70;
      case ArcBlueprintRarity.uncommon:
        return Colors.lightGreenAccent;
      case ArcBlueprintRarity.rare:
        return AppTheme.neonCyan;
      case ArcBlueprintRarity.epic:
        return AppTheme.neonPink;
      case ArcBlueprintRarity.legendary:
        return Colors.amberAccent;
    }
  }

  void _enterSelectionMode(String blueprintId) {
    setState(() {
      _selectionMode = true;
      _selectedBlueprintIds.add(blueprintId);
    });
  }

  void _toggleSelection(String blueprintId) {
    setState(() {
      if (_selectedBlueprintIds.contains(blueprintId)) {
        _selectedBlueprintIds.remove(blueprintId);
      } else {
        _selectedBlueprintIds.add(blueprintId);
      }
      if (_selectedBlueprintIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedBlueprintIds.clear();
    });
  }

  void _selectAll(List<ArcBlueprint> filtered) {
    setState(() {
      _selectionMode = true;
      _selectedBlueprintIds
        ..clear()
        ..addAll(filtered.map((item) => item.id));
    });
  }

  Future<void> _selectRow(List<ArcBlueprint> filtered) async {
    final rowCount = (filtered.length / _gridColumns).ceil();
    final rowIndex = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          title: Text(
            'Select Row',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(rowCount, (index) {
              return ActionChip(
                label: Text('Row ${index + 1}'),
                onPressed: () => Navigator.of(dialogContext).pop(index),
              );
            }),
          ),
        );
      },
    );

    if (rowIndex == null) return;

    final start = rowIndex * _gridColumns;
    final end = (start + _gridColumns).clamp(0, filtered.length);
    final selected = filtered.sublist(start, end);

    setState(() {
      _selectionMode = true;
      _selectedBlueprintIds
        ..clear()
        ..addAll(selected.map((item) => item.id));
    });
  }

  Future<void> _selectColumn(List<ArcBlueprint> filtered) async {
    final columnIndex = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          title: Text(
            'Select Column',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_gridColumns, (index) {
              return ActionChip(
                label: Text('Col ${index + 1}'),
                onPressed: () => Navigator.of(dialogContext).pop(index),
              );
            }),
          ),
        );
      },
    );

    if (columnIndex == null) return;

    final selected = <ArcBlueprint>[];
    for (var i = columnIndex; i < filtered.length; i += _gridColumns) {
      selected.add(filtered[i]);
    }

    setState(() {
      _selectionMode = true;
      _selectedBlueprintIds
        ..clear()
        ..addAll(selected.map((item) => item.id));
    });
  }

  Future<bool?> _askYesNo({
    required String title,
    required String message,
    String yesLabel = 'Yes',
    String noLabel = 'No',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.20)),
          ),
          title: Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(noLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(yesLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markMissingAsOwned(
    ArcBlueprint blueprint,
    ArcBlueprintState currentState,
  ) async {
    final ownedState = currentState.copyWith(
      owned: true,
      dupesOwned: 0,
      updatedAt: DateTime.now(),
    );

    await _repository.saveBlueprintState(ownedState);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${blueprint.name} marked as owned.')),
    );
    setState(() {});

    final wantsReport = await _askYesNo(
      title: 'Add drop report?',
      message: 'Do you want to add a drop report for ${blueprint.name} now?',
    );

    if (!mounted) return;
    if (wantsReport == true) {
      await _openBlueprintEditor(blueprint, ownedState);
    }

    if (!mounted) return;
    final wantsDupes = await _askYesNo(
      title: 'Add duplicates?',
      message: 'Do you want to add duplicates for ${blueprint.name} now?',
    );

    if (!mounted) return;
    if (wantsDupes == true) {
      final refreshed =
          (await _repository.watchMyBlueprintStates().first)[blueprint.id] ??
          ownedState;
      await _openBlueprintEditor(blueprint, refreshed);
    }
  }

  Future<void> _applyBulkOwned(
    List<ArcBlueprint> allBlueprints,
    Map<String, ArcBlueprintState> states,
  ) async {
    final updates = _selectedBlueprintIds.map((id) {
      final current = states[id] ?? ArcBlueprintState.empty(id);
      return current.copyWith(owned: true);
    }).toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updates.length} blueprints marked owned.')),
    );
    _clearSelection();
  }

  Future<void> _applyBulkDupes(
    List<ArcBlueprint> allBlueprints,
    Map<String, ArcBlueprintState> states,
  ) async {
    final updates = _selectedBlueprintIds.map((id) {
      final current = states[id] ?? ArcBlueprintState.empty(id);
      return current.copyWith(dupesOwned: current.dupesOwned + 1);
    }).toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added 1 dupe to ${updates.length} blueprints.')),
    );
    _clearSelection();
  }

  Future<void> _applyBulkClear(
    List<ArcBlueprint> allBlueprints,
    Map<String, ArcBlueprintState> states,
  ) async {
    final updates = _selectedBlueprintIds
        .map(
          (id) => ArcBlueprintState.empty(id).copyWith(updatedAt: DateTime.now()),
        )
        .toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updates.length} blueprints cleared.')),
    );
    _clearSelection();
  }

  Future<void> _confirmClearSingleBlueprint(
    ArcBlueprint blueprint,
    ArcBlueprintState currentState,
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
            'Clear ${blueprint.name}?',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: Colors.redAccent,
            ),
          ),
          content: const Text(
            'This will remove the owned state and dupes for this single blueprint and reset it back to missing.',
            style: TextStyle(color: Colors.white70, height: 1.4),
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
      await _repository.saveBlueprintState(
        currentState.copyWith(owned: false, dupesOwned: 0),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${blueprint.name} cleared.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear ${blueprint.name}: $e')),
      );
    }
  }

  Future<void> _confirmResetGrid() async {
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
            'Reset Blueprint Grid?',
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: Colors.redAccent,
            ),
          ),
          content: const Text(
            'This will remove all owned blueprint progress and dupes from the grid, like starting a fresh expedition run. Your grid positions and blueprint list will remain.',
            style: TextStyle(color: Colors.white70, height: 1.45),
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
      await _repository.resetAllBlueprintStates(
        ArcBlueprintSeedData.blueprints.map((blueprint) => blueprint.id),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blueprint grid reset.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset grid: $e')),
      );
    }
  }

  Future<void> _openBlueprintEditor(
    ArcBlueprint blueprint,
    ArcBlueprintState initialState,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ArcBlueprintDropReportSheet(
          blueprint: blueprint,
          initialState: initialState,
          repository: _repository,
          rarityColor: _rarityColor(blueprint.rarity),
          onSaved: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${blueprint.name} saved.')),
            );
            setState(() {});
          },
          onClear: () => _confirmClearSingleBlueprint(blueprint, initialState),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {});
    }
  }

  PreferredSizeWidget _buildAppBar(
    List<ArcBlueprint> allBlueprints,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
  ) {
    if (_selectionMode) {
      return AppBar(
        title: Text(
          '${_selectedBlueprintIds.length} selected',
          style: AppTheme.tradingHeading(fontSize: 23),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _clearSelection,
        ),
        actions: [
          IconButton(
            tooltip: 'Mark owned',
            onPressed: _selectedBlueprintIds.isEmpty
                ? null
                : () => _applyBulkOwned(allBlueprints, states),
            icon: const Icon(Icons.check_circle_rounded),
          ),
          IconButton(
            tooltip: 'Add 1 dupe',
            onPressed: _selectedBlueprintIds.isEmpty
                ? null
                : () => _applyBulkDupes(allBlueprints, states),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Clear selected',
            onPressed: _selectedBlueprintIds.isEmpty
                ? null
                : () => _applyBulkClear(allBlueprints, states),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      );
    }

    return AppBar(
      title: Text(
        'Blueprint Grid',
        style: AppTheme.tradingHeading(fontSize: 25),
      ),
      actions: [
        IconButton(
          tooltip: 'Select multiple',
          onPressed: () {
            setState(() {
              _selectionMode = true;
              _selectedBlueprintIds.clear();
            });
          },
          icon: const Icon(Icons.select_all_rounded),
        ),
        BlueprintActionsMenu(onResetGrid: _confirmResetGrid),
      ],
    );
  }

  Future<void> _handleSelectionTool(String value, List<ArcBlueprint> filtered) async {
    if (value == 'all') {
      _selectAll(filtered);
    } else if (value == 'row') {
      await _selectRow(filtered);
    } else if (value == 'column') {
      await _selectColumn(filtered);
    } else if (value == 'clear') {
      _clearSelection();
    }
  }

  Widget _buildFilterAndSearchBar(Map<ArcBlueprintFilter, int> counts, List<ArcBlueprint> filtered) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSideBySide = constraints.maxWidth >= 760;

        final searchField = SizedBox(
          width: showSideBySide ? 260 : double.infinity,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: AppTheme.tradingInputDecoration(
              label: 'Search blueprints',
            ).copyWith(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white70,
              ),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
            ),
          ),
        );

        if (!showSideBySide) {
          return Column(
            children: [
              BlueprintFilterBar(
                selectedFilter: _selectedFilter,
                counts: counts,
                selectionMode: _selectionMode,
                onEnterSelectionMode: () => setState(() { _selectionMode = true; _selectedBlueprintIds.clear(); }),
                onSelectionToolSelected: (value) => _handleSelectionTool(value, filtered),
                onFilterSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
              const SizedBox(height: AppTheme.spaceM),
              searchField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BlueprintFilterBar(
                selectedFilter: _selectedFilter,
                counts: counts,
                selectionMode: _selectionMode,
                onEnterSelectionMode: () => setState(() { _selectionMode = true; _selectedBlueprintIds.clear(); }),
                onSelectionToolSelected: (value) => _handleSelectionTool(value, filtered),
                onFilterSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            searchField,
          ],
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
  ) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = landscape ? _gridColumns : 2;
    final spacing = landscape ? _landscapeSpacing : _portraitSpacing;
    final childAspectRatio = landscape ? 0.98 : 1.16;

    if (filtered.isEmpty) {
      return Container(
        padding: AppTheme.sectionCardPadding,
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
        ),
        child: Text(
          _searchQuery.trim().isNotEmpty
              ? 'No blueprints matched "${_searchQuery.trim()}".'
              : 'No blueprints match this filter yet.',
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
            crossAxisCount;
        final mainAxisExtent = tileWidth / childAspectRatio;

        return GridView.builder(
          itemCount: filtered.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final blueprint = filtered[index];
            final state =
                states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
            return BlueprintTile(
              blueprint: blueprint,
              state: state,
              landscape: landscape,
              rarityColor: _rarityColor(blueprint.rarity),
              isSelectionMode: _selectionMode,
              isSelected: _selectedBlueprintIds.contains(blueprint.id),
              onTap: () async {
                if (_selectionMode) {
                  _toggleSelection(blueprint.id);
                  return;
                }

                if (state.owned) {
                  await _openBlueprintEditor(blueprint, state);
                } else {
                  await _markMissingAsOwned(blueprint, state);
                }
              },
              onLongPress: () {
                if (_selectionMode) {
                  _toggleSelection(blueprint.id);
                } else {
                  _enterSelectionMode(blueprint.id);
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBlueprints = [...ArcBlueprintSeedData.blueprints]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _repository.watchMyBlueprintStates(),
              builder: (context, snapshot) {
                final states = snapshot.data ?? <String, ArcBlueprintState>{};
                final filtered = _applyFilter(allBlueprints, states);
                final counts = _buildCounts(allBlueprints, states);

                final ownedCount = counts[ArcBlueprintFilter.owned] ?? 0;
                final completion = allBlueprints.isEmpty
                    ? 0.0
                    : ownedCount / allBlueprints.length;
                final landscape =
                    MediaQuery.of(context).orientation == Orientation.landscape;

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: _buildAppBar(allBlueprints, filtered, states),
                  body: ListView(
                    padding: AppTheme.pagePadding,
                    children: [
                      _buildFilterAndSearchBar(counts, filtered),
                      const SizedBox(height: AppTheme.spaceS),
                      if (_showTrackerHeader)
                        BlueprintProgressHeader(
                          completion: completion,
                          ownedCount: ownedCount,
                          missingCount: counts[ArcBlueprintFilter.missing] ?? 0,
                          dupesCount: counts[ArcBlueprintFilter.duplicates] ?? 0,
                          totalCount: allBlueprints.length,
                          landscape: landscape,
                          onClose: () =>
                              setState(() => _showTrackerHeader = false),
                        ),
                      const SizedBox(height: AppTheme.spaceS),
                      if (_selectionMode)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceM),
                          decoration: AppTheme.tradingCardDecoration(
                            borderColor: AppTheme.neonPink.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          child: const Text(
                            'Long press to start selecting, then use the top-right tools to select all visible, a full row, or a full column.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildGrid(context, filtered, states),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
