import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_cluster_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcRaidIntelligenceEngine {
  const ArcRaidIntelligenceEngine();

  ArcRaidIntelligenceState build({
    required String mapId,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    ArcSavedLoadout? favouriteLoadout,
    ArcOperationsUserState operationsState = ArcOperationsUserState.empty,
    List<ArcBlueprintDropReport> dropReports = const <ArcBlueprintDropReport>[],
    List<ArcCommunityIntelReport> communityReports =
        const <ArcCommunityIntelReport>[],
    ArcRaidMapFilterState filters = ArcRaidMapFilterState.defaults,
    ArcRaidMapLayer activeLayer = ArcRaidMapLayer.surface,
    ArcRaidRoutePlan? activeRoute,
  }) {
    final map = ArcRaidIntelligenceSeedData.mapById(mapId);
    final resolvedLayer = map.availableLayers.contains(activeLayer)
        ? activeLayer
        : (map.availableLayers.isEmpty
              ? ArcRaidMapLayer.surface
              : map.availableLayers.first);
    final clusters = opportunityClusters(
      map: map,
      blueprintStates: blueprintStates,
      favouriteLoadout: favouriteLoadout,
      operationsState: operationsState,
      dropReports: dropReports,
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
    final rawVisibleMarkers =
        [
              ...map.markers,
              ...clusterMarkers,
              ...communityMarkers,
              ...routeMarkers,
            ]
            .where((marker) => marker.layer == resolvedLayer)
            .where(filters.allows)
            .toList(growable: false)
          ..sort(_markerSort);
    final visibleMarkers = const ArcMapMarkerClusterEngine().cluster(
      rawVisibleMarkers,
    )..sort(_markerSort);
    final relevantCount = clusters.fold<int>(
      0,
      (total, cluster) => total + cluster.blueprintIds.length,
    );
    final status = activeRoute != null
        ? 'Route ready'
        : relevantCount == 0
        ? 'No current priority'
        : 'Generate a run';
    return ArcRaidIntelligenceState(
      map: map,
      activeLayer: resolvedLayer,
      filters: filters,
      visibleMarkers: visibleMarkers,
      opportunityClusters: clusters,
      routePlan: activeRoute,
      activeConditionLabel: _activeConditionLabel(clusters),
      statusLabel: status,
      recommendation: relevantCount == 0
          ? 'No evidence-backed Blueprint opportunities for current needs on ${map.displayName}.'
          : 'Generate a Blueprint Run through $relevantCount relevant opportunity ${_plural(relevantCount, 'cluster', 'clusters')}.',
    );
  }

  ArcRaidMapMarker _markerForCommunityReport(ArcCommunityIntelReport report) {
    final category = report.isStale
        ? ArcRaidMapMarkerCategory.staleIntel
        : report.confirmationCount >= 5
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

  List<ArcRaidIntelCluster> opportunityClusters({
    required ArcRaidMap map,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    ArcSavedLoadout? favouriteLoadout,
    ArcOperationsUserState operationsState = ArcOperationsUserState.empty,
    List<ArcBlueprintDropReport> dropReports = const <ArcBlueprintDropReport>[],
  }) {
    final loadoutNames = _loadoutItemNames(favouriteLoadout);
    final mapClusters = <ArcRaidIntelCluster>[];
    final missing = _missingBlueprints(blueprintStates);
    final reportClusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: dropReports,
      blueprintStates: blueprintStates,
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
      final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
      if (!_hintSupportsMap(hint, map)) continue;
      final poi = _poiForBlueprint(map, blueprint);
      final state = blueprintStates[blueprint.id];
      final topWanted = (state?.priorityRank ?? 0) > 0;
      final loadoutRelevant = loadoutNames.contains(
        blueprint.name.trim().toLowerCase(),
      );
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
          blueprintIds: [blueprint.id],
          evidence: [evidence],
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

    mapClusters.sort((a, b) {
      final scoreCompare = (_clusterScores[b.id] ?? 0).compareTo(
        _clusterScores[a.id] ?? 0,
      );
      if (scoreCompare != 0) return scoreCompare;
      return a.label.compareTo(b.label);
    });
    return _mergeNearbyClusters(mapClusters);
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

    final selected = ranked.take(stopLimit).toList(growable: false);
    final ordered = _orderClustersForTravel(
      map: map,
      clusters: selected,
      start: spawn.point,
      extraction: extraction.point,
    );
    final stops = <ArcRaidRouteStop>[
      for (var index = 0; index < ordered.length; index++)
        ArcRaidRouteStop(
          id: 'stop_${ordered[index].id}',
          label: ordered[index].label,
          point: ordered[index].point,
          order: index + 1,
          clusterId: ordered[index].id,
          blueprintIds: ordered[index].blueprintIds,
          reason: ordered[index].cautiousSummary,
        ),
    ];
    final metrics = _buildRouteMetrics(
      map: map,
      spawn: spawn,
      extraction: extraction,
      clusters: ordered,
      squadMode: squadMode,
      routeStyle: routeStyle,
    );

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
          '${routeStyle.label} ${squadMode.label} Loot Run: ${metrics.opportunityCount} opportunity ${_plural(metrics.opportunityCount, 'stop', 'stops')}, ${metrics.blueprintTargetCount} Blueprint ${_plural(metrics.blueprintTargetCount, 'target', 'targets')}, about ${metrics.estimatedMinutes} min, then ${extraction.label}.',
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
        reason: cluster.cautiousSummary,
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
        ((blueprintCount * 120 + averageConfidence * 2) /
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

    return ArcRaidRouteMetrics(
      totalDistance: double.parse(travelCost.toStringAsFixed(2)),
      estimatedMinutes: estimatedMinutes,
      opportunityCount: clusters.length,
      blueprintTargetCount: blueprintCount,
      averageConfidence: averageConfidence,
      efficiencyScore: efficiency,
      riskLabel: riskLabel,
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

  static ArcRaidMapMarker _markerForCluster(
    ArcRaidIntelCluster cluster,
    Map<String, ArcBlueprintState> blueprintStates,
  ) {
    final reportDriven = cluster.evidence.any(
      (item) => item.sourceCategory == 'community_drop_report',
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
        id: cluster.evidence
            .where((item) => item.blueprintId == id)
            .fold<int>(0, (total, _) => total + 1)
            .clamp(1, cluster.reportCount),
    };

    return ArcRaidMapMarker(
      id: '${cluster.id}_marker',
      mapId: cluster.mapId,
      category: ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: cluster.label,
      point: cluster.point,
      layer: cluster.layer,
      payloadId: cluster.id,
      confidence: cluster.confidence,
      count: math.max(cluster.reportCount, sortedBlueprintIds.length),
      approximate: !reportDriven,
      detail:
          '${cluster.cautiousSummary}. ${cluster.reportCount} report confirmations from ${cluster.independentReporterCount} independent Raiders. ${cluster.freshnessLabel}.',
      tags: <String>[
        if (reportDriven) 'Drop Reports' else 'Seeded Intel',
        cluster.commonSource,
        cluster.conditionCorrelation,
        cluster.freshnessLabel,
      ],
      blueprintIds: sortedBlueprintIds,
      blueprintFindCounts: findsPerBlueprint,
      prioritizedBlueprintIds: prioritizedIds,
    );
  }

  static List<ArcBlueprint> _missingBlueprints(
    Map<String, ArcBlueprintState> states,
  ) {
    if (states.isEmpty) {
      return ArcBlueprintSeedData.blueprints.take(5).toList(growable: false);
    }
    final missing = ArcBlueprintSeedData.blueprints
        .where((blueprint) => states[blueprint.id]?.owned != true)
        .toList(growable: false);
    missing.sort((a, b) {
      final aRank = states[a.id]?.priorityRank ?? 999;
      final bRank = states[b.id]?.priorityRank ?? 999;
      final rankCompare = aRank.compareTo(bRank);
      if (rankCompare != 0) return rankCompare;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return missing.take(12).toList(growable: false);
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
    if (operationsState.progressById.isNotEmpty) score += 4;
    return score;
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
      merged.add(
        ArcRaidIntelCluster(
          id: '${cluster.id}_merged',
          mapId: cluster.mapId,
          label: '${all.length} Blueprint opportunities',
          point: cluster.point,
          layer: cluster.layer,
          poiId: cluster.poiId,
          blueprintIds: all
              .expand((item) => item.blueprintIds)
              .toSet()
              .toList(growable: false),
          evidence: all.expand((item) => item.evidence).toList(growable: false),
          confidence: all
              .map((item) => item.confidence)
              .reduce((a, b) => a.score >= b.score ? a : b),
          reportCount: all.fold<int>(
            0,
            (total, item) => total + item.reportCount,
          ),
          independentReporterCount: all.fold<int>(
            0,
            (total, item) => total + item.independentReporterCount,
          ),
          freshnessLabel: 'Seed reviewed',
          commonSource: cluster.commonSource,
          conditionCorrelation: cluster.conditionCorrelation,
        ),
      );
    }
    return merged;
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
    var score = (cluster.confidence.score + (cluster.blueprintIds.length * 24))
        .toDouble();
    score -= distancePenalty;
    if (routeStyle == ArcRaidRouteStyle.safer) {
      score -=
          cluster.point.distanceTo(const ArcNormalizedPoint(x: 0.5, y: 0.5)) *
          12;
    }
    if (routeStyle == ArcRaidRouteStyle.thorough) {
      score += cluster.blueprintIds.length * 8;
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
}
