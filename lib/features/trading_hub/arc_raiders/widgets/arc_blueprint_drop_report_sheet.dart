import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_drop_report_options.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_intel_panel.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/blueprint_voice_search_button.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcBlueprintDropReportSheet extends StatefulWidget {
  const ArcBlueprintDropReportSheet({
    super.key,
    required this.blueprint,
    required this.initialState,
    required this.repository,
    required this.rarityColor,
    this.onSaved,
    this.onClear,
  });

  final ArcBlueprint blueprint;
  final ArcBlueprintState initialState;
  final ArcBlueprintRepository repository;
  final Color rarityColor;
  final VoidCallback? onSaved;
  final Future<void> Function()? onClear;

  @override
  State<ArcBlueprintDropReportSheet> createState() =>
      _ArcBlueprintDropReportSheetState();
}

class _AdditionalBlueprintReportEntry {
  ArcBlueprint? blueprint;
  bool useSamePoi = true;
  bool useSameContainerType = true;
  String? poiId;
  ArcContainerType? containerType;
}

class _ArcBlueprintDropReportSheetState
    extends State<ArcBlueprintDropReportSheet> {
  late final TextEditingController _dupesController;
  late final TextEditingController _notesController;
  final ScrollController _scrollController = ScrollController();

  late bool _owned;
  String? _selectedMap;
  String? _selectedPoiId;
  ArcContainerType? _selectedContainerType;
  ArcMapCondition? _selectedMapEvent;
  ArcRaidType? _raidType;
  ArcBlueprintAcquisitionSource? _acquisitionSource;
  ArcTimeOfDay? _timeOfDay;
  final List<_AdditionalBlueprintReportEntry> _additionalReports = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dupesController = TextEditingController(
      text: widget.initialState.dupesOwned.toString(),
    );
    _notesController = TextEditingController();
    _owned = widget.initialState.owned;
    _applyBlueprintDefaults();
  }

  @override
  void dispose() {
    _dupesController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ArcDropReportOptions get _options {
    final map = _selectedMap;
    if (map == null || map.isEmpty) {
      return const ArcDropReportOptions(
        mapName: '',
        poiOptions: [],
        enemyOptions: [],
        mapEventOptions: [],
      );
    }
    return ArcDropReportOptionsResolver.forMap(map);
  }

  List<ArcPoiData> get _poiOptions {
    final map = _selectedMap;
    if (map == null || map.isEmpty) return const <ArcPoiData>[];
    return ArcPoiDataStore.blueprintReportPoisForMap(map);
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

  bool get _canSubmitReport {
    if (_acquisitionSource == null) return false;

    if (!_requiresRaidDetails) return true;

    return (_selectedMap ?? '').isNotEmpty &&
        (_selectedPoiId ?? '').isNotEmpty &&
        _selectedContainerType != null &&
        _selectedMapEvent != null &&
        _raidType != null &&
        _timeOfDay != null;
  }

  bool get _allAdditionalReportsValid {
    for (final entry in _additionalReports) {
      if (entry.blueprint == null) return false;

      if (!_requiresRaidDetails) continue;

      final effectivePoiId = entry.useSamePoi ? _selectedPoiId : entry.poiId;
      if ((effectivePoiId ?? '').isEmpty) return false;

      final effectiveContainerType = entry.useSameContainerType
          ? _selectedContainerType
          : entry.containerType;
      if (effectiveContainerType == null) return false;
    }

    return true;
  }

  ArcRaidMode get _derivedMode {
    return (_timeOfDay == ArcTimeOfDay.night ||
            _timeOfDay == ArcTimeOfDay.lateNight)
        ? ArcRaidMode.nightRaid
        : ArcRaidMode.dayRaid;
  }

  bool get _usesAssessorFlow => widget.blueprint.id == 'dolabra';

  void _applyBlueprintDefaults() {
    final blueprintId = widget.blueprint.id;

    if (blueprintId == 'surge_coil') {
      _selectedMapEvent = ArcMapConditions.electromagneticStorm;
    } else if (blueprintId == 'canto') {
      _selectedMapEvent = ArcMapConditions.hurricane;
    } else if (blueprintId == 'dolabra') {
      _selectedMapEvent = ArcMapConditions.closeScrutiny;
      _selectedContainerType = ArcContainerTypes.assessor;
    }
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save ${widget.blueprint.name}: $e')),
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
      final manualDupes = _currentDupes;
      return current.copyWith(
        owned: true,
        dupesOwned: manualDupes,
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
      final reportTime = DateTime.now();
      final isRaidReport = _requiresRaidDetails;

      final selectedPoi = isRaidReport
          ? _poiOptions.firstWhere((item) => item.id == _selectedPoiId)
          : null;

      Future<void> saveReportForBlueprint(
        ArcBlueprint blueprint, {
        String? poiId,
        String? poiName,
        ArcContainerType? containerType,
      }) {
        final isDolabra = isRaidReport && blueprint.id == 'dolabra';

        return widget.repository.addDropReport(
          blueprintId: blueprint.id,
          mapName: isRaidReport ? _selectedMap! : 'Not Raid Specific',
          sourceType: isRaidReport
              ? (isDolabra ? ArcDropSourceType.enemy : ArcDropSourceType.poi)
              : ArcDropSourceType.other,
          poiId: isRaidReport && !isDolabra ? poiId : null,
          poiName: isRaidReport && !isDolabra ? poiName : null,
          enemySourceId: isDolabra ? 'enemy_assessor' : null,
          enemySourceName: isDolabra ? 'Assessor' : null,
          containerTypeId: isRaidReport ? containerType?.id : null,
          containerTypeLabel: isRaidReport ? containerType?.label : null,
          mapEventId: isRaidReport ? _selectedMapEvent?.id : null,
          mapEventLabel: isRaidReport ? _selectedMapEvent?.label : null,
          mode: isRaidReport ? _derivedMode : ArcRaidMode.dayRaid,
          raidType: isRaidReport ? _raidType! : ArcRaidType.fullRaid,
          entryTime: ArcEntryTime.unknown,
          timeOfDay: isRaidReport ? _timeOfDay! : ArcTimeOfDay.unknown,
          acquisitionSource:
              _acquisitionSource ?? ArcBlueprintAcquisitionSource.lootDrop,
          foundAt: reportTime,
          notes: _notesController.text,
        );
      }

      final stateUpdates = [
        _stateAfterFound(current: widget.initialState, isPrimary: true),
      ];

      await saveReportForBlueprint(
        widget.blueprint,
        poiId: selectedPoi?.id,
        poiName: selectedPoi?.name,
        containerType: isRaidReport ? _selectedContainerType : null,
      );

      for (final entry in _additionalReports) {
        final blueprint = entry.blueprint;
        if (blueprint == null) continue;

        ArcPoiData? additionalPoi;
        ArcContainerType? effectiveContainerType;

        if (isRaidReport) {
          final effectivePoiId = entry.useSamePoi
              ? _selectedPoiId
              : entry.poiId;
          additionalPoi = _poiOptions.firstWhere(
            (item) => item.id == effectivePoiId,
          );
          effectiveContainerType = entry.useSameContainerType
              ? _selectedContainerType
              : entry.containerType;
        }

        await saveReportForBlueprint(
          blueprint,
          poiId: additionalPoi?.id,
          poiName: additionalPoi?.name,
          containerType: effectiveContainerType,
        );

        final currentState = await _loadCurrentBlueprintState(blueprint.id);
        stateUpdates.add(_stateAfterFound(current: currentState));
      }

      await widget.repository.saveBlueprintStates(stateUpdates);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save ${widget.blueprint.name}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _scrollToNextStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = (position.pixels + 220).clamp(
        0.0,
        position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<T?> _showSearchPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelBuilder,
    bool enableVoiceSearch = false,
  }) async {
    final controller = TextEditingController();
    final sortedItems = List<T>.from(items)
      ..sort(
        (a, b) => labelBuilder(
          a,
        ).toLowerCase().compareTo(labelBuilder(b).toLowerCase()),
      );
    var filteredItems = List<T>.from(sortedItems);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFilter(String query) {
              final normalized = query.trim().toLowerCase();
              setModalState(() {
                if (normalized.isEmpty) {
                  filteredItems = List<T>.from(sortedItems);
                } else {
                  filteredItems = sortedItems
                      .where(
                        (item) => labelBuilder(
                          item,
                        ).toLowerCase().contains(normalized),
                      )
                      .toList(growable: false);
                }
              });
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppTheme.spaceL,
                  right: AppTheme.spaceL,
                  top: AppTheme.spaceL,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      AppTheme.spaceL,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: AppTheme.spaceL),
                      Text(
                        title,
                        style: AppTheme.tradingHeading(
                          fontSize: 22,
                          color: AppTheme.neonPink,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: updateFilter,
                        decoration:
                            AppTheme.tradingInputDecoration(
                              label: 'Search $title',
                            ).copyWith(
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Colors.white70,
                              ),
                              suffixIcon: enableVoiceSearch
                                  ? BlueprintVoiceSearchButton(
                                      onSearchText: (value) {
                                        controller.text = value;
                                        controller.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset: controller.text.length,
                                              ),
                                            );
                                        updateFilter(value);
                                      },
                                    )
                                  : null,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matches found.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, _) => Divider(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return ListTile(
                                    title: Text(
                                      labelBuilder(item),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () =>
                                        Navigator.of(context).pop(item),
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
      },
    );
  }

  Future<void> _pickMap() async {
    final selection = await _showSearchPicker<String>(
      title: 'Map',
      items: _availableMaps,
      labelBuilder: (item) => item,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedMap = selection;
      _selectedPoiId = null;
      _selectedContainerType = null;
      _selectedMapEvent = null;
      _raidType = null;
      _timeOfDay = null;
      _additionalReports.clear();
      _applyBlueprintDefaults();
    });
    _scrollToNextStep();
  }

  Future<void> _pickPoi() async {
    final selection = await _showSearchPicker<ArcPoiData>(
      title: 'Area / POI',
      items: _poiOptions,
      labelBuilder: (item) => item.name,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedPoiId = selection.id;
      _selectedContainerType = null;
      for (final entry in _additionalReports) {
        if (entry.useSamePoi) {
          entry.poiId = null;
        }
      }
    });
    _scrollToNextStep();
  }

  Future<void> _pickAdditionalPoi(int index) async {
    final selection = await _showSearchPicker<ArcPoiData>(
      title: 'Additional Area / POI',
      items: _poiOptions,
      labelBuilder: (item) => item.name,
    );
    if (selection == null || !mounted) return;
    setState(() => _additionalReports[index].poiId = selection.id);
  }

  Future<void> _pickContainerType() async {
    final selection = await _showSearchPicker<ArcContainerType>(
      title: 'Container Type',
      items: ArcContainerTypes.reportable,
      labelBuilder: (item) => item.label,
    );
    if (selection == null || !mounted) return;
    setState(() => _selectedContainerType = selection);
    _scrollToNextStep();
  }

  Future<void> _pickAdditionalContainerType(int index) async {
    final selection = await _showSearchPicker<ArcContainerType>(
      title: 'Additional Container Type',
      items: ArcContainerTypes.reportable,
      labelBuilder: (item) => item.label,
    );
    if (selection == null || !mounted) return;
    setState(() => _additionalReports[index].containerType = selection);
  }

  Future<void> _pickMapEvent() async {
    final selection = await _showSearchPicker<ArcMapCondition>(
      title: 'Map Event',
      items: _options.mapEventOptions,
      labelBuilder: (item) => item.label,
    );
    if (selection == null || !mounted) return;
    setState(() => _selectedMapEvent = selection);
    _scrollToNextStep();
  }

  Future<void> _pickRaidType() async {
    final selection = await _showSearchPicker<ArcRaidType>(
      title: 'Raid Round',
      items: ArcRaidType.values,
      labelBuilder: (item) => item.label,
    );
    if (selection == null || !mounted) return;
    setState(() => _raidType = selection);
    _scrollToNextStep();
  }

  Future<void> _pickAcquisitionSource() async {
    final selection = await _showSearchPicker<ArcBlueprintAcquisitionSource>(
      title: 'How Was It Obtained?',
      items: ArcBlueprintAcquisitionSource.values,
      labelBuilder: (item) => item.label,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _acquisitionSource = selection;
      if (selection != ArcBlueprintAcquisitionSource.lootDrop) {
        _selectedMap = null;
        _selectedMapEvent = null;
        _selectedPoiId = null;
        _selectedContainerType = null;
        _raidType = null;
        _timeOfDay = null;
        _additionalReports.clear();
      }
    });
    _scrollToNextStep();
  }

  Future<void> _pickTimeOfDay() async {
    final selection = await _showSearchPicker<ArcTimeOfDay>(
      title: 'Raider Time of Day',
      items: ArcTimeOfDay.values,
      labelBuilder: (item) => item.label,
    );
    if (selection == null || !mounted) return;
    setState(() => _timeOfDay = selection);
    _scrollToNextStep();
  }

  Future<void> _pickAdditionalBlueprint(int index) async {
    final currentBlueprint = _additionalReports[index].blueprint;
    final usedIds = <String>{widget.blueprint.id};
    for (var i = 0; i < _additionalReports.length; i++) {
      if (i == index) continue;
      final picked = _additionalReports[i].blueprint;
      if (picked != null) usedIds.add(picked.id);
    }

    final items =
        List<ArcBlueprint>.from(
            ArcBlueprintSeedData.blueprints,
          ).where((item) => !usedIds.contains(item.id)).toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (currentBlueprint != null &&
        !items.any((item) => item.id == currentBlueprint.id)) {
      items.add(currentBlueprint);
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    final selection = await _showSearchPicker<ArcBlueprint>(
      title: 'Additional Blueprint',
      items: items,
      labelBuilder: (item) => item.name,
      enableVoiceSearch: true,
    );
    if (selection == null || !mounted) return;
    setState(() => _additionalReports[index].blueprint = selection);
  }

  Future<void> _voicePickAdditionalBlueprint(
    int index,
    String spokenText,
  ) async {
    final query = spokenText.trim().toLowerCase();
    if (query.isEmpty || !mounted) return;

    final usedIds = <String>{widget.blueprint.id};
    for (var i = 0; i < _additionalReports.length; i++) {
      if (i == index) continue;
      final picked = _additionalReports[i].blueprint;
      if (picked != null) usedIds.add(picked.id);
    }

    final normalizedQuery = query.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final matches =
        ArcBlueprintSeedData.blueprints
            .where((item) => !usedIds.contains(item.id))
            .where((item) {
              final name = item.name.toLowerCase();
              final id = item.id.toLowerCase();
              final category = item.category.toLowerCase();
              final group = item.group.toLowerCase();
              return name.contains(query) ||
                  id.contains(normalizedQuery) ||
                  category.contains(query) ||
                  group.contains(query);
            })
            .toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (matches.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No blueprint found for "$spokenText".')),
      );
      return;
    }

    if (matches.length == 1) {
      setState(() => _additionalReports[index].blueprint = matches.first);
      return;
    }

    final selection = await _showSearchPicker<ArcBlueprint>(
      title: 'Additional Blueprint',
      items: matches,
      labelBuilder: (item) => item.name,
    );

    if (selection == null || !mounted) return;
    setState(() => _additionalReports[index].blueprint = selection);
  }

  void _addAnotherBlueprintEntry() {
    setState(() {
      _additionalReports.add(_AdditionalBlueprintReportEntry());
    });
  }

  void _removeAdditionalBlueprintEntry(int index) {
    setState(() {
      _additionalReports.removeAt(index);
    });
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

  Widget _buildSelectorField({
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: AppTheme.tradingInputDecoration(label: label),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalReportCard(BuildContext context, int index) {
    final entry = _additionalReports[index];
    final selectedPoi = entry.useSamePoi || entry.poiId == null
        ? null
        : _poiOptions.cast<ArcPoiData?>().firstWhere(
            (item) => item?.id == entry.poiId,
            orElse: () => null,
          );

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spaceM),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Additional Blueprint ${index + 1}',
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: _isSaving
                    ? null
                    : () => _removeAdditionalBlueprintEntry(index),
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.white70,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: _buildSelectorField(
                  label: 'Additional Blueprint',

                  value: entry.blueprint?.name ?? 'Select additional blueprint',

                  onTap: () => _pickAdditionalBlueprint(index),
                ),
              ),

              const SizedBox(width: AppTheme.spaceS),

              Padding(
                padding: const EdgeInsets.only(top: 6),

                child: BlueprintVoiceSearchButton(
                  onSearchText: (value) =>
                      _voicePickAdditionalBlueprint(index, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          SwitchListTile(
            value: entry.useSamePoi,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppTheme.neonPink,
            title: const Text(
              'Same Area / POI',
              style: TextStyle(color: Colors.white),
            ),
            onChanged: (value) => setState(() {
              entry.useSamePoi = value;
              if (value) entry.poiId = null;
            }),
          ),
          if (!entry.useSamePoi)
            _buildSelectorField(
              label: 'Additional Area / POI',
              value: selectedPoi == null
                  ? 'Select additional Area / POI'
                  : selectedPoi.name,
              onTap: _selectedMap == null
                  ? null
                  : () => _pickAdditionalPoi(index),
            ),
          const SizedBox(height: AppTheme.spaceS),
          SwitchListTile(
            value: entry.useSameContainerType,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppTheme.neonPink,
            title: const Text(
              'Same container type',
              style: TextStyle(color: Colors.white),
            ),
            onChanged: (value) => setState(() {
              entry.useSameContainerType = value;
              if (value) entry.containerType = null;
            }),
          ),
          if (!entry.useSameContainerType)
            _buildSelectorField(
              label: 'Additional Container Type',
              value:
                  entry.containerType?.label ??
                  'Select additional container type',
              onTap: () => _pickAdditionalContainerType(index),
            ),
        ],
      ),
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
        'This report is not tied to a raid location. Save it with the source selected so other players can see it came from a quest reward, trial reward or trade.',
        style: AppTheme.bodyTextStyle(
          fontSize: 14,
          color: AppTheme.tradingMutedText,
        ),
      ),
    );
  }

  Widget _buildRaidDetailsFields(ArcPoiData? selectedPoi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectorField(
          label: 'Map *',
          value: _selectedMap ?? 'Select Map',
          onTap: _pickMap,
        ),
        const SizedBox(height: AppTheme.spaceM),
        _buildSelectorField(
          label: 'Map Event *',
          value:
              _selectedMapEvent?.label ??
              (widget.blueprint.id == 'surge_coil'
                  ? 'Electromagnetic Storm'
                  : widget.blueprint.id == 'canto'
                  ? 'Hurricane'
                  : _usesAssessorFlow
                  ? 'Close Scrutiny'
                  : 'Select Map Event'),
          onTap:
              _selectedMap == null ||
                  _usesAssessorFlow ||
                  widget.blueprint.id == 'surge_coil' ||
                  widget.blueprint.id == 'canto'
              ? null
              : _pickMapEvent,
        ),
        const SizedBox(height: AppTheme.spaceM),
        _buildSelectorField(
          label: 'Area / POI *',
          value: selectedPoi == null ? 'Select Area / POI' : selectedPoi.name,
          onTap: _selectedMap == null ? null : _pickPoi,
        ),
        const SizedBox(height: AppTheme.spaceM),
        _buildSelectorField(
          label: 'Container Type *',
          value:
              _selectedContainerType?.label ??
              (_usesAssessorFlow ? 'Assessor' : 'Select Container Type'),
          onTap: _selectedPoiId == null || _usesAssessorFlow
              ? null
              : _pickContainerType,
        ),
        const SizedBox(height: AppTheme.spaceM),
        _buildSelectorField(
          label: 'Raid Round *',
          value: _raidType?.label ?? 'Select Raid Round',
          onTap: _selectedMap == null ? null : _pickRaidType,
        ),
        const SizedBox(height: AppTheme.spaceM),
        _buildSelectorField(
          label: 'Raider Time of Day *',
          value: _timeOfDay?.label ?? 'Select Raider Time of Day',
          onTap: _selectedMap == null ? null : _pickTimeOfDay,
        ),
      ],
    );
  }

  Widget _buildAdditionalBlueprintSection() {
    if (!_requiresRaidDetails) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppTheme.spaceM),
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Text(
          'Additional blueprint reporting is only available for Loot Drop reports from the same raid.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Additional blueprints from this raid',
                style: AppTheme.tradingHeading(
                  fontSize: 18,
                  color: AppTheme.neonCyan,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _selectedMap == null
                  ? null
                  : _addAnotherBlueprintEntry,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Another'),
            ),
          ],
        ),
        const Text(
          'Shared run details stay the same. For each extra blueprint you can keep the same Area / POI and container type, or change them.',
          style: TextStyle(color: Colors.white60, height: 1.35),
        ),
        if (_additionalReports.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: AppTheme.spaceM),
            padding: const EdgeInsets.all(AppTheme.spaceM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              'No additional blueprints added yet.',
              style: TextStyle(color: Colors.white60),
            ),
          )
        else
          ...List.generate(
            _additionalReports.length,
            (index) => _buildAdditionalReportCard(context, index),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoi = _selectedPoiId == null
        ? null
        : _poiOptions.cast<ArcPoiData?>().firstWhere(
            (item) => item?.id == _selectedPoiId,
            orElse: () => null,
          );

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
                        'Open this when you want to add how and where this blueprint was found.',
                    icon: Icons.add_location_alt_outlined,
                    children: [
                      Text(
                        'Start with how the blueprint was obtained. Loot Drop reports can include map, event, area, container, raid round and Raider time of day. Quest rewards, trial rewards and trades do not need raid details.',
                        style: const TextStyle(
                          color: Colors.white60,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      _buildSelectorField(
                        label: 'How Was It Obtained *',
                        value: _acquisitionSource?.label ?? 'Select Source',
                        onTap: _pickAcquisitionSource,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      if (_acquisitionSource != null &&
                          !_requiresRaidDetails) ...[
                        _buildNonRaidSourceNotice(),
                        const SizedBox(height: AppTheme.spaceM),
                      ],
                      if (_requiresRaidDetails)
                        _buildRaidDetailsFields(selectedPoi),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildAdditionalBlueprintSection(),
                      const SizedBox(height: AppTheme.spaceM),
                      TextField(
                        controller: _notesController,
                        style: const TextStyle(color: Colors.white),
                        minLines: 3,
                        maxLines: 5,
                        decoration: AppTheme.tradingInputDecoration(
                          label:
                              'Location Notes (bridge, back room, upper floor, hidden corner, etc.)',
                        ),
                      ),
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
