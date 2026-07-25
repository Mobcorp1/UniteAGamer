import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_view_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_marker_filter_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_community_intel_report_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_marker_detail_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcRaidIntelligenceScreen extends StatefulWidget {
  const ArcRaidIntelligenceScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/raid-intelligence';

  @override
  State<ArcRaidIntelligenceScreen> createState() =>
      _ArcRaidIntelligenceScreenState();
}

class _ArcRaidIntelligenceScreenState extends State<ArcRaidIntelligenceScreen> {
  final ArcRaidIntelligenceEngine _engine = const ArcRaidIntelligenceEngine();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcSavedLoadoutRepository _loadoutRepository =
      ArcSavedLoadoutRepository();
  final ArcRaidIntelligenceRepository _routeRepository =
      ArcRaidIntelligenceRepository();
  final ArcCommunityIntelRepository _communityIntelRepository =
      ArcCommunityIntelRepository();
  final ArcMapViewRepository _mapViewRepository = const ArcMapViewRepository();
  final TransformationController _mapController = TransformationController();
  final TextEditingController _searchController = TextEditingController();

  String _mapId = 'blue_gate';
  ArcRaidMapLayer _activeLayer = ArcRaidMapLayer.surface;
  ArcRaidMapFilterState _filters = ArcRaidMapFilterState.defaults;
  ArcRaidSquadMode _squadMode = ArcRaidSquadMode.solo;
  ArcRaidRouteStyle _routeStyle = ArcRaidRouteStyle.balanced;
  ArcRaidObjectivePriority _objectivePriority =
      ArcRaidObjectivePriority.myNeedsFirst;
  String _raidStage = 'Full';
  ArcRaidRouteStop? _spawn;
  ArcRaidRouteStop? _extraction;
  bool _usesHatch = false;
  bool _hatchKeyConfirmed = false;
  ArcRaidRoutePlan? _routePlan;
  ArcRaidMapMarker? _selectedMarker;
  Timer? _mapViewSaveTimer;
  bool _restoringMapView = false;

  @override
  void initState() {
    super.initState();
    _mapController.addListener(_onMapTransformChanged);
    unawaited(_initialiseScreen());
  }

  @override
  void dispose() {
    _mapViewSaveTimer?.cancel();
    _mapController.removeListener(_onMapTransformChanged);
    unawaited(_persistMapView());
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveRoute() async {
    final route = await _routeRepository.loadActiveRoute();
    if (!mounted || route == null) return;
    setState(() {
      if (ArcRaidIntelligenceSeedData.supportedMapIds.contains(route.mapId)) {
        _mapId = route.mapId;
      }
      _squadMode = route.squadMode;
      _routeStyle = route.routeStyle;
      _objectivePriority = route.objectivePriority;
      _raidStage = route.raidStage;
      _spawn = route.spawn;
      _extraction = route.extraction;
      _usesHatch = route.usesRaiderHatch;
      _hatchKeyConfirmed = route.hatchKeyConfirmed;
      _routePlan = route;
    });
  }

  Future<void> _initialiseScreen() async {
    await _loadActiveRoute();
    await _restoreLastMapView();
  }

  Future<void> _restoreLastMapView() async {
    final snapshot = await _mapViewRepository.loadLast();
    if (!mounted || snapshot == null) return;
    if (!ArcRaidIntelligenceSeedData.supportedMapIds.contains(snapshot.mapId)) {
      return;
    }
    final map = ArcRaidIntelligenceSeedData.mapById(snapshot.mapId);
    if (!map.availableLayers.contains(snapshot.layer)) return;

    _restoringMapView = true;
    setState(() {
      _mapId = snapshot.mapId;
      _activeLayer = snapshot.layer;
      _selectedMarker = null;
    });
    _mapController.value = Matrix4.fromList(snapshot.matrixValues);
    _restoringMapView = false;
  }

  Future<void> _restoreLayerView({
    required String mapId,
    required ArcRaidMapLayer layer,
  }) async {
    final snapshot = await _mapViewRepository.loadFor(
      mapId: mapId,
      layer: layer,
    );
    if (!mounted || mapId != _mapId || layer != _activeLayer) return;

    _restoringMapView = true;
    _mapController.value = snapshot == null
        ? Matrix4.identity()
        : Matrix4.fromList(snapshot.matrixValues);
    _restoringMapView = false;
    await _persistMapView();
  }

  void _onMapTransformChanged() {
    if (_restoringMapView) return;
    _mapViewSaveTimer?.cancel();
    _mapViewSaveTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_persistMapView()),
    );
  }

  Future<void> _persistMapView() {
    return _mapViewRepository.save(
      ArcMapViewSnapshot(
        mapId: _mapId,
        layer: _activeLayer,
        matrixValues: _mapController.value.storage.toList(growable: false),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _changeMap(String mapId) async {
    final nextMap = ArcRaidIntelligenceSeedData.mapById(mapId);
    final nextLayer = nextMap.availableLayers.contains(ArcRaidMapLayer.surface)
        ? ArcRaidMapLayer.surface
        : (nextMap.availableLayers.isEmpty
              ? ArcRaidMapLayer.surface
              : nextMap.availableLayers.first);
    setState(() {
      _mapId = mapId;
      _activeLayer = nextLayer;
      _spawn = null;
      _extraction = null;
      _routePlan = null;
      _selectedMarker = null;
    });
    await _restoreLayerView(mapId: mapId, layer: nextLayer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Raid Intelligence'),
        actions: [
          IconButton(
            tooltip: 'Open Blueprint Tracker',
            onPressed: () =>
                Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
            icon: const Icon(Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: 'Open Community Intel',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(ArcMarketIntelligenceScreen.routeName),
            icon: const Icon(Icons.radar_rounded),
          ),
        ],
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: StreamBuilder<Map<String, ArcBlueprintState>>(
          stream: _blueprintRepository.watchMyBlueprintStates(),
          builder: (context, blueprintSnapshot) {
            final states =
                blueprintSnapshot.data ?? const <String, ArcBlueprintState>{};
            return StreamBuilder<ArcSavedLoadout?>(
              stream: _loadoutRepository.watchFavouriteLoadout(),
              builder: (context, loadoutSnapshot) {
                final loadout = loadoutSnapshot.data;
                return StreamBuilder<List<ArcBlueprintDropReport>>(
                  stream: _blueprintRepository.watchRecentReports(limit: 300),
                  builder: (context, reportSnapshot) {
                    final reports =
                        reportSnapshot.data ?? const <ArcBlueprintDropReport>[];
                    return StreamBuilder<List<ArcCommunityIntelReport>>(
                      stream: _communityIntelRepository.watchMapReports(_mapId),
                      builder: (context, communitySnapshot) {
                        final communityReports =
                            communitySnapshot.data ??
                            const <ArcCommunityIntelReport>[];
                        final intelligence = _engine.build(
                          mapId: _mapId,
                          blueprintStates: states,
                          favouriteLoadout: loadout,
                          dropReports: reports,
                          communityReports: communityReports,
                          filters: _filters,
                          activeLayer: _activeLayer,
                          activeRoute: _routePlan,
                        );
                        return _buildLayout(
                          intelligence,
                          communityReports: communityReports,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayout(
    ArcRaidIntelligenceState intelligence, {
    required List<ArcCommunityIntelReport> communityReports,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        final panel = _controlPanel(
          intelligence,
          desktop: desktop,
          communityReports: communityReports,
        );
        final map = _mapPanel(intelligence);
        if (desktop) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(flex: 7, child: map),
                const SizedBox(width: 14),
                SizedBox(width: 390, child: panel),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: Padding(padding: const EdgeInsets.all(10), child: map),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.46,
              ),
              child: panel,
            ),
          ],
        );
      },
    );
  }

  Widget _mapPanel(ArcRaidIntelligenceState intelligence) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(
        radius: 20,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
        backgroundColor: Colors.black.withValues(alpha: 0.22),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ArcRaidIntelligenceMapRenderer(
                state: intelligence,
                controller: _mapController,
                selectedMarkerId: _selectedMarker?.id,
                onMarkerSelected: (marker) =>
                    setState(() => _selectedMarker = marker),
                onMapTapped: _setFreeformSpawn,
                onIntelReportRequested: (point) =>
                    _openCommunityIntelReport(intelligence.map, point),
              ),
            ),
          ),
          Positioned(right: 16, top: 16, child: _mapControls(intelligence)),
          if (intelligence.map.availableLayers.length > 1)
            Positioned(
              left: 70,
              top: 16,
              right: 86,
              child: Align(
                alignment: Alignment.topCenter,
                child: _layerSelector(intelligence.map),
              ),
            ),
          Positioned(
            left: 18,
            bottom: 18,
            right: 18,
            child: _routeStrip(intelligence),
          ),
        ],
      ),
    );
  }

  Widget _mapControls(ArcRaidIntelligenceState intelligence) {
    return Column(
      children: [
        _mapButton(Icons.add_rounded, 'Zoom in', () => _scaleMap(1.22)),
        const SizedBox(height: 7),
        _mapButton(Icons.remove_rounded, 'Zoom out', () => _scaleMap(0.82)),
        const SizedBox(height: 7),
        _mapButton(Icons.center_focus_strong_rounded, 'Fit map', _resetMap),
        const SizedBox(height: 7),
        _mapButton(
          Icons.add_location_alt_rounded,
          'Report Intel at map centre',
          () => _openCommunityIntelReport(
            intelligence.map,
            const ArcNormalizedPoint(x: 0.5, y: 0.5),
          ),
        ),
        const SizedBox(height: 7),
        _mapButton(
          Icons.my_location_rounded,
          'Jump to spawn',
          _spawn == null ? null : () => _jumpTo(_spawn!.point),
        ),
        const SizedBox(height: 7),
        _mapButton(
          Icons.exit_to_app_rounded,
          'Jump to extraction',
          _extraction == null ? null : () => _jumpTo(_extraction!.point),
        ),
        const SizedBox(height: 7),
        _mapButton(
          Icons.route_rounded,
          'Jump to route stop',
          _routePlan?.stops.isEmpty ?? true
              ? null
              : () => _jumpTo(_routePlan!.stops.first.point),
        ),
      ],
    );
  }

  Widget _layerSelector(ArcRaidMap map) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final layer in map.availableLayers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                selected: layer == _activeLayer,
                showCheckmark: false,
                label: Text(layer.label),
                avatar: Icon(
                  layer == ArcRaidMapLayer.surface
                      ? Icons.public_rounded
                      : Icons.layers_rounded,
                  size: 16,
                ),
                onSelected: (_) => unawaited(_selectLayer(layer)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectLayer(ArcRaidMapLayer layer) async {
    if (layer == _activeLayer) return;
    setState(() {
      _activeLayer = layer;
      _selectedMarker = null;
    });
    await _restoreLayerView(mapId: _mapId, layer: layer);
  }

  Widget _mapButton(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: AppTheme.neonCyan,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.84),
          disabledForegroundColor: Colors.white24,
        ),
      ),
    );
  }

  Widget _routeStrip(ArcRaidIntelligenceState intelligence) {
    final route = intelligence.routePlan;
    return IgnorePointer(
      ignoring: false,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.64),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.18)),
        ),
        child: Text(
          route == null
              ? intelligence.recommendation
              : '${route.summary} ${route.approximate ? 'Area-to-area route, approximate.' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _controlPanel(
    ArcRaidIntelligenceState intelligence, {
    required bool desktop,
    required List<ArcCommunityIntelReport> communityReports,
  }) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(
        radius: desktop ? 20 : 18,
        borderColor: AppTheme.neonPink.withValues(alpha: 0.22),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _hero(intelligence),
          const SizedBox(height: 12),
          _setupSection(intelligence),
          const SizedBox(height: 12),
          _filterSection(),
          const SizedBox(height: 12),
          _communityIntelSection(intelligence.map, communityReports),
          const SizedBox(height: 12),
          _selectedMarkerSection(intelligence),
          const SizedBox(height: 12),
          _routeSection(intelligence),
        ],
      ),
    );
  }

  Widget _hero(ArcRaidIntelligenceState intelligence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENERATE BLUEPRINT RUN',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${intelligence.map.displayName} • ${intelligence.statusLabel} • ${intelligence.activeConditionLabel}',
          style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill(
              '${intelligence.opportunityClusters.length} clusters',
              AppTheme.neonPink,
            ),
            _pill(
              '${intelligence.visibleMarkers.length} markers',
              AppTheme.neonCyan,
            ),
            _pill(
              intelligence.map.hasCalibratedLayer(intelligence.activeLayer)
                  ? 'Calibrated'
                  : 'Schematic',
              Colors.lightGreenAccent,
            ),
            _pill(intelligence.activeLayer.label, Colors.amberAccent),
          ],
        ),
      ],
    );
  }

  Widget _setupSection(ArcRaidIntelligenceState intelligence) {
    return _section(
      title: 'Start Of Raid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _mapId,
            dropdownColor: AppTheme.cardBackgroundAlt,
            decoration: AppTheme.tradingInputDecoration(label: 'Map'),
            items: [
              for (final map in ArcRaidIntelligenceSeedData.maps)
                DropdownMenuItem(value: map.id, child: Text(map.displayName)),
            ],
            onChanged: (value) {
              if (value == null) return;
              unawaited(_changeMap(value));
            },
          ),
          const SizedBox(height: 10),
          _chips<ArcRaidSquadMode>(
            values: ArcRaidSquadMode.values,
            selected: _squadMode,
            label: (value) => value.label,
            onSelected: (value) => setState(() => _squadMode = value),
          ),
          const SizedBox(height: 10),
          _chips<String>(
            values: const ['Full', 'Mid', 'Late'],
            selected: _raidStage,
            label: (value) => value,
            onSelected: (value) => setState(() => _raidStage = value),
          ),
          const SizedBox(height: 10),
          _chips<ArcRaidRouteStyle>(
            values: ArcRaidRouteStyle.values,
            selected: _routeStyle,
            label: (value) => value.label,
            onSelected: (value) => setState(() => _routeStyle = value),
          ),
          const SizedBox(height: 10),
          _chips<ArcRaidObjectivePriority>(
            values: ArcRaidObjectivePriority.values,
            selected: _objectivePriority,
            label: _objectivePriorityLabel,
            onSelected: (value) => setState(() => _objectivePriority = value),
          ),
          const SizedBox(height: 10),
          _spawnExtractionPickers(intelligence.map),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _usesHatch,
            onChanged: (value) => setState(() {
              _usesHatch = value;
              _hatchKeyConfirmed = false;
              _extraction = null;
            }),
            title: const Text(
              'Use Raider Hatch',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Requires player-confirmed hatch key.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          if (_usesHatch)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _hatchKeyConfirmed,
              onChanged: (value) =>
                  setState(() => _hatchKeyConfirmed = value ?? false),
              title: const Text(
                'Raider Hatch Key confirmed',
                style: TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _generateRoute(intelligence),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Generate Best Loot Run'),
          ),
        ],
      ),
    );
  }

  Widget _spawnExtractionPickers(ArcRaidMap map) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: map.spawnRegions.any((spawn) => spawn.id == _spawn?.id)
              ? _spawn!.id
              : null,
          dropdownColor: AppTheme.cardBackgroundAlt,
          decoration: AppTheme.tradingInputDecoration(
            label: 'Spawn Region or tap map',
          ),
          items: [
            for (final spawn in map.spawnRegions)
              DropdownMenuItem(value: spawn.id, child: Text(spawn.name)),
          ],
          onChanged: (value) {
            final spawn = map.spawnRegions.firstWhere(
              (item) => item.id == value,
            );
            setState(() => _spawn = _engine.stopFromSpawn(spawn));
            _jumpTo(spawn.center);
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _extraction?.id,
          dropdownColor: AppTheme.cardBackgroundAlt,
          decoration: AppTheme.tradingInputDecoration(
            label: _usesHatch ? 'Raider Hatch' : 'Standard Extraction',
          ),
          items: [
            if (_usesHatch)
              for (final hatch in map.hatches)
                DropdownMenuItem(value: hatch.id, child: Text(hatch.name))
            else
              for (final extraction in map.extractions)
                DropdownMenuItem(
                  value: extraction.id,
                  child: Text(extraction.name),
                ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              if (_usesHatch) {
                final hatch = map.hatches.firstWhere(
                  (item) => item.id == value,
                );
                _extraction = _engine.stopFromHatch(hatch);
                _jumpTo(hatch.point);
              } else {
                final extraction = map.extractions.firstWhere(
                  (item) => item.id == value,
                );
                _extraction = _engine.stopFromExtraction(extraction);
                _jumpTo(extraction.point);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _filterSection() {
    return _section(
      title: 'Map Layers',
      child: ArcMapMarkerFilterPanel(
        filters: _filters,
        searchController: _searchController,
        onChanged: (filters) {
          setState(() {
            _filters = filters;
            if (_selectedMarker != null && !_filters.allows(_selectedMarker!)) {
              _selectedMarker = null;
            }
          });
        },
      ),
    );
  }

  Widget _communityIntelSection(
    ArcRaidMap map,
    List<ArcCommunityIntelReport> reports,
  ) {
    final visible = reports
        .where((report) => report.layer == _activeLayer)
        .take(5)
        .toList(growable: false);
    return _section(
      title: 'Community Intel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Long-press the map on mobile or right-click on desktop to report a location.',
            style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openCommunityIntelReport(
                map,
                const ArcNormalizedPoint(x: 0.5, y: 0.5),
              ),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Report Intel'),
            ),
          ),
          if (visible.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final report in visible)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(report.confirmationCount.toString()),
                ),
                title: Text(
                  report.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${report.confidence.label} • ${report.layer.label}',
                ),
                trailing: IconButton(
                  tooltip: 'Confirm this Intel',
                  onPressed: () => unawaited(_confirmCommunityIntel(report.id)),
                  icon: const Icon(Icons.verified_outlined),
                ),
                onTap: () => _jumpTo(report.point),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCommunityIntelReport(
    ArcRaidMap map,
    ArcNormalizedPoint point,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      builder: (context) => ArcCommunityIntelReportSheet(
        map: map,
        layer: _activeLayer,
        point: point,
        repository: _communityIntelRepository,
      ),
    );
  }

  Future<void> _confirmCommunityIntel(String reportId) async {
    try {
      await _communityIntelRepository.confirm(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Intel confirmed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm Intel: $error')),
      );
    }
  }

  Widget _selectedMarkerSection(ArcRaidIntelligenceState intelligence) {
    final marker = _selectedMarker;
    ArcRaidIntelCluster? cluster;
    if (marker != null) {
      for (final item in intelligence.opportunityClusters) {
        if (item.id == marker.payloadId) {
          cluster = item;
          break;
        }
      }
    }

    return _section(
      title: 'Selected Intel',
      child: marker == null
          ? const Text(
              'Select a marker or Blueprint Opportunity cluster.',
              style: TextStyle(color: Colors.white60),
            )
          : ArcMapMarkerDetailCard(
              marker: marker,
              footer: cluster == null
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _smallButton(
                          'Centre Map',
                          Icons.center_focus_strong_rounded,
                          () => _jumpTo(marker.point),
                        ),
                        _smallButton(
                          'Add to Raid Planner',
                          Icons.playlist_add_rounded,
                          () => Navigator.of(
                            context,
                          ).pushNamed(RaidPlannerScreen.routeName),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cluster.cautiousSummary,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${cluster.blueprintIds.length} Blueprint ${cluster.blueprintIds.length == 1 ? 'target' : 'targets'} • ${cluster.commonSource} • ${cluster.conditionCorrelation}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _smallButton(
                              'Add Stop',
                              Icons.add_location_alt_rounded,
                              () => _addClusterStop(cluster!),
                            ),
                            _smallButton(
                              'Open Blueprint',
                              Icons.grid_view_rounded,
                              () => Navigator.of(
                                context,
                              ).pushNamed(BlueprintGridScreen.routeName),
                            ),
                            _smallButton(
                              'Add to Raid Planner',
                              Icons.playlist_add_rounded,
                              () => Navigator.of(
                                context,
                              ).pushNamed(RaidPlannerScreen.routeName),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _routeSection(ArcRaidIntelligenceState intelligence) {
    final route = intelligence.routePlan;
    return _section(
      title: 'Route',
      child: route == null
          ? Text(
              _usesHatch && !_hatchKeyConfirmed
                  ? 'Confirm Raider Hatch Key before generating a hatch route.'
                  : 'Choose a spawn. UAG can select the best extraction automatically.',
              style: const TextStyle(color: Colors.white60),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.summary,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (route.metrics.hasData) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        '${route.metrics.estimatedMinutes} min',
                        AppTheme.neonCyan,
                      ),
                      _pill(
                        '${route.metrics.blueprintTargetCount} targets',
                        AppTheme.neonPink,
                      ),
                      _pill(
                        '${route.metrics.efficiencyScore}% efficiency',
                        Colors.lightGreenAccent,
                      ),
                      _pill(route.metrics.riskLabel, Colors.amberAccent),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                for (final stop in route.orderedStops)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.neonPink.withValues(
                        alpha: 0.18,
                      ),
                      child: Text(
                        '${stop.order + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      stop.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      stop.reason,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: stop.clusterId == null
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (value) => _updateStop(stop, value),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'searched',
                                child: Text('Mark searched'),
                              ),
                              PopupMenuItem(
                                value: 'completed',
                                child: Text('Mark completed'),
                              ),
                              PopupMenuItem(value: 'skip', child: Text('Skip')),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove'),
                              ),
                            ],
                          ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _smallButton('Save Active', Icons.save_rounded, () async {
                      await _routeRepository.saveActiveRoute(route);
                      _showSnack('Active Raid Intelligence route saved.');
                    }),
                    _smallButton('Archive', Icons.archive_rounded, () async {
                      await _routeRepository.archiveActiveRoute();
                      if (!mounted) return;
                      setState(() => _routePlan = null);
                      _showSnack('Active route archived.');
                    }),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.tradingHeading(
              fontSize: 15,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _chips<T>({
    required List<T> values,
    required T selected,
    required String Function(T value) label,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(label(value)),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 11, color: color, isBold: true),
      ),
    );
  }

  Widget _smallButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  String _objectivePriorityLabel(ArcRaidObjectivePriority priority) {
    switch (priority) {
      case ArcRaidObjectivePriority.myNeedsFirst:
        return 'My needs';
      case ArcRaidObjectivePriority.balancedSquad:
        return 'Balanced squad';
      case ArcRaidObjectivePriority.helpTeammate:
        return 'Help teammate';
    }
  }

  void _setFreeformSpawn(ArcNormalizedPoint point) {
    setState(() {
      _spawn = ArcRaidRouteStop(
        id: 'freeform_spawn',
        label: 'Approximate Spawn',
        point: point,
        order: 0,
        reason: 'Approximate spawn tapped by player; no GPS used.',
      );
    });
  }

  Future<void> _generateRoute(ArcRaidIntelligenceState intelligence) async {
    final spawn = _spawn;
    var extraction = _extraction;
    if (spawn == null) {
      _showSnack('Choose a spawn region or tap the map first.');
      return;
    }
    extraction ??= _engine.recommendExtraction(
      map: intelligence.map,
      spawn: spawn,
      clusters: intelligence.opportunityClusters,
      usesRaiderHatch: _usesHatch,
    );
    if (extraction == null) {
      _showSnack('No valid extraction is available for this map.');
      return;
    }
    final resolvedExtraction = extraction;
    if (_extraction == null) {
      setState(() => _extraction = resolvedExtraction);
    }
    final route = _engine.generateRoute(
      map: intelligence.map,
      clusters: intelligence.opportunityClusters,
      spawn: spawn,
      extraction: resolvedExtraction,
      routeStyle: _routeStyle,
      raidStage: _raidStage,
      squadMode: _squadMode,
      objectivePriority: _objectivePriority,
      usesRaiderHatch: _usesHatch,
      hatchKeyConfirmed: _hatchKeyConfirmed,
    );
    if (route == null) {
      _showSnack(
        _usesHatch && !_hatchKeyConfirmed
            ? 'Confirm Raider Hatch Key before generating this route.'
            : 'No route can be generated from current evidence.',
      );
      return;
    }
    setState(() => _routePlan = route);
    if (await _saveActiveRoute(route)) {
      _showSnack('Blueprint Run generated and saved as active route.');
    } else {
      _showSnack('Blueprint Run generated locally; route save failed.');
    }
  }

  void _addClusterStop(ArcRaidIntelCluster cluster) {
    final route = _routePlan;
    if (route == null) {
      _showSnack('Generate a route before adding extra stops.');
      return;
    }
    final next = _engine.addStop(route, cluster);
    setState(() => _routePlan = next);
    _saveActiveRoute(next);
  }

  void _updateStop(ArcRaidRouteStop stop, String action) {
    final route = _routePlan;
    if (route == null) return;
    final next = switch (action) {
      'searched' => _engine.markStop(
        route,
        stop.id,
        ArcRaidRouteStopState.searched,
      ),
      'completed' => _engine.markStop(
        route,
        stop.id,
        ArcRaidRouteStopState.completed,
      ),
      'skip' => _engine.markStop(route, stop.id, ArcRaidRouteStopState.skipped),
      'remove' => _engine.removeStop(route, stop.id),
      _ => route,
    };
    setState(() => _routePlan = next);
    _saveActiveRoute(next);
  }

  Future<bool> _saveActiveRoute(ArcRaidRoutePlan route) async {
    try {
      await _routeRepository.saveActiveRoute(route);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _scaleMap(double factor) {
    final currentScale = _mapController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.75, 5.0);
    final appliedFactor = targetScale / currentScale;
    final next = _mapController.value.clone()
      ..scaleByDouble(appliedFactor, appliedFactor, appliedFactor, 1);
    _mapController.value = next;
  }

  void _resetMap() {
    _mapController.value = Matrix4.identity();
  }

  void _jumpTo(ArcNormalizedPoint point) {
    final scale = 1.8;
    _mapController.value = Matrix4.identity()
      ..translateByDouble(-point.x * 260, -point.y * 260, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
