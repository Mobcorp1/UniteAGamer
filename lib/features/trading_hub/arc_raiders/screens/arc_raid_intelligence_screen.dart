import '../data/arc_raid_endpoint_resolver.dart';
import '../data/arc_quest_map_binding.dart';
import '../data/arc_raid_time_budget.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_usage_gate.dart';
import '../widgets/arc_raid_location_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_preview_screen.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_launch_map_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_stack_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_view_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_auto_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_nomadic_trader_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
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
    this.availabilityLoader,
    this.nomadicTraderTrackerLoader,
    this.profileLoader,
    this.regionalConditionsLoader,
    this.initialMapId,
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
  final Future<ArcAvailability> Function()? availabilityLoader;
  final Future<ArcNomadicTraderTrackerSnapshot> Function()?
  nomadicTraderTrackerLoader;
  final Future<ArcTraderProfile> Function()? profileLoader;
  final Future<ArcRegionalMapConditionsSnapshot> Function()?
  regionalConditionsLoader;

  /// Explicit launch intent from Command Centre / recommendation routing.
  ///
  /// When null, Raid Intelligence preserves its normal remembered-map behaviour.
  final String? initialMapId;

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
  late final ArcNomadicTraderRepository _nomadicTraderRepository =
      const ArcNomadicTraderRepository();
  late final ArcTraderProfileRepository _profileRepository =
      ArcTraderProfileRepository();
  final ArcMapViewRepository _mapViewRepository = const ArcMapViewRepository();
  final TransformationController _mapController = TransformationController();
  final TextEditingController _searchController = TextEditingController();

  late final String? _explicitInitialMapId;
  String _mapId = ArcMapAssetRegistry.blueGateMapId;
  ArcRaidMapLayer _activeLayer = ArcRaidMapLayer.surface;
  ArcRaidMapFilterState _filters = ArcRaidMapFilterState.defaults;
  ArcRaidSquadMode _squadMode = ArcRaidSquadMode.solo;
  ArcRaidRouteStyle _routeStyle = ArcRaidRouteStyle.balanced;
  ArcRaidObjectivePriority _objectivePriority =
      ArcRaidObjectivePriority.myNeedsFirst;
  String _raidStage = 'Full';
  static const _timeBudget = ArcRaidTimeBudget();
  final _remainingController = TextEditingController(text: '30');
  int? _remainingMinutes = 30;
  ArcRaidEndpoints? _endpoints;
  bool _endpointsReady = false;
  bool _extractionConfirmed = false;
  bool _showAdvancedMarkers = false;
  String? _endpointNotice;
  ArcRaidRouteStop? _spawn;
  ArcRaidRouteStop? _extraction;
  bool _usesHatch = false;
  bool _hatchKeyConfirmed = false;
  ArcRaidRoutePlan? _routePlan;
  List<ArcRaidIntelCluster> _objectiveOnlyStops = const <ArcRaidIntelCluster>[];
  ArcRaidMapMarker? _selectedMarker;
  Timer? _mapViewSaveTimer;
  bool _restoringMapView = false;
  bool _controlPanelCollapsed = true;
  ArcAvailability _availability = ArcAvailability.initial();
  ArcNomadicTraderTrackerSnapshot _nomadicTraderTracker =
      ArcNomadicTraderTrackerSnapshot.empty;
  ArcTraderProfile _profile = ArcTraderProfile.empty('');
  ArcRegionalMapConditionsSnapshot? _regionalConditions;
  ArcRaidAutoRecommendation? _autoRecommendation;
  String? _goalRecommendedMapId;
  String? _recommendationSignature;
  bool _recommendationContextLoaded = false;
  bool _mapManuallySelected = false;
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
    _explicitInitialMapId = ArcRaidLaunchMapPolicy.canonicalExplicitMapId(
      widget.initialMapId,
    );
    if (_explicitInitialMapId != null) {
      _mapId = _explicitInitialMapId;
    }
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
    _remainingController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveRoute() async {
    final route =
        await (widget.loadActiveRoute?.call() ??
            _routeRepository.loadActiveRoute());
    if (!mounted || route == null) return;
    if (!ArcRaidLaunchMapPolicy.routeCanApply(
      explicitMapId: _explicitInitialMapId,
      routeMapId: route.mapId,
    )) {
      return;
    }
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
      _activeLayer = route.layer;
      _remainingMinutes =
          route.remainingMinutes ?? _timeBudget.preset(route.raidStage);
      _remainingController.text = '$_remainingMinutes';
      _extractionConfirmed = true;
      _spawn = route.spawn;
      _extraction = route.extraction;
      _usesHatch = route.usesRaiderHatch;
      _hatchKeyConfirmed = route.hatchKeyConfirmed;
      _routePlan = route;
    });
  }

  Future<void> _initialiseScreen() async {
    try {
      await _loadActiveRoute();
    } catch (_) {
      if (mounted) setState(() => _lastData['routeError'] = true);
    }
    if (!ArcRaidLaunchMapPolicy.shouldRestoreLastMap(
      explicitMapId: _explicitInitialMapId,
    )) {
      await _restoreLayerView(
        mapId: _explicitInitialMapId!,
        layer: _activeLayer,
      );
      return;
    }
    await _restoreLastMapView();
    unawaited(_loadRecommendationContext());
  }

  Future<void> _loadRecommendationContext() async {
    var availability = _availability;
    var trader = _nomadicTraderTracker;
    var profile = _profile;
    ArcRegionalMapConditionsSnapshot? regional;

    try {
      availability =
          await (widget.availabilityLoader?.call() ??
              _profileRepository.getAvailability());
    } catch (_) {}
    try {
      trader =
          await (widget.nomadicTraderTrackerLoader?.call() ??
              _nomadicTraderRepository.loadTrackerSnapshot());
    } catch (_) {}
    try {
      profile =
          await (widget.profileLoader?.call() ??
              _profileRepository.getProfile());
    } catch (_) {}
    try {
      regional =
          await (widget.regionalConditionsLoader?.call() ??
              ArcRegionalMapConditionsService.load());
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _availability = availability;
      _nomadicTraderTracker = trader;
      _profile = profile;
      _regionalConditions = regional;
      _recommendationContextLoaded = true;
    });
  }

  void _scheduleAutoRecommendation(
    Map<String, ArcBlueprintState> states,
    List<ArcRaidObjective> trackedObjectives,
    ArcSavedLoadout? favouriteLoadout,
    List<ArcBlueprintDropReport> reports,
  ) {
    if (!_recommendationContextLoaded) return;
    final snapshot = _regionalConditions;
    final next = snapshot == null
        ? null
        : _autoRecommendationEngine.recommend(
            snapshot: snapshot,
            availability: _availability,
            profile: _profile,
            nomadicTraderTracker: _nomadicTraderTracker,
            blueprintStates: states,
            favouriteLoadout: favouriteLoadout,
            trackedObjectives: trackedObjectives,
          );
    final goalMapId = next == null
        ? _bestGoalMap(
            states: states,
            favouriteLoadout: favouriteLoadout,
            trackedObjectives: trackedObjectives,
            reports: reports,
          )
        : null;
    final signature = next?.signature ?? 'goal:${goalMapId ?? 'none'}';
    if (_recommendationSignature == signature) return;
    _recommendationSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _autoRecommendation = next;
        _goalRecommendedMapId = goalMapId;
      });
      final recommendedMapId = next?.mapId ?? goalMapId;
      if (recommendedMapId != null &&
          _routePlan == null &&
          _spawn == null &&
          _extraction == null &&
          _selectedMarker == null &&
          !_mapManuallySelected &&
          recommendedMapId != _mapId) {
        unawaited(_changeMap(recommendedMapId, fromRecommendation: true));
      }
    });
  }

  String? _bestGoalMap({
    required Map<String, ArcBlueprintState> states,
    required ArcSavedLoadout? favouriteLoadout,
    required List<ArcRaidObjective> trackedObjectives,
    required List<ArcBlueprintDropReport> reports,
  }) {
    String? bestMapId;
    var bestScore = 0.0;
    for (final map in ArcRaidIntelligenceSeedData.maps) {
      var questMapScore = 0.0;
      for (final objective in trackedObjectives) {
        final questId = objective.questId;
        if (questId == null ||
            !ArcQuestMapBinding.questSupportsMap(questId, map.id)) {
          continue;
        }
        questMapScore += objective.questLocationOnly ? 180 : 35;
      }

      final clusters = _engine.opportunityClusters(
        map: map,
        blueprintStates: states,
        favouriteLoadout: favouriteLoadout,
        dropReports: reports,
        trackedObjectives: trackedObjectives,
      );
      if (clusters.isEmpty && questMapScore <= 0) continue;
      final scores =
          clusters
              .map((cluster) {
                var score =
                    cluster.objectiveScore +
                    (cluster.objectiveCount * 80) +
                    (cluster.blueprintIds.length * 35);
                for (final blueprintId in cluster.blueprintIds) {
                  if (states[blueprintId]?.isPrioritized == true) score += 120;
                }
                return score;
              })
              .toList(growable: false)
            ..sort((left, right) => right.compareTo(left));
      final score =
          questMapScore +
          scores.take(5).fold<double>(0, (total, value) => total + value);
      if (score > bestScore) {
        bestScore = score;
        bestMapId = map.id;
      }
    }
    return bestMapId;
  }

  Future<void> _restoreLastMapView() async {
    if (_routePlan != null) {
      await _restoreLayerView(mapId: _mapId, layer: _routePlan!.layer);
      return;
    }
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

  Future<void> _changeMap(
    String mapId, {
    bool fromRecommendation = false,
  }) async {
    final canonicalMapId =
        ArcMapAssetRegistry.canonicalMapIdFor(mapId) ?? mapId;
    final nextMap = ArcRaidIntelligenceSeedData.mapById(canonicalMapId);
    final nextLayer = nextMap.availableLayers.contains(ArcRaidMapLayer.surface)
        ? ArcRaidMapLayer.surface
        : (nextMap.availableLayers.isEmpty
              ? ArcRaidMapLayer.surface
              : nextMap.availableLayers.first);
    setState(() {
      if (!fromRecommendation) _mapManuallySelected = true;
      _mapId = canonicalMapId;
      _activeLayer = nextLayer;
      _spawn = null;
      _extraction = null;
      _extractionConfirmed = false;
      _endpointsReady = false;
      _endpointNotice = null;
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
            tooltip: 'Open Collections Tracker',
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
                                _endpointsReady =
                                    adminSnapshot.hasData &&
                                    !adminSnapshot.hasError &&
                                    adminSnapshot.connectionState !=
                                        ConnectionState.waiting;
                                _endpoints = const ArcRaidEndpointResolver()
                                    .resolve(
                                      seedMap:
                                          ArcRaidIntelligenceSeedData.mapById(
                                            _mapId,
                                          ),
                                      layer: _activeLayer,
                                      markers: adminMarkers,
                                    );
                                if (_endpointsReady) _reconcileEndpoints();
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
                                  nomadicTraderTracker: _nomadicTraderTracker,
                                  scrappyStates: scrappyStates,
                                  progressionRecords: progressionRecords,
                                  dropReports: reports,
                                  communityReports: communityReports,
                                  adminMarkers: adminMarkers,
                                  filters: _filters,
                                  activeLayer: _activeLayer,
                                  activeRoute: _routePlan,
                                );
                                _scheduleAutoRecommendation(
                                  states,
                                  intelligence.trackedObjectives,
                                  loadout,
                                  reports,
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
                state: _endpointMapState(intelligence),
                playerFacingLabels: true,
                controller: _mapController,
                selectedMarkerId: _selectedMarker?.id,
                highlightedMarkerIds: {
                  if (_spawn != null) 'endpoint_spawn_${_spawn!.id}',
                  if (_extraction != null) 'endpoint_exit_${_extraction!.id}',
                },
                onMarkerSelected: (marker) =>
                    _selectEndpointMarker(marker, intelligence),
                onMapTapped: (point) => _setFreeformSpawn(point, intelligence),
                onIntelReportRequested: (point) =>
                    _openCommunityIntelReport(intelligence.map, point),
              ),
            ),
          ),
          Positioned(right: 8, top: 8, child: _mapControls(intelligence)),
          Positioned(left: 8, bottom: 8, child: _blueprintIntelNotice()),
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

  Widget _blueprintIntelNotice() {
    return Tooltip(
      message:
          'Blueprint locations are known or reported spawn areas. Drops are not guaranteed; the route is designed to improve your chances.',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: ArcUiTokens.chipDecoration(
          color: ArcUiTokens.primaryAccent,
          selected: true,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: ArcUiTokens.primaryAccent,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Blueprint intel improves your odds - drops are not guaranteed.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
              ),
            ),
          ],
        ),
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
      _spawn = null;
      _extraction = null;
      _extractionConfirmed = false;
      _routePlan = null;
      _objectiveOnlyStops = const [];
      _endpointNotice = 'Choose endpoints on this layer.';
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

  Widget _hero(ArcRaidIntelligenceState intelligence) {
    final recommendation = _mapManuallySelected ? null : _autoRecommendation;
    final goalMapId = _mapManuallySelected ? null : _goalRecommendedMapId;
    final goalMap = goalMapId == null
        ? null
        : ArcRaidIntelligenceSeedData.mapById(goalMapId);
    final route = intelligence.routePlan;
    final mapLabel = recommendation != null
        ? '${recommendation.mapName} - ${recommendation.conditionName}'
        : goalMap != null
        ? '${goalMap.displayName} - BEST FIT'
        : intelligence.map.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDED RAID',
          style: ArcUiTokens.sectionTitle(
            fontSize: 24,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mapLabel,
          style: ArcUiTokens.body(
            color: ArcUiTokens.textPrimary,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          route == null
              ? 'Choose raid length, mark your spawn and confirm the exfil. UAG will build the run.'
              : 'Route ready. Follow the lettered stops to extraction.',
          style: ArcUiTokens.bodySmall(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pill('$_raidStage raid', ArcUiTokens.secondaryAccent),
            if (recommendation != null)
              _pill(
                recommendation.statusLabel,
                recommendation.live
                    ? Colors.lightGreenAccent
                    : Colors.amberAccent,
              )
            else if (goalMap != null)
              _pill('BEST FIT', Colors.lightGreenAccent),
            if (route != null)
              _pill(
                '${route.stops.length} route stops',
                ArcUiTokens.primaryAccent,
              ),
          ],
        ),
      ],
    );
  }

  Widget _setupSection(ArcRaidIntelligenceState intelligence) {
    final recommendation = _mapManuallySelected ? null : _autoRecommendation;
    final goalMapId = _mapManuallySelected ? null : _goalRecommendedMapId;
    final goalMap = goalMapId == null
        ? null
        : ArcRaidIntelligenceSeedData.mapById(goalMapId);
    return _section(
      title: 'Recommended Raid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommendation != null || goalMap != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.interactive,
                accent: ArcUiTokens.primaryAccent,
                borderOpacity: 0.22,
                radius: ArcUiTokens.radiusM,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: ArcUiTokens.primaryAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation != null
                          ? '${recommendation.statusLabel}: ${recommendation.mapName} - ${recommendation.conditionName}'
                          : 'BEST FIT: ${goalMap!.displayName}',
                      style: ArcUiTokens.body(
                        color: ArcUiTokens.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'TIME REMAINING',
            style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 6),
          _chips<String>(
            values: const ['Full', 'Mid', 'Late'],
            selected: _raidStage,
            label: (value) => value,
            onSelected: (value) => setState(() {
              _raidStage = value;
              _remainingMinutes = _timeBudget.preset(value);
              _remainingController.text = '$_remainingMinutes';
              _routePlan = null;
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remainingController,
            key: const Key('raid-remaining-minutes'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minutes remaining',
              helperText:
                  'Use the in-game timer. Presets are planning estimates.',
              errorText: _remainingMinutes == null
                  ? 'Enter a positive number of minutes'
                  : null,
            ),
            onChanged: (value) => setState(() {
              final minutes = int.tryParse(value);
              _remainingMinutes = minutes != null && minutes > 0
                  ? minutes
                  : null;
              _routePlan = null;
            }),
          ),
          if (_endpointNotice != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _endpointNotice!,
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'PLAYER SPAWN / PLANNED EXTRACTION',
            style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 6),
          _spawnExtractionPickers(intelligence),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ArcUiTokens.textButtonStyle(primary: true),
              onPressed: !_endpointsReady || _remainingMinutes == null
                  ? null
                  : () => _generateRoute(intelligence),
              icon: const Icon(Icons.route_rounded),
              label: const Text('BUILD MY RAID'),
            ),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Advanced options',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _mapId,
                isExpanded: true,
                dropdownColor: ArcUiTokens.surfaceOverlay,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                iconEnabledColor: ArcUiTokens.primaryAccent,
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'Map override',
                ),
                items: [
                  for (final map in ArcRaidIntelligenceSeedData.maps)
                    DropdownMenuItem(
                      value: map.id,
                      child: Text(
                        map.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                onSelected: (value) =>
                    setState(() => _objectivePriority = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _usesHatch,
                onChanged: (value) => setState(() {
                  _usesHatch = value;
                  _hatchKeyConfirmed = false;
                  _extraction = null;
                  _extractionConfirmed = false;
                  _routePlan = null;
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
            ],
          ),
        ],
      ),
    );
  }

  List<ArcRaidRouteStop> _extractionOptions(ArcRaidMap map) =>
      (_usesHatch ? _endpoints?.hatches : _endpoints?.extractions) ?? const [];

  Widget _spawnExtractionPickers(ArcRaidIntelligenceState intelligence) {
    return Column(
      children: [
        ArcRaidLocationPicker(
          label: 'Player Spawn',
          options: [
            ...?_endpoints?.spawns,
            if (_spawn?.id == 'freeform_spawn' &&
                _endpoints?.authoritativeSpawns != true)
              _spawn!,
          ],
          selected: _spawn,
          onChanged: (spawn) {
            _setSpawnAndRecommendExtraction(spawn, intelligence);
            _jumpTo(spawn.point);
          },
        ),
        const SizedBox(height: 10),
        ArcRaidLocationPicker(
          label: _usesHatch ? 'Planned Raider Hatch' : 'Planned Extraction',
          options: _extractionOptions(intelligence.map),
          selected: _extraction,
          onChanged: (extraction) {
            setState(() {
              _extraction = extraction;
              _extractionConfirmed = true;
              _routePlan = null;
              _endpointNotice = null;
            });
            _jumpTo(extraction.point);
          },
        ),
        if (_extraction != null && !_extractionConfirmed)
          TextButton(
            onPressed: () => setState(() => _extractionConfirmed = true),
            child: Text(
              'Confirm recommended extraction: ${_extraction!.label}',
            ),
          ),
        if (_extraction != null && _extractionConfirmed)
          const Text('Extraction confirmed'),
      ],
    );
  }

  void _reconcileEndpoints() {
    final endpoints = _endpoints;
    if (endpoints == null) return;

    final currentSpawn = _spawn;
    final currentExit = _extraction;

    bool changed(ArcRaidRouteStop? old, ArcRaidRouteStop? current) =>
        old?.id != current?.id ||
        old?.point.x != current?.point.x ||
        old?.point.y != current?.point.y ||
        old?.label != current?.label;

    final resolvedSpawn = currentSpawn == null
        ? null
        : endpoints.resolveSpawn(currentSpawn);
    final resolvedExit = currentExit == null
        ? null
        : endpoints.resolveExtraction(currentExit, hatch: _usesHatch);

    if (!changed(currentSpawn, resolvedSpawn) &&
        !changed(currentExit, resolvedExit)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_endpointsReady) return;

      final latest = _endpoints;
      if (latest == null) return;

      // Re-read the CURRENT selections here. A rebuild between scheduling this
      // callback and executing it may legitimately replace route-stop objects
      // with equivalent instances. Object identity must never cancel endpoint
      // invalidation.
      final currentSpawn = _spawn;
      final currentExit = _extraction;
      final latestSpawn = currentSpawn == null
          ? null
          : latest.resolveSpawn(currentSpawn);
      final latestExit = currentExit == null
          ? null
          : latest.resolveExtraction(currentExit, hatch: _usesHatch);

      if (!changed(currentSpawn, latestSpawn) &&
          !changed(currentExit, latestExit)) {
        return;
      }

      final lostSpawn = currentSpawn != null && latestSpawn == null;
      final lostExit = currentExit != null && latestExit == null;

      setState(() {
        _spawn = latestSpawn;
        _extraction = latestExit;

        if (lostSpawn || lostExit) {
          _endpointNotice =
              'A saved endpoint is no longer published on this map/layer. Choose again.';
          _routePlan = null;
          _extractionConfirmed = false;
          _objectiveOnlyStops = const [];
        } else if (_routePlan != null &&
            latestSpawn != null &&
            latestExit != null) {
          _routePlan = _routePlan!.copyWith(
            spawn: latestSpawn.copyWith(order: 0),
            extraction: latestExit.copyWith(
              order: _routePlan!.stops.length + 1,
            ),
          );
        }
      });
    });
  }

  void _selectEndpointMarker(
    ArcRaidMapMarker marker,
    ArcRaidIntelligenceState intelligence,
  ) {
    if (!_endpointsReady) {
      if (!marker.id.startsWith('endpoint_')) _selectMarker(marker);
      return;
    }
    for (final spawn in _endpoints?.spawns ?? <ArcRaidRouteStop>[]) {
      if (marker.id == 'endpoint_spawn_${spawn.id}') {
        _setSpawnAndRecommendExtraction(spawn, intelligence);
        return;
      }
    }
    for (final exit in _extractionOptions(intelligence.map)) {
      if (marker.id == 'endpoint_exit_${exit.id}') {
        setState(() {
          _controlPanelCollapsed = false;
          _extraction = exit;
          _extractionConfirmed = true;
          _routePlan = null;
          _endpointNotice = null;
        });
        return;
      }
    }
    _selectMarker(marker);
  }

  ArcRaidIntelligenceState _endpointMapState(ArcRaidIntelligenceState state) {
    final endpointCategories = {
      ArcRaidMapMarkerCategory.spawn,
      ArcRaidMapMarkerCategory.spawnRegion,
      ArcRaidMapMarkerCategory.standardExtraction,
      ArcRaidMapMarkerCategory.raiderHatch,
    };
    final visible = state.visibleMarkers
        .where(
          (m) =>
              !endpointCategories.contains(m.category) &&
              (_routePlan == null ||
                  _showAdvancedMarkers ||
                  m.category == ArcRaidMapMarkerCategory.routeWaypoint),
        )
        .toList();
    void add(ArcRaidRouteStop stop, bool spawn) => visible.add(
      ArcRaidMapMarker(
        id: 'endpoint_${spawn ? 'spawn' : 'exit'}_${stop.id}',
        mapId: _mapId,
        layer: _activeLayer,
        label: stop.label,
        point: stop.point,
        payloadId: stop.id,
        category: spawn
            ? ArcRaidMapMarkerCategory.spawn
            : _usesHatch
            ? ArcRaidMapMarkerCategory.raiderHatch
            : ArcRaidMapMarkerCategory.standardExtraction,
        approximate: spawn
            ? _endpoints?.authoritativeSpawns != true
            : !_usesHatch && _endpoints?.authoritativeExtractions != true,
      ),
    );
    for (final spawn in _endpoints?.spawns ?? <ArcRaidRouteStop>[]) {
      if (_routePlan == null ||
          _showAdvancedMarkers ||
          spawn.id == _spawn?.id) {
        add(spawn, true);
      }
    }
    if (_spawn?.id == 'freeform_spawn') add(_spawn!, true);
    for (final exit in _extractionOptions(state.map)) {
      if (_routePlan == null ||
          _showAdvancedMarkers ||
          exit.id == _extraction?.id) {
        add(exit, false);
      }
    }
    return ArcRaidIntelligenceState(
      map: state.map,
      activeLayer: state.activeLayer,
      filters: state.filters,
      visibleMarkers: visible,
      opportunityClusters: state.opportunityClusters,
      routePlan: state.routePlan,
      activeConditionLabel: state.activeConditionLabel,
      statusLabel: state.statusLabel,
      recommendation: state.recommendation,
      trackedObjectives: state.trackedObjectives,
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
            _showAdvancedMarkers = true;
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
                        'Best available stops from your spawn. Confirm an exfil to complete the route.',
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
                              _routeLetter(index),
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
                Text(
                  '${route.mapName} - ${route.raidStage} raid${route.remainingMinutes != null
                      ? ' - ${route.remainingMinutes} min remaining'
                      : route.metrics.estimatedMinutes > 0
                      ? ' - about ${route.metrics.estimatedMinutes} min (estimate)'
                      : ''}',
                  style: ArcUiTokens.body(
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
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
                        _routeLetter(stop.order - 1),
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

  String _routeLetter(int order) {
    final safe = order.clamp(0, 25).toInt();
    return String.fromCharCode(65 + safe);
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

  void _setFreeformSpawn(
    ArcNormalizedPoint point,
    ArcRaidIntelligenceState intelligence,
  ) {
    if (!_endpointsReady || _endpoints?.authoritativeSpawns == true) {
      _showSnack('Choose a published Player Spawn marker or use the selector.');
      return;
    }
    final spawn = ArcRaidRouteStop(
      id: 'freeform_spawn',
      label: 'Approximate Spawn',
      point: point,
      order: 0,
      reason: 'Approximate spawn tapped by player; no GPS used.',
    );
    _setSpawnAndRecommendExtraction(spawn, intelligence);
  }

  void _setSpawnAndRecommendExtraction(
    ArcRaidRouteStop spawn,
    ArcRaidIntelligenceState intelligence,
  ) {
    final extraction =
        _extraction ??
        _engine.recommendExtraction(
          endpoints: _extractionOptions(intelligence.map),
          map: intelligence.map,
          spawn: spawn,
          clusters: intelligence.opportunityClusters,
          usesRaiderHatch: _usesHatch,
        );
    setState(() {
      _spawn = spawn;
      _controlPanelCollapsed = false;
      if (_extraction == null) _extractionConfirmed = false;
      _extraction = extraction;
      _endpointNotice = null;
      _routePlan = null;
      _objectiveOnlyStops = const <ArcRaidIntelCluster>[];
    });
  }

  Future<void> _generateRoute(ArcRaidIntelligenceState intelligence) async {
    if (!_endpointsReady || _remainingMinutes == null) {
      _showSnack('Wait for live endpoints and enter the time remaining.');
      return;
    }
    final savedSpawn = _spawn;
    final spawn = savedSpawn == null
        ? null
        : _endpoints!.resolveSpawn(savedSpawn);
    if (spawn == null) {
      _showSnack('Choose an available Player Spawn first.');
      return;
    }
    final savedExit = _extraction;
    final resolvedExtraction = savedExit == null
        ? null
        : _endpoints!.resolveExtraction(savedExit, hatch: _usesHatch);
    if (resolvedExtraction == null) {
      _showSnack('Choose your planned extraction.');
      return;
    }
    if (!_extractionConfirmed) {
      _showSnack('Confirm the recommended extraction, or choose another one.');
      return;
    }
    final route = _engine.generateRoute(
      map: intelligence.map,
      clusters: intelligence.opportunityClusters,
      spawn: spawn,
      extraction: resolvedExtraction,
      remainingMinutes: _remainingMinutes,
      layer: _activeLayer,
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
    final latestSpawn = _endpoints?.resolveSpawn(spawn);
    final latestExit = _endpoints?.resolveExtraction(
      resolvedExtraction,
      hatch: _usesHatch,
    );
    if (!_endpointsReady ||
        _spawn?.id != savedSpawn?.id ||
        _extraction?.id != savedExit?.id ||
        _mapId != route.mapId ||
        _activeLayer != route.layer ||
        _remainingMinutes != route.remainingMinutes ||
        latestSpawn?.point.x != spawn.point.x ||
        latestSpawn?.point.y != spawn.point.y ||
        latestExit?.point.x != resolvedExtraction.point.x ||
        latestExit?.point.y != resolvedExtraction.point.y) {
      _showSnack(
        'Raid endpoints changed. Review your choices before building again.',
      );
      return;
    }
    setState(() {
      _routePlan = route;
      _objectiveOnlyStops = const <ArcRaidIntelCluster>[];
    });
    if (await _saveActiveRoute(route)) {
      _showSnack('Smart Raid Run generated and saved as active route.');
    } else {
      _showSnack('Smart Raid Run generated locally; route save failed.');
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
