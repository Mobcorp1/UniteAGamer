import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_filter.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_voice_search_button.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_dialogs.dart';

class BlueprintGridScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/blueprints';

  const BlueprintGridScreen({super.key});

  @override
  State<BlueprintGridScreen> createState() => _BlueprintGridScreenState();
}

class _BlueprintGridScreenState extends State<BlueprintGridScreen> {
  final ArcBlueprintRepository _repository = ArcBlueprintRepository();
  final TextEditingController _searchController = TextEditingController();

  ArcBlueprintFilter _selectedFilter = ArcBlueprintFilter.all;
  bool _selectionMode = false;
  bool _overviewMode = false;
  final Set<String> _selectedBlueprintIds = <String>{};
  String _searchQuery = '';

  static const int _gridColumns = 10;
  static const double _landscapeSpacing = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Intro prompt disabled for launch polish; help remains available in UI.
    });
  }

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

    return blueprints
        .where((blueprint) {
          final state =
              states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);

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
        })
        .toList(growable: false);
  }

  Map<ArcBlueprintFilter, int> _buildCounts(
    List<ArcBlueprint> blueprints,
    Map<String, ArcBlueprintState> states,
  ) {
    int countWhere(bool Function(ArcBlueprintState state) predicate) {
      var count = 0;
      for (final blueprint in blueprints) {
        final state =
            states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
        if (predicate(state)) count++;
      }
      return count;
    }

    int sumDupesOwned() {
      var total = 0;

      for (final blueprint in blueprints) {
        final state =
            states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
        total += state.dupesOwned;
      }

      return total;
    }

    final ownedCount = countWhere((state) => state.owned);

    return <ArcBlueprintFilter, int>{
      ArcBlueprintFilter.all: blueprints.length,
      ArcBlueprintFilter.owned: ownedCount,
      ArcBlueprintFilter.missing: blueprints.length - ownedCount,
      ArcBlueprintFilter.duplicates: sumDupesOwned(),
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

  void _enterSelectionMode([String? blueprintId]) {
    setState(() {
      _selectionMode = true;
      if (blueprintId != null) {
        _selectedBlueprintIds.add(blueprintId);
      }
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
    if (filtered.isEmpty) return;

    final rowCount = (filtered.length / _gridColumns).ceil();
    final rowIndex = await UagDialogs.chooseIndex(
      context: context,
      title: 'Select Row',
      itemCount: rowCount,
      labelBuilder: (index) => 'Row ${index + 1}',
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
    if (filtered.isEmpty) return;

    final columnIndex = await UagDialogs.chooseIndex(
      context: context,
      title: 'Select Column',
      itemCount: _gridColumns,
      labelBuilder: (index) => 'Col ${index + 1}',
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
    return UagDialogs.confirm(
      context: context,
      title: title,
      message: message,
      confirmLabel: yesLabel,
      cancelLabel: noLabel,
      borderColor: AppTheme.neonCyan,
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

  Future<void> _applyBulkOwned(Map<String, ArcBlueprintState> states) async {
    final updates = _selectedBlueprintIds
        .map((id) {
          final current = states[id] ?? ArcBlueprintState.empty(id);
          return current.copyWith(owned: true);
        })
        .toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updates.length} blueprints marked owned.')),
    );
    _clearSelection();
  }

  Future<void> _applyBulkDupes(Map<String, ArcBlueprintState> states) async {
    final updates = _selectedBlueprintIds
        .map((id) {
          final current = states[id] ?? ArcBlueprintState.empty(id);
          return current.copyWith(dupesOwned: current.dupesOwned + 1);
        })
        .toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added 1 dupe to ${updates.length} blueprints.')),
    );
    _clearSelection();
  }

  Future<void> _applyBulkClear() async {
    final updates = _selectedBlueprintIds
        .map(
          (id) =>
              ArcBlueprintState.empty(id).copyWith(updatedAt: DateTime.now()),
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
    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Clear ${blueprint.name}?',
      message:
          'This will remove the owned state and dupes for this single blueprint and reset it back to missing.',
      titleColor: Colors.redAccent,
      confirmLabel: 'Clear',
      confirmBackgroundColor: Colors.redAccent,
      confirmForegroundColor: Colors.black,
      borderColor: Colors.redAccent,
    );

    if (confirmed != true) return;

    try {
      await _repository.saveBlueprintState(
        currentState.copyWith(owned: false, dupesOwned: 0),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${blueprint.name} cleared.')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear ${blueprint.name}: $e')),
      );
    }
  }

  Future<void> _confirmResetGrid() async {
    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Reset Blueprint Grid?',
      message:
          'This will remove all owned blueprint progress and dupes from the grid, like starting a fresh expedition run. Your grid positions and blueprint list will remain.',
      titleColor: Colors.redAccent,
      confirmLabel: 'Confirm Reset',
      confirmBackgroundColor: Colors.redAccent,
      confirmForegroundColor: Colors.black,
      borderColor: Colors.redAccent,
    );

    if (confirmed != true) return;

    try {
      await _repository.resetAllBlueprintStates(
        ArcBlueprintSeedData.blueprints.map((blueprint) => blueprint.id),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Blueprint grid reset.')));
      _clearSelection();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not reset grid: $e')));
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${blueprint.name} saved.')));
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

  Widget _buildSearchAppBarTitle() {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search blueprints',
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlueprintVoiceSearchButton(
                onSearchText: (value) {
                  if (value.trim().isEmpty) return;
                  _searchController.text = value;
                  setState(() => _searchQuery = value);
                },
              ),
              if (_searchQuery.trim().isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
            ],
          ),
          isDense: true,
          filled: true,
          fillColor: AppTheme.cardBackgroundAlt.withValues(alpha: 0.9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: AppTheme.neonCyan.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: AppTheme.neonPink.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    List<ArcBlueprint> allBlueprints,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
    Map<ArcBlueprintFilter, int> counts,
  ) {
    final ownedCount = counts[ArcBlueprintFilter.owned] ?? 0;
    final missingCount = counts[ArcBlueprintFilter.missing] ?? 0;
    final dupesCount = counts[ArcBlueprintFilter.duplicates] ?? 0;
    final completion = allBlueprints.isEmpty
        ? 0.0
        : ownedCount / allBlueprints.length;

    Widget miniButton({
      required String label,
      required VoidCallback? onPressed,
      bool selected = false,
      bool energized = false,
      double radius = 16,
    }) {
      final borderColor = selected ? AppTheme.neonPink : AppTheme.neonCyan;
      final backgroundColor = selected
          ? AppTheme.neonPink.withValues(alpha: 0.14)
          : Colors.transparent;
      final textColor = selected ? AppTheme.neonPink : AppTheme.neonCyan;

      return ElectricChargeBorder(
        active: energized || selected,
        radius: radius,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: onPressed == null
                  ? Colors.white.withValues(alpha: 0.03)
                  : backgroundColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: onPressed == null
                    ? Colors.white.withValues(alpha: 0.10)
                    : borderColor.withValues(alpha: 0.78),
              ),
            ),
            child: Text(
              label,
              style: AppTheme.buttonTextStyle(
                color: onPressed == null ? Colors.white38 : textColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    Widget toolButton({
      required String label,
      required VoidCallback? onTap,
      required Color color,
      bool energized = false,
    }) {
      return ElectricChargeBorder(
        active: energized,
        radius: 999,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: onTap == null
                  ? Colors.white.withValues(alpha: 0.03)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: onTap == null
                    ? Colors.white.withValues(alpha: 0.10)
                    : color.withValues(alpha: 0.40),
              ),
            ),
            child: Text(
              label,
              style: AppTheme.buttonTextStyle(
                color: onTap == null ? Colors.white38 : color,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonCyan,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$ownedCount / ${allBlueprints.length} owned  •  $missingCount missing  •  $dupesCount dupes',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              miniButton(
                label: 'All (${counts[ArcBlueprintFilter.all] ?? 0})',
                selected: _selectedFilter == ArcBlueprintFilter.all,
                onPressed: () =>
                    setState(() => _selectedFilter = ArcBlueprintFilter.all),
              ),
              miniButton(
                label: 'Owned ($ownedCount)',
                selected: _selectedFilter == ArcBlueprintFilter.owned,
                onPressed: () =>
                    setState(() => _selectedFilter = ArcBlueprintFilter.owned),
              ),
              miniButton(
                label: 'Missing ($missingCount)',
                selected: _selectedFilter == ArcBlueprintFilter.missing,
                onPressed: () => setState(
                  () => _selectedFilter = ArcBlueprintFilter.missing,
                ),
              ),
              miniButton(
                label: 'Dupes ($dupesCount)',
                selected: _selectedFilter == ArcBlueprintFilter.duplicates,
                onPressed: () => setState(
                  () => _selectedFilter = ArcBlueprintFilter.duplicates,
                ),
              ),
              miniButton(
                label: _overviewMode ? 'Standard View' : 'Full View',
                selected: _overviewMode,
                energized: _overviewMode,
                onPressed: () => setState(() => _overviewMode = !_overviewMode),
              ),
              miniButton(
                label: _selectionMode ? 'Selecting' : 'Select Multiple',
                selected: _selectionMode,
                energized: _selectionMode,
                onPressed: () => _enterSelectionMode(),
              ),
              miniButton(
                label: 'Reset All',
                onPressed: () => _confirmResetGrid(),
              ),
              Tooltip(
                message:
                    'Tap missing to mark owned. Tap owned to edit reports or duplicates. Long press to select quickly.',
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSearchAppBarTitle(),
          if (_selectionMode) ...[
            const SizedBox(height: 18),
            Text(
              '${_selectedBlueprintIds.length} selected',
              style: AppTheme.tradingHeading(
                fontSize: 18,
                color: AppTheme.neonPink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                toolButton(
                  label: 'Select All Visible',
                  onTap: filtered.isEmpty ? null : () => _selectAll(filtered),
                  color: AppTheme.neonCyan,
                  energized: filtered.isNotEmpty,
                ),
                toolButton(
                  label: 'Select Row',
                  onTap: filtered.isEmpty ? null : () => _selectRow(filtered),
                  color: AppTheme.neonCyan,
                  energized: filtered.isNotEmpty,
                ),
                toolButton(
                  label: 'Select Column',
                  onTap: filtered.isEmpty
                      ? null
                      : () => _selectColumn(filtered),
                  color: AppTheme.neonCyan,
                  energized: filtered.isNotEmpty,
                ),
                toolButton(
                  label: 'Mark Owned',
                  onTap: _selectedBlueprintIds.isEmpty
                      ? null
                      : () => _applyBulkOwned(states),
                  color: AppTheme.neonPink,
                  energized: _selectedBlueprintIds.isNotEmpty,
                ),
                toolButton(
                  label: 'Add 1 Dupe',
                  onTap: _selectedBlueprintIds.isEmpty
                      ? null
                      : () => _applyBulkDupes(states),
                  color: AppTheme.neonPink,
                  energized: _selectedBlueprintIds.isNotEmpty,
                ),
                toolButton(
                  label: 'Clear Selected',
                  onTap: _selectedBlueprintIds.isEmpty ? null : _applyBulkClear,
                  color: Colors.redAccent,
                  energized: _selectedBlueprintIds.isNotEmpty,
                ),
                toolButton(
                  label: 'Exit Selection',
                  onTap: _clearSelection,
                  color: Colors.white70,
                  energized: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlueprintActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElectricChargeBorder(
      active: true,
      radius: 999,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.buttonTextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBlueprintPreview(
    ArcBlueprint blueprint,
    ArcBlueprintState state,
  ) async {
    final accent = _rarityColor(blueprint.rarity);
    final intel = ArcBlueprintIntelLibrary.resolve(blueprint);
    final maps = ArcBlueprintIntelLibrary.isAllMaps(intel.likelyMaps)
        ? 'All maps / community intel still improving.'
        : intel.likelyMaps.join(', ');
    final containers = intel.likelyContainers.isEmpty
        ? 'Check Community Intel and recent reports.'
        : intel.likelyContainers.join(', ');
    final conditions = intel.bestConditions.isEmpty
        ? 'Any raid condition.'
        : intel.bestConditions.join(', ');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 14,
          ),
          child: ElectricChargeBorder(
            active: true,
            radius: 28,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: accent.withValues(alpha: 0.46)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 34,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            blueprint.name.toUpperCase(),
                            style: AppTheme.tradingHeading(
                              fontSize: 24,
                              color: accent,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: BlueprintTile(
                        blueprint: blueprint,
                        state: state,
                        landscape: false,
                        rarityColor: accent,
                        isSelectionMode: _selectionMode,
                        isSelected: _selectedBlueprintIds.contains(
                          blueprint.id,
                        ),
                        onTap: () {},
                        onLongPress: () {},
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.owned
                          ? state.hasDuplicates
                                ? 'Owned - ${state.dupesOwned} duplicate${state.dupesOwned == 1 ? '' : 's'} available.'
                                : 'Owned - no duplicates registered.'
                          : 'Missing - use the tips below to target likely sources.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIntelLine(
                      icon: Icons.tips_and_updates_rounded,
                      label: 'Tip',
                      value: intel.tip,
                      color: AppTheme.neonCyan,
                    ),
                    _buildIntelLine(
                      icon: Icons.inventory_2_rounded,
                      label: 'Likely Sources',
                      value: containers,
                      color: accent,
                    ),
                    _buildIntelLine(
                      icon: Icons.map_rounded,
                      label: 'Maps',
                      value: maps,
                      color: AppTheme.neonPink,
                    ),
                    _buildIntelLine(
                      icon: Icons.wb_twilight_rounded,
                      label: 'Conditions',
                      value: conditions,
                      color: Colors.amberAccent,
                    ),
                    if (intel.specialSource != null)
                      _buildIntelLine(
                        icon: Icons.verified_rounded,
                        label: 'Special Source',
                        value: intel.specialSource!,
                        color: Colors.lightGreenAccent,
                      ),
                    _buildIntelLine(
                      icon: Icons.insights_rounded,
                      label: 'Confidence',
                      value: intel.confidenceLabel,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBlueprintActionButton(
                          label: state.hasDuplicates
                              ? 'Trade'
                              : 'Where to Find',
                          icon: state.hasDuplicates
                              ? Icons.swap_horiz_rounded
                              : Icons.radar_rounded,
                          color: state.hasDuplicates
                              ? AppTheme.neonPink
                              : AppTheme.neonCyan,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            Navigator.of(context).pushNamed(
                              state.hasDuplicates
                                  ? TraderHubScreen.routeName
                                  : ArcMarketIntelligenceScreen.routeName,
                            );
                          },
                        ),
                        _buildBlueprintActionButton(
                          label: state.owned ? 'Add Intel' : 'Mark Owned',
                          icon: state.owned
                              ? Icons.add_location_alt_rounded
                              : Icons.check_circle_rounded,
                          color: state.owned
                              ? AppTheme.neonCyan
                              : AppTheme.neonPink,
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            if (state.owned) {
                              await _openBlueprintEditor(blueprint, state);
                            } else {
                              await _markMissingAsOwned(blueprint, state);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
  ) {
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

    const crossAxisCount = _gridColumns;
    const spacing = _landscapeSpacing;
    const childAspectRatio = 0.98;
    const naturalTileWidth = 96.0;
    final rowCount = (filtered.length / crossAxisCount).ceil();
    final naturalTileHeight = naturalTileWidth / childAspectRatio;
    final naturalWidth =
        (naturalTileWidth * crossAxisCount) + (spacing * (crossAxisCount - 1));
    final naturalHeight =
        (naturalTileHeight * rowCount) + (spacing * (rowCount - 1));

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final safeHeight =
            mediaQuery.size.height -
            mediaQuery.padding.top -
            mediaQuery.padding.bottom;
        final reservedChromeHeight =
            mediaQuery.orientation == Orientation.landscape ? 138.0 : 232.0;
        final availableGridHeight = (safeHeight - reservedChromeHeight).clamp(
          160.0,
          safeHeight,
        );
        final widthScale = constraints.maxWidth / naturalWidth;
        final heightScale = availableGridHeight / naturalHeight;
        final scale = (widthScale < heightScale ? widthScale : heightScale)
            .clamp(0.20, 1.0)
            .toDouble();
        final fittedHeight = naturalHeight * scale;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                'Overview keeps the exact in-game order. Double tap any tile to enlarge it and view where-to-find tips.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  isBold: true,
                ),
              ),
            ),
            SizedBox(
              width: constraints.maxWidth,
              height: fittedHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: naturalWidth,
                  height: naturalHeight,
                  child: GridView.builder(
                    itemCount: filtered.length,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: childAspectRatio,
                        ),
                    itemBuilder: (context, index) {
                      final blueprint = filtered[index];
                      final state =
                          states[blueprint.id] ??
                          ArcBlueprintState.empty(blueprint.id);

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: () =>
                            _openBlueprintPreview(blueprint, state),
                        child: BlueprintTile(
                          blueprint: blueprint,
                          state: state,
                          landscape: true,
                          rarityColor: _rarityColor(blueprint.rarity),
                          isSelectionMode: _selectionMode,
                          isSelected: _selectedBlueprintIds.contains(
                            blueprint.id,
                          ),
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
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortraitBlueprintCarousel(
    BuildContext context,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
  ) {
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

    return SizedBox(
      height: 470,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.84),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final blueprint = filtered[index];
          final state =
              states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
          final accent = _rarityColor(blueprint.rarity);
          final owned = state.owned;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ElectricChargeBorder(
              active: owned || state.hasDuplicates,
              radius: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accent.withValues(alpha: owned ? 0.74 : 0.34),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: owned ? 0.16 : 0.08),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: BlueprintTile(
                        blueprint: blueprint,
                        state: state,
                        landscape: false,
                        rarityColor: accent,
                        isSelectionMode: _selectionMode,
                        isSelected: _selectedBlueprintIds.contains(
                          blueprint.id,
                        ),
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
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            owned
                                ? state.hasDuplicates
                                      ? 'Owned - ${state.dupesOwned} duplicate${state.dupesOwned == 1 ? '' : 's'} ready for trading.'
                                      : 'Owned - add intel or register duplicates.'
                                : 'Missing - check Community Intel, then mark owned when found.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              isBold: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (state.hasDuplicates)
                                _buildBlueprintActionButton(
                                  label: 'Trade',
                                  icon: Icons.swap_horiz_rounded,
                                  color: AppTheme.neonPink,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(TraderHubScreen.routeName),
                                )
                              else
                                _buildBlueprintActionButton(
                                  label: 'Where to Find',
                                  icon: Icons.radar_rounded,
                                  color: AppTheme.neonCyan,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    ArcMarketIntelligenceScreen.routeName,
                                  ),
                                ),
                              _buildBlueprintActionButton(
                                label: owned ? 'Add Intel' : 'Mark Owned',
                                icon: owned
                                    ? Icons.add_location_alt_rounded
                                    : Icons.check_circle_rounded,
                                color: owned
                                    ? AppTheme.neonCyan
                                    : AppTheme.neonPink,
                                onTap: () async {
                                  if (owned) {
                                    await _openBlueprintEditor(
                                      blueprint,
                                      state,
                                    );
                                  } else {
                                    await _markMissingAsOwned(blueprint, state);
                                  }
                                },
                              ),
                              _buildBlueprintActionButton(
                                label: 'Select',
                                icon: Icons.select_all_rounded,
                                color: Colors.white70,
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelection(blueprint.id);
                                  } else {
                                    _enterSelectionMode(blueprint.id);
                                  }
                                },
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
        },
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
  ) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (!landscape) {
      return _buildPortraitBlueprintCarousel(context, filtered, states);
    }

    final crossAxisCount = _gridColumns;
    final spacing = _landscapeSpacing;
    final childAspectRatio = 0.98;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()));
        },
        icon: const Icon(Icons.feedback_outlined),
        label: const Text('Feedback'),
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'BLUEPRINT INTEL',
          style: AppTheme.tradingHeading(
            fontSize: 26,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Track'),
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),

          SafeArea(
            child: StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _repository.watchMyBlueprintStates(),
              builder: (context, snapshot) {
                final states = snapshot.data ?? <String, ArcBlueprintState>{};
                final filtered = _applyFilter(allBlueprints, states);
                final counts = _buildCounts(allBlueprints, states);

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.pagePadding.left,
                    8,
                    AppTheme.pagePadding.right,
                    AppTheme.pagePadding.bottom + 108,
                  ),
                  children: [
                    _overviewMode
                        ? _buildOverviewGrid(context, filtered, states)
                        : _buildGrid(context, filtered, states),
                    const SizedBox(height: 18),
                    _buildBottomControls(
                      allBlueprints,
                      filtered,
                      states,
                      counts,
                    ),
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
