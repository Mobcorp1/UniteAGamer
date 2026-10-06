import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_map_backend.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_trade_value_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_research_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_cluster_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_objective_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_runtime_map_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_world_intel_population_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcRaidIntelligenceEngine {
  const ArcRaidIntelligenceEngine();

  ArcRaidIntelligenceState build({
    required String mapId,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    ArcSavedLoadout? favouriteLoadout,
    ArcOperationsUserState operationsState = ArcOperationsUserState.empty,
    Map<String, ArcScrappyState> scrappyStates =
        const <String, ArcScrappyState>{},
    ArcProgressionRecords progressionRecords = ArcProgressionRecords.empty,
    ArcNomadicTraderTrackerSnapshot nomadicTraderTracker =
        ArcNomadicTraderTrackerSnapshot.empty,
    List<ArcBlueprintDropReport> dropReports = const <ArcBlueprintDropReport>[],
    List<ArcCommunityIntelReport> communityReports =
        const <ArcCommunityIntelReport>[],
    List<ArcAdminMapMarker> adminMarkers = const <ArcAdminMapMarker>[],
    ArcRaidMapFilterState filters = ArcRaidMapFilterState.defaults,
    ArcRaidMapLayer activeLayer = ArcRaidMapLayer.surface,
    ArcRaidRoutePlan? activeRoute,
  }) {
    final seedMap = ArcRaidIntelligenceSeedData.mapById(mapId);
    final map = const ArcRaidRuntimeMapResolver().resolve(
      seedMap: seedMap,
      adminMarkers: adminMarkers,
    );
    final worldIntel = const ArcWorldIntelPopulationEngine().build(
      maps: <ArcRaidMap>[map],
      dropReports: dropReports,
      communityReports: communityReports,
      adminMarkers: adminMarkers,
    );
    final resolvedLayer = map.availableLayers.contains(activeLayer)
        ? activeLayer
        : (map.availableLayers.isEmpty
              ? ArcRaidMapLayer.surface
              : map.availableLayers.first);
    final progression = const ArcProgressionEngine().build(
      scrappyStates: scrappyStates,
      records: progressionRecords,
    );
    final trackedObjectives = const ArcRaidObjectiveIntelligenceEngine()
        .trackedObjectives(
          progression: progression,
          scrappyStates: scrappyStates,
          nomadicTraderTracker: nomadicTraderTracker,
        );
    final clusters = opportunityClusters(
      map: map,
      blueprintStates: blueprintStates,
      favouriteLoadout: favouriteLoadout,
      operationsState: operationsState,
      dropReports: dropReports,
      canonicalMarkers: adminMarkers,
      trackedObjectives: trackedObjectives,
    );
    final clusterMarkers = clusters
        .map((cluster) => _markerForCluster(cluster, blueprintStates))
        .toList();
    final routeMarkers =
        activeRoute?.orderedStops
            .map(
              (stop) => ArcRaidMapMarker(
                id: 'route_${activeRoute.id}_${stop.id}',
                mapId: map.id,
                category: stop.order == 0
                    ? ArcRaidMapMarkerCategory.spawn
                    : stop.order == activeRoute.orderedStops.length - 1
                    ? activeRoute.usesRaiderHatch
                          ? ArcRaidMapMarkerCategory.raiderHatch
                          : ArcRaidMapMarkerCategory.standardExtraction
                    : ArcRaidMapMarkerCategory.routeWaypoint,
                label: '${stop.order + 1}. ${stop.label}',
                point: stop.point,
                payloadId: stop.id,
                confidence: ArcRaidIntelConfidence.moderate,
                approximate: true,
              ),
            )
            .toList(growable: false) ??
        const <ArcRaidMapMarker>[];
    final communityMarkers = communityReports
        .where((report) => report.mapId == map.id && report.active)
        .map(_markerForCommunityReport)
        .toList(growable: false);
    final importedMarkers = adminMarkers
        .where((marker) => marker.mapId == map.id && marker.isLive)
        .map(_markerForAdminMarker)
        .toList(growable: false);
    final worldMarkers = worldIntel.liveMarkers
        .where((marker) => marker.mapId == map.id)
        .map(_markerForAdminMarker)
        .toList(growable: false);
    final rawVisibleMarkers =
        _dedupeMarkers([
              ...map.markers,
              ...worldMarkers,
              ...importedMarkers,
              ...clusterMarkers,
              ...communityMarkers,
              ...routeMarkers,
            ])
            .where((marker) => marker.layer == resolvedLayer)
            .where(filters.allows)
            .toList(growable: false)
          ..sort(_markerSort);
    final visibleMarkers = const ArcMapMarkerClusterEngine().cluster(
      rawVisibleMarkers,
    )..sort(_markerSort);
    final blueprintTargetCount = clusters
        .expand((cluster) => cluster.blueprintIds)
        .toSet()
        .length;
    final objectiveTargetCount = trackedObjectives.length;
    final mappedObjectiveCount = clusters
        .expand((cluster) => cluster.objectives)
        .map((objective) => objective.id)
        .toSet()
        .length;
    final status = activeRoute != null
        ? 'Route ready'
        : clusters.isEmpty && objectiveTargetCount > 0
        ? 'Tracker goals need location intel'
        : clusters.isEmpty
        ? 'No current priority'
        : 'Generate a smart run';
    return ArcRaidIntelligenceState(
      map: map,
      activeLayer: resolvedLayer,
      filters: filters,
      visibleMarkers: visibleMarkers,
      opportunityClusters: clusters,
      routePlan: activeRoute,
      activeConditionLabel: _activeConditionLabel(clusters),
      statusLabel: status,
      recommendation: clusters.isEmpty && objectiveTargetCount > 0
          ? '$objectiveTargetCount tracked ${_plural(objectiveTargetCount, 'goal', 'goals')} detected, but none can be mapped confidently to ${map.displayName} yet. Add verified POI/resource intel or choose another map.'
          : clusters.isEmpty
          ? 'No current tracked objectives or evidence-backed Blueprint opportunities on ${map.displayName}.'
          : 'Generate a Smart Raid Run using ${clusters.length} relevant ${_plural(clusters.length, 'stop', 'stops')} for $mappedObjectiveCount mapped of $objectiveTargetCount tracked ${_plural(objectiveTargetCount, 'goal', 'goals')} and $blueprintTargetCount Blueprint ${_plural(blueprintTargetCount, 'target', 'targets')}.',
      trackedObjectives: trackedObjectives,
    );
  }

  ArcRaidMapMarker _markerForCommunityReport(ArcCommunityIntelReport report) {
    final verification = report.verificationState;
    final category = verification == ArcCommunityIntelVerificationState.expired
        ? ArcRaidMapMarkerCategory.staleIntel
        : verification == ArcCommunityIntelVerificationState.disputed
        ? ArcRaidMapMarkerCategory.staleIntel
        : verification == ArcCommunityIntelVerificationState.communityVerified
        ? ArcRaidMapMarkerCategory.confirmedIntel
        : report.confirmationCount >= 2
        ? ArcRaidMapMarkerCategory.researchedIntel
        : ArcRaidMapMarkerCategory.communityIntel;
    final tags = <String>[
      report.category.label,
      if (report.poiName?.trim().isNotEmpty == true) report.poiName!.trim(),
      if (report.blueprintName?.trim().isNotEmpty == true)
        report.blueprintName!.trim(),
      '${report.confirmationCount} ${_plural(report.confirmationCount, 'confirmation', 'confirmations')}',
      '${report.disputeCount} ${_plural(report.disputeCount, 'dispute', 'disputes')}',
      verification.label,
    ];
    return ArcRaidMapMarker(
      id: 'community_${report.id}',
      mapId: report.mapId,
      category: category,
      label: report.displayLabel,
      point: report.point,
      layer: report.layer,
      payloadId: report.id,
      confidence: report.confidence,
      approximate: false,
      count: report.confirmationCount,
      detail: report.notes.trim().isEmpty
          ? 'Community-submitted Intel.'
          : report.notes.trim(),
      tags: tags,
    );
  }

  ArcRaidMapMarker _markerForAdminMarker(ArcAdminMapMarker marker) {
    final category = _categoryForAdminMarker(marker);
    final resource = marker.upgradeResource;
    final tags = <String>[
      marker.effectiveKind.label,
      if (resource != null) resource.usageLabel,
      if (marker.subtypeLabel?.trim().isNotEmpty == true)
        marker.subtypeLabel!.trim(),
      marker.confidence.label,
      if (marker.evidence.isNotEmpty)
        '${marker.evidence.length} evidence ${_plural(marker.evidence.length, 'record', 'records')}',
      if (marker.provisionalVisible) 'Provisional',
      if (marker.adminVerified) 'Verified location',
      if (marker.hasBlueprintRoutingMetadata) marker.blueprintIntelType.label,
      if (marker.effectiveBlueprintContainerFamily !=
          ArcBlueprintContainerFamily.unknown)
        marker.effectiveBlueprintContainerFamily.label,
      if (marker.effectiveBlueprintLootTier != ArcBlueprintLootTier.standard)
        marker.effectiveBlueprintLootTier.label,
      if (marker.blueprintContainerDensity > 0)
        'Container density ${marker.blueprintContainerDensity}/5',
      for (final condition in marker.blueprintConditionIds)
        _conditionDisplayLabel(condition),
    ];
    // Older published records contain generated provenance in their description.
    // Keep that metadata in storage/admin tools, not in the player marker card.
    final description = marker.description
        .replaceAll(
          RegExp(
            r'(?:Source basis|Coordinate status):[^.]*\.',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll('UAG-generated ', '')
        .replaceAll('Linked to a UAG POI anchor.', 'Approximate location.')
        .replaceAll(
          'Location requires admin matching before publication.',
          'Exact location unconfirmed.',
        )
        .trim();
    final containsInternalId = RegExp(
      r'\badmin_[a-zA-Z0-9_-]+|\b[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\b',
    ).hasMatch(description);
    final detail = description.isEmpty || containsInternalId
        ? '${marker.effectiveKind.label} location.'
        : description;
    final iconKey = ArcMapFilterIconRegistry.iconKeyForAdminMarker(marker);

    return ArcRaidMapMarker(
      id: 'admin_${marker.id}',
      mapId: marker.mapId,
      category: category,
      label: marker.name,
      point: marker.point,
      layer: marker.layer,
      payloadId: marker.id,
      confidence: marker.confidence,
      approximate: !marker.adminVerified,
      count: math.max(1, marker.resolvedEvidenceCount),
      detail: resource == null
          ? _mapMarkerDetail(marker, detail)
          : '${_mapMarkerDetail(marker, detail)}\n${resource.usageDetails}',
      iconKey: iconKey,
      tags: tags,
      blueprintIds: marker.blueprintId == null
          ? const <String>[]
          : <String>[marker.blueprintId!],
      prioritizedBlueprintIds: marker.blueprintId == null
          ? const <String>[]
          : <String>[marker.blueprintId!],
    );
  }

  static String _mapMarkerDetail(ArcAdminMapMarker marker, String baseDetail) {
    if (!marker.hasBlueprintRoutingMetadata) return baseDetail;
    final parts = <String>[baseDetail];
    if (marker.effectiveBlueprintContainerFamily !=
        ArcBlueprintContainerFamily.unknown) {
      parts.add(
        'Blueprint source: ${marker.effectiveBlueprintContainerFamily.label}.',
      );
    }
    if (marker.blueprintContainerDensity > 0) {
      parts.add(
        'Relevant container density: ${marker.blueprintContainerDensity}/5.',
      );
    }
    if (marker.effectiveBlueprintLootTier != ArcBlueprintLootTier.standard) {
      parts.add('${marker.effectiveBlueprintLootTier.label}.');
    }
    if (marker.blueprintConditionIds.isNotEmpty) {
      parts.add(
        'Conditions: ${marker.blueprintConditionIds.map(_conditionDisplayLabel).join(', ')}.',
      );
    }
    if (marker.blueprintFallbackEligible) {
      parts.add('Eligible for probability fallback routing.');
    }
    return parts.join(' ');
  }

  List<ArcRaidIntelCluster> opportunityClusters({
    required ArcRaidMap map,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    ArcSavedLoadout? favouriteLoadout,
    ArcOperationsUserState operationsState = ArcOperationsUserState.empty,
    List<ArcBlueprintDropReport> dropReports = const <ArcBlueprintDropReport>[],
    List<ArcAdminMapMarker> canonicalMarkers = const <ArcAdminMapMarker>[],
    List<ArcRaidObjective> trackedObjectives = const <ArcRaidObjective>[],
  }) {
    final loadoutNames = _loadoutItemNames(favouriteLoadout);
    final mapClusters = <ArcRaidIntelCluster>[];
    final missing = _missingBlueprints(blueprintStates);
    final reportClusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: dropReports,
      blueprintStates: blueprintStates,
      canonicalMarkers: canonicalMarkers,
    );
    final reportBlueprintIds = reportClusters
        .expand((cluster) => cluster.blueprintIds)
        .toSet();
    for (final cluster in reportClusters) {
      mapClusters.add(cluster);
      _clusterScores[cluster.id] =
          120 +
          cluster.confidence.score +
          (cluster.reportCount * 4) +
          (cluster.independentReporterCount * 8);
    }
    for (final blueprint in missing) {
      if (reportBlueprintIds.contains(blueprint.id)) continue;

      final state = blueprintStates[blueprint.id];
      final topWanted = (state?.priorityRank ?? 0) > 0;
      final loadoutRelevant = loadoutNames.contains(
        blueprint.name.trim().toLowerCase(),
      );
      final research = ArcBlueprintResearchCatalog.forBlueprintOnMap(
        blueprint.id,
        map.id,
      );
      final markerMatches = ArcBlueprintMapBackend.matchesForBlueprint(
        blueprint: blueprint,
        mapId: map.id,
        markers: canonicalMarkers,
      );
      final directMarkerMatches = markerMatches
          .where((match) => !match.fallback)
          .toList(growable: false);

      if (directMarkerMatches.isNotEmpty) {
        _appendBlueprintMarkerMatches(
          target: mapClusters,
          matches: directMarkerMatches,
          blueprint: blueprint,
          state: state,
          loadoutRelevant: loadoutRelevant,
          operationsState: operationsState,
          map: map,
        );
        continue;
      }

      if (research != null && research.canAutoRoute) {
        var researchClusterAdded = false;
        for (final site in research.autoRouteSites.take(3)) {
          final resolution = const ArcIntelligenceLocationResolver().resolve(
            map: map,
            adminMarkers: canonicalMarkers,
            canonicalPoiId: site.poiId,
            currentPoiName: site.poiName,
          );
          if (resolution == null || resolution.needsAdminReview) continue;

          final confidence = research.reportedFindCount > 0
              ? ArcRaidIntelConfidence.moderate
              : ArcRaidIntelConfidence.limited;
          final score = _opportunityScore(
            blueprint: blueprint,
            state: state,
            confidence: confidence,
            loadoutRelevant: loadoutRelevant,
            operationsState: operationsState,
          );
          final evidence = ArcRaidIntelEvidence(
            id: '${map.id}_${blueprint.id}_${site.poiId}_research',
            blueprintId: blueprint.id,
            mapId: map.id,
            poiId: site.poiId,
            approximateArea: resolution.label,
            point: resolution.point,
            containerSource: research.container,
            conditionId: research.condition.trim().isEmpty
                ? null
                : research.condition,
            raidStage: 'Full',
            acquisitionSource: 'research_baseline',
            claimSummary:
                '${blueprint.name}: search ${research.container.toLowerCase()} around ${resolution.label}.',
            sourceCategory: 'uag_research_baseline',
            sourceReference: ArcBlueprintResearchCatalog.dataVersion,
            reviewedAt: DateTime.utc(2026, 9, 23),
            direct: false,
            confidence: confidence,
            notes:
                '${research.evidenceSummary}. Candidate POI, not a guaranteed Blueprint spawn.',
          );
          final cluster = ArcRaidIntelCluster(
            id: '${map.id}_${blueprint.id}_${site.poiId}_research_cluster',
            mapId: map.id,
            label: '${blueprint.name} search — ${resolution.label}',
            point: resolution.point,
            layer: resolution.layer,
            poiId: site.poiId,
            blueprintIds: <String>[blueprint.id],
            evidence: <ArcRaidIntelEvidence>[evidence],
            confidence: confidence,
            reportCount: research.reportedFindCount,
            independentReporterCount: 0,
            freshnessLabel: 'Research baseline — 23 Sep 2026',
            commonSource: research.container,
            conditionCorrelation: research.condition.trim().isEmpty
                ? 'Any condition'
                : research.condition,
          );
          mapClusters.add(cluster);
          _clusterScores[cluster.id] = score + (research.reportedFindCount * 8);
          researchClusterAdded = true;
        }

        // A mapped research POI is preferred over a generic high-value fallback,
        // but if legacy POI aliases cannot resolve we can still use map-backend
        // probability markers rather than returning no route at all.
        if (researchClusterAdded) continue;
      }

      final probabilityFallbacks = markerMatches
          .where((match) => match.fallback)
          .toList(growable: false);
      if (probabilityFallbacks.isNotEmpty) {
        _appendBlueprintMarkerMatches(
          target: mapClusters,
          matches: probabilityFallbacks,
          blueprint: blueprint,
          state: state,
          loadoutRelevant: loadoutRelevant,
          operationsState: operationsState,
          map: map,
        );
        continue;
      }

      if (research != null) {
        // Event-only, quest-only and unavailable pools must not silently fall
        // through to a random POI. The catalogue is authoritative here.
        continue;
      }

      // Compatibility fallback for future blueprints that are not yet in the
      // research catalogue. Current baseline records should not reach here.
      final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
      if (!_hintSupportsMap(hint, map)) continue;
      final poi = _poiForBlueprint(map, blueprint);
      final confidence = _confidenceFromHint(hint, topWanted: topWanted);
      final source = hint.likelyContainers.isEmpty
          ? 'Area-level report'
          : hint.likelyContainers.first;
      final conditions = ArcBlueprintIntelLibrary.playableConditions(
        hint.bestConditions,
      );
      final score = _opportunityScore(
        blueprint: blueprint,
        state: state,
        confidence: confidence,
        loadoutRelevant: loadoutRelevant,
        operationsState: operationsState,
      );
      final evidence = ArcRaidIntelEvidence(
        id: '${map.id}_${blueprint.id}_seed',
        blueprintId: blueprint.id,
        mapId: map.id,
        poiId: poi?.id,
        approximateArea: poi?.name,
        point: poi?.point,
        containerSource: source,
        conditionId: conditions.isEmpty ? null : conditions.first,
        raidStage: 'Full',
        acquisitionSource: 'normal_drop',
        claimSummary: hint.tip,
        sourceReference: 'UAG Blueprint Intel seed',
        reviewedAt: DateTime.utc(2026, 7, 23),
        direct: false,
        confidence: confidence,
        notes: 'Area-level opportunity seed; not an exact crate coordinate.',
      );
      mapClusters.add(
        ArcRaidIntelCluster(
          id: '${map.id}_${blueprint.id}_cluster',
          mapId: map.id,
          label: poi == null
              ? '${blueprint.name} opportunity'
              : '${blueprint.name} near ${poi.name}',
          point: poi?.point ?? const ArcNormalizedPoint(x: 0.5, y: 0.5),
          poiId: poi?.id,
          blueprintIds: <String>[blueprint.id],
          evidence: <ArcRaidIntelEvidence>[evidence],
          confidence: confidence,
          reportCount: confidence.score ~/ 18,
          independentReporterCount: confidence.score ~/ 26,
          freshnessLabel: 'Seed reviewed',
          commonSource: source,
          conditionCorrelation: conditions.isEmpty
              ? 'Any condition'
              : conditions.join(', '),
        ),
      );
      _clusterScores[mapClusters.last.id] = score;
    }

    if (trackedObjectives.isNotEmpty) {
      final objectiveClusters = const ArcRaidObjectiveIntelligenceEngine()
          .buildClusters(
            map: map,
            objectives: trackedObjectives,
            adminMarkers: canonicalMarkers,
          );
      _mergeTrackedObjectiveClusters(mapClusters, objectiveClusters);
    }

    mapClusters.sort((a, b) {
      final scoreCompare = (_clusterScores[b.id] ?? 0).compareTo(
        _clusterScores[a.id] ?? 0,
      );
      if (scoreCompare != 0) return scoreCompare;
      return a.label.compareTo(b.label);
    });
    return _mergeNearbyClusters(mapClusters);
  }

  List<ArcRaidIntelCluster> orderObjectiveStops({
    required ArcRaidMap map,
    required List<ArcRaidIntelCluster> clusters,
    required ArcRaidRouteStop spawn,
    ArcRaidRouteStyle routeStyle = ArcRaidRouteStyle.balanced,
    String raidStage = 'Full',
  }) {
    if (clusters.isEmpty) return const <ArcRaidIntelCluster>[];
    final stopLimit = routeStyle.stopLimitForStage(raidStage);
    final remaining = [...clusters]
      ..sort((a, b) {
        final aScore =
            (_clusterScores[a.id] ?? a.confidence.score.toDouble()) -
            (_graphTravelCost(map, spawn.point, a.point) * 2.2);
        final bScore =
            (_clusterScores[b.id] ?? b.confidence.score.toDouble()) -
            (_graphTravelCost(map, spawn.point, b.point) * 2.2);
        final compare = bScore.compareTo(aScore);
        if (compare != 0) return compare;
        return a.label.compareTo(b.label);
      });
    final candidates = remaining.take(math.max(stopLimit * 2, stopLimit));
    final selected = <ArcRaidIntelCluster>[];
    var current = spawn.point;
    final pool = candidates.toList();
    while (pool.isNotEmpty && selected.length < stopLimit) {
      pool.sort((a, b) {
        final aCost = _graphTravelCost(map, current, a.point);
        final bCost = _graphTravelCost(map, current, b.point);
        final compare = aCost.compareTo(bCost);
        if (compare != 0) return compare;
        return (_clusterScores[b.id] ?? 0).compareTo(_clusterScores[a.id] ?? 0);
      });
      final next = pool.removeAt(0);
      selected.add(next);
      current = next.point;
    }
    return List<ArcRaidIntelCluster>.unmodifiable(selected);
  }

  ArcRaidRoutePlan? generateRoute({
    required ArcRaidMap map,
    required List<ArcRaidIntelCluster> clusters,
    required ArcRaidRouteStop spawn,
    required ArcRaidRouteStop extraction,
    ArcRaidRouteStyle routeStyle = ArcRaidRouteStyle.balanced,
    String raidStage = 'Full',
    ArcRaidSquadMode squadMode = ArcRaidSquadMode.solo,
    ArcRaidObjectivePriority objectivePriority =
        ArcRaidObjectivePriority.myNeedsFirst,
    bool usesRaiderHatch = false,
    bool hatchKeyConfirmed = false,
    List<ArcRaidRouteParticipant> participants =
        const <ArcRaidRouteParticipant>[],
  }) {
    if (usesRaiderHatch && !hatchKeyConfirmed) return null;
    if (clusters.isEmpty) return null;

    final stopLimit = routeStyle.stopLimitForStage(raidStage);
    final ranked = [...clusters]
      ..sort((a, b) {
        final aScore = _routeStopScore(
          map: map,
          cluster: a,
          spawn: spawn.point,
          extraction: extraction.point,
          routeStyle: routeStyle,
          objectivePriority: objectivePriority,
          squadMode: squadMode,
          participants: participants,
        );
        final bScore = _routeStopScore(
          map: map,
          cluster: b,
          spawn: spawn.point,
          extraction: extraction.point,
          routeStyle: routeStyle,
          objectivePriority: objectivePriority,
          squadMode: squadMode,
          participants: participants,
        );
        final scoreCompare = bScore.compareTo(aScore);
        if (scoreCompare != 0) return scoreCompare;
        return a.label.compareTo(b.label);
      });

    var selected = ranked.take(stopLimit).toList(growable: true);
    var ordered = _orderClustersForTravel(
      map: map,
      clusters: selected,
      start: spawn.point,
      extraction: extraction.point,
    );
    var metrics = _buildRouteMetrics(
      map: map,
      spawn: spawn,
      extraction: extraction,
      clusters: ordered,
      squadMode: squadMode,
      routeStyle: routeStyle,
      raidStage: raidStage,
      usesRaiderHatch: usesRaiderHatch,
    );

    // Time remaining is a hard route constraint. Remove the lowest-value stop
    // until the run fits the Full/Mid/Late budget, while preserving at least
    // one meaningful objective when evidence exists.
    while (selected.length > 1 && !metrics.fitsTimeBudget) {
      selected.sort((a, b) {
        final aScore = _routeStopScore(
          map: map,
          cluster: a,
          spawn: spawn.point,
          extraction: extraction.point,
          routeStyle: routeStyle,
          objectivePriority: objectivePriority,
          squadMode: squadMode,
          participants: participants,
        );
        final bScore = _routeStopScore(
          map: map,
          cluster: b,
          spawn: spawn.point,
          extraction: extraction.point,
          routeStyle: routeStyle,
          objectivePriority: objectivePriority,
          squadMode: squadMode,
          participants: participants,
        );
        return aScore.compareTo(bScore);
      });
      selected.removeAt(0);
      ordered = _orderClustersForTravel(
        map: map,
        clusters: selected,
        start: spawn.point,
        extraction: extraction.point,
      );
      metrics = _buildRouteMetrics(
        map: map,
        spawn: spawn,
        extraction: extraction,
        clusters: ordered,
        squadMode: squadMode,
        routeStyle: routeStyle,
        raidStage: raidStage,
        usesRaiderHatch: usesRaiderHatch,
      );
    }

    final stops = <ArcRaidRouteStop>[
      for (var index = 0; index < ordered.length; index++)
        ArcRaidRouteStop(
          id: 'stop_${ordered[index].id}',
          label: ordered[index].label,
          point: ordered[index].point,
          order: index + 1,
          clusterId: ordered[index].id,
          blueprintIds: ordered[index].blueprintIds,
          objectiveIds: ordered[index].objectives
              .map((objective) => objective.id)
              .toList(growable: false),
          reason: _routeStopReason(ordered[index]),
        ),
    ];
    return ArcRaidRoutePlan(
      id: 'route_${map.id}_${DateTime.now().millisecondsSinceEpoch}',
      mapId: map.id,
      mapName: map.displayName,
      squadMode: squadMode,
      routeStyle: routeStyle,
      raidStage: raidStage,
      objectivePriority: objectivePriority,
      spawn: spawn.copyWith(order: 0),
      extraction: extraction.copyWith(order: stops.length + 1),
      stops: stops,
      usesRaiderHatch: usesRaiderHatch,
      hatchKeyConfirmed: hatchKeyConfirmed,
      participants: _privacySafeParticipants(participants),
      metrics: metrics,
      score: metrics.efficiencyScore,
      summary:
          '${routeStyle.label} ${squadMode.label} Smart Raid Run: ${metrics.opportunityCount} ${_plural(metrics.opportunityCount, 'stop', 'stops')}, ${metrics.objectiveTargetCount} tracked ${_plural(metrics.objectiveTargetCount, 'goal', 'goals')}, ${metrics.blueprintTargetCount} Blueprint ${_plural(metrics.blueprintTargetCount, 'target', 'targets')}, about ${metrics.estimatedMinutes} min + ${metrics.extractionReserveMinutes} min extraction reserve inside a ${metrics.timeBudgetMinutes} min ${raidStage.toLowerCase()}-raid budget, then ${extraction.label}.',
      approximate: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ArcRaidRouteStop? recommendExtraction({
    required ArcRaidMap map,
    required ArcRaidRouteStop spawn,
    required List<ArcRaidIntelCluster> clusters,
    bool usesRaiderHatch = false,
  }) {
    if (usesRaiderHatch) {
      if (map.hatches.isEmpty) return null;
      final target = clusters.isEmpty ? spawn.point : clusters.first.point;
      final hatch = [...map.hatches]
        ..sort(
          (a, b) =>
              a.point.distanceTo(target).compareTo(b.point.distanceTo(target)),
        );
      return stopFromHatch(hatch.first);
    }
    if (map.extractions.isEmpty) return null;
    final target = clusters.isEmpty
        ? spawn.point
        : ArcNormalizedPoint(
            x:
                clusters.map((item) => item.point.x).reduce((a, b) => a + b) /
                clusters.length,
            y:
                clusters.map((item) => item.point.y).reduce((a, b) => a + b) /
                clusters.length,
          );
    final extractions = [...map.extractions]
      ..sort(
        (a, b) =>
            a.point.distanceTo(target).compareTo(b.point.distanceTo(target)),
      );
    return stopFromExtraction(extractions.first);
  }

  ArcRaidRoutePlan addStop(ArcRaidRoutePlan plan, ArcRaidIntelCluster cluster) {
    final nextStops = [
      ...plan.stops,
      ArcRaidRouteStop(
        id: 'stop_${cluster.id}',
        label: cluster.label,
        point: cluster.point,
        order: plan.stops.length + 1,
        clusterId: cluster.id,
        blueprintIds: cluster.blueprintIds,
        objectiveIds: cluster.objectives
            .map((objective) => objective.id)
            .toList(growable: false),
        reason: _routeStopReason(cluster),
      ),
    ];
    return _renumber(plan.copyWith(stops: nextStops));
  }

  ArcRaidRoutePlan removeStop(ArcRaidRoutePlan plan, String stopId) {
    return _renumber(
      plan.copyWith(
        stops: plan.stops
            .where((stop) => stop.id != stopId)
            .toList(growable: false),
      ),
    );
  }

  ArcRaidRoutePlan markStop(
    ArcRaidRoutePlan plan,
    String stopId,
    ArcRaidRouteStopState state,
  ) {
    return plan.copyWith(
      stops: plan.stops
          .map((stop) => stop.id == stopId ? stop.copyWith(state: state) : stop)
          .toList(growable: false),
    );
  }

  ArcRaidRoutePlan reorderStops(
    ArcRaidRoutePlan plan,
    int oldIndex,
    int newIndex,
  ) {
    final stops = [...plan.stops];
    if (oldIndex < 0 || oldIndex >= stops.length) return plan;
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final stop = stops.removeAt(oldIndex);
    stops.insert(adjustedIndex.clamp(0, stops.length), stop);
    return _renumber(plan.copyWith(stops: stops));
  }

  static List<ArcRaidIntelCluster> _orderClustersForTravel({
    required ArcRaidMap map,
    required List<ArcRaidIntelCluster> clusters,
    required ArcNormalizedPoint start,
    required ArcNormalizedPoint extraction,
  }) {
    final remaining = [...clusters];
    final ordered = <ArcRaidIntelCluster>[];
    var current = start;
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final aCost =
            _graphTravelCost(map, current, a.point) +
            (_graphTravelCost(map, a.point, extraction) * 0.18);
        final bCost =
            _graphTravelCost(map, current, b.point) +
            (_graphTravelCost(map, b.point, extraction) * 0.18);
        final costCompare = aCost.compareTo(bCost);
        if (costCompare != 0) return costCompare;
        return b.confidence.score.compareTo(a.confidence.score);
      });
      final next = remaining.removeAt(0);
      ordered.add(next);
      current = next.point;
    }
    return ordered;
  }

  static ArcRaidRouteMetrics _buildRouteMetrics({
    required ArcRaidMap map,
    required ArcRaidRouteStop spawn,
    required ArcRaidRouteStop extraction,
    required List<ArcRaidIntelCluster> clusters,
    required ArcRaidSquadMode squadMode,
    required ArcRaidRouteStyle routeStyle,
    required String raidStage,
    required bool usesRaiderHatch,
  }) {
    var travelCost = 0.0;
    var current = spawn.point;
    for (final cluster in clusters) {
      travelCost += _graphTravelCost(map, current, cluster.point);
      current = cluster.point;
    }
    travelCost += _graphTravelCost(map, current, extraction.point);

    final blueprintCount = clusters
        .expand((cluster) => cluster.blueprintIds)
        .toSet()
        .length;
    final objectiveCount = clusters
        .expand((cluster) => cluster.objectives)
        .map((objective) => objective.id)
        .toSet()
        .length;
    final averageConfidence = clusters.isEmpty
        ? 0
        : (clusters.fold<int>(
                    0,
                    (total, cluster) => total + cluster.confidence.score,
                  ) /
                  clusters.length)
              .round();
    final paceFactor = switch (routeStyle) {
      ArcRaidRouteStyle.fast => 0.78,
      ArcRaidRouteStyle.balanced => 1.0,
      ArcRaidRouteStyle.thorough => 1.24,
      ArcRaidRouteStyle.safer => 1.14,
    };
    final squadFactor = 1 - ((squadMode.size - 1) * 0.08);
    final estimatedMinutes = math
        .max(
          4,
          ((travelCost * 1.7 + clusters.length * 2.4) *
                  paceFactor *
                  squadFactor)
              .round(),
        )
        .toInt();
    final efficiency =
        ((blueprintCount * 120 + objectiveCount * 84 + averageConfidence * 2) /
                math.max(1.0, travelCost + estimatedMinutes * 0.55))
            .round()
            .clamp(0, 100)
            .toInt();
    final riskLabel = routeStyle == ArcRaidRouteStyle.safer
        ? 'Lower risk'
        : travelCost > 24
        ? 'High exposure'
        : travelCost > 15
        ? 'Moderate exposure'
        : 'Compact route';

    final timeBudget = ArcRaidTimeBudget.forStage(raidStage);
    final extractionReserve = timeBudget.extractionReserveMinutes(
      usesRaiderHatch: usesRaiderHatch,
    );
    final routeBudget = timeBudget.routeMinutes(
      usesRaiderHatch: usesRaiderHatch,
    );

    return ArcRaidRouteMetrics(
      totalDistance: double.parse(travelCost.toStringAsFixed(2)),
      estimatedMinutes: estimatedMinutes,
      opportunityCount: clusters.length,
      blueprintTargetCount: blueprintCount,
      objectiveTargetCount: objectiveCount,
      averageConfidence: averageConfidence,
      efficiencyScore: efficiency,
      riskLabel: riskLabel,
      timeBudgetMinutes: timeBudget.totalMinutes,
      routeBudgetMinutes: routeBudget,
      extractionReserveMinutes: extractionReserve,
      fitsTimeBudget: estimatedMinutes <= routeBudget,
    );
  }

  ArcRaidIntelConfidence confidenceForEvidence({
    required int independentReportCount,
    required Duration age,
    bool coordinateAgreement = false,
    bool sourceAgreement = false,
    bool reputationTrusted = false,
    bool hasEvidence = false,
    bool hasConflicts = false,
    bool adminVerified = false,
  }) {
    if (adminVerified) return ArcRaidIntelConfidence.confirmed;
    var score = 0;
    score += math.min(independentReportCount, 5) * 18;
    if (coordinateAgreement) score += 12;
    if (sourceAgreement) score += 10;
    if (reputationTrusted) score += 8;
    if (hasEvidence) score += 12;
    if (age.inDays <= 7) score += 10;
    if (age.inDays > 45) score -= 18;
    if (hasConflicts) score -= 22;
    if (score >= 82) return ArcRaidIntelConfidence.strong;
    if (score >= 58) return ArcRaidIntelConfidence.moderate;
    if (score >= 28) return ArcRaidIntelConfidence.limited;
    return ArcRaidIntelConfidence.unverified;
  }

  ArcRaidRouteStop stopFromSpawn(ArcRaidSpawnRegion spawn) {
    return ArcRaidRouteStop(
      id: spawn.id,
      label: spawn.name,
      point: spawn.center,
      order: 0,
      markerId: spawn.id,
      reason: 'Approximate spawn selected by player.',
    );
  }

  ArcRaidRouteStop stopFromExtraction(ArcRaidExtraction extraction) {
    return ArcRaidRouteStop(
      id: extraction.id,
      label: extraction.name,
      point: extraction.point,
      order: 999,
      markerId: extraction.id,
      reason:
          'Standard extraction selected by player. Confirm live timer in-game.',
    );
  }

  ArcRaidRouteStop stopFromHatch(ArcRaiderHatch hatch) {
    return ArcRaidRouteStop(
      id: hatch.id,
      label: hatch.name,
      point: hatch.point,
      order: 999,
      markerId: hatch.id,
      reason: 'Raider Hatch selected after key confirmation.',
    );
  }

  static final Map<String, double> _clusterScores = <String, double>{};

  static int _markerSort(ArcRaidMapMarker a, ArcRaidMapMarker b) {
    final groupCompare = a.category.filteringGroup.compareTo(
      b.category.filteringGroup,
    );
    if (groupCompare != 0) return groupCompare;
    final countCompare = b.count.compareTo(a.count);
    if (countCompare != 0) return countCompare;
    return a.label.compareTo(b.label);
  }

  static ArcRaidMapMarkerCategory _categoryForAdminMarker(
    ArcAdminMapMarker marker,
  ) {
    switch (marker.effectiveKind) {
      case ArcAdminMapMarkerKind.poi:
        return ArcRaidMapMarkerCategory.poi;
      case ArcAdminMapMarkerKind.extraction:
        return ArcRaidMapMarkerCategory.standardExtraction;
      case ArcAdminMapMarkerKind.raiderHatch:
        return ArcRaidMapMarkerCategory.raiderHatch;
      case ArcAdminMapMarkerKind.blueprint:
        return ArcRaidMapMarkerCategory.blueprintOpportunity;
      case ArcAdminMapMarkerKind.questLocation:
        return ArcRaidMapMarkerCategory.questObjective;
      case ArcAdminMapMarkerKind.mapEvent:
        return ArcRaidMapMarkerCategory.mapEvent;
      case ArcAdminMapMarkerKind.resourceNode:
        return ArcRaidMapMarkerCategory.tradePreparationRequirement;
      case ArcAdminMapMarkerKind.upgrade:
        return ArcRaidMapMarkerCategory.upgrade;
      case ArcAdminMapMarkerKind.naturalResource:
        return ArcRaidMapMarkerCategory.generalLoot;
      case ArcAdminMapMarkerKind.arcSpawn:
        return ArcRaidMapMarkerCategory.arcThreat;
      case ArcAdminMapMarkerKind.weaponCase:
        return ArcRaidMapMarkerCategory.weaponCase;
      case ArcAdminMapMarkerKind.weaponCache:
        return ArcRaidMapMarkerCategory.raiderCache;
      case ArcAdminMapMarkerKind.firstWaveCache:
        return ArcRaidMapMarkerCategory.firstWaveCache;
      case ArcAdminMapMarkerKind.raiderCache:
        return ArcRaidMapMarkerCategory.raiderCache;
      case ArcAdminMapMarkerKind.fieldCrate:
        return ArcRaidMapMarkerCategory.fieldCrate;
      case ArcAdminMapMarkerKind.lootContainer:
        return ArcRaidMapMarkerCategory.fieldCrate;
      case ArcAdminMapMarkerKind.containerCluster:
        return ArcRaidMapMarkerCategory.containerCluster;
      case ArcAdminMapMarkerKind.lockedRoom:
        return ArcRaidMapMarkerCategory.lockedRoom;
      case ArcAdminMapMarkerKind.securityRoom:
        return ArcRaidMapMarkerCategory.securityLocker;
      case ArcAdminMapMarkerKind.highValueLoot:
        return ArcRaidMapMarkerCategory.raiderCache;
      case ArcAdminMapMarkerKind.key:
      case ArcAdminMapMarkerKind.keyRequiredLocation:
        return ArcRaidMapMarkerCategory.keyRoom;
      case ArcAdminMapMarkerKind.arcThreat:
        return ArcRaidMapMarkerCategory.arcThreat;
      case ArcAdminMapMarkerKind.extractionDanger:
      case ArcAdminMapMarkerKind.hazard:
        return ArcRaidMapMarkerCategory.configuredHazard;
      case ArcAdminMapMarkerKind.surfaceTransition:
        return ArcRaidMapMarkerCategory.surfaceTransition;
      case ArcAdminMapMarkerKind.undergroundTransition:
        return ArcRaidMapMarkerCategory.undergroundTransition;
      case ArcAdminMapMarkerKind.customIntel:
        if (marker.adminVerified ||
            marker.confidence == ArcRaidIntelConfidence.confirmed) {
          return ArcRaidMapMarkerCategory.confirmedIntel;
        }
        return marker.provisionalVisible
            ? ArcRaidMapMarkerCategory.researchedIntel
            : ArcRaidMapMarkerCategory.communityIntel;
    }
  }

  static List<ArcRaidMapMarker> _dedupeMarkers(
    Iterable<ArcRaidMapMarker> markers,
  ) {
    final merged = <ArcRaidMapMarker>[];
    for (final marker in markers) {
      final duplicateIndex = merged.indexWhere(
        (existing) =>
            existing.mapId == marker.mapId &&
            existing.layer == marker.layer &&
            existing.category == marker.category &&
            existing.label.trim().toLowerCase() ==
                marker.label.trim().toLowerCase() &&
            _pointDistance(existing.point, marker.point) <= 0.025,
      );
      if (duplicateIndex == -1) {
        merged.add(marker);
        continue;
      }
      final existing = merged[duplicateIndex];
      if (marker.confidence.score > existing.confidence.score ||
          marker.count > existing.count) {
        merged[duplicateIndex] = marker;
      }
    }
    return merged;
  }

  static double _pointDistance(ArcNormalizedPoint a, ArcNormalizedPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  static ArcRaidMapMarker _markerForCluster(
    ArcRaidIntelCluster cluster,
    Map<String, ArcBlueprintState> blueprintStates,
  ) {
    final reportDriven = cluster.evidence.any(
      (item) => item.sourceCategory == 'community_drop_report',
    );
    final researchDriven = cluster.evidence.any(
      (item) => item.sourceCategory == 'uag_research_baseline',
    );
    final sortedBlueprintIds = List<String>.from(cluster.blueprintIds)
      ..sort((a, b) {
        final aState = blueprintStates[a];
        final bState = blueprintStates[b];
        final aRank = aState?.priorityRank ?? 0;
        final bRank = bState?.priorityRank ?? 0;
        if ((aRank > 0) != (bRank > 0)) return aRank > 0 ? -1 : 1;
        if (aRank > 0 && bRank > 0 && aRank != bRank) {
          return aRank.compareTo(bRank);
        }
        return a.compareTo(b);
      });
    final prioritizedIds = sortedBlueprintIds
        .where((id) => (blueprintStates[id]?.priorityRank ?? 0) > 0)
        .toList(growable: false);
    final findsPerBlueprint = <String, int>{
      for (final id in sortedBlueprintIds)
        id: researchDriven
            ? cluster.reportCount
            : cluster.evidence
                  .where((item) => item.blueprintId == id)
                  .fold<int>(0, (total, _) => total + 1)
                  .clamp(1, math.max(1, cluster.reportCount)),
    };

    final objectiveOnly =
        sortedBlueprintIds.isEmpty && cluster.hasTrackedObjectives;
    final objectiveDetail = cluster.hasTrackedObjectives
        ? ' Supports ${cluster.objectiveCount} tracked ${_plural(cluster.objectiveCount, 'goal', 'goals')}: ${cluster.objectiveSummary}. Category/POI match only; resource drops are not guaranteed.'
        : '';
    return ArcRaidMapMarker(
      id: '${cluster.id}_marker',
      mapId: cluster.mapId,
      category: objectiveOnly
          ? cluster.markerCategory
          : ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: cluster.label,
      point: cluster.point,
      layer: cluster.layer,
      payloadId: cluster.id,
      confidence: cluster.confidence,
      count: math.max(
        math.max(cluster.reportCount, sortedBlueprintIds.length),
        cluster.objectiveCount,
      ),
      approximate: !reportDriven,
      detail: objectiveOnly
          ? '${cluster.cautiousSummary}. ${cluster.objectiveSummary}. Tracker guidance based on POI/loot classification; not a guaranteed resource spawn. ${cluster.freshnessLabel}.'
          : researchDriven
          ? cluster.reportCount > 0
                ? '${cluster.cautiousSummary}. Baseline POI/container match with ${cluster.reportCount} separately documented find ${_plural(cluster.reportCount, 'lead', 'leads')}. Not a guaranteed spawn. ${cluster.freshnessLabel}.$objectiveDetail'
                : '${cluster.cautiousSummary}. Baseline POI/container match for route planning; not an individually verified Blueprint spawn. ${cluster.freshnessLabel}.$objectiveDetail'
          : '${cluster.cautiousSummary}. ${cluster.reportCount} report confirmations from ${cluster.independentReporterCount} independent Raiders. ${cluster.freshnessLabel}.$objectiveDetail',
      tags: <String>[
        if (objectiveOnly)
          'Tracker Objectives'
        else if (reportDriven)
          'Drop Reports'
        else if (researchDriven)
          'Research Baseline'
        else
          'General guidance',
        cluster.commonSource,
        cluster.conditionCorrelation,
        cluster.freshnessLabel,
        ...cluster.objectives.map((objective) => objective.system),
      ],
      blueprintIds: sortedBlueprintIds,
      blueprintFindCounts: findsPerBlueprint,
      prioritizedBlueprintIds: prioritizedIds,
    );
  }

  static List<ArcBlueprint> _missingBlueprints(
    Map<String, ArcBlueprintState> states,
  ) {
    final missing = ArcBlueprintSeedData.blueprints
        .where((blueprint) => states[blueprint.id]?.owned != true)
        .toList(growable: true);
    missing.sort((a, b) {
      final aRank = states[a.id]?.priorityRank ?? 0;
      final bRank = states[b.id]?.priorityRank ?? 0;
      final aPrioritised = aRank > 0;
      final bPrioritised = bRank > 0;
      if (aPrioritised != bPrioritised) return aPrioritised ? -1 : 1;
      if (aPrioritised && bPrioritised) {
        final rankCompare = aRank.compareTo(bRank);
        if (rankCompare != 0) return rankCompare;
      }
      final marketCompare = ArcBlueprintTradeValueCatalog.compareBlueprints(
        a,
        b,
      );
      if (marketCompare != 0) return marketCompare;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return missing.take(states.isEmpty ? 5 : 12).toList(growable: false);
  }

  static Set<String> _loadoutItemNames(ArcSavedLoadout? loadout) {
    if (loadout == null) return const <String>{};
    return {
          loadout.primaryWeapon,
          loadout.secondaryWeapon,
          loadout.augment,
          if (loadout.shield != null) loadout.shield!,
          ...loadout.primaryAttachments,
          ...loadout.secondaryAttachments,
          ...loadout.equipment,
          ...loadout.consumables,
          ...loadout.quickUse,
        }
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty && item != 'empty slot')
        .toSet();
  }

  static bool _hintSupportsMap(ArcBlueprintHintData hint, ArcRaidMap map) {
    if (ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps)) return true;
    final mapNames = {
      map.displayName.trim().toLowerCase(),
      ...map.aliases.map((alias) => alias.trim().toLowerCase()),
    };
    return hint.likelyMaps.any(
      (entry) => mapNames.contains(entry.trim().toLowerCase()),
    );
  }

  static ArcRaidMapPoi? _poiForBlueprint(
    ArcRaidMap map,
    ArcBlueprint blueprint,
  ) {
    if (map.pois.isEmpty) return null;
    final hash = blueprint.id.codeUnits.fold<int>(
      0,
      (total, unit) => total + unit,
    );
    return map.pois[hash % map.pois.length];
  }

  static void _appendBlueprintMarkerMatches({
    required List<ArcRaidIntelCluster> target,
    required List<ArcBlueprintMarkerMatch> matches,
    required ArcBlueprint blueprint,
    required ArcBlueprintState? state,
    required bool loadoutRelevant,
    required ArcOperationsUserState operationsState,
    required ArcRaidMap map,
  }) {
    final baseScore = _opportunityScore(
      blueprint: blueprint,
      state: state,
      confidence: matches.first.fallback
          ? ArcRaidIntelConfidence.limited
          : matches.first.marker.confidence,
      loadoutRelevant: loadoutRelevant,
      operationsState: operationsState,
    );
    for (final match in matches.take(4)) {
      final marker = match.marker;
      final confidence = match.fallback
          ? ArcRaidIntelConfidence.limited
          : marker.confidence;
      final research = ArcBlueprintResearchCatalog.forBlueprintOnMap(
        blueprint.id,
        map.id,
      );
      final researchConditions = research == null
          ? const <String>[]
          : ArcBlueprintMapBackend.conditionIdsForResearch(research.condition);
      final effectiveConditions = marker.blueprintConditionIds.isNotEmpty
          ? marker.blueprintConditionIds
          : researchConditions;
      final condition = effectiveConditions.isEmpty
          ? 'Any condition'
          : effectiveConditions.map(_conditionDisplayLabel).join(', ');
      final researchFamily = research == null
          ? ArcBlueprintContainerFamily.unknown
          : ArcBlueprintMapBackend.containerFamilyForResearch(
              research.container,
            );
      final effectiveFamily =
          marker.effectiveBlueprintContainerFamily !=
              ArcBlueprintContainerFamily.unknown
          ? marker.effectiveBlueprintContainerFamily
          : researchFamily;
      final source = effectiveFamily == ArcBlueprintContainerFamily.unknown
          ? marker.effectiveKind.label
          : effectiveFamily.label;
      final evidence = ArcRaidIntelEvidence(
        id: '${map.id}_${blueprint.id}_${marker.id}_map_backend',
        blueprintId: blueprint.id,
        mapId: map.id,
        approximateArea: marker.name,
        point: marker.point,
        containerSource: source,
        conditionId: effectiveConditions.isEmpty
            ? null
            : effectiveConditions.first,
        raidStage: 'Full',
        acquisitionSource: match.fallback
            ? 'map_probability_fallback'
            : 'admin_map_blueprint_intel',
        claimSummary: match.fallback
            ? '${blueprint.name}: probability route through ${marker.name}.'
            : '${blueprint.name}: ${match.reason}',
        sourceCategory: match.fallback
            ? 'uag_map_probability_fallback'
            : 'uag_admin_map_blueprint_intel',
        sourceReference:
            marker.blueprintResearchVersion ?? 'UAG map backend marker',
        reviewedAt: marker.updatedAt,
        direct:
            marker.effectiveBlueprintIntelType ==
            ArcBlueprintMapIntelType.exactFind,
        confidence: confidence,
        notes: match.fallback
            ? '${match.reason} This is a probability route, not a guaranteed Blueprint spawn.'
            : '${match.reason} Admin map intelligence; drops remain probabilistic unless marked as an exact historical find.',
      );
      final cluster = ArcRaidIntelCluster(
        id: '${map.id}_${blueprint.id}_${marker.id}_map_cluster',
        mapId: map.id,
        label: match.fallback
            ? '${blueprint.name} fallback — ${marker.name}'
            : '${blueprint.name} — ${marker.name}',
        point: marker.point,
        layer: marker.layer,
        blueprintIds: <String>[blueprint.id],
        evidence: <ArcRaidIntelEvidence>[evidence],
        confidence: confidence,
        reportCount: marker.resolvedEvidenceCount,
        independentReporterCount: 0,
        freshnessLabel: marker.updatedAt == null
            ? 'Admin map intelligence'
            : 'Admin map intel updated ${marker.updatedAt!.year}-${marker.updatedAt!.month.toString().padLeft(2, '0')}-${marker.updatedAt!.day.toString().padLeft(2, '0')}',
        commonSource: source,
        conditionCorrelation: condition,
      );
      target.add(cluster);
      _clusterScores[cluster.id] = baseScore + (match.score * 0.25);
    }
  }

  static String _conditionDisplayLabel(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  static ArcRaidIntelConfidence _confidenceFromHint(
    ArcBlueprintHintData hint, {
    required bool topWanted,
  }) {
    final base = switch (hint.confidence) {
      ArcIntelConfidence.confirmed => ArcRaidIntelConfidence.confirmed,
      ArcIntelConfidence.community => ArcRaidIntelConfidence.moderate,
      ArcIntelConfidence.starter => ArcRaidIntelConfidence.limited,
    };
    if (topWanted && base == ArcRaidIntelConfidence.limited) {
      return ArcRaidIntelConfidence.moderate;
    }
    return base;
  }

  static double _opportunityScore({
    required ArcBlueprint blueprint,
    required ArcBlueprintState? state,
    required ArcRaidIntelConfidence confidence,
    required bool loadoutRelevant,
    required ArcOperationsUserState operationsState,
  }) {
    var score = 20.0 + confidence.score;
    final rank = state?.priorityRank ?? 0;
    if (rank > 0) score += math.max(0, 70 - (rank * 8));
    if (loadoutRelevant) score += 32;
    if (blueprint.rarity == ArcBlueprintRarity.legendary) score += 16;
    if (blueprint.rarity == ArcBlueprintRarity.epic) score += 10;
    score += ArcBlueprintTradeValueCatalog.tradePointsFor(blueprint) * 3;
    if (operationsState.progressById.isNotEmpty) score += 4;
    return score;
  }

  static void _mergeTrackedObjectiveClusters(
    List<ArcRaidIntelCluster> base,
    List<ArcRaidIntelCluster> objectiveClusters,
  ) {
    for (final objectiveCluster in objectiveClusters) {
      var matchIndex = -1;
      for (var index = 0; index < base.length; index++) {
        final current = base[index];
        final samePoi =
            current.poiId?.trim().isNotEmpty == true &&
            objectiveCluster.poiId?.trim().isNotEmpty == true &&
            _normalize(current.poiId!) == _normalize(objectiveCluster.poiId!);
        final sameNamedLocation =
            current.layer == objectiveCluster.layer &&
            _locationIdentity(current) == _locationIdentity(objectiveCluster);
        if (samePoi || sameNamedLocation) {
          matchIndex = index;
          break;
        }
      }

      if (matchIndex < 0) {
        base.add(objectiveCluster);
        _clusterScores[objectiveCluster.id] =
            40 + objectiveCluster.objectiveScore;
        continue;
      }

      final current = base[matchIndex];
      final objectivesById = <String, ArcRaidObjective>{
        for (final objective in current.objectives) objective.id: objective,
        for (final objective in objectiveCluster.objectives)
          objective.id: objective,
      };
      final merged = current.copyWith(
        objectives: objectivesById.values.toList(growable: false),
        objectiveScore:
            current.objectiveScore + objectiveCluster.objectiveScore,
        markerCategory: current.blueprintIds.isNotEmpty
            ? ArcRaidMapMarkerCategory.blueprintOpportunity
            : objectiveCluster.markerCategory,
      );
      base[matchIndex] = merged;
      _clusterScores[merged.id] =
          (_clusterScores[current.id] ?? current.confidence.score.toDouble()) +
          objectiveCluster.objectiveScore;
    }
  }

  static List<ArcRaidIntelCluster> _mergeNearbyClusters(
    List<ArcRaidIntelCluster> clusters,
  ) {
    final merged = <ArcRaidIntelCluster>[];
    final used = <String>{};
    for (final cluster in clusters) {
      if (used.contains(cluster.id)) continue;
      final nearby = clusters
          .where(
            (other) =>
                other.id != cluster.id &&
                !used.contains(other.id) &&
                other.layer == cluster.layer &&
                _canMergeClusters(cluster, other) &&
                other.point.distanceTo(cluster.point) < 0.055,
          )
          .toList(growable: false);
      if (nearby.isEmpty) {
        merged.add(cluster);
        used.add(cluster.id);
        continue;
      }
      used.add(cluster.id);
      used.addAll(nearby.map((item) => item.id));
      final all = [cluster, ...nearby];
      final reportDriven = all.where(_reportDriven).toList(growable: false);
      final anchor = reportDriven.isEmpty ? cluster : reportDriven.first;
      final evidenceClusters = reportDriven.isEmpty ? all : reportDriven;
      merged.add(
        ArcRaidIntelCluster(
          id: '${anchor.id}_merged',
          mapId: anchor.mapId,
          label: reportDriven.isEmpty
              ? all.any((item) => item.hasTrackedObjectives)
                    ? anchor.label
                    : '${all.length} Blueprint opportunities'
              : anchor.label,
          point: anchor.point,
          layer: anchor.layer,
          poiId: anchor.poiId,
          blueprintIds: all
              .expand((item) => item.blueprintIds)
              .toSet()
              .toList(growable: false),
          evidence: all.expand((item) => item.evidence).toList(growable: false),
          confidence: all
              .map((item) => item.confidence)
              .reduce((a, b) => a.score >= b.score ? a : b),
          reportCount: evidenceClusters.fold<int>(
            0,
            (total, item) => total + item.reportCount,
          ),
          independentReporterCount: evidenceClusters.fold<int>(
            0,
            (total, item) => total + item.independentReporterCount,
          ),
          freshnessLabel: reportDriven.isEmpty
              ? all.any((item) => item.hasTrackedObjectives)
                    ? 'Live tracker guidance'
                    : 'Seed reviewed'
              : anchor.freshnessLabel,
          commonSource: anchor.commonSource,
          conditionCorrelation: anchor.conditionCorrelation,
          markerCategory: all.any((item) => item.blueprintIds.isNotEmpty)
              ? ArcRaidMapMarkerCategory.blueprintOpportunity
              : anchor.markerCategory,
          objectives: <String, ArcRaidObjective>{
            for (final item in all)
              for (final objective in item.objectives) objective.id: objective,
          }.values.toList(growable: false),
          objectiveScore: all.fold<double>(
            0,
            (total, item) => total + item.objectiveScore,
          ),
        ),
      );
      final mergedCluster = merged.last;
      _clusterScores[mergedCluster.id] = all.fold<double>(
        0,
        (total, item) =>
            total +
            (_clusterScores[item.id] ?? item.confidence.score.toDouble()),
      );
    }
    return merged;
  }

  static bool _canMergeClusters(ArcRaidIntelCluster a, ArcRaidIntelCluster b) {
    final aReportDriven = _reportDriven(a);
    final bReportDriven = _reportDriven(b);
    if (a.hasTrackedObjectives || b.hasTrackedObjectives) {
      return _locationIdentity(a) == _locationIdentity(b);
    }
    if (!aReportDriven && !bReportDriven) return true;
    return _locationIdentity(a) == _locationIdentity(b);
  }

  static bool _reportDriven(ArcRaidIntelCluster cluster) {
    return cluster.evidence.any(
      (item) => item.sourceCategory == 'community_drop_report',
    );
  }

  static String _locationIdentity(ArcRaidIntelCluster cluster) {
    final poiId = cluster.poiId?.trim();
    if (poiId != null && poiId.isNotEmpty) return 'poi:${_normalize(poiId)}';
    final evidencePoiId = cluster.evidence
        .map((item) => item.poiId?.trim())
        .whereType<String>()
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    if (evidencePoiId.isNotEmpty) {
      return 'poi:${_normalize(evidencePoiId)}';
    }
    final label = cluster.evidence
        .map((item) => item.approximateArea?.trim())
        .whereType<String>()
        .firstWhere((item) => item.isNotEmpty, orElse: () => cluster.label);
    return 'label:${_normalize(label)}';
  }

  static String _routeStopReason(ArcRaidIntelCluster cluster) {
    if (!cluster.hasTrackedObjectives) return cluster.cautiousSummary;
    if (cluster.blueprintIds.isEmpty) {
      return '${cluster.objectiveSummary}. Tracker-guided POI match; drops are not guaranteed.';
    }
    return '${cluster.cautiousSummary}. Also supports ${cluster.objectiveCount} tracked ${_plural(cluster.objectiveCount, 'goal', 'goals')}: ${cluster.objectiveSummary}.';
  }

  static double _routeStopScore({
    required ArcRaidMap map,
    required ArcRaidIntelCluster cluster,
    required ArcNormalizedPoint spawn,
    required ArcNormalizedPoint extraction,
    required ArcRaidRouteStyle routeStyle,
    required ArcRaidObjectivePriority objectivePriority,
    required ArcRaidSquadMode squadMode,
    required List<ArcRaidRouteParticipant> participants,
  }) {
    final travelCost =
        _graphTravelCost(map, spawn, cluster.point) +
        _graphTravelCost(map, cluster.point, extraction);
    final distancePenalty = travelCost * 3.4;
    var score =
        (cluster.confidence.score +
                (cluster.blueprintIds.length * 24) +
                (cluster.objectiveCount * 18))
            .toDouble();
    score += cluster.objectiveScore * 0.55;
    score -= distancePenalty;
    if (routeStyle == ArcRaidRouteStyle.safer) {
      score -=
          cluster.point.distanceTo(const ArcNormalizedPoint(x: 0.5, y: 0.5)) *
          12;
    }
    if (routeStyle == ArcRaidRouteStyle.thorough) {
      score += cluster.blueprintIds.length * 8;
      score += cluster.objectiveCount * 6;
    }
    if (objectivePriority == ArcRaidObjectivePriority.balancedSquad) {
      score +=
          participants
              .where((participant) => participant.sharesSpecificObjectives)
              .length *
          7;
    }
    if (objectivePriority == ArcRaidObjectivePriority.helpTeammate &&
        squadMode != ArcRaidSquadMode.solo) {
      score += 10;
    }
    return score;
  }

  static double _graphTravelCost(
    ArcRaidMap map,
    ArcNormalizedPoint start,
    ArcNormalizedPoint end,
  ) {
    if (map.routeNodes.isEmpty || map.routeEdges.isEmpty) {
      return start.distanceTo(end) * 10;
    }
    final startNode = _nearestNode(map.routeNodes, start);
    final endNode = _nearestNode(map.routeNodes, end);
    if (startNode == null || endNode == null) return start.distanceTo(end) * 10;
    final edgeCost = _shortestPathCost(
      map.routeEdges,
      startNode.id,
      endNode.id,
    );
    final approach =
        start.distanceTo(startNode.point) * 10 +
        end.distanceTo(endNode.point) * 10;
    if (edgeCost.isInfinite) {
      return approach + (start.distanceTo(end) * 10);
    }
    return edgeCost + approach;
  }

  static ArcRaidRouteNode? _nearestNode(
    List<ArcRaidRouteNode> nodes,
    ArcNormalizedPoint point,
  ) {
    ArcRaidRouteNode? nearest;
    var best = double.infinity;
    for (final node in nodes) {
      final distance = node.point.distanceTo(point);
      if (distance < best) {
        best = distance;
        nearest = node;
      }
    }
    return nearest;
  }

  static double _shortestPathCost(
    List<ArcRaidRouteEdge> edges,
    String startNodeId,
    String endNodeId,
  ) {
    if (startNodeId == endNodeId) return 0;
    final nodeIds = <String>{startNodeId, endNodeId};
    for (final edge in edges) {
      nodeIds
        ..add(edge.fromNodeId)
        ..add(edge.toNodeId);
    }
    final distances = {
      for (final nodeId in nodeIds) nodeId: double.infinity,
      startNodeId: 0.0,
    };
    final visited = <String>{};
    while (visited.length < nodeIds.length) {
      String? current;
      var currentDistance = double.infinity;
      for (final entry in distances.entries) {
        if (!visited.contains(entry.key) && entry.value < currentDistance) {
          current = entry.key;
          currentDistance = entry.value;
        }
      }
      if (current == null || currentDistance.isInfinite) break;
      if (current == endNodeId) return currentDistance;
      visited.add(current);
      for (final edge in edges.where((item) => item.fromNodeId == current)) {
        final cost = currentDistance + edge.travelCost + edge.riskCost;
        if (cost < (distances[edge.toNodeId] ?? double.infinity)) {
          distances[edge.toNodeId] = cost;
        }
      }
      for (final edge in edges.where(
        (item) => !item.oneWay && item.toNodeId == current,
      )) {
        final cost = currentDistance + edge.travelCost + edge.riskCost;
        if (cost < (distances[edge.fromNodeId] ?? double.infinity)) {
          distances[edge.fromNodeId] = cost;
        }
      }
    }
    return distances[endNodeId] ?? double.infinity;
  }

  static List<ArcRaidRouteParticipant> _privacySafeParticipants(
    List<ArcRaidRouteParticipant> participants,
  ) {
    return participants
        .map(
          (participant) =>
              participant.objectiveSharing ==
                  ArcRaidObjectiveSharing.keepPrivate
              ? ArcRaidRouteParticipant(
                  uid: participant.uid,
                  displayName: participant.displayName,
                )
              : participant,
        )
        .toList(growable: false);
  }

  static ArcRaidRoutePlan _renumber(ArcRaidRoutePlan plan) {
    final stops = [
      for (var index = 0; index < plan.stops.length; index++)
        plan.stops[index].copyWith(order: index + 1),
    ];
    return plan.copyWith(
      stops: stops,
      extraction: plan.extraction.copyWith(order: stops.length + 1),
    );
  }

  static String _activeConditionLabel(List<ArcRaidIntelCluster> clusters) {
    final condition = clusters
        .map((cluster) => cluster.conditionCorrelation)
        .firstWhere(
          (value) =>
              value.trim().isNotEmpty &&
              value.trim().toLowerCase() != 'any condition',
          orElse: () => 'Any condition',
        );
    return condition;
  }

  static String _plural(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}
