import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_personal_need_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_universal_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

/// Converts existing published map pins and current player needs into eligible
/// Smart Raid Run stops. Never creates a new geographical location or a drop report.
class ArcPersonalRouteCandidateEngine {
  const ArcPersonalRouteCandidateEngine();

  /// The route optimiser, not this engine, decides the final order/stop count.
  /// A candidate is only produced at an existing pin on the selected map/layer.
  List<ArcRaidIntelCluster> build({
    required ArcRaidMap map,
    required ArcRaidMapLayer layer,
    required List<ArcRaidMapMarker> markers,
    required Map<String, List<ArcPoiPersonalMatch>> personalMatches,
    required List<ArcRaidObjective> trackedObjectives,
    int maxCandidates = 16,
  }) {
    if (maxCandidates <= 0) return const [];
    final objectiveByItem = <String, List<ArcRaidObjective>>{};
    for (final objective in trackedObjectives) {
      if (objective.missingCount <= 0 || objective.questLocationOnly) continue;
      final key = ArcPoiPersonalNeedResolver.normalise(objective.itemName);
      if (key.isEmpty) continue;
      (objectiveByItem[key] ??= []).add(objective);
    }
    final universal = const ArcUniversalIntelligenceEngine();
    final expandedObjectives = universal.expandObjectives(trackedObjectives);
    final candidates = <ArcRaidIntelCluster>[];
    final seenPins = <String>{};
    for (final marker in markers) {
      if (!marker.enabled || marker.mapId != map.id || marker.layer != layer ||
          marker.isCluster || marker.tags.contains('Provisional')) continue;
      if (!seenPins.add(marker.id)) continue;
      final matches = personalMatches[marker.id] ?? const <ArcPoiPersonalMatch>[];
      final universalMatches = universal.matchesForMarker(
        marker: marker, objectives: expandedObjectives);
      // An explicit published Bastion spawn is an eligible source for a
      // Bastion Cell requirement; this is a target to fight, not loot guaranteed.
      final bastionObjective = marker.category == ArcRaidMapMarkerCategory.arcThreat &&
          RegExp(r'\bbastion\b', caseSensitive: false).hasMatch(marker.label)
          ? (objectiveByItem[ArcPoiPersonalNeedResolver.normalise('Bastion Cell')] ?? const <ArcRaidObjective>[])
          : const <ArcRaidObjective>[];
      if (matches.isEmpty && bastionObjective.isEmpty && universalMatches.isEmpty) continue;
      final objectives = <String, ArcRaidObjective>{};
      for (final match in matches) {
        final key = ArcPoiPersonalNeedResolver.normalise(match.itemName);
        for (final objective in objectiveByItem[key] ?? const <ArcRaidObjective>[]) {
          objectives[objective.id] = objective;
        }
      }
      for (final match in universalMatches) {
        objectives[match.objective.id] = match.objective;
      }
      for (final objective in bastionObjective) {
        objectives[objective.id] = objective;
      }
      // Prioritised missing blueprints may have no ArcRaidObjective record;
      // represent those as route-local goals without changing account state.
      for (final match in matches.where((match) => match.reason == 'Priority blueprint')) {
        final key = ArcPoiPersonalNeedResolver.normalise(match.itemName);
        final id = 'priority-blueprint:$key';
        objectives.putIfAbsent(id, () => ArcRaidObjective(
          id: id,
          label: match.itemName,
          reason: 'Prioritised missing Blueprint; possible drop, not guaranteed.',
          category: ArcRaidMapMarkerCategory.blueprintOpportunity,
          system: 'Blueprint',
          itemName: match.itemName,
          missingCount: 1,
          weight: 1.3,
        ));
      }
      if (objectives.isEmpty) continue;
      final strong = matches.where((m) => m.isNamedPoiEvidence).length;
      // POI-loot pool guidance stays low confidence. Explicit pin matching is
      // also a possible encounter, never an assured resource reward.
      candidates.add(ArcRaidIntelCluster(
        id: 'personal-pin:${marker.id}',
        mapId: map.id,
        label: marker.label,
        point: marker.point,
        layer: marker.layer,
        poiId: marker.payloadId,
        blueprintIds: const [],
        evidence: const [],
        confidence: ArcRaidIntelConfidence.limited,
        commonSource: universalMatches.isNotEmpty ? universalMatches.first.source :
          (bastionObjective.isNotEmpty ? 'Published ARC spawn marker' : 'POI item research'),
        freshnessLabel: 'Unconfirmed opportunity',
        markerCategory: marker.category,
        objectives: objectives.values.toList(growable: false),
        objectiveScore: strong * 7.0 + (bastionObjective.isNotEmpty ? 12.0 : 0.0) +
          universalMatches.fold<double>(0, (sum, m) => sum + m.score),
      ));
    }
    // Prefer stops completing several goals and direct location evidence.
    candidates.sort((a, b) {
      final byGoals = b.objectiveCount.compareTo(a.objectiveCount);
      if (byGoals != 0) return byGoals;
      final byEvidence = b.objectiveScore.compareTo(a.objectiveScore);
      if (byEvidence != 0) return byEvidence;
      return a.id.compareTo(b.id);
    });
    // Prevent a single ubiquitous resource (for example ARC Alloy) from
    // flooding the plan with identical stops. Permit a second opportunity
    // when more than one unit is still needed; the route planner orders them.
    final selected = <ArcRaidIntelCluster>[];
    final covered = <String, int>{};
    for (final candidate in candidates) {
      final addsCoverage = candidate.objectives.any((objective) {
        final limit = objective.missingCount > 1 ? 2 : 1;
        return (covered[objective.id] ?? 0) < limit;
      });
      if (!addsCoverage) continue;
      selected.add(candidate);
      for (final objective in candidate.objectives) {
        covered[objective.id] = (covered[objective.id] ?? 0) + 1;
      }
      if (selected.length >= maxCandidates) break;
    }
    return List<ArcRaidIntelCluster>.unmodifiable(selected);
  }
}
