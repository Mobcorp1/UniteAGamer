import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_usage_gate.dart';
import '../widgets/arc_raid_location_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_preview_screen.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_stack_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_view_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_auto_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_nomadic_trader_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_marker_filter_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_selected_blueprint_intel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_community_intel_report_sheet.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_marker_detail_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_intelligence_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcRaidIntelligenceScreen extends StatefulWidget {
  const ArcRaidIntelligenceScreen({
    super.key,
    this.blueprintStates,
    this.favouriteLoadout,
    this.dropReports,
    this.communityReports,
    this.publishedMarkers,
    this.scrappyStates,
    this.progressionRecords,
    this.loadActiveRoute,
  });
  final Stream<Map<String, ArcBlueprintState>> Function()? blueprintStates;
  final Stream<ArcSavedLoadout?> Function()? favouriteLoadout;
  final Stream<List<ArcBlueprintDropReport>> Function()? dropReports;
  final Stream<List<ArcCommunityIntelReport>> Function(String)?
  communityReports;
  final Stream<List<ArcAdminMapMarker>> Function(String)? publishedMarkers;
  final Stream<Map<String, ArcScrappyState>> Function()? scrappyStates;
  final Stream<ArcProgressionRecords> Function()? progressionRecords;
  final Future<ArcRaidRoutePlan?> Function()? loadActiveRoute;

  static const routeName = '/trading-hub/arc-raiders/raid-intelligence';

  @override
  State<ArcRaidIntelligenceScreen> createState() =>
      _ArcRaidIntelligenceScreenState();
}

class _ArcRaidIntelligenceScreenState extends State<ArcRaidIntelligenceScreen> {
  final ArcRaidIntelligenceEngine _engine = const ArcRaidIntelligenceEngine();
  final ArcRaidAutoRecommendationEngine _autoRecommendationEngine =
      const ArcRaidAutoRecommendationEngine();
  final ArcMapMarkerStackResolver _stackResolver =
      const ArcMapMarkerStackResolver();
  late final ArcBlueprintRepository _blueprintRepository =
      ArcBlueprintRepository();
  late final ArcSavedLoadoutRepository _loadoutRepository =
      ArcSavedLoadoutRepository();
  late final ArcRaidIntelligenceRepository _routeRepository =
      ArcRaidIntelligenceRepository();
  late final ArcCommunityIntelRepository _communityIntelRepository =
      ArcCommunityIntelRepository();
  late final ArcAdminMapEditorRepository _adminMapRepository =
      ArcAdminMapEditorRepository();
  late final ArcScrappyRepository _scrappyRepository = ArcScrappyRepository();
  late final ArcProgressionRepository _progressionRepository =
      ArcProgressionRepository();
  late final ArcTraderProfileRepository _traderProfileRepository =
      ArcTraderProfileRepository();
  final ArcNomadicTraderRepository _nomadicTraderRepository =
      const ArcNomadicTraderRepository();
  late final UagEntitlementService _entitlementService =
      UagEntitlementService();
  final ArcMapViewRepository _mapViewRepository = const ArcMapViewRepository();
  final TransformationController _mapController = TransformationController();
  final TextEditingController _searchController = TextEditingController();

  ArcRegionalMapConditionsSnapshot? _regionalConditions;
  ArcAvailability _savedAvailability = ArcAvailability.initial();
  ArcTraderProfile? _traderProfile;
  ArcNomadicTraderTrackerSnapshot _nomadicTraderTracker =
      ArcNomadicTraderTrackerSnapshot.empty;

  String _mapId = ArcMapAssetRegistry.blueGateMapId;
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
  List<ArcRaidRoutePlan> _routeAlternatives = const <ArcRaidRoutePlan>[];
  UagSubscriptionTier _generatedRouteTier = UagSubscriptionTier.free;
  List<ArcRaidIntelCluster> _objectiveOnlyStops = const <ArcRaidIntelCluster>[];
  ArcRaidMapMarker? _selectedMarker;
  Timer? _mapViewSaveTimer;
  bool _restoringMapView = false;
  bool _controlPanelCollapsed = true;
  bool _showExplorerMarkers = false;
  final Map<String, Stream<dynamic>> _streams = {};
  final Map<String, dynamic> _lastData = {};
  final ScrollController _panelScroll = ScrollController();
  Stream<T> _source<T>(String key, Stream<T> Function() factory) =>
      (_streams.putIfAbsent(key, factory)) as Stream<T>;
  T _retain<T>(String key, AsyncSnapshot<T> snapshot, T fallback) {
    if (snapshot.connectionState == ConnectionState.active ||
        snapshot.connectionState == ConnectionState.done) {
      if (!snapshot.hasError && (snapshot.hasData || key == 'loadout')) {
        _lastData[key] = snapshot.data;
      }
    }
    return _lastData.containsKey(key) ? _lastData[key] as T : fallback;
  }

  void _selectMarker(ArcRaidMapMarker marker) {
    setState(() {
      _selectedMarker = marker;
      _controlPanelCollapsed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_panelScroll.hasClients) _panelScroll.jumpTo(0);
    });
  }

  @override
  void initState() {
    super.initState();
    _mapController.addListener(_onMapTransformChanged);
    unawaited(_initialiseScreen());
  }

  @override
  void dispose() {
    _panelScroll.dispose();
    _mapViewSaveTimer?.cancel();
    _mapController.removeListener(_onMapTransformChanged);
    unawaited(_persistMapView());
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveRoute() async {
    final route =
        await (widget.loadActiveRoute?.call() ??
            _routeRepository.loadActiveRoute());
    if (!mounted || route == null) return;
    var routeTier = UagSubscriptionTier.free;
    try {
      routeTier = (await _entitlementService.getMyEntitlement()).effectiveTier;
    } catch (_) {
      routeTier = UagSubscriptionTier.free;
    }
    if (!mounted) return;
    setState(() {
      final canonicalRouteMapId =
          ArcMapAssetRegistry.canonicalMapIdFor(route.mapId) ?? route.mapId;
      if (ArcRaidIntelligenceSeedData.supportedMapIds.contains(
        canonicalRouteMapId,
      )) {
        _mapId = canonicalRouteMapId;
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
      _routeAlternatives = <ArcRaidRoutePlan>[route];
      _generatedRouteTier = routeTier;
    });
  }

  Future<void> _initialiseScreen() async {
    try {
      await _loadActiveRoute();
    } catch (_) {
      if (mounted) setState(() => _lastData['routeError'] = true);
    }
    await _loadRecommendationContext();
    await _restoreLastMapView();
  }

  Future<void> _loadRecommendationContext() async {
    final regional = await ArcRegionalMapConditionsService.load();
    var availability = ArcAvailability.initial();
    ArcTraderProfile? profile;
    var nomadic = ArcNomadicTraderTrackerSnapshot.empty;

    try {
      if (_traderProfileRepository.currentUid != null) {
        availability = await _traderProfileRepository.getAvailability();
        profile = await _traderProfileRepository.getProfile();
      }
    } catch (_) {
      // Recommendation context is additive; the core Raid Intelligence screen
      // remains usable if profile or availability cannot be read.
    }

    try {
      nomadic = await _nomadicTraderRepository.loadTrackerSnapshot();
    } catch (_) {
      nomadic = ArcNomadicTraderTrackerSnapshot.empty;
    }

    if (!mounted) return;
    setState(() {
      _regionalConditions = regional;
      _savedAvailability = availability;
      _traderProfile = profile;
      _nomadicTraderTracker = nomadic;
    });
  }

  Future<void> _restoreLastMapView() async {
    final snapshot = await _mapViewRepository.loadLast();
    if (!mounted || snapshot == null) return;
    final canonicalSnapshotMapId =
        ArcMapAssetRegistry.canonicalMapIdFor(snapshot.mapId) ?? snapshot.mapId;
    if (!ArcRaidIntelligenceSeedData.supportedMapIds.contains(
      canonicalSnapshotMapId,
    )) {
      return;
    }
    final map = ArcRaidIntelligenceSeedData.mapById(canonicalSnapshotMapId);
    if (!map.availableLayers.contains(snapshot.layer)) return;

    _restoringMapView = true;
    setState(() {
      _mapId = canonicalSnapshotMapId;
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
    final canonicalMapId =
        ArcMapAssetRegistry.canonicalMapIdFor(mapId) ?? mapId;
    final nextMap = ArcRaidIntelligenceSeedData.mapById(canonicalMapId);
    final nextLayer = nextMap.availableLayers.contains(ArcRaidMapLayer.surface)
        ? ArcRaidMapLayer.surface
        : (nextMap.availableLayers.isEmpty
              ? ArcRaidMapLayer.surface
              : nextMap.availableLayers.first);
    setState(() {
      _mapId = canonicalMapId;
      _activeLayer = nextLayer;
      _spawn = null;
      _extraction = null;
      _routePlan = null;
      _objectiveOnlyStops = const <ArcRaidIntelCluster>[];
      _selectedMarker = null;
    });
    await _restoreLayerView(mapId: canonicalMapId, layer: nextLayer);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inlineWorkspace = media.orientation == Orientation.landscape;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: inlineWorkspace
            ? Row(
                children: [
                  Text(
                    'RAID INTELLIGENCE',
                    style: ArcUiTokens.display(
                      fontSize: 20,
                      color: ArcUiTokens.secondaryAccent,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: _inlineWorkspaceNavigation(),
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                'RAID INTELLIGENCE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.display(
                  fontSize: 20,
                  color: ArcUiTokens.secondaryAccent,
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'Frozen Trail preview',
            icon: const Icon(Icons.ac_unit_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ArcFrozenTrailPreviewScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Map tools',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => setState(
              () => _controlPanelCollapsed = !_controlPanelCollapsed,
            ),
          ),
          IconButton(
            tooltip: 'Open Blueprint Tracker',
            onPressed: () =>
                Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
            icon: const Icon(Icons.grid_view_rounded),
          ),
          if (!inlineWorkspace)
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
        child: _liveBody(showWorkspaceBar: !inlineWorkspace),
      ),
    );
  }

  Widget _inlineWorkspaceNavigation() {
    const workspaces = <ArcIntelligenceWorkspace>[
      ArcIntelligenceWorkspace.raidMap,
      ArcIntelligenceWorkspace.community,
      ArcIntelligenceWorkspace.explorer,
      ArcIntelligenceWorkspace.planner,
    ];
    return Row(
      key: const Key('raid-inline-workspaces'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < workspaces.length; index++) ...[
          _inlineWorkspaceButton(workspaces[index]),
          if (index != workspaces.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _inlineWorkspaceButton(ArcIntelligenceWorkspace workspace) {
    final selected = workspace == ArcIntelligenceWorkspace.raidMap;
    final accent = selected
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textSecondary;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        foregroundColor: accent,
        backgroundColor: selected
            ? ArcUiTokens.primaryAccent.withValues(alpha: 0.12)
            : Colors.transparent,
        side: BorderSide(
          color: selected
              ? ArcUiTokens.primaryAccent.withValues(alpha: 0.72)
              : ArcUiTokens.textTertiary.withValues(alpha: 0.42),
        ),
        shape: const StadiumBorder(),
      ),
      onPressed: selected
          ? null
          : () => Navigator.of(context).pushNamed(workspace.routeName),
      icon: Icon(workspace.icon, size: 14, color: accent),
      label: Text(
        workspace.label.toUpperCase(),
        style: ArcUiTokens.label(color: accent),
      ),
    );
  }

  Widget _liveBody({required bool showWorkspaceBar}) {
    return StreamBuilder<Map<String, ArcScrappyState>>(
      stream: _source(
        'scrappy-tracker',
        widget.scrappyStates ?? _scrappyRepository.watchMyScrappyStateMap,
      ),
      builder: (context, scrappySnapshot) {
        final scrappyStates = _retain(
          'scrappy-tracker',
          scrappySnapshot,
          const <String, ArcScrappyState>{},
        );
        return StreamBuilder<ArcProgressionRecords>(
          stream: _source(
            'progression-records',
            widget.progressionRecords ??
                _progressionRepository.watchProgressionRecords,
          ),
          builder: (context, progressionSnapshot) {
            final progressionRecords = _retain(
              'progression-records',
              progressionSnapshot,
              ArcProgressionRecords.empty,
            );
            return StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _source(
                'blueprints',
                widget.blueprintStates ??
                    _blueprintRepository.watchMyBlueprintStates,
              ),
              builder: (context, blueprintSnapshot) {
                final states = _retain(
                  'blueprints',
                  blueprintSnapshot,
                  const <String, ArcBlueprintState>{},
                );
                return StreamBuilder<ArcSavedLoadout?>(
                  stream: _source(
                    'loadout',
                    widget.favouriteLoadout ??
                        _loadoutRepository.watchFavouriteLoadout,
                  ),
                  builder: (context, loadoutSnapshot) {
                    final loadout = _retain('loadout', loadoutSnapshot, null);
                    return StreamBuilder<List<ArcBlueprintDropReport>>(
                      stream: _source(
                        'reports',
                        widget.dropReports ??
                            () => _blueprintRepository.watchRecentReports(
                              limit: 300,
                            ),
                      ),
                      builder: (context, reportSnapshot) {
                        final reports = _retain(
                          'reports',
                          reportSnapshot,
                          const <ArcBlueprintDropReport>[],
                        );
                        return StreamBuilder<List<ArcCommunityIntelReport>>(
                          stream: _source(
                            'community:$_mapId',
                            () =>
                                widget.communityReports?.call(_mapId) ??
                                _communityIntelRepository.watchMapReports(
                                  _mapId,
                                ),
                          ),
                          builder: (context, communitySnapshot) {
                            final communityReports = _retain(
                              'community:$_mapId',
                              communitySnapshot,
                              const <ArcCommunityIntelReport>[],
                            );
                            return StreamBuilder<List<ArcAdminMapMarker>>(
                              stream: _source(
                                'admin:$_mapId',
                                () =>
                                    widget.publishedMarkers?.call(_mapId) ??
                                    _adminMapRepository.watchPublishedMap(
                                      _mapId,
                                    ),
                              ),
                              builder: (context, adminSnapshot) {
                                final adminMarkers = _retain(
                                  'admin:$_mapId',
                                  adminSnapshot,
                                  const <ArcAdminMapMarker>[],
                                );
                                final snapshots = <AsyncSnapshot<dynamic>>[
                                  scrappySnapshot,
                                  progressionSnapshot,
                                  blueprintSnapshot,
                                  loadoutSnapshot,
                                  reportSnapshot,
                                  communitySnapshot,
                                  adminSnapshot,
                                ];
                                final failed =
                                    snapshots.any(
                                      (snapshot) => snapshot.hasError,
                                    ) ||
                                    _lastData['routeError'] == true;
                                final loading = snapshots.any(
                                  (snapshot) =>
                                      snapshot.connectionState ==
                                      ConnectionState.waiting,
                                );
                                final intelligence = _engine.build(
                                  mapId: _mapId,
                                  blueprintStates: states,
                                  favouriteLoadout: loadout,
                                  scrappyStates: scrappyStates,
                                  progressionRecords: progressionRecords,
                                  dropReports: reports,
                                  communityReports: communityReports,
                                  adminMarkers: adminMarkers,
                                  filters: _filters,
                                  activeLayer: _activeLayer,
                                  activeRoute: _routePlan,
                                );
                                final snapshot = _regionalConditions;
                                final profile = _traderProfile;
                                final recommendation =
                                    snapshot == null || profile == null
                                    ? null
                                    : _autoRecommendationEngine.recommend(
                                        snapshot: snapshot,
                                        availability: _savedAvailability,
                                        profile: profile,
                                        nomadicTraderTracker:
                                            _nomadicTraderTracker,
                                        blueprintStates: states,
                                        favouriteLoadout: loadout,
                                        trackedObjectives:
                                            intelligence.trackedObjectives,
                                      );
                                return Column(
                                  children: [
                                    if (showWorkspaceBar) ...[
                                      const SizedBox(height: 8),
                                      const ArcIntelligenceWorkspaceBar(
                                        current:
                                            ArcIntelligenceWorkspace.raidMap,
                                      ),
                                    ],
                                    if (failed || loading)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              failed
                                                  ? 'Some intel is unavailable. Showing saved information and route guidance.'
                                                  : 'Loading raid intel...',
                                              maxLines: 2,
                                            ),
                                          ),
                                          if (failed)
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _streams.clear();
                                                  _lastData.remove(
                                                    'routeError',
                                                  );
                                                });
                                                unawaited(_initialiseScreen());
                                              },
                                              child: const Text('Retry'),
                                            ),
                                        ],
                                      ),
                                    Expanded(
                                      child: _buildLayout(
                                        intelligence,
                                        autoRecommendation: recommendation,
                                        communityReports: communityReports,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLayout(
    ArcRaidIntelligenceState intelligence, {
    required ArcRaidAutoRecommendation? autoRecommendation,
    required List<ArcCommunityIntelReport> communityReports,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        final compactLandscape =
            constraints.maxWidth >= 680 &&
            constraints.maxWidth > constraints.maxHeight * 1.25;
        final sideBySide = desktop || compactLandscape;
        final panel = _controlPanel(
          intelligence,
          desktop: sideBySide,
          autoRecommendation: autoRecommendation,
          communityReports: communityReports,
        );
        final map = _mapPanel(intelligence);
        if (sideBySide) {
          final expandedPanelWidth = desktop
              ? 390.0
              : math.min(340.0, constraints.maxWidth * 0.40);
          return Padding(
            padding: EdgeInsets.all(desktop ? 14 : 10),
            child: Row(
              children: [
                Expanded(flex: desktop ? 7 : 6, child: map),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: AppTheme.fastAnimation,
                  curve: Curves.easeOutCubic,
                  width: _controlPanelCollapsed ? 52 : expandedPanelWidth,
                  child: _controlPanelCollapsed
                      ? _collapsedControlRail()
                      : panel,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Positioned.fill(child: map),
              if (!_controlPanelCollapsed)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: constraints.maxHeight * 0.62,
                  child: panel,
                ),
            ],
          ),
        );
      },
    );
  }

  ArcRaidIntelligenceState _playerFacingMapState(
    ArcRaidIntelligenceState intelligence,
  ) {
    if (_showExplorerMarkers) return intelligence;
    final routeCategories = <ArcRaidMapMarkerCategory>{
      ArcRaidMapMarkerCategory.spawn,
      ArcRaidMapMarkerCategory.standardExtraction,
      ArcRaidMapMarkerCategory.raiderHatch,
      ArcRaidMapMarkerCategory.routeWaypoint,
      ArcRaidMapMarkerCategory.currentPosition,
    };
    final routeMarkers = _routePlan == null
        ? const <ArcRaidMapMarker>[]
        : intelligence.visibleMarkers
              .where((marker) => routeCategories.contains(marker.category))
              .toList(growable: false);
    return ArcRaidIntelligenceState(
      map: intelligence.map,
      activeLayer: intelligence.activeLayer,
      filters: intelligence.filters,
      visibleMarkers: routeMarkers,
      opportunityClusters: intelligence.opportunityClusters,
      routePlan: intelligence.routePlan,
      activeConditionLabel: intelligence.activeConditionLabel,
      statusLabel: intelligence.statusLabel,
      recommendation: intelligence.recommendation,
      trackedObjectives: intelligence.trackedObjectives,
    );
  }

  Widget _mapPanel(ArcRaidIntelligenceState intelligence) {
    return Container(
      key: const Key('raid-map-viewport'),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        radius: ArcUiTokens.radiusXL,
        backgroundColor: ArcUiTokens.background.withValues(alpha: 0.42),
        borderOpacity: 0.24,
        glow: true,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ArcRaidIntelligenceMapRenderer(
                state: _playerFacingMapState(intelligence),
                playerFacingLabels: true,
                controller: _mapController,
                selectedMarkerId: _selectedMarker?.id,
                onMarkerSelected: _selectMarker,
                onMapTapped: _setFreeformSpawn,
                onIntelReportRequested: (point) =>
                    _openCommunityIntelReport(intelligence.map, point),
              ),
            ),
          ),
          if (!_showExplorerMarkers && _routePlan == null)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: ArcUiTokens.surfaceDecoration(
                    role: ArcSurfaceRole.overlay,
                    accent: ArcUiTokens.primaryAccent,
                    radius: ArcUiTokens.radiusM,
                    borderOpacity: 0.24,
                  ),
                  child: Text(
                    'Clean map mode â€¢ choose your spawn, raid time and extraction, then generate a run. UAG will only reveal intel that matters to that route.',
                    textAlign: TextAlign.center,
                    style: ArcUiTokens.bodySmall(
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(right: 8, top: 8, child: _mapControls(intelligence)),
          if (intelligence.map.availableLayers.length > 1)
            Positioned(
              left: 8,
              top: 56,
              right: 8,
              child: Align(
                alignment: Alignment.topCenter,
                child: _layerSelector(intelligence.map),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapControls(ArcRaidIntelligenceState intelligence) {
    return Row(
      key: const Key('map-zoom-controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _mapButton(Icons.add_rounded, 'Zoom in', () => _scaleMap(1.22)),
        _mapButton(Icons.remove_rounded, 'Zoom out', () => _scaleMap(0.82)),
        _mapButton(Icons.center_focus_strong_rounded, 'Fit map', _resetMap),
      ],
    );
  }

  Widget _secondaryMapControls(ArcRaidIntelligenceState intelligence) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _mapButton(
          Icons.add_location_alt_rounded,
          'Report Intel at map centre',
          () => _openCommunityIntelReport(
            intelligence.map,
            const ArcNormalizedPoint(x: 0.5, y: 0.5),
          ),
        ),
        _mapButton(
          Icons.my_location_rounded,
          'Jump to spawn',
          _spawn == null ? null : () => _jumpTo(_spawn!.point),
        ),
        _mapButton(
          Icons.exit_to_app_rounded,
          'Jump to extraction',
          _extraction == null ? null : () => _jumpTo(_extraction!.point),
        ),
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
      key: const Key('map-layer-selector'),
      padding: const EdgeInsets.all(4),
      decoration: ArcUiTokens.chipDecoration(
        color: ArcUiTokens.primaryAccent,
        selected: true,
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
                selectedColor: ArcUiTokens.primaryAccent.withValues(
                  alpha: 0.22,
                ),
                backgroundColor: ArcUiTokens.surfaceInteractive.withValues(
                  alpha: 0.82,
                ),
                labelStyle: ArcUiTokens.label(
                  color: layer == _activeLayer
                      ? ArcUiTokens.primaryAccent
                      : ArcUiTokens.textSecondary,
                ),
                side: BorderSide(
                  color:
                      (layer == _activeLayer
                              ? ArcUiTokens.primaryAccent
                              : ArcUiTokens.borderSubtle)
                          .withValues(alpha: 0.62),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                ),
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
        color: ArcUiTokens.primaryAccent,
        style: IconButton.styleFrom(
          backgroundColor: ArcUiTokens.surfaceOverlay.withValues(alpha: 0.84),
          disabledForegroundColor: ArcUiTokens.textDisabled,
        ),
      ),
    );
  }

  Widget _controlPanel(
    ArcRaidIntelligenceState intelligence, {
    required bool desktop,
    required ArcRaidAutoRecommendation? autoRecommendation,
    required List<ArcCommunityIntelReport> communityReports,
  }) {
    return Container(
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.secondaryAccent,
        radius: desktop ? ArcUiTokens.radiusXL : ArcUiTokens.radiusL,
        backgroundColor: ArcUiTokens.surfaceOverlay,
        borderOpacity: 0.22,
      ),
      child: ListView(
        controller: _panelScroll,
        padding: const EdgeInsets.all(14),
        children: [
          ...[
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'Collapse map controls',
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      setState(() => _controlPanelCollapsed = true),
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: ArcUiTokens.primaryAccent,
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
          if (_selectedMarker != null) ...[
            _selectedMarkerSection(intelligence),
            const SizedBox(height: 10),
          ],
          _secondaryMapControls(intelligence),
          _hero(intelligence),
          if (autoRecommendation != null) ...[
            const SizedBox(height: 10),
            _autoRecommendationCard(autoRecommendation),
          ],
          const SizedBox(height: 10),
          ArcLiveMapConditionsStrip(
            mapDisplayName: intelligence.map.displayName,
            compact: true,
          ),
          const SizedBox(height: 10),
          _raidAccordion(
            title: 'RAID SETUP',
            subtitle: 'Map, spawn, extraction and objective-led run',
            icon: Icons.tune_rounded,
            accent: ArcUiTokens.primaryAccent,
            initiallyExpanded: true,
            child: _setupSection(intelligence),
          ),
          const SizedBox(height: 8),
          _raidAccordion(
            title: 'INTEL FILTERS',
            subtitle: 'Objectives, intel type and quality',
            icon: Icons.filter_alt_rounded,
            accent: ArcUiTokens.secondaryAccent,
            child: _filterSection(),
          ),
          const SizedBox(height: 8),
          _raidAccordion(
            title: 'COMMUNITY INTEL',
            subtitle: '${communityReports.length} reports on this map',
            icon: Icons.radar_rounded,
            accent: ArcUiTokens.secondaryAccent,
            child: _communityIntelSection(intelligence.map, communityReports),
          ),
          const SizedBox(height: 8),
          _raidAccordion(
            title: 'ROUTE PLAN',
            subtitle: intelligence.routePlan == null
                ? _objectiveOnlyStops.isEmpty
                      ? 'No route generated yet'
                      : 'Objective stop order ready'
                : 'Active run ready',
            icon: Icons.route_rounded,
            accent: ArcUiTokens.secondaryAccent,
            child: _routeSection(intelligence),
          ),
        ],
      ),
    );
  }

  Widget _raidAccordion({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: accent,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.22,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Icon(icon, color: accent, size: 19),
          iconColor: accent,
          collapsedIconColor: ArcUiTokens.textSecondary,
          title: Text(
            title,
            style: ArcUiTokens.sectionTitle(fontSize: 18, color: accent),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _collapsedControlRail() {
    return Container(
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        radius: ArcUiTokens.radiusL,
        backgroundColor: ArcUiTokens.surfaceOverlay,
        borderOpacity: 0.24,
      ),
      child: Center(
        child: Tooltip(
          message: 'Expand map controls',
          child: IconButton(
            onPressed: () => setState(() => _controlPanelCollapsed = false),
            icon: const Icon(Icons.chevron_left_rounded),
            color: ArcUiTokens.primaryAccent,
          ),
        ),
      ),
    );
  }

  Widget _autoRecommendationCard(ArcRaidAutoRecommendation recommendation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: Colors.amberAccent,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED RAID - ${recommendation.statusLabel}',
            style: ArcUiTokens.label(color: Colors.amberAccent),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.mapName,
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${recommendation.conditionName} - ${recommendation.targetLabel}',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.live
                ? 'Official condition is live now and falls inside your saved play window.'
                : 'Best upcoming official condition inside your saved play window.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: ArcUiTokens.textButtonStyle(primary: true),
            onPressed: () async {
              if (recommendation.mapId != _mapId) {
                await _changeMap(recommendation.mapId);
              }
              if (!mounted) return;
              setState(() => _controlPanelCollapsed = false);
            },
            icon: const Icon(Icons.radar_rounded),
            label: const Text('USE RECOMMENDED RAID'),
          ),
        ],
      ),
    );
  }

  Widget _hero(ArcRaidIntelligenceState intelligence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENERATE SMART RAID RUN',
          style: ArcUiTokens.sectionTitle(
            fontSize: 24,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${intelligence.map.displayName} - ${intelligence.statusLabel} - ${intelligence.activeConditionLabel}',
          style: ArcUiTokens.bodySmall(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill(
              '${intelligence.opportunityClusters.length} smart stops',
              ArcUiTokens.secondaryAccent,
            ),
            _pill(
              '${intelligence.trackedObjectives.length} tracker goals',
              Colors.lightGreenAccent,
            ),
            _pill(
              '${intelligence.visibleMarkers.length} markers',
              ArcUiTokens.primaryAccent,
            ),
            _pill(
              intelligence.map.hasCalibratedLayer(intelligence.activeLayer)
                  ? 'Map available'
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
            isExpanded: true,
            dropdownColor: ArcUiTokens.surfaceOverlay,
            style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
            iconEnabledColor: ArcUiTokens.primaryAccent,
            decoration: ArcUiTokens.inputDecoration(labelText: 'Map'),
            items: [
              for (final map in ArcRaidIntelligenceSeedData.maps)
                DropdownMenuItem(
                  value: map.id,
                  child: Text(map.displayName, overflow: TextOverflow.ellipsis),
                ),
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
            label: (value) {
              final budget = ArcRaidTimeBudget.forStage(value);
              return '${budget.label} Â· ~${budget.totalMinutes}m';
            },
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
              style: TextStyle(color: ArcUiTokens.textPrimary),
            ),
            subtitle: const Text(
              'Requires player-confirmed hatch key.',
              style: TextStyle(color: ArcUiTokens.textTertiary),
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
                style: TextStyle(color: ArcUiTokens.textPrimary),
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ArcUiTokens.textButtonStyle(primary: true),
            onPressed: () => _generateRoute(intelligence),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('BUILD MY RAID'),
          ),
        ],
      ),
    );
  }

  List<ArcRaidRouteStop> _extractionOptions(ArcRaidMap map) => _usesHatch
      ? map.hatches.map(_engine.stopFromHatch).toList()
      : map.extractions.map(_engine.stopFromExtraction).toList();

  Widget _spawnExtractionPickers(ArcRaidMap map) {
    return Column(
      children: [
        ArcRaidLocationPicker(
          label: 'Spawn Region or tap map',
          options: [
            ...map.spawnRegions.map(_engine.stopFromSpawn),
            if (_spawn?.id == 'freeform_spawn') _spawn!,
          ],
          selected: _spawn,
          onChanged: (spawn) {
            setState(() => _spawn = spawn);
            _jumpTo(spawn.point);
          },
        ),
        const SizedBox(height: 10),
        ArcRaidLocationPicker(
          label: _usesHatch ? 'Raider Hatch' : 'Standard Extraction',
          options: _extractionOptions(map),
          selected: _extraction,
          onChanged: (extraction) {
            setState(() => _extraction = extraction);
            _jumpTo(extraction.point);
          },
        ),
      ],
    );
  }

  Widget _filterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _showExplorerMarkers,
          onChanged: (value) => setState(() {
            _showExplorerMarkers = value;
            if (!value) _selectedMarker = null;
          }),
          title: const Text(
            'Explore all intel markers',
            style: TextStyle(color: ArcUiTokens.textPrimary),
          ),
          subtitle: const Text(
            'Off keeps the map clean and only shows your generated run. Turn on for manual map exploration.',
            style: TextStyle(color: ArcUiTokens.textTertiary),
          ),
        ),
        if (_showExplorerMarkers) ...[
          const SizedBox(height: 6),
          _section(
            title: 'Map Layers',
            child: ArcMapMarkerFilterPanel(
              filters: _filters,
              searchController: _searchController,
              onChanged: (filters) {
                setState(() {
                  _filters = filters;
                  if (_selectedMarker != null &&
                      !_filters.allows(_selectedMarker!)) {
                    _selectedMarker = null;
                  }
                });
              },
            ),
          ),
        ],
      ],
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
            style: ArcUiTokens.bodySmall(),
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
                  backgroundColor: ArcUiTokens.primaryAccent.withValues(
                    alpha: 0.16,
                  ),
                  child: Text(report.confirmationCount.toString()),
                ),
                title: Text(
                  report.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.body(
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${report.confidence.label} - ${report.layer.label}',
                  style: ArcUiTokens.bodySmall(),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Confirm this Intel',
                      onPressed: () =>
                          unawaited(_confirmCommunityIntel(report.id)),
                      icon: const Icon(Icons.verified_outlined),
                    ),
                    IconButton(
                      tooltip: 'Dispute this Intel',
                      onPressed: () =>
                          unawaited(_disputeCommunityIntel(report.id)),
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ],
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
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ArcUiTokens.radiusXL),
        ),
      ),
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm Intel. Try again.')),
      );
    }
  }

  Future<void> _disputeCommunityIntel(String reportId) async {
    try {
      await _communityIntelRepository.dispute(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Intel disputed.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dispute Intel. Try again.')),
      );
    }
  }

  Widget _selectedMarkerSection(ArcRaidIntelligenceState intelligence) {
    final marker = _selectedMarker;
    final stack = marker == null
        ? const <ArcRaidMapMarker>[]
        : _stackResolver.stackFor(
            selected: marker,
            markers: intelligence.visibleMarkers,
          );
    return _section(
      title: 'Selected Intel',
      child: marker == null
          ? Text(
              'Select a marker or Blueprint Opportunity cluster.',
              style: ArcUiTokens.bodySmall(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.isBlueprintOpportunity)
                  ArcSelectedBlueprintIntel(
                    marker: marker,
                    clusters: intelligence.opportunityClusters,
                    map: intelligence.map,
                    onCentreMap: () => _jumpTo(marker.point),
                    onAddStop: _addClusterStop,
                    onOpenBlueprint: () => Navigator.of(
                      context,
                    ).pushNamed(BlueprintGridScreen.routeName),
                    onOpenRaidPlanner: () => Navigator.of(
                      context,
                    ).pushNamed(RaidPlannerScreen.routeName),
                  )
                else
                  ArcMapMarkerDetailCard(
                    marker: marker,
                    footer: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _smallButton(
                          'Centre Map',
                          Icons.center_focus_strong_rounded,
                          () => _jumpTo(marker.point),
                        ),
                        _smallButton(
                          'Open Raid Planner',
                          Icons.playlist_add_rounded,
                          () => Navigator.of(
                            context,
                          ).pushNamed(RaidPlannerScreen.routeName),
                        ),
                      ],
                    ),
                  ),
                if (stack.length > 1) ...[
                  const SizedBox(height: 10),
                  _stackedMarkerList(stack),
                ],
              ],
            ),
    );
  }

  Widget _stackedMarkerList(List<ArcRaidMapMarker> stack) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: ArcUiTokens.primaryAccent,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stack.length} MARKERS AT THIS LOCATION',
            style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
          ),
          const SizedBox(height: 8),
          for (final marker in stack)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                marker.id == _selectedMarker?.id
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: marker.id == _selectedMarker?.id
                    ? ArcUiTokens.primaryAccent
                    : ArcUiTokens.textTertiary,
              ),
              title: Text(
                marker.label,
                style: ArcUiTokens.body(
                  color: ArcUiTokens.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                marker.category.label,
                style: ArcUiTokens.bodySmall(),
              ),
              trailing: IconButton(
                tooltip: 'View this marker',
                onPressed: () => _selectMarker(marker),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              onTap: () => _selectMarker(marker),
            ),
        ],
      ),
    );
  }

  Widget _routeSection(ArcRaidIntelligenceState intelligence) {
    final route = intelligence.routePlan;
    return _section(
      title: 'Route',
      child: route == null
          ? _objectiveOnlyStops.isEmpty
                ? Text(
                    _usesHatch && !_hatchKeyConfirmed
                        ? 'Confirm Raider Hatch Key before generating a hatch route.'
                        : 'Choose a spawn. UAG can select the best extraction automatically.',
                    style: ArcUiTokens.bodySmall(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No synced extraction is required to start planning. These are the highest-value objective stops from your selected spawn. Add/sync an extraction later to calculate the complete run.',
                        style: ArcUiTokens.bodySmall(),
                      ),
                      const SizedBox(height: 8),
                      for (
                        var index = 0;
                        index < _objectiveOnlyStops.length;
                        index++
                      )
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.neonCyan.withValues(
                              alpha: 0.16,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: ArcUiTokens.body(
                                color: ArcUiTokens.textPrimary,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            _objectiveOnlyStops[index].label,
                            style: ArcUiTokens.body(
                              color: ArcUiTokens.textPrimary,
                              weight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            _objectiveOnlyStops[index].hasTrackedObjectives
                                ? _objectiveOnlyStops[index].objectiveSummary
                                : _objectiveOnlyStops[index].cautiousSummary,
                            style: ArcUiTokens.bodySmall(),
                          ),
                          onTap: () =>
                              _jumpTo(_objectiveOnlyStops[index].point),
                        ),
                    ],
                  )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.summary, style: ArcUiTokens.body()),
                if (_routeAlternatives.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _routeAlternativesPanel(route),
                ],
                if (route.metrics.hasData) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        route.metrics.routeBudgetMinutes > 0
                            ? '${route.metrics.estimatedMinutes}/${route.metrics.routeBudgetMinutes} min route'
                            : '${route.metrics.estimatedMinutes} min',
                        route.metrics.fitsTimeBudget
                            ? AppTheme.neonCyan
                            : Colors.redAccent,
                      ),
                      if (route.metrics.extractionReserveMinutes > 0)
                        _pill(
                          '${route.metrics.extractionReserveMinutes} min extract reserve',
                          Colors.amberAccent,
                        ),
                      if (route.metrics.bufferMinutes > 0)
                        _pill(
                          '+${route.metrics.bufferMinutes} min buffer',
                          Colors.lightGreenAccent,
                        ),
                      if (route.metrics.objectiveTargetCount > 0)
                        _pill(
                          '${route.metrics.objectiveTargetCount} tracker goals',
                          Colors.lightGreenAccent,
                        ),
                      if (route.metrics.blueprintTargetCount > 0)
                        _pill(
                          '${route.metrics.blueprintTargetCount} Blueprints',
                          ArcUiTokens.secondaryAccent,
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
                        style: ArcUiTokens.body(
                          color: ArcUiTokens.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      stop.label,
                      style: ArcUiTokens.body(
                        color: ArcUiTokens.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(stop.reason, style: ArcUiTokens.bodySmall()),
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
                      setState(() {
                        _routePlan = null;
                        _routeAlternatives = const <ArcRaidRoutePlan>[];
                      });
                      _showSnack('Active route archived.');
                    }),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _routeAlternativesPanel(ArcRaidRoutePlan activeRoute) {
    final tier = _generatedRouteTier;
    final accent = tier == UagSubscriptionTier.premium
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent;
    final message = switch (tier) {
      UagSubscriptionTier.free =>
        'Free gives you one complete recommended run. Essential adds a second viable strategy; Premium compares every viable route style.',
      UagSubscriptionTier.essential =>
        'Essential gives you two viable run strategies. Premium unlocks every viable Fast, Balanced, Thorough and Safer route.',
      UagSubscriptionTier.premium =>
        'Premium intelligence: every viable route style found for this raid is available below.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        radius: ArcUiTokens.radiusM,
        accent: accent,
        borderOpacity: 0.32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tier.label.toUpperCase()} ROUTE INTELLIGENCE',
            style: ArcUiTokens.label(color: accent),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final option in _routeAlternatives)
                ChoiceChip(
                  selected: option.routeStyle == activeRoute.routeStyle,
                  label: Text(
                    '${option.routeStyle.label} Â· ${option.metrics.estimatedMinutes}m Â· ${option.metrics.efficiencyScore}%',
                  ),
                  onSelected: (_) => _selectRouteAlternative(option),
                  selectedColor: accent.withValues(alpha: 0.20),
                  backgroundColor: ArcUiTokens.surfaceRaised,
                  side: BorderSide(
                    color: option.routeStyle == activeRoute.routeStyle
                        ? accent.withValues(alpha: 0.72)
                        : ArcUiTokens.textTertiary.withValues(alpha: 0.25),
                  ),
                  labelStyle: ArcUiTokens.bodySmall(
                    color: option.routeStyle == activeRoute.routeStyle
                        ? ArcUiTokens.textPrimary
                        : ArcUiTokens.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(message, style: ArcUiTokens.bodySmall()),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusL,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: ArcUiTokens.sectionTitle(
              fontSize: 15,
              color: ArcUiTokens.secondaryAccent,
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
            showCheckmark: false,
            selectedColor: ArcUiTokens.primaryAccent.withValues(alpha: 0.18),
            backgroundColor: ArcUiTokens.surfaceInteractive.withValues(
              alpha: 0.74,
            ),
            side: BorderSide(
              color:
                  (value == selected
                          ? ArcUiTokens.primaryAccent
                          : ArcUiTokens.borderSubtle)
                      .withValues(alpha: 0.62),
            ),
            labelStyle: ArcUiTokens.label(
              color: value == selected
                  ? ArcUiTokens.primaryAccent
                  : ArcUiTokens.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
            ),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(label, style: ArcUiTokens.label(color: color)),
    );
  }

  Widget _smallButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: ArcUiTokens.textButtonStyle(),
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
    if (extraction != null) {
      final current = _extractionOptions(
        intelligence.map,
      ).where((option) => option.id == extraction!.id);
      if (current.isEmpty) {
        _showSnack(
          'Saved extraction is unavailable. Choose another extraction.',
        );
        return;
      }
      extraction = current.first;
    }
    if (spawn != null &&
        spawn.id != 'freeform_spawn' &&
        !intelligence.map.spawnRegions.any((option) => option.id == spawn.id)) {
      _showSnack(
        'Saved spawn is unavailable. Choose a spawn region or tap the map.',
      );
      return;
    }
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
      final objectiveStops = _engine.orderObjectiveStops(
        map: intelligence.map,
        clusters: intelligence.opportunityClusters,
        spawn: spawn,
        routeStyle: _routeStyle,
        raidStage: _raidStage,
      );
      if (objectiveStops.isEmpty) {
        _showSnack('No current objective stops are available for this map.');
        return;
      }
      final allowed = await UagUsageGate.consumeOrShowUpgrade(
        context,
        action: UagBillableAction.premiumIntelUnlock,
      );
      if (!allowed || !mounted) return;
      setState(() {
        _routePlan = null;
        _routeAlternatives = const <ArcRaidRoutePlan>[];
        _generatedRouteTier = UagSubscriptionTier.free;
        _objectiveOnlyStops = objectiveStops;
      });
      _showSnack(
        'Objective stop order ready. Sync/select an extraction when available to complete the run.',
      );
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
    final allowed = await UagUsageGate.consumeOrShowUpgrade(
      context,
      action: UagBillableAction.premiumIntelUnlock,
    );
    if (!allowed || !mounted) return;
    var generatedTier = UagSubscriptionTier.free;
    try {
      generatedTier =
          (await _entitlementService.getMyEntitlement()).effectiveTier;
    } catch (_) {
      generatedTier = UagSubscriptionTier.free;
    }
    if (!mounted) return;
    final alternatives = _buildTierRouteAlternatives(
      intelligence: intelligence,
      spawn: spawn,
      extraction: resolvedExtraction,
      primary: route,
      tier: generatedTier,
    );
    setState(() {
      _routePlan = route;
      _routeAlternatives = alternatives;
      _generatedRouteTier = generatedTier;
      _objectiveOnlyStops = const <ArcRaidIntelCluster>[];
    });
    if (await _saveActiveRoute(route)) {
      _showSnack('Smart Raid Run generated and saved as active route.');
    } else {
      _showSnack('Smart Raid Run generated locally; route save failed.');
    }
  }

  List<ArcRaidRoutePlan> _buildTierRouteAlternatives({
    required ArcRaidIntelligenceState intelligence,
    required ArcRaidRouteStop spawn,
    required ArcRaidRouteStop extraction,
    required ArcRaidRoutePlan primary,
    required UagSubscriptionTier tier,
  }) {
    if (tier == UagSubscriptionTier.free) {
      return <ArcRaidRoutePlan>[primary];
    }

    final candidates = <ArcRaidRoutePlan>[primary];
    for (final style in ArcRaidRouteStyle.values) {
      if (style == primary.routeStyle) continue;
      final candidate = _engine.generateRoute(
        map: intelligence.map,
        clusters: intelligence.opportunityClusters,
        spawn: spawn,
        extraction: extraction,
        routeStyle: style,
        raidStage: _raidStage,
        squadMode: _squadMode,
        objectivePriority: _objectivePriority,
        usesRaiderHatch: _usesHatch,
        hatchKeyConfirmed: _hatchKeyConfirmed,
      );
      if (candidate == null || !candidate.metrics.fitsTimeBudget) continue;
      candidates.add(candidate);
    }

    if (tier == UagSubscriptionTier.premium) {
      return candidates;
    }

    if (candidates.length <= 2) return candidates;
    final secondary = candidates.skip(1).toList(growable: false)
      ..sort((a, b) {
        final efficiency = b.metrics.efficiencyScore.compareTo(
          a.metrics.efficiencyScore,
        );
        if (efficiency != 0) return efficiency;
        return a.metrics.estimatedMinutes.compareTo(b.metrics.estimatedMinutes);
      });
    return <ArcRaidRoutePlan>[primary, secondary.first];
  }

  Future<void> _selectRouteAlternative(ArcRaidRoutePlan route) async {
    if (identical(_routePlan, route)) return;
    setState(() => _routePlan = route);
    final saved = await _saveActiveRoute(route);
    if (!mounted) return;
    _showSnack(
      saved
          ? '${route.routeStyle.label} route selected and saved.'
          : '${route.routeStyle.label} route selected locally; save failed.',
    );
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
