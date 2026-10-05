import 'dart:async';

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_drop_report_event_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_drop_report_region_store.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_intel_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_drop_report_carousel_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_drop_report_map_picker.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintDropReportSheet extends StatefulWidget {
  const ArcBlueprintDropReportSheet({
    super.key,
    required this.blueprint,
    required this.initialState,
    required this.repository,
    required this.rarityColor,
    this.onSaved,
    this.onClear,
    this.markerRepository,
  });

  final ArcBlueprint blueprint;
  final ArcBlueprintState initialState;
  final ArcBlueprintRepository repository;
  final Color rarityColor;
  final VoidCallback? onSaved;
  final Future<void> Function()? onClear;
  final ArcAdminMapEditorRepository? markerRepository;

  @override
  State<ArcBlueprintDropReportSheet> createState() =>
      _ArcBlueprintDropReportSheetState();
}

class _AdditionalBlueprintReportEntry {
  ArcBlueprint? blueprint;
  bool useSameLocation = true;
  bool useSameContainerType = true;
  ArcNormalizedPoint? point;
  ArcRaidMapLayer layer = ArcRaidMapLayer.surface;
  ArcContainerType? containerType;
}

enum _DropReportStep {
  source,
  map,
  pinpoint,
  region,
  event,
  container,
  round,
  review,
}

class _ArcBlueprintDropReportSheetState
    extends State<ArcBlueprintDropReportSheet> {
  late final TextEditingController _dupesController;
  late final TextEditingController _notesController;
  final ScrollController _scrollController = ScrollController();

  late bool _owned;
  late final DateTime _capturedReportTime;
  late final int _capturedTimezoneOffsetMinutes;
  late ArcTimeOfDay _timeOfDay;

  String? _selectedMap;
  ArcNormalizedPoint? _selectedPoint;
  ArcRaidMapLayer _selectedLayer = ArcRaidMapLayer.surface;
  ArcContainerType? _selectedContainerType;
  ArcMapCondition? _selectedMapEvent;
  ArcRaidType? _raidType;
  ArcBlueprintAcquisitionSource? _acquisitionSource;
  _DropReportStep _activeDropStep = _DropReportStep.source;

  ArcServerRegion _serverRegion = ArcServerRegion.europe;
  ArcRegionalMapConditionsSnapshot? _regionalSnapshot;
  bool _regionalLoading = true;
  bool _eventManuallySelected = false;

  final List<_AdditionalBlueprintReportEntry> _additionalReports = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dupesController = TextEditingController(
      text: widget.initialState.dupesOwned.toString(),
    );
    _notesController = TextEditingController();
    _capturedReportTime = DateTime.now();
    _capturedTimezoneOffsetMinutes =
        _capturedReportTime.timeZoneOffset.inMinutes;
    _timeOfDay = _timeOfDayFor(_capturedReportTime);
    _owned = widget.initialState.owned;
    _applyBlueprintDefaults();
    unawaited(_loadRegionalContext());
  }

  @override
  void dispose() {
    _dupesController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRegionalContext() async {
    final region = await ArcDropReportRegionStore.load();
    ArcRegionalMapConditionsSnapshot? snapshot;
    try {
      snapshot = await ArcRegionalMapConditionsService.load();
    } catch (_) {
      snapshot = null;
    }
    if (!mounted) return;
    setState(() {
      _serverRegion = region;
      _regionalSnapshot = snapshot;
      _regionalLoading = false;
      if (_selectedMap != null && !_eventManuallySelected) {
        _selectedMapEvent = _suggestedEvent();
      }
    });
  }

  List<String> get _availableMaps {
    final maps = List<String>.from(ArcPoiDataStore.availableMaps);
    maps.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return maps;
  }

  int get _currentDupes =>
      int.tryParse(_dupesController.text.trim())?.clamp(0, 999) ?? 0;

  bool get _effectiveOwned => _owned || _currentDupes > 0;

  bool get _requiresRaidDetails =>
      _acquisitionSource == ArcBlueprintAcquisitionSource.lootDrop;

  bool get _usesAssessorFlow => widget.blueprint.id == 'dolabra';

  ArcMapCondition? get _forcedBlueprintCondition {
    return switch (widget.blueprint.id) {
      'surge_coil' => ArcMapConditions.electromagneticStorm,
      'canto' => ArcMapConditions.hurricane,
      'dolabra' => ArcMapConditions.closeScrutiny,
      _ => null,
    };
  }

  String? get _primaryBlueprintAsset =>
      widget.blueprint.imageAssetPath ??
      ArcBlueprintAssetRegistry.assetFor(widget.blueprint.name);

  List<ArcMapCondition> get _eventOptions {
    final mapName = _selectedMap;
    if (mapName == null || mapName.isEmpty) {
      return const <ArcMapCondition>[ArcMapConditions.noSpecialCondition];
    }
    return ArcDropReportEventResolver.optionsFor(
      mapName: mapName,
      region: _serverRegion,
      capturedAtUtc: _capturedReportTime.toUtc(),
      snapshot: _regionalSnapshot,
      forcedCondition: _forcedBlueprintCondition,
    );
  }

  ArcMapCondition _suggestedEvent() {
    final mapName = _selectedMap;
    if (mapName == null || mapName.isEmpty) {
      return ArcMapConditions.noSpecialCondition;
    }
    return ArcDropReportEventResolver.suggestedFor(
      mapName: mapName,
      region: _serverRegion,
      capturedAtUtc: _capturedReportTime.toUtc(),
      snapshot: _regionalSnapshot,
      forcedCondition: _forcedBlueprintCondition,
    );
  }

  bool get _canSubmitReport {
    if (_acquisitionSource == null) return false;
    if (!_requiresRaidDetails) return true;
    return (_selectedMap ?? '').isNotEmpty &&
        _selectedPoint != null &&
        _selectedContainerType != null &&
        _selectedMapEvent != null &&
        _raidType != null;
  }

  bool get _allAdditionalReportsValid {
    for (final entry in _additionalReports) {
      if (entry.blueprint == null) return false;
      if (!_requiresRaidDetails) continue;
      if (!entry.useSameLocation && entry.point == null) return false;
      final container = entry.useSameContainerType
          ? _selectedContainerType
          : entry.containerType;
      if (container == null) return false;
    }
    return true;
  }

  ArcRaidMode get _derivedMode {
    if (_selectedMapEvent?.id == ArcMapConditions.nightRaid.id) {
      return ArcRaidMode.nightRaid;
    }
    return (_timeOfDay == ArcTimeOfDay.night ||
            _timeOfDay == ArcTimeOfDay.lateNight)
        ? ArcRaidMode.nightRaid
        : ArcRaidMode.dayRaid;
  }

  ArcTimeOfDay _timeOfDayFor(DateTime value) {
    final hour = value.hour;
    if (hour >= 5 && hour < 9) return ArcTimeOfDay.earlyMorning;
    if (hour >= 9 && hour < 12) return ArcTimeOfDay.midMorning;
    if (hour >= 12 && hour < 14) return ArcTimeOfDay.midday;
    if (hour >= 14 && hour < 18) return ArcTimeOfDay.midAfternoon;
    if (hour >= 18 && hour < 22) return ArcTimeOfDay.night;
    return ArcTimeOfDay.lateNight;
  }

  String _formatLocalTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  void _applyBlueprintDefaults() {
    final forced = _forcedBlueprintCondition;
    if (forced != null) _selectedMapEvent = forced;
    if (_usesAssessorFlow) {
      _selectedContainerType = ArcContainerTypes.assessor;
    }
  }

  String _pinpointLabel(ArcNormalizedPoint? point, ArcRaidMapLayer layer) {
    if (point == null) return 'Tap to pinpoint exact location';
    return 'Exact location pinned • ${layer.label}';
  }

  Future<void> _saveStateOnly() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final normalizedState = widget.initialState.copyWith(
        owned: _effectiveOwned,
        dupesOwned: _effectiveOwned ? _currentDupes : 0,
        updatedAt: DateTime.now(),
      );
      await widget.repository.saveBlueprintState(normalizedState);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save ${widget.blueprint.name}. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ArcBlueprintState _stateAfterFound({
    required ArcBlueprintState current,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return current.copyWith(
        owned: true,
        dupesOwned: _currentDupes,
        updatedAt: DateTime.now(),
      );
    }
    if (current.owned) {
      return current.copyWith(
        owned: true,
        dupesOwned: current.dupesOwned + 1,
        updatedAt: DateTime.now(),
      );
    }
    return current.copyWith(
      owned: true,
      dupesOwned: current.dupesOwned,
      updatedAt: DateTime.now(),
    );
  }

  Future<ArcBlueprintState> _loadCurrentBlueprintState(
    String blueprintId,
  ) async {
    final states = await widget.repository.watchMyBlueprintStates().first;
    return states[blueprintId] ?? ArcBlueprintState.empty(blueprintId);
  }

  Future<void> _saveWithReport() async {
    if (_isSaving || !_canSubmitReport || !_allAdditionalReportsValid) return;
    setState(() => _isSaving = true);

    try {
      final reportTime = _capturedReportTime;
      final isRaidReport = _requiresRaidDetails;

      Future<void> saveReportForBlueprint(
        ArcBlueprint blueprint, {
        ArcNormalizedPoint? point,
        ArcRaidMapLayer layer = ArcRaidMapLayer.surface,
        ArcContainerType? containerType,
      }) {
        final isDolabra = isRaidReport && blueprint.id == 'dolabra';

        return widget.repository.addDropReport(
          blueprintId: blueprint.id,
          mapName: isRaidReport ? _selectedMap! : 'Not Raid Specific',
          sourceType: isRaidReport
              ? (isDolabra ? ArcDropSourceType.enemy : ArcDropSourceType.poi)
              : ArcDropSourceType.other,
          poiId: null,
          poiName: isRaidReport && !isDolabra && point != null
              ? 'Exact map pinpoint'
              : null,
          historicalPoint: isRaidReport ? point : null,
          poiLayer: isRaidReport ? layer : null,
          serverRegion: isRaidReport ? _serverRegion.key : null,
          enemySourceId: isDolabra ? 'enemy_assessor' : null,
          enemySourceName: isDolabra ? 'Assessor' : null,
          containerTypeId: isRaidReport ? containerType?.id : null,
          containerTypeLabel: isRaidReport ? containerType?.label : null,
          mapEventId: isRaidReport ? _selectedMapEvent?.id : null,
          mapEventLabel: isRaidReport ? _selectedMapEvent?.label : null,
          mode: isRaidReport ? _derivedMode : ArcRaidMode.dayRaid,
          raidType: isRaidReport ? _raidType! : ArcRaidType.fullRaid,
          entryTime: ArcEntryTime.unknown,
          timeOfDay: isRaidReport ? _timeOfDay : ArcTimeOfDay.unknown,
          acquisitionSource:
              _acquisitionSource ?? ArcBlueprintAcquisitionSource.lootDrop,
          foundAt: reportTime,
          localTimeLabel: isRaidReport ? _formatLocalTime(reportTime) : null,
          timezoneOffsetMinutes: isRaidReport
              ? _capturedTimezoneOffsetMinutes
              : null,
          notes: _notesController.text,
        );
      }

      final stateUpdatesById = <String, ArcBlueprintState>{
        widget.blueprint.id: _stateAfterFound(
          current: widget.initialState,
          isPrimary: true,
        ),
      };

      void queueAdditionalStateUpdate(
        ArcBlueprint blueprint,
        ArcBlueprintState currentState,
      ) {
        final existing = stateUpdatesById[blueprint.id];
        if (existing != null) {
          stateUpdatesById[blueprint.id] = existing.copyWith(
            owned: true,
            dupesOwned: existing.dupesOwned + 1,
            updatedAt: DateTime.now(),
          );
          return;
        }
        stateUpdatesById[blueprint.id] = _stateAfterFound(
          current: currentState,
        );
      }

      await saveReportForBlueprint(
        widget.blueprint,
        point: isRaidReport ? _selectedPoint : null,
        layer: _selectedLayer,
        containerType: isRaidReport ? _selectedContainerType : null,
      );

      for (final entry in _additionalReports) {
        final blueprint = entry.blueprint;
        if (blueprint == null) continue;
        final point = !isRaidReport
            ? null
            : entry.useSameLocation
            ? _selectedPoint
            : entry.point;
        final layer = entry.useSameLocation ? _selectedLayer : entry.layer;
        final container = !isRaidReport
            ? null
            : entry.useSameContainerType
            ? _selectedContainerType
            : entry.containerType;

        await saveReportForBlueprint(
          blueprint,
          point: point,
          layer: layer,
          containerType: container,
        );

        final currentState = await _loadCurrentBlueprintState(blueprint.id);
        queueAdditionalStateUpdate(blueprint, currentState);
      }

      await widget.repository.saveBlueprintStates(
        stateUpdatesById.values.toList(growable: false),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save ${widget.blueprint.name}. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAcquisitionSource() async {
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'How Was It Obtained?',
      items: const <ArcBlueprintAcquisitionSource>[
        ArcBlueprintAcquisitionSource.lootDrop,
        ArcBlueprintAcquisitionSource.giftedBySquadmate,
        ArcBlueprintAcquisitionSource.giftedByAnotherRaider,
        ArcBlueprintAcquisitionSource.tradedDuringRaid,
        ArcBlueprintAcquisitionSource.recoveredFromAnotherRaider,
        ArcBlueprintAcquisitionSource.questReward,
        ArcBlueprintAcquisitionSource.trialReward,
        ArcBlueprintAcquisitionSource.unknown,
      ],
      labelBuilder: (item) => item.label,
      initialValue: _acquisitionSource,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _acquisitionSource = selection;
      if (selection != ArcBlueprintAcquisitionSource.lootDrop) {
        _selectedMap = null;
        _selectedPoint = null;
        _selectedMapEvent = null;
        _selectedContainerType = null;
        _raidType = null;
        _additionalReports.clear();
        _activeDropStep = _DropReportStep.review;
      } else {
        _applyBlueprintDefaults();
        _activeDropStep = _DropReportStep.map;
      }
    });
  }

  Future<void> _pickMap() async {
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'Map',
      items: _availableMaps,
      labelBuilder: (item) => item,
      initialValue: _selectedMap,
    );
    if (selection == null || !mounted) return;

    setState(() {
      _selectedMap = selection;
      _selectedPoint = null;
      _selectedLayer = ArcRaidMapLayer.surface;
      _selectedContainerType = _usesAssessorFlow
          ? ArcContainerTypes.assessor
          : null;
      _raidType = null;
      _eventManuallySelected = false;
      _additionalReports.clear();
      _selectedMapEvent = _suggestedEvent();
      _activeDropStep = _DropReportStep.pinpoint;
    });

    await _pickPrimaryLocation();
  }

  Future<void> _pickPrimaryLocation() async {
    final mapName = _selectedMap;
    if (mapName == null || !mounted) return;
    final selection = await showArcDropReportMapPicker(
      context: context,
      mapName: mapName,
      blueprintName: widget.blueprint.name,
      blueprintAssetPath: _primaryBlueprintAsset,
      initialSelection: _selectedPoint == null
          ? null
          : ArcDropReportMapSelection(
              point: _selectedPoint!,
              layer: _selectedLayer,
            ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedPoint = selection.point;
      _selectedLayer = selection.layer;
      _activeDropStep = _DropReportStep.region;
    });
  }

  Future<void> _pickServerRegion() async {
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'Server Region',
      items: ArcServerRegion.values,
      labelBuilder: (item) => item.label,
      initialValue: _serverRegion,
    );
    if (selection == null || !mounted) return;
    await ArcDropReportRegionStore.save(selection);
    if (!mounted) return;
    setState(() {
      _serverRegion = selection;
      _eventManuallySelected = false;
      if (_selectedMap != null) _selectedMapEvent = _suggestedEvent();
      _activeDropStep = _usesAssessorFlow
          ? _DropReportStep.round
          : _DropReportStep.event;
    });
  }

  Future<void> _pickMapEvent() async {
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'Map Event',
      items: _eventOptions,
      labelBuilder: (item) => item.label,
      subtitleBuilder: (item) => item.isNeutral
          ? 'Standard raid with no special map condition.'
          : 'Available for ${_selectedMap ?? 'this map'} in the regional schedule.',
      initialValue: _selectedMapEvent,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedMapEvent = selection;
      _eventManuallySelected = true;
      _activeDropStep = _DropReportStep.container;
    });
  }

  Future<void> _pickContainerType() async {
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'Container Type',
      items: ArcContainerTypes.reportable,
      labelBuilder: (item) => item.label,
      initialValue: _selectedContainerType,
      searchable: true,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedContainerType = selection;
      _activeDropStep = _DropReportStep.round;
    });
  }

  Future<void> _pickRaidType() async {
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'Raid Round',
      items: const <ArcRaidType>[
        ArcRaidType.fullRaid,
        ArcRaidType.midRaid,
        ArcRaidType.lateRaid,
      ],
      labelBuilder: (item) => item.label,
      initialValue: _raidType,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _raidType = selection;
      _activeDropStep = _DropReportStep.review;
    });
  }

  Future<void> _pickAdditionalLocation(int index) async {
    final mapName = _selectedMap;
    final blueprint = _additionalReports[index].blueprint;
    if (mapName == null || blueprint == null || !mounted) return;
    final entry = _additionalReports[index];
    final asset =
        blueprint.imageAssetPath ??
        ArcBlueprintAssetRegistry.assetFor(blueprint.name);
    final selection = await showArcDropReportMapPicker(
      context: context,
      mapName: mapName,
      blueprintName: blueprint.name,
      blueprintAssetPath: asset,
      initialSelection: entry.point == null
          ? null
          : ArcDropReportMapSelection(point: entry.point!, layer: entry.layer),
    );
    if (selection == null || !mounted) return;
    setState(() {
      entry.point = selection.point;
      entry.layer = selection.layer;
    });
  }

  Future<void> _pickAdditionalContainerType(int index) async {
    final entry = _additionalReports[index];
    final selection = await showArcDropReportCarouselPicker(
      context: context,
      title: 'Additional Container Type',
      items: ArcContainerTypes.reportable,
      labelBuilder: (item) => item.label,
      initialValue: entry.containerType,
      searchable: true,
    );
    if (selection == null || !mounted) return;
    setState(() => entry.containerType = selection);
  }

  Future<void> _addAnotherBlueprintEntry() async {
    final usedIds = _additionalReports
        .map((entry) => entry.blueprint?.id)
        .whereType<String>()
        .toSet();
    final items =
        ArcBlueprintSeedData.blueprints
            .where((item) => !usedIds.contains(item.id))
            .toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final selection = await showArcDropReportCarouselPicker<ArcBlueprint>(
      context: context,
      title: 'Additional Blueprint',
      items: items,
      labelBuilder: (item) => item.name,
      searchable: true,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _additionalReports.add(
        _AdditionalBlueprintReportEntry()..blueprint = selection,
      );
    });
  }

  void _removeAdditionalBlueprintEntry(int index) {
    setState(() => _additionalReports.removeAt(index));
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildExpandablePanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.white.withValues(alpha: 0.04),
        highlightColor: Colors.white.withValues(alpha: 0.03),
      ),
      child: Container(
        width: double.infinity,
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
          radius: 18,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceM,
            vertical: AppTheme.spaceS,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTheme.spaceM,
            0,
            AppTheme.spaceM,
            AppTheme.spaceM,
          ),
          iconColor: AppTheme.neonCyan,
          collapsedIconColor: Colors.white70,
          leading: Icon(icon, color: AppTheme.neonCyan),
          title: Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonCyan,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildIntelSummary() {
    return StreamBuilder<ArcDropIntel>(
      stream: widget.repository.watchIntelForBlueprint(widget.blueprint.id),
      builder: (context, snapshot) {
        final intel = snapshot.data ?? ArcDropIntel.empty(widget.blueprint.id);
        return ArcBlueprintIntelPanel(
          blueprint: widget.blueprint,
          intel: intel,
        );
      },
    );
  }

  int get _raidStepNumber {
    return switch (_activeDropStep) {
      _DropReportStep.source => 1,
      _DropReportStep.map => 2,
      _DropReportStep.pinpoint => 3,
      _DropReportStep.region => 4,
      _DropReportStep.event => 5,
      _DropReportStep.container => 6,
      _DropReportStep.round => 7,
      _DropReportStep.review => 8,
    };
  }

  String get _activeStepTitle {
    return switch (_activeDropStep) {
      _DropReportStep.source => 'How was it obtained?',
      _DropReportStep.map => 'Which map?',
      _DropReportStep.pinpoint => 'Pinpoint the exact drop',
      _DropReportStep.region => 'Server region',
      _DropReportStep.event => 'Map event',
      _DropReportStep.container => 'Container type',
      _DropReportStep.round => 'Raid round',
      _DropReportStep.review => 'Review this report',
    };
  }

  void _goToStep(_DropReportStep step) {
    setState(() => _activeDropStep = step);
  }

  void _goBackOneStep() {
    final next = switch (_activeDropStep) {
      _DropReportStep.source => _DropReportStep.source,
      _DropReportStep.map => _DropReportStep.source,
      _DropReportStep.pinpoint => _DropReportStep.map,
      _DropReportStep.region => _DropReportStep.pinpoint,
      _DropReportStep.event => _DropReportStep.region,
      _DropReportStep.container => _DropReportStep.event,
      _DropReportStep.round => _DropReportStep.container,
      _DropReportStep.review =>
        _requiresRaidDetails ? _DropReportStep.round : _DropReportStep.source,
    };
    _goToStep(next);
  }

  Widget _summaryChip({
    required String label,
    required _DropReportStep step,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.neonCyan),
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: _isSaving ? null : () => _goToStep(step),
      side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: .28)),
      backgroundColor: Colors.white.withValues(alpha: .035),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }

  Widget _buildCompletedSummary() {
    final chips = <Widget>[];
    if (_acquisitionSource != null) {
      chips.add(
        _summaryChip(
          label: _acquisitionSource!.label,
          step: _DropReportStep.source,
          icon: Icons.inventory_2_outlined,
        ),
      );
    }
    if (_requiresRaidDetails && _selectedMap != null) {
      chips.add(
        _summaryChip(
          label: _selectedMap!,
          step: _DropReportStep.map,
          icon: Icons.map_outlined,
        ),
      );
    }
    if (_requiresRaidDetails && _selectedPoint != null) {
      chips.add(
        _summaryChip(
          label: 'Exact pin',
          step: _DropReportStep.pinpoint,
          icon: Icons.add_location_alt_outlined,
        ),
      );
    }
    if (_requiresRaidDetails && _selectedPoint != null) {
      chips.add(
        _summaryChip(
          label: _serverRegion.label,
          step: _DropReportStep.region,
          icon: Icons.public_rounded,
        ),
      );
    }
    if (_requiresRaidDetails && _selectedMapEvent != null) {
      chips.add(
        _summaryChip(
          label: _selectedMapEvent!.label,
          step: _DropReportStep.event,
          icon: Icons.bolt_outlined,
        ),
      );
    }
    if (_requiresRaidDetails && _selectedContainerType != null) {
      chips.add(
        _summaryChip(
          label: _selectedContainerType!.label,
          step: _DropReportStep.container,
          icon: Icons.inventory_2_outlined,
        ),
      );
    }
    if (_requiresRaidDetails && _raidType != null) {
      chips.add(
        _summaryChip(
          label: _raidType!.label,
          step: _DropReportStep.round,
          icon: Icons.timelapse_rounded,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _stepChoice({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
    String? helper,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: .38),
          radius: 20,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: .08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: .26),
                ),
              ),
              child: Icon(icon, color: AppTheme.neonCyan, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTheme.tradingHeading(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  if (helper != null && helper.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      helper,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStepCard() {
    final body = switch (_activeDropStep) {
      _DropReportStep.source => _stepChoice(
        label: 'How Was It Obtained',
        value: _acquisitionSource?.label ?? 'Select source',
        icon: Icons.inventory_2_outlined,
        onTap: _pickAcquisitionSource,
        helper: 'Pick once and this step collapses into the summary strip.',
      ),
      _DropReportStep.map => _stepChoice(
        label: 'Map',
        value: _selectedMap ?? 'Select map',
        icon: Icons.map_outlined,
        onTap: _pickMap,
        helper: 'Selecting a map immediately opens the exact pinpoint view.',
      ),
      _DropReportStep.pinpoint => _stepChoice(
        label: 'Exact Drop Pinpoint',
        value: _pinpointLabel(_selectedPoint, _selectedLayer),
        icon: Icons.add_location_alt_outlined,
        onTap: _selectedMap == null ? null : _pickPrimaryLocation,
        helper:
            'This remains an exact coordinate. It is not attached to a nearby POI.',
      ),
      _DropReportStep.region => _stepChoice(
        label: 'Server Region',
        value: _regionalLoading
            ? '${_serverRegion.label} • checking schedule…'
            : _serverRegion.label,
        icon: Icons.public_rounded,
        onTap: _pickServerRegion,
        helper: 'Used only to match the correct regional event schedule.',
      ),
      _DropReportStep.event => _stepChoice(
        label: 'Map Event',
        value: _selectedMapEvent?.label ?? 'No event / standard raid',
        icon: Icons.bolt_outlined,
        onTap: _usesAssessorFlow ? null : _pickMapEvent,
        helper: _regionalSnapshot == null
            ? 'No event / standard raid stays first.'
            : '${_regionalSnapshot!.sourceLabel} • ${_serverRegion.label}',
      ),
      _DropReportStep.container => _stepChoice(
        label: 'Container Type',
        value:
            _selectedContainerType?.label ??
            (_usesAssessorFlow ? 'Assessor' : 'Select container type'),
        icon: Icons.inventory_2_outlined,
        onTap: _usesAssessorFlow ? null : _pickContainerType,
      ),
      _DropReportStep.round => _stepChoice(
        label: 'Raid Round',
        value: _raidType?.label ?? 'Select raid round',
        icon: Icons.timelapse_rounded,
        onTap: _pickRaidType,
      ),
      _DropReportStep.review => _buildReviewStep(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(.10, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Container(
        key: ValueKey<_DropReportStep>(_activeDropStep),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .025),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .07)),
        ),
        child: body,
      ),
    );
  }

  Widget _buildAdditionalReportCard(int index) {
    final entry = _additionalReports[index];
    final blueprint = entry.blueprint;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: .20),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  blueprint?.name ?? 'Additional Blueprint',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(
                    fontSize: 17,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: _isSaving
                    ? null
                    : () => _removeAdditionalBlueprintEntry(index),
                icon: const Icon(Icons.close_rounded, size: 19),
                color: Colors.white60,
              ),
            ],
          ),
          const Spacer(),
          if (_requiresRaidDetails) ...[
            TextButton.icon(
              onPressed: blueprint == null
                  ? null
                  : () async {
                      if (entry.useSameLocation) {
                        setState(() => entry.useSameLocation = false);
                        await _pickAdditionalLocation(index);
                        if (mounted && entry.point == null) {
                          setState(() => entry.useSameLocation = true);
                        }
                      } else {
                        await _pickAdditionalLocation(index);
                      }
                    },
              icon: const Icon(Icons.add_location_alt_outlined, size: 17),
              label: Text(
                entry.useSameLocation
                    ? 'Same pinpoint'
                    : _pinpointLabel(entry.point, entry.layer),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!entry.useSameLocation)
              TextButton(
                onPressed: () => setState(() {
                  entry.useSameLocation = true;
                  entry.point = null;
                }),
                child: const Text('Use primary pinpoint'),
              ),
            TextButton.icon(
              onPressed: () async {
                if (entry.useSameContainerType) {
                  setState(() => entry.useSameContainerType = false);
                }
                await _pickAdditionalContainerType(index);
                if (mounted && entry.containerType == null) {
                  setState(() => entry.useSameContainerType = true);
                }
              },
              icon: const Icon(Icons.inventory_2_outlined, size: 17),
              label: Text(
                entry.useSameContainerType
                    ? 'Same container'
                    : entry.containerType?.label ?? 'Choose container',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!entry.useSameContainerType)
              TextButton(
                onPressed: () => setState(() {
                  entry.useSameContainerType = true;
                  entry.containerType = null;
                }),
                child: const Text('Use primary container'),
              ),
          ] else
            Text(
              _acquisitionSource?.label ?? 'Same source',
              style: const TextStyle(color: Colors.white60),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalBlueprintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _requiresRaidDetails
                    ? 'Additional blueprints from this raid'
                    : 'Additional blueprints from this source',
                style: AppTheme.tradingHeading(
                  fontSize: 18,
                  color: AppTheme.neonCyan,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _acquisitionSource == null
                  ? null
                  : _addAnotherBlueprintEntry,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Another'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_additionalReports.isEmpty)
          const Text(
            'No additional blueprints added.',
            style: TextStyle(color: Colors.white54),
          )
        else
          SizedBox(
            height: _requiresRaidDetails ? 235 : 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _additionalReports.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _buildAdditionalReportCard(index),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_acquisitionSource != null && !_requiresRaidDetails) ...[
          _buildNonRaidSourceNotice(),
          const SizedBox(height: AppTheme.spaceM),
        ],
        _buildAdditionalBlueprintSection(),
        const SizedBox(height: AppTheme.spaceM),
        TextField(
          controller: _notesController,
          style: const TextStyle(color: Colors.white),
          minLines: 2,
          maxLines: 4,
          decoration: AppTheme.tradingInputDecoration(
            label: 'Location Notes (optional)',
          ),
        ),
      ],
    );
  }

  Widget _buildDropReportRevolver() {
    final total = _requiresRaidDetails ? 8 : 2;
    final visibleStep = _requiresRaidDetails
        ? _raidStepNumber
        : (_activeDropStep == _DropReportStep.source ? 1 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompletedSummary(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP $visibleStep OF $total',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _activeStepTitle,
                    style: AppTheme.tradingHeading(
                      fontSize: 20,
                      color: AppTheme.neonPink,
                    ),
                  ),
                ],
              ),
            ),
            if (_activeDropStep != _DropReportStep.source)
              IconButton.filledTonal(
                tooltip: 'Previous step',
                onPressed: _goBackOneStep,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildActiveStepCard(),
      ],
    );
  }

  Widget _buildNonRaidSourceNotice() {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.22),
      ),
      child: Text(
        'This source is not tied to a raid location. Save it with the selected source; map, event and pinpoint details are not required.',
        style: AppTheme.bodyTextStyle(
          fontSize: 14,
          color: AppTheme.tradingMutedText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.24),
            ),
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white70,
                          splashRadius: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    widget.blueprint.name,
                    style: AppTheme.tradingHeading(
                      fontSize: 28,
                      color: widget.rarityColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.blueprint.category} ${String.fromCharCode(0x2022)} ${widget.blueprint.group} ${String.fromCharCode(0x2022)} ${widget.blueprint.rarityLabel}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  SwitchListTile(
                    value: _owned,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.neonPink,
                    title: const Text(
                      'Owned',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _owned
                          ? 'This blueprint is in your collection.'
                          : 'Missing blueprints are automatically wanted.',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    onChanged: (value) => setState(() => _owned = value),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  TextField(
                    controller: _dupesController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.tradingInputDecoration(
                      label: _owned ? 'Dupes Owned' : 'Dupes Owned (optional)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag(
                        _effectiveOwned ? 'Owned' : 'Missing',
                        _effectiveOwned ? AppTheme.neonCyan : AppTheme.neonPink,
                      ),
                      _tag(
                        _currentDupes > 0
                            ? 'Tradeable x$_currentDupes'
                            : 'No Dupes',
                        _currentDupes > 0 ? Colors.amberAccent : Colors.white54,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  _buildExpandablePanel(
                    title: 'Community Intel',
                    subtitle:
                        'Open community drop data, confidence and reported locations.',
                    icon: Icons.insights_rounded,
                    children: [_buildIntelSummary()],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _buildExpandablePanel(
                    title: 'Drop Report',
                    subtitle:
                        'A stable step-by-step report with exact map pinpointing.',
                    icon: Icons.add_location_alt_outlined,
                    children: [
                      const Text(
                        'One step at a time. Each completed choice rolls into the compact summary strip instead of building a long form.',
                        style: TextStyle(color: Colors.white60, height: 1.35),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      _buildDropReportRevolver(),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveStateOnly,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Owned / Dupes Only',
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (_isSaving ||
                                  !_canSubmitReport ||
                                  !_allAdditionalReportsValid)
                              ? null
                              : _saveWithReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.rarityColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Save Blueprint + Report',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.onClear != null) ...[
                    const SizedBox(height: AppTheme.spaceM),
                    Center(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                await widget.onClear?.call();
                                if (!mounted) return;
                                Navigator.of(this.context).pop(true);
                              },
                        child: const Text(
                          'Clear this blueprint',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
