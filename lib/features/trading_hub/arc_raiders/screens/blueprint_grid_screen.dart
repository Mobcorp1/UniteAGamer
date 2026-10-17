import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_season_reset_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_layout_metrics.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_responsive_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_layout_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_unlock_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_smart_build_hunt_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_progress_header.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_voice_search_button.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_service.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_dialogs.dart';

class BlueprintGridTargetPickArgs {
  const BlueprintGridTargetPickArgs({required this.slotIndex});

  final int slotIndex;
}

class BlueprintGridScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/blueprints';

  const BlueprintGridScreen({
    super.key,
    this.blueprintStateSnapshotStream,
    this.favouriteLoadoutStream,
    this.loadViewMode,
    this.saveViewMode,
    this.showFirstRunTutorial = true,
    this.bannerSlot,
    this.favouriteLoadoutTargetSlotIndex,
  });

  final Stream<ArcBlueprintStateSnapshot> Function()?
  blueprintStateSnapshotStream;
  final Stream<ArcSavedLoadout?> Function()? favouriteLoadoutStream;
  final Future<ArcBlueprintGridViewMode> Function()? loadViewMode;
  final Future<void> Function(ArcBlueprintGridViewMode mode)? saveViewMode;
  final bool showFirstRunTutorial;
  final Widget? bannerSlot;
  final int? favouriteLoadoutTargetSlotIndex;

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
  ArcBlueprintRepository? _repository;
  ArcSavedLoadoutRepository? _loadoutRepository;
  final TextEditingController _searchController = TextEditingController();
  final TransformationController _blueprintGridTransformController =
      TransformationController();

  ArcBlueprintFilter _selectedFilter = ArcBlueprintFilter.all;
  bool _selectionMode = false;
  bool _toolsOpen = false;
  ArcBlueprintStateSnapshot? _lastHydration;
  late Stream<ArcBlueprintStateSnapshot> _stateStream;
  late Stream<ArcSavedLoadout?> _loadoutStream;
  bool _showOverviewHint = true;
  bool _showProgressHeader = true;
  ArcBlueprintGridViewMode _viewMode = ArcBlueprintGridViewMode.fullOverview;
  bool _viewModeLoaded = false;
  final Set<String> _selectedBlueprintIds = <String>{};
  String _searchQuery = '';
  bool _smartBuildHuntMode = false;
  bool _advancedGridControlsVisible = false;
  String? _targetPickSavingBlueprintId;

  bool get _isFavouriteLoadoutTargetPickMode =>
      widget.favouriteLoadoutTargetSlotIndex != null;

  static const int _gridColumns = 17;
  static const double _landscapeSpacing = 6;

  ArcBlueprintRepository get _blueprintRepository =>
      _repository ??= ArcBlueprintRepository();

  ArcSavedLoadoutRepository get _savedLoadoutRepository =>
      _loadoutRepository ??= ArcSavedLoadoutRepository();

  Stream<ArcBlueprintStateSnapshot> _watchBlueprintStateSnapshot() {
    final streamBuilder = widget.blueprintStateSnapshotStream;
    if (streamBuilder != null) return streamBuilder();
    return _blueprintRepository.watchMyBlueprintStateSnapshot();
  }

  Stream<ArcSavedLoadout?> _watchFavouriteLoadout() {
    final streamBuilder = widget.favouriteLoadoutStream;
    if (streamBuilder != null) return streamBuilder();
    return _savedLoadoutRepository.watchFavouriteLoadout();
  }

  @override
  void initState() {
    super.initState();
    _stateStream = _watchBlueprintStateSnapshot().asBroadcastStream();
    _loadoutStream = _watchFavouriteLoadout().asBroadcastStream();
    if (_isFavouriteLoadoutTargetPickMode) {
      _selectedFilter = ArcBlueprintFilter.missing;
      _showOverviewHint = false;
    }
    _loadViewMode();
    if (!widget.showFirstRunTutorial || _isFavouriteLoadoutTargetPickMode) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ArcBetaFirstRun.showOnce(
        context: context,
        key: ArcBetaFirstRunKeys.hasSeenBlueprintTutorial,
        title: 'WELCOME TO COLLECTIONS TRACKER',
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
    final mode =
        await (widget.loadViewMode?.call() ??
            ArcBlueprintGridViewPreferences.load());
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
    final saveViewMode = widget.saveViewMode;
    if (saveViewMode != null) {
      await saveViewMode(mode);
    } else {
      await ArcBlueprintGridViewPreferences.save(mode);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _blueprintGridTransformController.dispose();
    super.dispose();
  }

  Future<void> _openBlueprintPhotoImport() async {
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ArcFrozenTrailSingleGridCaptureScreen(),
      ),
    );
  }

  // Frozen Trail: display order is independent of persisted Blueprint IDs.
  // The original 83 IDs are not modified and the scanner remains guarded.
  static const String _unknownSlotPrefix = 'uag-unresolved-grid-slot-';

  bool _isUnknownGridCell(ArcBlueprint item) =>
      item.id.startsWith(_unknownSlotPrefix);

  List<ArcBlueprint> _frozenTrailBlueprints() {
    final seeds = ArcBlueprintSeedData.blueprints;
    final seedById = {for (final blueprint in seeds) blueprint.id: blueprint};
    final mapped = <ArcBlueprint>[];
    final occupied = <int>{};
    for (final entry in ArcFrozenTrailCollectionCatalogue.blueprintEntries) {
      final slot = entry.slot;
      if (slot == null) continue;
      if (slot < 1 || slot > 91 || !occupied.add(slot)) {
        throw StateError('Invalid or duplicated Frozen Trail slot $slot');
      }
      final seed = seedById[entry.id];
      if (seed != null) {
        mapped.add(
          ArcBlueprint(
            id: seed.id,
            name: seed.name,
            category: seed.category,
            group: seed.group,
            sortOrder: slot,
            rarity: seed.rarity,
            icon: seed.icon,
            imageAssetPath: seed.imageAssetPath,
            intelHint: seed.intelHint,
          ),
        );
      } else {
        final asset =
            ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths[entry.id];
        mapped.add(
          ArcBlueprint(
            id: entry.id,
            name: entry.name,
            category: 'Frozen Trail',
            group: 'Blueprint',
            sortOrder: slot,
            rarity: ArcBlueprintRarity.rare,
            icon: Icons.auto_awesome_outlined,
            imageAssetPath: asset,
          ),
        );
      }
    }
    mapped.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return mapped;
  }

  // Unknown cells preserve their physical positions without inventing IDs
  // that can be saved or selected. Use only in unfiltered full-grid rendering.
  List<ArcBlueprint> _fullGridWithUnknownCells(List<ArcBlueprint> mapped) {
    final bySlot = {for (final item in mapped) item.sortOrder: item};
    return <ArcBlueprint>[
      for (var slot = 1; slot <= 91; slot++)
        bySlot[slot] ??
            ArcBlueprint(
              id: '$_unknownSlotPrefix$slot',
              name: 'Unidentified Blueprint',
              category: 'Unknown',
              group: 'Unresolved',
              sortOrder: slot,
              rarity: ArcBlueprintRarity.common,
              icon: Icons.help_outline,
            ),
    ];
  }

  Widget _unknownGridCell(int slot) => Container(
    key: Key('blueprint-unresolved-slot-$slot'),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF111B22),
      border: Border.all(color: const Color(0xFF406070), width: 0.8),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.lock_outline, color: Colors.white38, size: 18),
  );

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

          if (_isFavouriteLoadoutTargetPickMode) {
            final canonical = ArcBlueprintSeedData.blueprints.any(
              (candidate) => candidate.id == blueprint.id,
            );
            if (!canonical || state.owned || state.priorityRank > 0) {
              return false;
            }
          }

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
    setState(() => _toolsOpen = false);
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
      setState(() => _toolsOpen = false);
    });
  }

  void _selectAll(List<ArcBlueprint> filtered) {
    setState(() {
      _selectionMode = true;
      _selectedBlueprintIds
        ..clear()
        ..addAll(
          filtered
              .where((item) => !_isUnknownGridCell(item))
              .map((item) => item.id),
        );
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
        ..addAll(
          selected
              .where((item) => !_isUnknownGridCell(item))
              .map((item) => item.id),
        );
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
      if (!_isUnknownGridCell(filtered[i])) selected.add(filtered[i]);
    }

    setState(() {
      _selectionMode = true;
      _selectedBlueprintIds
        ..clear()
        ..addAll(
          selected
              .where((item) => !_isUnknownGridCell(item))
              .map((item) => item.id),
        );
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
      ownershipSource:
          currentState.ownershipSource == ArcBlueprintOwnershipSource.scan
          ? ArcBlueprintOwnershipSource.scan
          : ArcBlueprintOwnershipSource.manual,
      updatedAt: DateTime.now(),
    );

    await _blueprintRepository.saveBlueprintState(ownedState);

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
          (await _blueprintRepository
              .watchMyBlueprintStates()
              .first)[blueprint.id] ??
          ownedState;
      await _openBlueprintEditor(blueprint, refreshed);
    }
  }

  Future<void> _applyBulkOwned(Map<String, ArcBlueprintState> states) async {
    final updates = _selectedBlueprintIds
        .map((id) {
          final current = states[id] ?? ArcBlueprintState.empty(id);
          return current.copyWith(
            owned: true,
            ownershipSource:
                current.ownershipSource == ArcBlueprintOwnershipSource.scan
                ? ArcBlueprintOwnershipSource.scan
                : ArcBlueprintOwnershipSource.manual,
          );
        })
        .toList(growable: false);

    await _blueprintRepository.saveBlueprintStates(updates);
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
            ownershipSource: isMissing
                ? ArcBlueprintOwnershipSource.unknown
                : current.ownershipSource == ArcBlueprintOwnershipSource.scan
                ? ArcBlueprintOwnershipSource.scan
                : ArcBlueprintOwnershipSource.manual,
            updatedAt: now,
          );
        })
        .toList(growable: false);

    await _blueprintRepository.saveBlueprintStates(updates);
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

    await _blueprintRepository.saveBlueprintStates(updates);
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

    await _blueprintRepository.saveBlueprintStates(updates);
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
      await _blueprintRepository.saveBlueprintState(
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
        SnackBar(
          content: Text('Could not clear ${blueprint.name}. Try again.'),
        ),
      );
    }
  }

  Future<void> _confirmClearBlueprintGridOnly() async {
    final confirmed = await UagDialogs.confirm(
      context: context,
      title: 'Clear Blueprint Grid?',
      message:
          'This clears only Blueprint ownership, duplicate counts and Blueprint priorities. '
          'It does not reset Scrappy, quests, bench progress, Operations, profile or reputation.',
      titleColor: Colors.redAccent,
      confirmLabel: 'Clear Grid',
      confirmBackgroundColor: Colors.redAccent,
      confirmForegroundColor: Colors.black,
      borderColor: Colors.redAccent,
    );

    if (confirmed != true) return;

    try {
      // Reset both legacy and newly introduced Frozen Trail Blueprint IDs.
      // Grid artwork remains visible, but every cleared card becomes unowned.
      final allBlueprintIds = <String>{
        for (final blueprint in ArcBlueprintSeedData.blueprints) blueprint.id,
        for (final entry in ArcFrozenTrailCollectionCatalogue.blueprintEntries)
          entry.id,
      };
      await _blueprintRepository.resetAllBlueprintStates(allBlueprintIds);
      if (!mounted) return;

      _blueprintGridTransformController.value = Matrix4.identity();
      _returnToFullGridView();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Blueprint Grid cleared.')),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not clear the Blueprint Grid. Try again.'),
        ),
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
          repository: _blueprintRepository,
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
    Map<ArcBlueprintFilter, int> counts, {
    ArcSmartBuildHuntSnapshot? hunt,
  }) {
    final media = MediaQuery.of(context);
    final compactBlueprintToolsLandscape =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        media.orientation == Orientation.landscape &&
        media.size.height <= 720;
    Widget action(String label, VoidCallback? onPressed) =>
        OutlinedButton(onPressed: onPressed, child: Text(label));
    return Material(
      key: const Key('blueprint-tools-panel'),
      color: AppTheme.cardBackgroundDeep,
      borderRadius: BorderRadius.circular(16),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Blueprint tools')),
              IconButton(
                tooltip: 'Close Blueprint tools',
                onPressed: () => setState(() => _toolsOpen = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          _buildSearchAppBarTitle(),
          if (hunt != null) _buildSmartBuildHuntPanel(hunt),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final filter in ArcBlueprintFilter.values)
                ChoiceChip(
                  label: Text('${filter.name} (${counts[filter] ?? 0})'),
                  selected: _selectedFilter == filter,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_showProgressHeader && !compactBlueprintToolsLandscape) ...[
            BlueprintProgressHeader(
              completion: (counts[ArcBlueprintFilter.owned] ?? 0) /
                  ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots,
              ownedCount: counts[ArcBlueprintFilter.owned] ?? 0,
              missingCount: counts[ArcBlueprintFilter.missing] ?? 0,
              dupesCount: counts[ArcBlueprintFilter.duplicates] ?? 0,
              totalCount: ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots,
              landscape:
                  MediaQuery.of(context).orientation == Orientation.landscape,
              onClose: () => setState(() => _showProgressHeader = false),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${counts[ArcBlueprintFilter.owned]} / ${ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots} owned · ${counts[ArcBlueprintFilter.missing]} known missing · ${ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots - allBlueprints.length} unidentified · ${counts[ArcBlueprintFilter.duplicates]} dupes',
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              action('Import from game', _openBlueprintPhotoImport),
              action(
                'Market Intel',
                () => Navigator.of(
                  context,
                ).pushNamed(ArcMarketIntelligenceScreen.routeName),
              ),
              action(
                'Trade Hub',
                () =>
                    Navigator.of(context).pushNamed(TraderHubScreen.routeName),
              ),
              action('Select Multiple', () {
                _enterSelectionMode();
                setState(() => _toolsOpen = false);
              }),
              if (_selectionMode) ...[
                action(
                  'Select All Visible',
                  filtered.isEmpty ? null : () => _selectAll(filtered),
                ),
                action(
                  'Select Row',
                  filtered.isEmpty ? null : () => _selectRow(filtered),
                ),
                action(
                  'Select Column',
                  filtered.isEmpty ? null : () => _selectColumn(filtered),
                ),
                action(
                  'Mark Owned',
                  _selectedBlueprintIds.isEmpty
                      ? null
                      : () => _applyBulkOwned(states),
                ),
                action(
                  'Selected Missing',
                  _selectedBlueprintIds.isEmpty
                      ? null
                      : () => _applySelectedMissingAndOwnRest(
                          allBlueprints,
                          states,
                        ),
                ),
                action(
                  'Bulk Dupes',
                  _selectedBlueprintIds.isEmpty
                      ? null
                      : () => _applyBulkDupes(states),
                ),
                action(
                  'Clear Selected',
                  _selectedBlueprintIds.isEmpty ? null : _applyBulkClear,
                ),
                action('Exit Selection', _clearSelection),
              ],
            ],
          ),
        ],
      ),
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

  Future<void> _selectFavouriteLoadoutWantedBlueprint(
    ArcBlueprint blueprint,
    ArcBlueprintState state,
    Map<String, ArcBlueprintState> states,
  ) async {
    final slotIndex = widget.favouriteLoadoutTargetSlotIndex;
    if (slotIndex == null ||
        slotIndex < 0 ||
        slotIndex >= ArcLoadoutLayoutEngine.wantedBlueprintSlotCount) {
      return;
    }
    if (state.owned ||
        state.priorityRank > 0 ||
        _targetPickSavingBlueprintId != null) {
      return;
    }

    final targetRank = slotIndex + 1;
    final updates = <ArcBlueprintState>[];

    for (final current in states.values) {
      if (current.blueprintId != blueprint.id &&
          current.priorityRank == targetRank) {
        updates.add(current.copyWith(priorityRank: 0));
      }
    }
    updates.add(state.copyWith(priorityRank: targetRank));

    setState(() => _targetPickSavingBlueprintId = blueprint.id);
    try {
      await _blueprintRepository.saveBlueprintStates(updates);
      if (!mounted) return;
      Navigator.of(context).pop(blueprint.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _targetPickSavingBlueprintId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not add ${blueprint.name} to Wanted Blueprints.',
          ),
        ),
      );
    }
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

  Future<void> _adjustBlueprintSearchDupe(
    ArcBlueprint blueprint, ArcBlueprintState current, int delta,
  ) async {
    if (delta > 0 && !current.owned) {
      final confirm = await UagDialogs.confirm(
        context: context,
        title: 'Own ${blueprint.name}?',
        message: 'This Blueprint is marked missing. Confirm you own one AND have a spare copy before adding +1.',
        confirmLabel: 'Own it + add spare',
        cancelLabel: 'Cancel',
        borderColor: AppTheme.neonCyan,
      );
      if (confirm != true || !mounted) return;
    }
    final next = (current.dupesOwned + delta).clamp(0, 999);
    if (next == current.dupesOwned) return;
    final update = current.copyWith(
      owned: current.owned || delta > 0,
      dupesOwned: next,
      ownershipSource: current.owned
          ? current.ownershipSource : ArcBlueprintOwnershipSource.manual,
      updatedAt: DateTime.now(),
    );
    await _blueprintRepository.saveBlueprintState(update);
  }

  Widget _buildBlueprintDupeSearch(
    List<ArcBlueprint> allBlueprints,
    Map<String, ArcBlueprintState> states,
  ) {
    return ArcCollectionDupeManager(
      collection: 'Blueprints',
      entries: [for (final blueprint in allBlueprints)
        ArcCollectionDupeEntry(
          id: blueprint.id,
          name: blueprint.name,
          owned: (states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id)).owned,
          spares: (states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id)).dupesOwned,
          detail: blueprint.category,
          imageAssetPath: blueprint.imageAssetPath,
          icon: blueprint.icon,
        )],
      onAdjust: (id, delta) {
        final blueprint = allBlueprints.firstWhere((item) => item.id == id);
        return _adjustBlueprintSearchDupe(
          blueprint, states[id] ?? ArcBlueprintState.empty(id), delta);
      },
    );
  }

  // Owned cards are trading actions; acquisition intel is only useful when missing.
  Future<void> _openOwnedBlueprintDupeActions(
    ArcBlueprint blueprint,
    ArcBlueprintState state,
  ) async {
    if (!mounted || !state.owned) return;
    var displayed = state.dupesOwned;
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1B26),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, refresh) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(blueprint.name, textAlign: TextAlign.center,
                style: AppTheme.tradingHeading(fontSize: 22, color: AppTheme.neonCyan)),
              const SizedBox(height: 5),
              Text('Owned  ·  $displayed spare ${displayed == 1 ? 'copy' : 'copies'}',
                style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('blueprint-quick-add-dupe'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('ADD DUPE +1'),
                onPressed: saving || displayed >= 999 ? null : () async {
                  refresh(() => saving = true);
                  try {
                    final latest = state.copyWith(
                      owned: true,
                      dupesOwned: displayed + 1,
                      updatedAt: DateTime.now(),
                    );
                    await _blueprintRepository.saveBlueprintState(latest);
                    displayed = latest.dupesOwned;
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${blueprint.name}: $displayed spare copies saved.')));
                    }
                  } catch (_) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Could not save duplicate. Try again.')));
                    }
                  } finally {
                    if (sheetContext.mounted) refresh(() => saving = false);
                  }
                },
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton.icon(
                  key: const Key('blueprint-quick-remove-dupe'),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('REMOVE ONE'),
                  onPressed: saving || displayed <= 0 ? null : () async {
                    refresh(() => saving = true);
                    try {
                      final latest = state.copyWith(dupesOwned: displayed - 1,
                        updatedAt: DateTime.now());
                      await _blueprintRepository.saveBlueprintState(latest);
                      displayed = latest.dupesOwned;
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    } catch (_) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Could not save duplicate change.')));
                      }
                    } finally {
                      if (sheetContext.mounted) refresh(() => saving = false);
                    }
                  },
                ),
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(sheetContext).pop(),
                  child: const Text('DONE'),
                ),
              ]),
            ]),
          ),
        ),
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
    final unlockPlan = ArcBlueprintUnlockEngine.planForBlueprint(
      blueprint.name,
    );

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
                    if (unlockPlan != null)
                      _buildIntelLine(
                        icon: Icons.account_tree_rounded,
                        label: 'Guaranteed Quest Unlock',
                        value: unlockPlan.shortSummary,
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
                        if (unlockPlan != null && !state.owned)
                          _buildBlueprintActionButton(
                            label: 'Quest Path',
                            icon: Icons.account_tree_rounded,
                            color: Colors.lightGreenAccent,
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              Navigator.of(context).pushNamed(
                                ScrappyGridScreen.questRouteName,
                                arguments: <String, Object?>{
                                  'questFocusId': unlockPlan.quest.id,
                                  'sourceBlueprintName': blueprint.name,
                                },
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

  Future<void> _shareBlueprintCollection() async {
    final hydration = _lastHydration;
    if (hydration == null || !hydration.hasConfirmedLoad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for saved Blueprint ownership to load before sharing.')),
      );
      return;
    }
    final owned = <ArcCollectionShareItem>[];
    final needed = <ArcCollectionShareItem>[];
    final spares = <ArcCollectionShareItem>[];
    final mapped = _frozenTrailBlueprints();
    for (final blueprint in mapped) {
      if (_isUnknownGridCell(blueprint)) continue;
      final state = hydration.states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      final item = ArcCollectionShareItem(
        id: blueprint.id,
        label: blueprint.name,
        rarity: blueprint.rarity.name,
        assetPath: blueprint.imageAssetPath,
        spares: state.dupesOwned,
      );
      if (state.owned) { owned.add(item); } else { needed.add(item); }
      if (state.dupesOwned > 0) { spares.add(item); }
    }
    if (!mounted) return;
    await ArcCollectionVisualShare.show(
      context: context,
      title: 'Blueprints',
      owned: owned,
      needed: needed,
      duplicates: spares,
      wantedPriorityRanks: {
        for (final entry in mapped)
          if ((hydration.states[entry.id]?.priorityRank ?? 0) > 0)
            entry.id: hydration.states[entry.id]!.priorityRank,
      },
    );
  }

  Widget _buildGridCommandBar({
    required double viewportHeight,
    required double gridHeight,
    required int rowCount,
    required bool enableRowJumps,
    required bool hasOwnedBlueprints,
    bool vertical = false,
  }) {
    return AnimatedBuilder(
      animation: _blueprintGridTransformController,
      builder: (context, _) {
        const gap = 6.0;
        const portraitSmallColumns = 4;
        const verticalColumns = 2;
        final panelWidth = vertical ? 106.0 : double.infinity;
        final panelHeight = vertical ? 256.0 : 54.0;

        return Container(
          key: Key(
            vertical
                ? 'blueprint-grid-vertical-command-rail'
                : 'blueprint-grid-horizontal-command-bar',
          ),
          width: panelWidth,
          height: panelHeight,
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.24),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const padding = 6.0;
              final contentWidth = math.max(
                constraints.maxWidth - (padding * 2),
                1.0,
              );
              final portraitSmallWidth = math.max(
                (contentWidth - (gap * (portraitSmallColumns - 1))) /
                    portraitSmallColumns,
                1.0,
              );
              final portraitLargeWidth = math.max(
                (contentWidth - gap) / 2,
                1.0,
              );
              final verticalCellWidth = math.max(
                (contentWidth - (gap * (verticalColumns - 1))) /
                    verticalColumns,
                1.0,
              );
              final verticalPrimaryWidth = contentWidth;
              final buttonHeight = vertical ? 44.0 : 48.0;
              const portraitLargeHeight = 58.0;

              Widget commandButton({
                required IconData icon,
                required String tooltip,
                required Color accent,
                required VoidCallback onTap,
                String? label,
                String? subtitle,
                bool selected = false,
                bool enabled = true,
                bool primaryCameraAction = false,
                double? width,
                double? height,
              }) {
                final resolvedColor = !enabled
                    ? Colors.white30
                    : primaryCameraAction
                    ? AppTheme.neonCyan
                    : selected
                    ? accent
                    : Colors.white70;
                final resolvedWidth =
                    width ??
                    (vertical
                        ? primaryCameraAction
                              ? verticalPrimaryWidth
                              : verticalCellWidth
                        : label == null
                        ? portraitSmallWidth
                        : portraitLargeWidth);
                final resolvedHeight =
                    height ??
                    (vertical || label == null
                        ? buttonHeight
                        : portraitLargeHeight);

                final content = label == null
                    ? Icon(icon, color: resolvedColor, size: vertical ? 21 : 22)
                    : vertical
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: resolvedColor, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: AppTheme.bodyTextStyle(
                                fontSize: 10,
                                color: resolvedColor,
                                isBold: true,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(icon, color: resolvedColor, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 11,
                                      color: resolvedColor,
                                      isBold: true,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodyTextStyle(
                                        fontSize: 8.5,
                                        color: resolvedColor.withValues(
                                          alpha: enabled ? 0.72 : 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                return Tooltip(
                  message: tooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: enabled ? onTap : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: resolvedWidth,
                      height: resolvedHeight,
                      decoration: BoxDecoration(
                        color: primaryCameraAction
                            ? AppTheme.neonPink.withValues(
                                alpha: enabled ? 0.92 : 0.32,
                              )
                            : selected
                            ? accent.withValues(alpha: 0.14)
                            : AppTheme.cardBackgroundDeep.withValues(
                                alpha: 0.72,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryCameraAction
                              ? AppTheme.neonCyan.withValues(
                                  alpha: enabled ? 0.95 : 0.35,
                                )
                              : selected
                              ? accent.withValues(alpha: 0.68)
                              : Colors.white.withValues(alpha: 0.12),
                          width: primaryCameraAction ? 1.8 : 1,
                        ),
                        boxShadow: primaryCameraAction && enabled
                            ? [
                                BoxShadow(
                                  color: AppTheme.neonPink.withValues(
                                    alpha: 0.24,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: content,
                    ),
                  ),
                );
              }

              Widget inGameButton({double? width, double? height}) =>
                  commandButton(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'In-game view - five-row game layout',
                    accent: AppTheme.neonCyan,
                    label: vertical ? null : 'IN-GAME VIEW',
                    subtitle: vertical ? null : '5-row game layout',
                    selected:
                        _viewMode == ArcBlueprintGridViewMode.inGameFramed,
                    width: width,
                    height: height,
                    onTap: () =>
                        _setViewMode(ArcBlueprintGridViewMode.inGameFramed),
                  );

              Widget fullGridButton({double? width, double? height}) =>
                  commandButton(
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Full grid overview - all Blueprint slots',
                    accent: AppTheme.neonCyan,
                    label: vertical ? null : 'FULL GRID',
                    subtitle: vertical ? null : 'Full collection view',
                    selected:
                        _viewMode == ArcBlueprintGridViewMode.fullOverview,
                    width: width,
                    height: height,
                    onTap: () =>
                        _setViewMode(ArcBlueprintGridViewMode.fullOverview),
                  );

              Widget updateButton({double? width, double? height}) =>
                  commandButton(
                    icon: Icons.camera_alt_outlined,
                    tooltip: hasOwnedBlueprints
                        ? 'Update Blueprint ownership from game'
                        : 'Scan Blueprint grid from game',
                    accent: AppTheme.neonCyan,
                    label: null,
                    subtitle: vertical ? null : 'Scan ownership',
                    primaryCameraAction: true,
                    width: width,
                    height: height,
                    onTap: _openBlueprintPhotoImport,
                  );

              Widget zoomOutButton({double? width}) => commandButton(
                icon: Icons.zoom_out_rounded,
                tooltip: 'Zoom out',
                accent: AppTheme.neonCyan,
                width: width,
                onTap: () => _zoomBlueprintGrid(-0.45),
              );

              Widget zoomInButton({double? width}) => commandButton(
                icon: Icons.zoom_in_rounded,
                tooltip: 'Zoom in',
                accent: AppTheme.neonCyan,
                width: width,
                onTap: () => _zoomBlueprintGrid(0.45),
              );

              Widget resetViewButton({double? width, double? height}) =>
                  commandButton(
                    icon: Icons.center_focus_strong_rounded,
                    tooltip: 'Reset grid view',
                    accent: AppTheme.neonCyan,
                    label: vertical ? null : 'RESET VIEW',
                    subtitle: vertical ? null : 'Fit & centre',
                    width: width,
                    height: height,
                    onTap: _resetBlueprintGridZoom,
                  );

              Widget clearGridButton() => commandButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: 'Clear Blueprint Grid',
                accent: Colors.redAccent,
                onTap: _confirmClearBlueprintGridOnly,
              );

              if (vertical) {
                final controls = <Widget>[
                  updateButton(width: verticalPrimaryWidth, height: 38),
                  commandButton(
                    icon: Icons.apps_rounded, tooltip: 'Show all blueprints',
                    accent: AppTheme.neonCyan, label: 'ALL',
                    width: verticalPrimaryWidth, height: 33,
                    selected: _selectedFilter == ArcBlueprintFilter.all,
                    onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.all),
                  ),
                  commandButton(
                    icon: Icons.help_outline_rounded, tooltip: 'Show needed blueprints',
                    accent: AppTheme.neonCyan, label: 'NEEDED',
                    width: verticalPrimaryWidth, height: 33,
                    selected: _selectedFilter == ArcBlueprintFilter.missing,
                    onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.missing),
                  ),
                  commandButton(
                    icon: Icons.copy_all_rounded, tooltip: 'Show duplicate blueprints',
                    accent: AppTheme.neonPink, label: 'DUPES',
                    width: verticalPrimaryWidth, height: 33,
                    selected: _selectedFilter == ArcBlueprintFilter.duplicates,
                    onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.duplicates),
                  ),
                  commandButton(
                    icon: Icons.share_outlined, tooltip: 'Share selected Blueprint list',
                    accent: AppTheme.neonCyan, label: 'SHARE',
                    width: verticalPrimaryWidth, height: 33,
                    onTap: _shareBlueprintCollection,
                  ),
                  commandButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: 'Advanced grid controls', accent: AppTheme.neonCyan,
                    label: 'MORE', width: verticalPrimaryWidth, height: 32,
                    onTap: () => setState(() =>
                        _advancedGridControlsVisible = !_advancedGridControlsVisible),
                  ),
                  if (_advancedGridControlsVisible) ...[
                    inGameButton(), fullGridButton(),
                    zoomOutButton(), resetViewButton(), zoomInButton(), clearGridButton(),
                  ],
                ];

                return Padding(
                  padding: const EdgeInsets.all(padding),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            alignment: WrapAlignment.start,
                            children: controls,
                          ),
                        ),
                      ),
                      if (!_viewModeLoaded)
                        const Positioned(
                          right: 2,
                          bottom: 2,
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.3),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(padding),
                child: Stack(
                  children: [
                    SizedBox(
                      key: const Key('blueprint-portrait-command-layout'),
                      height: 43,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          updateButton(width: 50, height: 38),
                          const SizedBox(width: 6),
                          commandButton(icon: Icons.apps_rounded, tooltip: 'All',
                            accent: AppTheme.neonCyan, label: 'ALL', width: 85, height: 38,
                            selected: _selectedFilter == ArcBlueprintFilter.all,
                            onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.all)),
                          const SizedBox(width: 6),
                          commandButton(icon: Icons.help_outline_rounded, tooltip: 'Needed',
                            accent: AppTheme.neonCyan, label: 'NEEDED', width: 112, height: 38,
                            selected: _selectedFilter == ArcBlueprintFilter.missing,
                            onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.missing)),
                          const SizedBox(width: 6),
                          commandButton(icon: Icons.copy_all_rounded, tooltip: 'Duplicates',
                            accent: AppTheme.neonPink, label: 'DUPES', width: 105, height: 38,
                            selected: _selectedFilter == ArcBlueprintFilter.duplicates,
                            onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.duplicates)),
                          const SizedBox(width: 6),
                          commandButton(icon: Icons.share_outlined, tooltip: 'Share collection',
                            accent: AppTheme.neonCyan, label: 'SHARE', width: 106, height: 38,
                            onTap: _shareBlueprintCollection),
                          const SizedBox(width: 6),
                          commandButton(icon: Icons.more_horiz_rounded,
                            tooltip: 'More', accent: AppTheme.neonCyan,
                            width: 50, height: 38,
                            onTap: () => setState(() => _toolsOpen = true)),
                        ]),
                      ),
                    ),
                    if (!_viewModeLoaded)
                      const Positioned(
                        right: 2,
                        bottom: 2,
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.3),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBlueprintHeaderTitle(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    // PASS05: collection switcher occupies the top toolbar, not a second row.
    final showWorkspaceInHeader = !_isFavouriteLoadoutTargetPickMode;
    final showHint =
        !showWorkspaceInHeader && _showOverviewHint && width >= 650;
    final hint = _viewMode == ArcBlueprintGridViewMode.inGameFramed
        ? 'Exact in-game order - Five rows per frame - Pinch to zoom - Drag to pan'
        : 'Full grid overview - Pinch to zoom - Drag to pan';

    return Row(
      children: [
        Text(
          _isFavouriteLoadoutTargetPickMode
              ? 'PICK WANTED ${widget.favouriteLoadoutTargetSlotIndex! + 1}/10'
              : 'Collections Tracker',
          style: ArcUiTokens.pageTitle(
            fontSize: width < 430 ? 17 : 19,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
        if (showWorkspaceInHeader) ...[
          const SizedBox(width: 18),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: ArcCollectionsCategoryBar(
                  selected: ArcCollectionsCategory.blueprints,
                  showDupes: true,
                  dupesSelected: _selectedFilter == ArcBlueprintFilter.duplicates,
                  onDupesSelected: () => setState(() =>
                    _selectedFilter = ArcBlueprintFilter.duplicates),
                  onSelected: (category) {
                    if (category == ArcCollectionsCategory.blueprints) {
                      if (_selectedFilter == ArcBlueprintFilter.duplicates) {
                        setState(() => _selectedFilter = ArcBlueprintFilter.all);
                      }
                      return;
                    }
                    Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        settings: const RouteSettings(name: BlueprintGridScreen.routeName),
                        builder: (_) => ArcAdditionalCollectionsScreen(
                          initialKind: category == ArcCollectionsCategory.stencils
                              ? ArcNativeCollectionKind.stencils
                              : ArcNativeCollectionKind.designs,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ] else if (showHint) ...[
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
    final isNativeMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final hasOwnedBlueprints = states.values.any((state) => state.owned);

    Widget buildTiles({required double width, required double height}) {
      return SizedBox(
        width: width,
        height: height,
        child: GridView.builder(
          key: const Key('blueprint-authoritative-grid-view'),
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
            if (_isUnknownGridCell(blueprint)) {
              return _unknownGridCell(blueprint.sortOrder);
            }
            final state =
                states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _isFavouriteLoadoutTargetPickMode
                  ? null
                  : () => _openBlueprintPreview(blueprint, state),
              child: BlueprintTile(
                blueprint: blueprint,
                state: state,
                landscape: true,
                rarityColor: _rarityColor(blueprint.rarity),
                isSelectionMode: _selectionMode,
                isSelected: _selectedBlueprintIds.contains(blueprint.id),
                showOwnershipBadge: !isNativeMobile,
                onTap: () async {
                  if (_isFavouriteLoadoutTargetPickMode) {
                    await _selectFavouriteLoadoutWantedBlueprint(
                      blueprint,
                      state,
                      states,
                    );
                    return;
                  }
                  if (_selectionMode) {
                    _toggleSelection(blueprint.id);
                    return;
                  }

                  if (!state.owned) {
                    await _markMissingAsOwned(blueprint, state);
                    return;
                  }
                  await _openOwnedBlueprintDupeActions(blueprint, state);
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
                        onDoubleTap: _isFavouriteLoadoutTargetPickMode
                            ? null
                            : () => _openBlueprintPreview(blueprint, state),
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
                          showOwnershipBadge: !isNativeMobile,
                          onTap: () async {
                            if (_isFavouriteLoadoutTargetPickMode) {
                              await _selectFavouriteLoadoutWantedBlueprint(
                                blueprint,
                                state,
                                states,
                              );
                              return;
                            }
                            if (_selectionMode) {
                              _toggleSelection(blueprint.id);
                              return;
                            }

                            if (!state.owned) {
                              await _markMissingAsOwned(blueprint, state);
                              return;
                            }
                            await _openOwnedBlueprintDupeActions(blueprint, state);
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

    return AnimatedBuilder(
      animation: UagAdService.instance,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final isLandscape = mediaQuery.orientation == Orientation.landscape;
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : mediaQuery.size.width;

            if (searchActive) {
              return SingleChildScrollView(
                child: buildResponsiveSearchResults(),
              );
            }
            final compactNativeLandscape =
                isNativeMobile && isLandscape && mediaQuery.size.height <= 720;
            const commandRailWidth = 106.0;
            const commandRailGap = 8.0;
            final reservedSideWidth = compactNativeLandscape
                ? commandRailWidth + commandRailGap
                : 0.0;
            final availableGridWidth = math.max(
              280.0,
              maxWidth - reservedSideWidth,
            );

            final bodyHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : mediaQuery.size.height;
            const commandBarHeight = 54.0;
            const commandBarGap = 6.0;
            const gridVerticalSafetyInset = 10.0;
            final availableGridHeight = math.max(
              120.0,
              compactNativeLandscape
                  ? bodyHeight - gridVerticalSafetyInset
                  : bodyHeight -
                        commandBarHeight -
                        commandBarGap -
                        gridVerticalSafetyInset,
            );

            Widget compose({
              required Widget viewport,
              required double viewportHeight,
              required double gridHeight,
              required int rowCount,
              required bool enableRowJumps,
            }) {
              if (compactNativeLandscape) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: availableGridHeight,
                    child: Row(
                      key: const Key('blueprint-landscape-side-layout'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        viewport,
                        const SizedBox(width: commandRailGap),
                        _buildGridCommandBar(
                          viewportHeight: viewportHeight,
                          gridHeight: gridHeight,
                          rowCount: rowCount,
                          enableRowJumps: enableRowJumps,
                          hasOwnedBlueprints: hasOwnedBlueprints,
                          vertical: true,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final centre = SizedBox(
                width: availableGridWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    viewport,
                    const SizedBox(height: commandBarGap),
                    _buildGridCommandBar(
                      viewportHeight: viewportHeight,
                      gridHeight: gridHeight,
                      rowCount: rowCount,
                      enableRowJumps: enableRowJumps,
                      hasOwnedBlueprints: hasOwnedBlueprints,
                    ),
                  ],
                ),
              );

              return Align(alignment: Alignment.topCenter, child: centre);
            }

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

              final viewport = SizedBox(
                key: const Key('blueprint-authoritative-grid-viewport'),
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
              );

              return compose(
                viewport: viewport,
                viewportHeight: layout.viewportHeight,
                gridHeight: layout.gridHeight,
                rowCount: rowCount,
                enableRowJumps: true,
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

              // Display all six physical rows within the available
              // landscape viewport at initial zoom. Pinch/pan still work.
              final fittedScale = math.min(widthScale, heightScale).clamp(
                0.05,
                1.35,
              ).toDouble();
              final fittedHeight = metrics.naturalHeight * fittedScale;
              final fittedWidth = metrics.naturalWidth * fittedScale;
              final viewportHeight = isLandscape
                  ? availableGridHeight
                  : math.min(fittedHeight, availableGridHeight);
              final viewportWidth = fittedWidth;
              final canvasWidth = math.max(viewportWidth, fittedWidth);
              final canvasHeight = math.max(viewportHeight, fittedHeight);

              final viewport = SizedBox(
                key: const Key('blueprint-authoritative-grid-viewport'),
                width: viewportWidth,
                height: viewportHeight,
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: _blueprintGridTransformController,
                    alignment: Alignment.topCenter,
                    panEnabled: true,
                    scaleEnabled: true,
                    constrained: !isLandscape,
                    minScale: 1.0,
                    maxScale: isLandscape ? 5.5 : 4.2,
                    boundaryMargin: const EdgeInsets.all(256),
                    clipBehavior: Clip.none,
                    child: isLandscape
                        ? SizedBox(
                            width: canvasWidth,
                            height: canvasHeight,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: fittedWidth,
                                height: fittedHeight,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: buildTiles(
                                    width: metrics.naturalWidth,
                                    height: metrics.naturalHeight,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.contain,
                            child: buildTiles(
                              width: metrics.naturalWidth,
                              height: metrics.naturalHeight,
                            ),
                          ),
                  ),
                ),
              );

              return compose(
                viewport: viewport,
                viewportHeight: viewportHeight,
                gridHeight: fittedHeight,
                rowCount: metrics.rowCount,
                enableRowJumps: isLandscape && metrics.rowCount > 5,
              );
            }

            return Padding(
              key: const Key('blueprint-authoritative-grid'),
              padding: const EdgeInsets.only(top: 2),
              child: _viewMode == ArcBlueprintGridViewMode.inGameFramed &&
                      !compactNativeLandscape
                  ? buildFramedGrid()
                  : buildFullOverviewGrid(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compactMobileLandscape =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        media.orientation == Orientation.landscape &&
        media.size.height <= 720;

    // The canonical 17-column Frozen Trail view is landscape-only.
    if (media.orientation == Orientation.portrait) {
      return const Scaffold(
        backgroundColor: Color(0xFF07111B),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation_rounded,
                  size: 72,
                  color: AppTheme.neonCyan,
                ),
                SizedBox(height: 16),
                Text(
                  'ROTATE TO LANDSCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'The Blueprint collection uses 17 columns. '
                  'Rotate your device to view the full grid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Stream<DocumentSnapshot<Map<String, dynamic>>>? adminConfigStream;
    if (Firebase.apps.isNotEmpty) {
      adminConfigStream = FirebaseFirestore.instance
          .collection('config')
          .doc('arc_admin_controls')
          .snapshots();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: adminConfigStream,
      builder: (context, configSnapshot) {
        // Admin legacy expansion slots are deliberately not injected into the
        // official 91-cell Frozen Trail layout. They cannot mutate canonical IDs.
        final allBlueprints = _frozenTrailBlueprints();

        return Scaffold(
          extendBody: false,
          extendBodyBehindAppBar: false,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: compactMobileLandscape ? 40 : 48,
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
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      );
                      return;
                    case 'reset':
                      _confirmResetGrid();
                      return;
                    case 'clear-grid':
                      _confirmClearBlueprintGridOnly();
                      return;
                    case 'search':
                      setState(() => _toolsOpen = true);
                      return;
                    case 'filters':
                      setState(() => _toolsOpen = true);
                      return;
                    case 'select':
                      setState(() => _selectionMode = true);
                      setState(() => _toolsOpen = true);
                      return;
                    case 'loadout':
                      Navigator.of(
                        context,
                      ).pushNamed(FavouriteLoadoutScreen.routeName);
                      return;
                    case 'watches':
                      Navigator.of(
                        context,
                      ).pushNamed(TradingBlueprintWatchesScreen.routeName);
                      return;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'search', child: Text('Search')),
                  PopupMenuItem(value: 'filters', child: Text('Filters')),
                  PopupMenuItem(value: 'select', child: Text('Multi Select')),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'loadout',
                    child: Text('Favourite Loadout'),
                  ),
                  PopupMenuItem(
                    value: 'watches',
                    child: Text('Blueprint Watches'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'feedback', child: Text('Feedback')),
                  PopupMenuItem(value: 'reset', child: Text('Reset Ownership')),
                  PopupMenuItem(
                    value: 'clear-grid',
                    child: Text(
                      'Clear Blueprint Grid',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: AnimatedBuilder(
            animation: UagAdService.instance,
            builder: (context, _) {
              if (compactMobileLandscape) {
                return KeyedSubtree(
                  key: const Key('blueprint-landscape-static-ad'),
                  child: widget.bannerSlot ?? const ArcBlueprintBannerSlot(),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.bannerSlot ?? const ArcBlueprintBannerSlot(),
                  const ArcCompanionBottomDock(activeLabel: 'Track'),
                ],
              );
            },
          ),
          body: ArcRaidersScreenShell(
            showAdBanner: false,
            child: SafeArea(
              child: StreamBuilder<ArcBlueprintStateSnapshot>(
                stream: _stateStream,
                builder: (context, snapshot) {
                  final incoming = snapshot.data;
                  if (incoming?.status ==
                          ArcBlueprintStateHydrationStatus.signedOut ||
                      (incoming?.userId != null &&
                          _lastHydration?.userId != incoming?.userId)) {
                    _lastHydration = null;
                  }
                  if (incoming?.hasConfirmedLoad == true) {
                    _lastHydration = incoming;
                  }
                  final hydration = incoming?.hasUsableState == true
                      ? incoming
                      : _lastHydration ?? incoming;
                  final states =
                      hydration?.states ?? const <String, ArcBlueprintState>{};
                  if (snapshot.hasError ||
                      incoming?.status ==
                          ArcBlueprintStateHydrationStatus.error) {
                    if (states.isEmpty) {
                      return Center(
                        child: ArcRaidersStatePanel(
                          title: 'Blueprints unavailable',
                          message:
                              'Ownership could not be loaded. Your collection has not been cleared.',
                          compact: true,
                          action: TextButton(
                            onPressed: () => setState(
                              () =>
                                  _stateStream = _watchBlueprintStateSnapshot()
                                      .asBroadcastStream(),
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      );
                    }
                  }
                  if (hydration == null ||
                      (hydration.isLoading && states.isEmpty)) {
                    return _buildOwnershipSynchronizingState();
                  }
                  final counts = _buildCounts(allBlueprints, states);
                  final hasHydrationError =
                      snapshot.hasError ||
                      incoming?.status ==
                          ArcBlueprintStateHydrationStatus.error;

                  final loadoutContent = StreamBuilder<ArcSavedLoadout?>(
                    stream: _loadoutStream,
                    builder: (context, loadoutSnapshot) {
                      final loadout = loadoutSnapshot.data;
                      final plan = ArcGeneratedLoadoutPlan.fromMap(
                        loadout?.smartBuildData,
                      );
                      final smartBuildHunt = ArcSmartBuildHuntEngine.build(
                        plan: plan,
                        blueprintStates: states,
                      );
                      final filteredByState = _applyFilter(
                        allBlueprints,
                        states,
                        smartBuildHunt: smartBuildHunt,
                      );
                      final filtered =
                          _selectedFilter == ArcBlueprintFilter.all &&
                              _searchQuery.trim().isEmpty &&
                              !_smartBuildHuntMode &&
                              !_isFavouriteLoadoutTargetPickMode
                          ? _fullGridWithUnknownCells(filteredByState)
                          : filteredByState;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compactMobileLandscape ? 4 : 8,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                if (!compactMobileLandscape)
                                  SizedBox(
                                    height: 36,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _isFavouriteLoadoutTargetPickMode
                                                ? _targetPickSavingBlueprintId ==
                                                          null
                                                      ? 'Tap a missing Blueprint to add it and return'
                                                      : 'Adding Blueprint target...'
                                                : _selectionMode
                                                ? '${_selectedBlueprintIds.length} selected'
                                                : '${counts[ArcBlueprintFilter.owned]} / ${ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots} owned',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (hasHydrationError)
                                          TextButton(
                                            onPressed: () => setState(
                                              () => _stateStream =
                                                  _watchBlueprintStateSnapshot(),
                                            ),
                                            child: const Text('Retry sync'),
                                          ),
                                        if (_selectionMode)
                                          IconButton(
                                            tooltip: 'Mark selected owned',
                                            onPressed:
                                                _selectedBlueprintIds.isEmpty
                                                ? null
                                                : () => _applyBulkOwned(states),
                                            icon: const Icon(
                                              Icons.check,
                                              size: 18,
                                            ),
                                          ),
                                        if (_selectionMode)
                                          IconButton(
                                            tooltip: 'Exit selection',
                                            onPressed: _clearSelection,
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: 'Blueprint tools',
                                          onPressed: () => setState(
                                            () => _toolsOpen = !_toolsOpen,
                                          ),
                                          icon: const Icon(
                                            Icons.tune,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: !_isFavouriteLoadoutTargetPickMode &&
                                      _selectedFilter == ArcBlueprintFilter.duplicates
                                    ? _buildBlueprintDupeSearch(allBlueprints, states)
                                    : _buildOverviewGrid(
                                        context, filtered, states),
                                ),
                              ],
                            ),
                            if (_toolsOpen)
                              Positioned.fill(
                                child: _buildBottomControls(
                                  allBlueprints,
                                  filtered,
                                  states,
                                  counts,
                                  hunt: smartBuildHunt,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );

                  if (!compactMobileLandscape) {
                    return loadoutContent;
                  }

                  return Stack(
                    children: [
                      Positioned.fill(child: loadoutContent),
                      if (hasHydrationError)
                        Positioned(
                          key: const Key('blueprint-retry-sync-overlay'),
                          top: 4,
                          right: 4,
                          child: TextButton.icon(
                            onPressed: () => setState(
                              () =>
                                  _stateStream = _watchBlueprintStateSnapshot()
                                      .asBroadcastStream(),
                            ),
                            icon: const Icon(Icons.sync_problem, size: 16),
                            label: const Text('Retry sync'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
