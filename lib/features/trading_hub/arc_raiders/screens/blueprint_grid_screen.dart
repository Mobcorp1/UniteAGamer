import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_season_reset_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_layout_metrics.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_responsive_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_loadout_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_smart_build_hunt_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_filter.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_smart_build_hunt_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_beta_first_run.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_voice_search_button.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_dialogs.dart';

class BlueprintGridScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/blueprints';

  const BlueprintGridScreen({super.key});

  @override
  State<BlueprintGridScreen> createState() => _BlueprintGridScreenState();
}

class _BlueprintViewportFrame extends StatelessWidget {
  const _BlueprintViewportFrame();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.68),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueprintGridScreenState extends State<BlueprintGridScreen> {
  final ArcBlueprintRepository _repository = ArcBlueprintRepository();
  final ArcSavedLoadoutRepository _loadoutRepository =
      ArcSavedLoadoutRepository();
  final TextEditingController _searchController = TextEditingController();
  final TransformationController _blueprintGridTransformController =
      TransformationController();

  ArcBlueprintFilter _selectedFilter = ArcBlueprintFilter.all;
  bool _selectionMode = false;
  static const int _commandBarrelLoopBasePage = 5000;
  int _commandBarrelIndex = 0;
  int _commandBarrelPage = _commandBarrelLoopBasePage;
  final PageController _commandBarrelPageController = PageController(
    initialPage: _commandBarrelLoopBasePage,
    viewportFraction: 0.96,
  );
  bool _showOverviewHint = true;
  ArcBlueprintGridViewMode _viewMode = ArcBlueprintGridViewMode.fullOverview;
  bool _viewModeLoaded = false;
  final Set<String> _selectedBlueprintIds = <String>{};
  String _searchQuery = '';
  bool _smartBuildHuntMode = false;

  static const int _gridColumns = 10;
  static const double _landscapeSpacing = 6;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ArcBetaFirstRun.showOnce(
        context: context,
        key: ArcBetaFirstRunKeys.hasSeenBlueprintTutorial,
        title: 'WELCOME TO BLUEPRINT TRACKER',
        accent: AppTheme.neonCyan,
        steps: const [
          'Tap owned blueprints to build your collection.',
          'Add duplicates so Trade Assist can find useful swaps.',
          'Set your Top 5 wanted blueprints for faster matching.',
          'Use missing, owned and duplicate filters to plan your next raid.',
        ],
      );
    });
  }

  Future<void> _loadViewMode() async {
    final mode = await ArcBlueprintGridViewPreferences.load();
    if (!mounted) return;
    setState(() {
      _viewMode = mode;
      _viewModeLoaded = true;
    });
  }

  Future<void> _setViewMode(ArcBlueprintGridViewMode mode) async {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _blueprintGridTransformController.value = Matrix4.identity();
    });
    await ArcBlueprintGridViewPreferences.save(mode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _commandBarrelPageController.dispose();
    _blueprintGridTransformController.dispose();
    super.dispose();
  }

  Future<void> _openBlueprintPhotoImport() async {
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ArcBlueprintPhotoCaptureScreen()),
    );
    if (imported == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Blueprint ownership imported successfully.'),
          ),
        );
    }
  }

  List<ArcBlueprint> _applyFilter(
    List<ArcBlueprint> blueprints,
    Map<String, ArcBlueprintState> states, {
    ArcSmartBuildHuntSnapshot? smartBuildHunt,
  }) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return blueprints
        .where((blueprint) {
          if (_smartBuildHuntMode &&
              (smartBuildHunt == null ||
                  !smartBuildHunt.contains(blueprint.id, missingOnly: true))) {
            return false;
          }
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
      _selectedFilter = ArcBlueprintFilter.all;
      _selectionMode = false;
      _selectedBlueprintIds.clear();
    });
    _jumpCommandBarrelToIndex(0);
  }

  void _jumpCommandBarrelToIndex(int index) {
    final safeIndex = index % 5;
    final targetPage = _commandBarrelLoopBasePage + safeIndex;
    _commandBarrelPage = targetPage;
    _commandBarrelIndex = safeIndex;

    if (_commandBarrelPageController.hasClients) {
      _commandBarrelPageController.jumpToPage(targetPage);
    }
  }

  void _returnToFullGridView() {
    if (!mounted) return;
    setState(() {
      _selectedFilter = ArcBlueprintFilter.all;
      _selectionMode = false;
      _selectedBlueprintIds.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpCommandBarrelToIndex(0);
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
    _returnToFullGridView();

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

  Future<void> _applySelectedMissingAndOwnRest(
    List<ArcBlueprint> allBlueprints,
    Map<String, ArcBlueprintState> states,
  ) async {
    if (_selectedBlueprintIds.isEmpty || allBlueprints.isEmpty) return;

    final selectedMissingCount = _selectedBlueprintIds.length;
    final ownedCount = allBlueprints.length - selectedMissingCount;

    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Mark selected as missing?',
      message:
          'This will mark $selectedMissingCount selected blueprints as missing and automatically mark the other $ownedCount blueprints as owned. No intel or duplicate prompts will be shown.',
      confirmLabel: 'Apply Missing Selection',
      cancelLabel: 'Cancel',
      borderColor: AppTheme.neonPink,
    );

    if (confirmed != true) return;

    final now = DateTime.now();
    final updates = allBlueprints
        .map((blueprint) {
          final isMissing = _selectedBlueprintIds.contains(blueprint.id);
          final current =
              states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
          return current.copyWith(
            owned: !isMissing,
            dupesOwned: isMissing ? 0 : current.dupesOwned,
            updatedAt: now,
          );
        })
        .toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$selectedMissingCount marked missing. $ownedCount marked owned.',
        ),
      ),
    );

    _returnToFullGridView();
  }

  Future<void> _applyBulkDupes(Map<String, ArcBlueprintState> states) async {
    if (_selectedBlueprintIds.isEmpty) return;

    final selectedIndex = await UagDialogs.chooseIndex(
      context: context,
      title: 'Set duplicate amount',
      itemCount: 10,
      labelBuilder: (index) {
        final count = index + 1;
        return count == 1 ? 'Add 1 duplicate' : 'Add $count duplicates';
      },
    );

    if (selectedIndex == null) return;

    final dupeAmount = selectedIndex + 1;
    final updates = _selectedBlueprintIds
        .map((id) {
          final current = states[id] ?? ArcBlueprintState.empty(id);
          return current.copyWith(
            owned: true,
            dupesOwned: current.dupesOwned + dupeAmount,
            updatedAt: DateTime.now(),
          );
        })
        .toList(growable: false);

    await _repository.saveBlueprintStates(updates);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $dupeAmount duplicate${dupeAmount == 1 ? '' : 's'} to ${updates.length} blueprints.',
        ),
      ),
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
      _returnToFullGridView();
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
      title: 'Start New Expedition?',
      message:
          'A fresh expedition resets blueprint ownership and duplicates together with Scrappy, quests, bench progress and current-season Operations. Permanent profile, reputation, availability, Favourite Raiders and earned reward history remain.',
      titleColor: Colors.redAccent,
      confirmLabel: 'Review Full Reset',
      confirmBackgroundColor: Colors.redAccent,
      confirmForegroundColor: Colors.black,
      borderColor: Colors.redAccent,
    );

    if (confirmed != true || !mounted) return;

    await Navigator.of(context).pushNamed(ArcSeasonResetScreen.routeName);
    if (!mounted) return;
    _clearSelection();
    _returnToFullGridView();
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
            _returnToFullGridView();
          },
          onClear: () => _confirmClearSingleBlueprint(blueprint, initialState),
        );
      },
    );

    if (saved == true && mounted) {
      _returnToFullGridView();
    }
  }

  Widget? _buildLoadoutAction(
    ArcBlueprint blueprint,
    ArcSavedLoadout? loadout, {
    required bool compact,
  }) {
    final candidate = ArcBlueprintLoadoutBridge.candidateFor(blueprint);
    if (candidate == null) return null;
    final selected = ArcBlueprintLoadoutBridge.isSelected(
      blueprint: blueprint,
      loadout: loadout,
    );
    final label = selected
        ? 'Remove ${blueprint.name} from Favourite Loadout'
        : 'Add ${blueprint.name} to Favourite Loadout';
    final size = compact ? 26.0 : 34.0;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _toggleBlueprintLoadoutItem(blueprint, loadout),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.amberAccent.withValues(alpha: 0.86)
                      : AppTheme.neonCyan.withValues(alpha: 0.62),
                ),
              ),
              child: Icon(
                selected ? Icons.star_rounded : Icons.star_border_rounded,
                size: compact ? 16 : 21,
                color: selected ? Colors.amberAccent : AppTheme.neonCyan,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBlueprintLoadoutItem(
    ArcBlueprint blueprint,
    ArcSavedLoadout? currentLoadout,
  ) async {
    final candidate = ArcBlueprintLoadoutBridge.candidateFor(blueprint);
    if (candidate == null) return;

    try {
      final selected = ArcBlueprintLoadoutBridge.isSelected(
        blueprint: blueprint,
        loadout: currentLoadout,
      );
      final baseLoadout = ArcBlueprintLoadoutBridge.baseLoadout(currentLoadout);

      ArcSavedLoadout? nextLoadout;
      if (selected) {
        nextLoadout = ArcBlueprintLoadoutBridge.remove(
          blueprint: blueprint,
          loadout: baseLoadout,
        );
      } else {
        final destinations = ArcBlueprintLoadoutBridge.destinationsFor(
          blueprint: blueprint,
          loadout: baseLoadout,
        );
        if (destinations.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${blueprint.name} is not compatible with your current Favourite Loadout slots.',
              ),
            ),
          );
          return;
        }

        final destination = destinations.length == 1
            ? destinations.single
            : await _pickLoadoutDestination(
                blueprint: blueprint,
                candidate: candidate,
                destinations: destinations,
              );
        if (destination == null) return;

        nextLoadout = ArcBlueprintLoadoutBridge.applyDestination(
          blueprint: blueprint,
          loadout: baseLoadout,
          destination: destination,
        );
      }

      await _loadoutRepository.saveLoadout(nextLoadout);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected
                ? '${blueprint.name} removed from Favourite Loadout.'
                : '${blueprint.name} added to Favourite Loadout.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update Favourite Loadout: $error')),
      );
    }
  }

  Future<ArcBlueprintLoadoutDestination?> _pickLoadoutDestination({
    required ArcBlueprint blueprint,
    required ArcBlueprintLoadoutCandidate candidate,
    required List<ArcBlueprintLoadoutDestination> destinations,
  }) {
    return showModalBottomSheet<ArcBlueprintLoadoutDestination>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: ElectricChargeBorder(
            active: true,
            radius: 24,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ADD ${blueprint.name.toUpperCase()}',
                            style: AppTheme.tradingHeading(
                              fontSize: 20,
                              color: AppTheme.neonCyan,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      '${candidate.kindLabel} blueprint. Pick the Favourite Loadout slot to update.',
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: destinations.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final destination = destinations[index];
                        final replacement = destination.replacesOccupiedSlot
                            ? 'Replaces ${destination.currentItem}'
                            : 'Empty slot';
                        return ListTile(
                          title: Text(
                            destination.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            replacement,
                            style: const TextStyle(color: Colors.white60),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.neonCyan,
                          ),
                          onTap: () =>
                              Navigator.of(sheetContext).pop(destination),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  Widget _buildSmartBuildHuntPanel(ArcSmartBuildHuntSnapshot hunt) {
    final accent = hunt.complete ? Colors.lightGreenAccent : Colors.amberAccent;
    final subtitle = hunt.complete
        ? 'Every Blueprint required for this build is owned.'
        : '${hunt.missingCount} of ${hunt.requiredCount} required Blueprints still missing';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ElectricChargeBorder(
        active: _smartBuildHuntMode,
        radius: 18,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.38)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: hunt.completionPercent / 100,
                      strokeWidth: 5,
                      color: accent,
                      backgroundColor: Colors.white12,
                    ),
                    Text(
                      '${hunt.completionPercent}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hunt.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    if (hunt.nextTargetName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Next target: ${hunt.nextTargetName}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('smart-build-hunt-toggle'),
                onPressed: hunt.complete
                    ? null
                    : () {
                        setState(() {
                          _smartBuildHuntMode = !_smartBuildHuntMode;
                          if (_smartBuildHuntMode) {
                            _selectedFilter = ArcBlueprintFilter.missing;
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                icon: Icon(
                  _smartBuildHuntMode
                      ? Icons.grid_view_rounded
                      : Icons.my_location_rounded,
                ),
                label: Text(
                  _smartBuildHuntMode ? 'Show Full Grid' : 'Hunt Build Gaps',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FavouriteLoadoutScreen(),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Edit Smart Build'),
              ),
            ],
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
    final totalCount = allBlueprints.length;
    final completion = totalCount == 0 ? 0.0 : ownedCount / totalCount;

    Widget barrelChip({
      required String label,
      required VoidCallback? onTap,
      bool selected = false,
      Color? color,
    }) {
      final accent =
          color ?? (selected ? AppTheme.neonPink : AppTheme.neonCyan);
      return ElectricChargeBorder(
        active: selected,
        radius: 999,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: onTap == null
                    ? Colors.white.withValues(alpha: 0.10)
                    : accent.withValues(alpha: selected ? 0.72 : 0.34),
              ),
            ),
            child: Text(
              label,
              style: AppTheme.buttonTextStyle(
                color: onTap == null ? Colors.white38 : accent,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    Widget barrelCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> children,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElectricChargeBorder(
          active: true,
          radius: 24,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.08),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppTheme.neonCyan, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.tradingHeading(
                          fontSize: 14,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                    ),
                    Text(
                      '${_commandBarrelIndex + 1}/5',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                ] else
                  const SizedBox(height: 3),
                Wrap(spacing: 5, runSpacing: 5, children: children),
              ],
            ),
          ),
        ),
      );
    }

    final cards = <Widget>[
      barrelCard(
        icon: Icons.search_rounded,
        title: 'Search',
        subtitle: 'Find a blueprint without leaving the full grid.',
        children: [SizedBox(width: 235, child: _buildSearchAppBarTitle())],
      ),
      barrelCard(
        icon: Icons.filter_alt_rounded,
        title: 'Filters',
        subtitle: '',
        children: [_buildVerticalFilterBarrel(counts: counts)],
      ),
      barrelCard(
        icon: Icons.analytics_rounded,
        title: 'Progress',
        subtitle:
            '$ownedCount / $totalCount owned • $missingCount missing • $dupesCount dupes',
        children: [
          SizedBox(
            width: 280,
            child: ClipRRect(
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
          ),
          barrelChip(
            label: '${(completion * 100).round()}% complete',
            onTap: null,
            selected: true,
          ),
        ],
      ),
      barrelCard(
        icon: Icons.trending_up_rounded,
        title: 'Market',
        subtitle: 'Jump into demand, trades and community drop reports.',
        children: [
          barrelChip(
            label: 'Market Intel',
            color: AppTheme.neonPink,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ArcMarketIntelligenceScreen.routeName),
          ),
          barrelChip(
            label: 'Trade Hub',
            color: AppTheme.neonCyan,
            onTap: () =>
                Navigator.of(context).pushNamed(TraderHubScreen.routeName),
          ),
        ],
      ),
      barrelCard(
        icon: Icons.select_all_rounded,
        title: 'Multi Select',
        subtitle: _selectionMode
            ? '${_selectedBlueprintIds.length} selected'
            : 'Bulk mark owned, missing, dupes, rows or columns.',
        children: [
          barrelChip(
            label: _selectionMode ? 'Selecting' : 'Select Multiple',
            selected: _selectionMode,
            color: AppTheme.neonPink,
            onTap: () => _enterSelectionMode(),
          ),
          if (_selectionMode) ...[
            barrelChip(
              label: 'Select All Visible',
              onTap: filtered.isEmpty ? null : () => _selectAll(filtered),
            ),
            barrelChip(
              label: 'Select Row',
              onTap: filtered.isEmpty ? null : () => _selectRow(filtered),
            ),
            barrelChip(
              label: 'Select Column',
              onTap: filtered.isEmpty ? null : () => _selectColumn(filtered),
            ),
            barrelChip(
              label: 'Mark Owned',
              color: AppTheme.neonPink,
              onTap: _selectedBlueprintIds.isEmpty
                  ? null
                  : () => _applyBulkOwned(states),
            ),
            barrelChip(
              label: 'Selected Missing',
              color: Colors.amberAccent,
              onTap: _selectedBlueprintIds.isEmpty
                  ? null
                  : () =>
                        _applySelectedMissingAndOwnRest(allBlueprints, states),
            ),
            barrelChip(
              label: 'Bulk Dupes',
              color: AppTheme.neonPink,
              onTap: _selectedBlueprintIds.isEmpty
                  ? null
                  : () => _applyBulkDupes(states),
            ),
            barrelChip(
              label: 'Clear Selected',
              color: Colors.redAccent,
              onTap: _selectedBlueprintIds.isEmpty ? null : _applyBulkClear,
            ),
            barrelChip(
              label: 'Exit',
              color: Colors.white70,
              onTap: _clearSelection,
            ),
          ],
        ],
      ),
    ];

    void goToBarrelPage(int delta) {
      final targetPage = _commandBarrelPage + delta;
      _commandBarrelPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      setState(() {
        _commandBarrelPage = targetPage;
        _commandBarrelIndex = targetPage % cards.length;
      });
    }

    Widget barrelArrow(IconData icon, VoidCallback? onTap) {
      return IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: AppTheme.neonCyan,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
          side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final cardHeight = desktop
            ? (_selectionMode ? 178.0 : 118.0)
            : (_selectionMode ? 226.0 : 136.0);
        final maxCardWidth = desktop
            ? switch (_commandBarrelIndex) {
                0 => 270.0,
                1 => 210.0,
                2 => 255.0,
                3 => 295.0,
                4 => _selectionMode ? 390.0 : 270.0,
                _ => 270.0,
              }
            : constraints.maxWidth;

        final pageView = AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: maxCardWidth,
          constraints: BoxConstraints(maxWidth: maxCardWidth),
          child: SizedBox(
            height: cardHeight,
            child: PageView.builder(
              onPageChanged: (page) => setState(() {
                _commandBarrelPage = page;
                _commandBarrelIndex = page % cards.length;
              }),
              controller: _commandBarrelPageController,
              itemBuilder: (context, index) => cards[index % cards.length],
            ),
          ),
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (desktop) ...[
                    barrelArrow(
                      Icons.chevron_left_rounded,
                      () => goToBarrelPage(-1),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(child: pageView),
                  if (desktop) ...[
                    const SizedBox(width: 12),
                    barrelArrow(
                      Icons.chevron_right_rounded,
                      () => goToBarrelPage(1),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(cards.length, (index) {
                  final active = index == _commandBarrelIndex;
                  return AnimatedContainer(
                    duration: AppTheme.fastAnimation,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.neonPink
                          : Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnershipSynchronizingState() {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.pagePadding.left,
        18,
        AppTheme.pagePadding.right,
        AppTheme.pagePadding.bottom + 82,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.raised,
            accent: AppTheme.neonCyan,
            radius: 22,
            borderOpacity: 0.28,
            glow: true,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synchronising Blueprint ownership',
                      style: AppTheme.tradingHeading(
                        fontSize: 18,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Restoring your saved ownership and duplicate counts.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<ArcBlueprintFilter> get _filterBarrelOrder => const [
    ArcBlueprintFilter.all,
    ArcBlueprintFilter.owned,
    ArcBlueprintFilter.missing,
    ArcBlueprintFilter.duplicates,
  ];

  String _filterBarrelLabel(
    ArcBlueprintFilter filter,
    Map<ArcBlueprintFilter, int> counts,
  ) {
    final count = counts[filter] ?? 0;
    return switch (filter) {
      ArcBlueprintFilter.all => 'All ($count)',
      ArcBlueprintFilter.owned => 'Owned ($count)',
      ArcBlueprintFilter.missing => 'Missing ($count)',
      ArcBlueprintFilter.duplicates => 'Dupes ($count)',
    };
  }

  ArcBlueprintFilter _filterAtOffset(int offset) {
    final order = _filterBarrelOrder;
    final selectedIndex = order.indexOf(_selectedFilter);
    final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final nextIndex = (safeIndex + offset) % order.length;
    return order[nextIndex < 0 ? nextIndex + order.length : nextIndex];
  }

  void _rotateFilterBarrel(int offset) {
    setState(() => _selectedFilter = _filterAtOffset(offset));
  }

  Widget _filterBarrelRow({
    required ArcBlueprintFilter filter,
    required Map<ArcBlueprintFilter, int> counts,
    required bool active,
  }) {
    final color = active ? AppTheme.neonCyan : Colors.white60;
    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: active ? 0 : 5),
      padding: EdgeInsets.symmetric(
        horizontal: active ? 9 : 8,
        vertical: active ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.neonCyan.withValues(alpha: 0.13)
            : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(active ? 18 : 14),
        border: Border.all(
          color: active
              ? AppTheme.neonCyan.withValues(alpha: 0.46)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.12),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Text(
        _filterBarrelLabel(filter, counts).toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.buttonTextStyle(
          color: color,
          fontSize: active ? 11 : 9,
        ),
      ),
    );
  }

  Widget _buildVerticalFilterBarrel({
    required Map<ArcBlueprintFilter, int> counts,
  }) {
    Widget arrowButton(IconData icon, VoidCallback onTap) {
      return SizedBox(
        width: 30,
        height: 30,
        child: IconButton.filledTonal(
          tooltip: icon == Icons.keyboard_arrow_up_rounded
              ? 'Previous filter'
              : 'Next filter',
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          color: AppTheme.neonCyan,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.cardBackgroundDeep.withValues(
              alpha: 0.82,
            ),
            side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.26)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = MediaQuery.of(context).size.width >= 900;
        final barrelWidth = desktop
            ? 166.0
            : constraints.maxWidth.clamp(180.0, 240.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 0) {
              _rotateFilterBarrel(-1);
            } else if (velocity < 0) {
              _rotateFilterBarrel(1);
            }
          },
          child: SizedBox(
            width: barrelWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _filterBarrelRow(
                        filter: _filterAtOffset(-1),
                        counts: counts,
                        active: false,
                      ),
                      const SizedBox(height: 4),
                      _filterBarrelRow(
                        filter: _selectedFilter,
                        counts: counts,
                        active: true,
                      ),
                      const SizedBox(height: 4),
                      _filterBarrelRow(
                        filter: _filterAtOffset(1),
                        counts: counts,
                        active: false,
                      ),
                    ],
                  ),
                ),
                if (desktop) ...[
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      arrowButton(
                        Icons.keyboard_arrow_up_rounded,
                        () => _rotateFilterBarrel(-1),
                      ),
                      const SizedBox(height: 5),
                      arrowButton(
                        Icons.keyboard_arrow_down_rounded,
                        () => _rotateFilterBarrel(1),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
          decoration: ArcUiTokens.chipDecoration(color: color, selected: true),
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

  Future<void> _openBlueprintLoadoutActions(
    ArcBlueprint blueprint,
    ArcBlueprintState state,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final accent = _rarityColor(blueprint.rarity);
        Widget actionTile({
          required String value,
          required IconData icon,
          required String title,
          required String subtitle,
        }) {
          return ListTile(
            leading: Icon(icon, color: accent),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Colors.white60),
            ),
            onTap: () => Navigator.of(sheetContext).pop(value),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(14),
          child: ElectricChargeBorder(
            active: true,
            radius: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.38)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              blueprint.name.toUpperCase(),
                              style: AppTheme.tradingHeading(
                                fontSize: 18,
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
                    ),
                    actionTile(
                      value: 'loadout',
                      icon: Icons.inventory_2_rounded,
                      title: 'Add to Favourite Loadout',
                      subtitle: state.owned
                          ? 'Use this owned blueprint in your public build.'
                          : 'Add as missing and make it a priority target.',
                    ),
                    actionTile(
                      value: 'primary',
                      icon: Icons.looks_one_rounded,
                      title: 'Set as Primary',
                      subtitle:
                          'Open the loadout builder with this as primary focus.',
                    ),
                    actionTile(
                      value: 'secondary',
                      icon: Icons.looks_two_rounded,
                      title: 'Set as Secondary',
                      subtitle:
                          'Open the loadout builder with this as secondary focus.',
                    ),
                    actionTile(
                      value: 'track',
                      icon: Icons.track_changes_rounded,
                      title: 'Track / Select Blueprint',
                      subtitle:
                          'Select it for missing, duplicate or hunt workflows.',
                    ),
                    actionTile(
                      value: 'trade',
                      icon: Icons.swap_horiz_rounded,
                      title: 'Find Trade',
                      subtitle: 'Open Trading to look for swaps or offers.',
                    ),
                    actionTile(
                      value: 'intel',
                      icon: Icons.radar_rounded,
                      title: 'View Intel',
                      subtitle: 'Open Community Intel for drop reports.',
                    ),
                    actionTile(
                      value: 'raid',
                      icon: Icons.route_rounded,
                      title: 'Generate Blueprint Run',
                      subtitle: 'Open Raid Intelligence for a route.',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'loadout':
      case 'primary':
      case 'secondary':
        Navigator.of(context).pushNamed(FavouriteLoadoutScreen.routeName);
        return;
      case 'track':
        _enterSelectionMode(blueprint.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${blueprint.name} selected for blueprint workflows.',
            ),
          ),
        );
        return;
      case 'trade':
        Navigator.of(context).pushNamed(TraderHubScreen.routeName);
        return;
      case 'intel':
        Navigator.of(context).pushNamed(ArcMarketIntelligenceScreen.routeName);
        return;
      case 'raid':
        Navigator.of(context).pushNamed(ArcRaidIntelligenceScreen.routeName);
        return;
    }
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
                        onLongPress: () =>
                            _openBlueprintLoadoutActions(blueprint, state),
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
                        _buildBlueprintActionButton(
                          label: 'Generate Run',
                          icon: Icons.route_rounded,
                          color: Colors.amberAccent,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            Navigator.of(
                              context,
                            ).pushNamed(ArcRaidIntelligenceScreen.routeName);
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

  void _zoomBlueprintGrid(double delta) {
    final currentScale = _blueprintGridTransformController.value
        .getMaxScaleOnAxis();
    final nextScale = (currentScale + delta).clamp(1.0, 5.5).toDouble();
    _blueprintGridTransformController.value = Matrix4.diagonal3Values(
      nextScale,
      nextScale,
      1,
    );
  }

  void _resetBlueprintGridZoom() {
    _blueprintGridTransformController.value = Matrix4.identity();
  }

  void _jumpBlueprintOverviewRows({
    required bool down,
    required double viewportHeight,
    required double gridHeight,
    required int rowCount,
  }) {
    final current = _blueprintGridTransformController.value;
    var scale = current.getMaxScaleOnAxis();
    var currentTranslationY = current.storage[13];

    final targetY = ArcBlueprintGridLayoutMetrics.jumpTranslationY(
      currentTranslationY: currentTranslationY,
      scale: scale,
      viewportHeight: viewportHeight,
      fittedGridHeight: gridHeight,
      rowCount: rowCount,
      down: down,
    );

    final next = Matrix4.copy(current)
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(2, 2, 1)
      ..setEntry(1, 3, targetY);

    setState(() {
      _blueprintGridTransformController.value = next;
    });
  }

  Widget _buildGridControlRail({
    required double viewportHeight,
    required double gridHeight,
    required int rowCount,
    required bool enableRowJumps,
  }) {
    Widget button({
      required IconData icon,
      required String tooltip,
      required Color accent,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      final color = enabled ? accent : Colors.white30;
      return Tooltip(
        message: tooltip,
        child: ElectricChargeBorder(
          active: enabled,
          radius: 999,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onTap : null,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.42)),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.14),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _blueprintGridTransformController,
      builder: (context, _) {
        final current = _blueprintGridTransformController.value;
        final scale = current.getMaxScaleOnAxis();
        final translationY = current.storage[13];
        final jumpState = ArcBlueprintGridLayoutMetrics.jumpState(
          currentTranslationY: translationY,
          scale: scale,
          viewportHeight: viewportHeight,
          fittedGridHeight: gridHeight,
          rowCount: rowCount,
        );
        final canJumpDown =
            enableRowJumps &&
            rowCount > 5 &&
            (scale <= 1.01 || jumpState.canJumpDown);

        return Container(
          key: const ValueKey('blueprint-grid-right-control-rail'),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(
                icon: Icons.keyboard_arrow_up_rounded,
                tooltip: 'Jump back to upper grid',
                accent: AppTheme.neonPink,
                enabled: enableRowJumps && jumpState.canJumpUp,
                onTap: () => _jumpBlueprintOverviewRows(
                  down: false,
                  viewportHeight: viewportHeight,
                  gridHeight: gridHeight,
                  rowCount: rowCount,
                ),
              ),
              const SizedBox(height: 6),
              button(
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: 'Jump to lower grid',
                accent: AppTheme.neonPink,
                enabled: canJumpDown,
                onTap: () => _jumpBlueprintOverviewRows(
                  down: true,
                  viewportHeight: viewportHeight,
                  gridHeight: gridHeight,
                  rowCount: rowCount,
                ),
              ),
              const SizedBox(height: 10),
              button(
                icon: Icons.zoom_in_rounded,
                tooltip: 'Zoom in',
                accent: AppTheme.neonCyan,
                enabled: true,
                onTap: () => _zoomBlueprintGrid(0.45),
              ),
              const SizedBox(height: 6),
              button(
                icon: Icons.center_focus_strong_rounded,
                tooltip: 'Reset grid view',
                accent: AppTheme.neonCyan,
                enabled: true,
                onTap: _resetBlueprintGridZoom,
              ),
              const SizedBox(height: 6),
              button(
                icon: Icons.zoom_out_rounded,
                tooltip: 'Zoom out',
                accent: AppTheme.neonCyan,
                enabled: true,
                onTap: () => _zoomBlueprintGrid(-0.45),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewModeRail({required bool compact}) {
    Widget modeButton(ArcBlueprintGridViewMode mode, IconData icon) {
      final selected = _viewMode == mode;
      final label = mode == ArcBlueprintGridViewMode.inGameFramed
          ? 'IN-GAME'
          : 'FULL GRID';

      return Semantics(
        button: true,
        selected: selected,
        label: mode.label,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _setViewMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: compact ? 42 : 78,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 9,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.neonCyan.withValues(alpha: 0.14)
                    : AppTheme.cardBackgroundDeep.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppTheme.neonCyan.withValues(alpha: 0.68)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? AppTheme.neonCyan : Colors.white60,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 5),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTheme.buttonTextStyle(
                        color: selected ? AppTheme.neonCyan : Colors.white60,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('blueprint-grid-left-view-rail'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          modeButton(
            ArcBlueprintGridViewMode.inGameFramed,
            Icons.crop_free_rounded,
          ),
          const SizedBox(height: 8),
          modeButton(
            ArcBlueprintGridViewMode.fullOverview,
            Icons.grid_view_rounded,
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Import blueprint grid from game',
            child: Tooltip(
              message: 'IMPORT FROM GAME',
              child: InkWell(
                key: const Key('blueprint-import-from-game'),
                borderRadius: BorderRadius.circular(16),
                onTap: _openBlueprintPhotoImport,
                child: Container(
                  width: compact ? 42 : 78,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonPink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.neonPink.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 18,
                        color: AppTheme.neonPink,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 5),
                        Text(
                          'IMPORT',
                          textAlign: TextAlign.center,
                          style: AppTheme.buttonTextStyle(
                            color: AppTheme.neonPink,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_viewModeLoaded) ...[
            const SizedBox(height: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlueprintHeaderTitle(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showHint = _showOverviewHint && width >= 650;
    final hint = _viewMode == ArcBlueprintGridViewMode.inGameFramed
        ? 'Exact in-game order • Five rows per frame • Pinch to zoom • Drag to pan'
        : 'Full grid overview • Pinch to zoom • Drag to pan';

    return Row(
      children: [
        Text(
          'Blueprint Tracker',
          style: ArcUiTokens.pageTitle(
            fontSize: width < 430 ? 17 : 19,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
        if (showHint) ...[
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: Colors.white70,
                isBold: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hide grid instructions',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _showOverviewHint = false),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.70),
              size: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    List<ArcBlueprint> filtered,
    Map<String, ArcBlueprintState> states,
    ArcSavedLoadout? loadout,
  ) {
    if (filtered.isEmpty) {
      return Container(
        padding: AppTheme.sectionCardPadding,
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.panel,
          accent: AppTheme.neonCyan,
          radius: 16,
          borderOpacity: 0.16,
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
    final searchActive = _searchQuery.trim().isNotEmpty;

    Widget buildTiles({required double width, required double height}) {
      return SizedBox(
        width: width,
        height: height,
        child: GridView.builder(
          itemCount: filtered.length,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final blueprint = filtered[index];
            final state =
                states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => _openBlueprintPreview(blueprint, state),
              child: BlueprintTile(
                blueprint: blueprint,
                state: state,
                landscape: true,
                rarityColor: _rarityColor(blueprint.rarity),
                isSelectionMode: _selectionMode,
                isSelected: _selectedBlueprintIds.contains(blueprint.id),
                loadoutAction: _buildLoadoutAction(
                  blueprint,
                  loadout,
                  compact: true,
                ),
                onTap: () async {
                  if (_selectionMode) {
                    _toggleSelection(blueprint.id);
                    return;
                  }

                  await _openBlueprintPreview(blueprint, state);
                },
                onLongPress: () =>
                    _openBlueprintLoadoutActions(blueprint, state),
              ),
            );
          },
        ),
      );
    }

    Widget buildResponsiveSearchResults() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final layout = ArcBlueprintGridResponsivePolicy.searchLayout(
            resultCount: filtered.length,
            width: maxWidth,
          );
          final resultSpacing = maxWidth < 520 ? 10.0 : 12.0;
          final gridWidth = math.min(
            maxWidth,
            layout.columns * layout.maxTileWidth +
                (layout.columns - 1) * resultSpacing,
          );

          return Center(
            child: SizedBox(
              width: gridWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${filtered.length} search result${filtered.length == 1 ? '' : 's'}',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        isBold: true,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: layout.columns,
                      crossAxisSpacing: resultSpacing,
                      mainAxisSpacing: resultSpacing,
                      childAspectRatio: layout.childAspectRatio,
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
                          landscape: false,
                          rarityColor: _rarityColor(blueprint.rarity),
                          isSelectionMode: _selectionMode,
                          isSelected: _selectedBlueprintIds.contains(
                            blueprint.id,
                          ),
                          contentScale:
                              layout.size == ArcBlueprintSearchResultSize.single
                              ? 1.35
                              : layout.size == ArcBlueprintSearchResultSize.grid
                              ? 1.08
                              : 1.20,
                          loadoutAction: _buildLoadoutAction(
                            blueprint,
                            loadout,
                            compact: false,
                          ),
                          onTap: () async {
                            if (_selectionMode) {
                              _toggleSelection(blueprint.id);
                              return;
                            }

                            await _openBlueprintPreview(blueprint, state);
                          },
                          onLongPress: () =>
                              _openBlueprintLoadoutActions(blueprint, state),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget buildRotatePrompt() {
      return Semantics(
        container: true,
        label:
            'Rotate your device. The In-Game View needs a wider screen. Turn your device to landscape, or use Full Grid Overview.',
        child: Container(
          padding: AppTheme.sectionCardPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.raised,
            accent: AppTheme.neonCyan,
            radius: 16,
            borderOpacity: 0.28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.screen_rotation_alt_rounded,
                    color: AppTheme.neonCyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rotate your device',
                      style: AppTheme.tradingHeading(
                        fontSize: 24,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'The In-Game View needs a wider screen. Turn your device to landscape, or use Full Grid Overview.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _setViewMode(ArcBlueprintGridViewMode.fullOverview),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Use Full Grid'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final safeHeight =
            mediaQuery.size.height -
            mediaQuery.padding.top -
            mediaQuery.padding.bottom;
        final isLandscape = mediaQuery.orientation == Orientation.landscape;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaQuery.size.width;
        if (searchActive) return buildResponsiveSearchResults();
        if (_viewMode == ArcBlueprintGridViewMode.inGameFramed &&
            ArcBlueprintGridResponsivePolicy.shouldShowInGameRotatePrompt(
              width: maxWidth,
              height: mediaQuery.size.height,
            )) {
          return buildRotatePrompt();
        }
        final compactRails = maxWidth < 620;
        final leftRailWidth = compactRails ? 50.0 : 86.0;
        const rightRailWidth = 46.0;
        final railGap = compactRails ? 4.0 : 8.0;
        final availableGridWidth =
            ArcBlueprintGridLayoutMetrics.availableGridWidth(
              availableWidth: maxWidth,
              leftRailWidth: leftRailWidth,
              rightRailWidth: rightRailWidth,
              railGap: railGap,
            );
        final reservedChromeHeight = isLandscape ? 72.0 : 142.0;
        final availableGridHeight = (safeHeight - reservedChromeHeight).clamp(
          170.0,
          safeHeight,
        );

        Widget buildFramedGrid() {
          final layout = ArcBlueprintGridLayoutMetrics.framedLayout(
            itemCount: filtered.length,
            columns: crossAxisCount,
            childAspectRatio: childAspectRatio,
            spacing: spacing,
            availableWidth: availableGridWidth,
            availableHeight: availableGridHeight,
          );
          final rowCount = filtered.isEmpty
              ? 0
              : (filtered.length / crossAxisCount).ceil();

          return Center(
            child: SizedBox(
              width:
                  leftRailWidth +
                  railGap +
                  layout.viewportWidth +
                  railGap +
                  rightRailWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: leftRailWidth,
                    height: layout.viewportHeight,
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildViewModeRail(compact: compactRails),
                    ),
                  ),
                  SizedBox(width: railGap),
                  SizedBox(
                    width: layout.viewportWidth,
                    height: layout.viewportHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: InteractiveViewer(
                              transformationController:
                                  _blueprintGridTransformController,
                              alignment: Alignment.topCenter,
                              panEnabled: true,
                              scaleEnabled: true,
                              constrained: false,
                              minScale: 1.0,
                              maxScale: isLandscape ? 5.5 : 4.2,
                              boundaryMargin: const EdgeInsets.symmetric(
                                vertical: 32,
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: buildTiles(
                                width: layout.gridWidth,
                                height: layout.gridHeight,
                              ),
                            ),
                          ),
                        ),
                        const _BlueprintViewportFrame(),
                      ],
                    ),
                  ),
                  SizedBox(width: railGap),
                  SizedBox(
                    width: rightRailWidth,
                    height: layout.viewportHeight,
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildGridControlRail(
                        viewportHeight: layout.viewportHeight,
                        gridHeight: layout.gridHeight,
                        rowCount: rowCount,
                        enableRowJumps: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget buildFullOverviewGrid() {
          const naturalTileWidth = 96.0;
          final metrics = ArcBlueprintGridLayoutMetrics(
            itemCount: filtered.length,
            columns: crossAxisCount,
            tileWidth: naturalTileWidth,
            childAspectRatio: childAspectRatio,
            spacing: spacing,
          );
          final widthScale = availableGridWidth / metrics.naturalWidth;
          final heightScale = availableGridHeight / metrics.naturalHeight;
          final fittedScale = math
              .min(widthScale, heightScale)
              .clamp(0.20, 1.0)
              .toDouble();
          final fittedHeight = metrics.naturalHeight * fittedScale;
          final fittedWidth = metrics.naturalWidth * fittedScale;
          final viewportHeight = fittedHeight.clamp(170.0, availableGridHeight);

          return Center(
            child: SizedBox(
              width:
                  leftRailWidth +
                  railGap +
                  fittedWidth +
                  railGap +
                  rightRailWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: leftRailWidth,
                    height: viewportHeight,
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildViewModeRail(compact: compactRails),
                    ),
                  ),
                  SizedBox(width: railGap),
                  SizedBox(
                    width: fittedWidth,
                    height: viewportHeight,
                    child: ClipRect(
                      child: InteractiveViewer(
                        transformationController:
                            _blueprintGridTransformController,
                        alignment: Alignment.center,
                        panEnabled: true,
                        scaleEnabled: true,
                        constrained: true,
                        minScale: 1.0,
                        maxScale: isLandscape ? 5.5 : 4.2,
                        boundaryMargin: const EdgeInsets.all(384),
                        clipBehavior: Clip.none,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: buildTiles(
                            width: metrics.naturalWidth,
                            height: metrics.naturalHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: railGap),
                  SizedBox(
                    width: rightRailWidth,
                    height: viewportHeight,
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildGridControlRail(
                        viewportHeight: viewportHeight,
                        gridHeight: fittedHeight,
                        rowCount: metrics.rowCount,
                        enableRowJumps: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _viewMode == ArcBlueprintGridViewMode.inGameFramed
              ? buildFramedGrid()
              : buildFullOverviewGrid(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBlueprints = [...ArcBlueprintSeedData.blueprints]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: _buildBlueprintHeaderTitle(context),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Blueprint menu',
            icon: const Icon(Icons.menu_rounded, color: AppTheme.neonPink),
            color: AppTheme.cardBackgroundDeep,
            onSelected: (value) {
              switch (value) {
                case 'feedback':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  );
                  return;
                case 'reset':
                  _confirmResetGrid();
                  return;
                case 'search':
                  _jumpCommandBarrelToIndex(0);
                  return;
                case 'filters':
                  _jumpCommandBarrelToIndex(1);
                  return;
                case 'select':
                  setState(() => _selectionMode = true);
                  _jumpCommandBarrelToIndex(4);
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'search', child: Text('Search')),
              PopupMenuItem(value: 'filters', child: Text('Filters')),
              PopupMenuItem(value: 'select', child: Text('Multi Select')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'feedback', child: Text('Feedback')),
              PopupMenuItem(value: 'reset', child: Text('Reset Ownership')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Track'),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: StreamBuilder<ArcBlueprintStateSnapshot>(
            stream: _repository.watchMyBlueprintStateSnapshot(),
            builder: (context, snapshot) {
              final hydration = snapshot.data;
              final states =
                  hydration?.states ?? const <String, ArcBlueprintState>{};
              if (hydration == null ||
                  (hydration.isLoading && states.isEmpty)) {
                return _buildOwnershipSynchronizingState();
              }
              final counts = _buildCounts(allBlueprints, states);

              return StreamBuilder<ArcSavedLoadout?>(
                stream: _loadoutRepository.watchFavouriteLoadout(),
                builder: (context, loadoutSnapshot) {
                  final loadout = loadoutSnapshot.data;
                  final plan = ArcGeneratedLoadoutPlan.fromMap(
                    loadout?.smartBuildData,
                  );
                  final smartBuildHunt = ArcSmartBuildHuntEngine.build(
                    plan: plan,
                    blueprintStates: states,
                  );
                  final filtered = _applyFilter(
                    allBlueprints,
                    states,
                    smartBuildHunt: smartBuildHunt,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.pagePadding.left,
                      8,
                      AppTheme.pagePadding.right,
                      AppTheme.pagePadding.bottom + 82,
                    ),
                    children: [
                      if (smartBuildHunt != null)
                        _buildSmartBuildHuntPanel(smartBuildHunt),
                      _buildOverviewGrid(context, filtered, states, loadout),
                      const SizedBox(height: 18),
                      _buildBottomControls(
                        allBlueprints,
                        filtered,
                        states,
                        counts,
                      ),
                      const SizedBox(height: 10),
                      const ArcAdBannerCard(),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
