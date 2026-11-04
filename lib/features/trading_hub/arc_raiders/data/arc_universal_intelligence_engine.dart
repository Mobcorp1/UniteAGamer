import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_item_dependency_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_loot_intel_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_map_binding.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_personal_need_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/research/uag_research_catalogue.dart';

/// An evidence-aware relationship between a *published* map marker and a
/// current player objective. This never creates map coordinates or reports.
enum ArcUniversalEvidence { explicitMarker, namedPoi, researchedPool, inferredSource }

class ArcUniversalMatch {
  const ArcUniversalMatch({required this.objective, required this.markerId,
    required this.evidence, required this.itemName, required this.source,
    required this.score});
  final ArcRaidObjective objective;
  final String markerId;
  final ArcUniversalEvidence evidence;
  final String itemName;
  final String source;
  final double score;
}

class ArcUniversalMapScore {
  const ArcUniversalMapScore({required this.mapId, required this.score,
    required this.matchedObjectiveIds, required this.stopIds, required this.matches});
  final String mapId;
  final double score;
  final List<String> matchedObjectiveIds;
  final List<String> stopIds;
  final List<ArcUniversalMatch> matches;
  int get objectiveCount => matchedObjectiveIds.length;
}

/// Indexed from the application's existing item database, POI evidence and
/// research material requirements. An unknown relationship is not a drop claim.
class ArcUniversalIntelligenceEngine {
  const ArcUniversalIntelligenceEngine();

  static String key(String value) => ArcPoiPersonalNeedResolver.normalise(value);
  static String idKey(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static final Map<String, List<ArcPersonalItemRecord>> _itemIndex = () {
    final result = <String, List<ArcPersonalItemRecord>>{};
    for (final item in ArcPersonalItemDependencyCatalog.current.records) {
      for (final name in <String>[item.name, ...item.aliases]) {
        final normalized = key(name);
        if (normalized.isEmpty) continue;
        final values = result.putIfAbsent(normalized, () => <ArcPersonalItemRecord>[]);
        if (!values.contains(item)) values.add(item);
      }
    }
    return result;
  }();

  /// Resolve only research projects explicitly named as player goals. The
  /// recipe catalogue provides materials; arbitrary crafting outputs with
  /// unknown recipes are never expanded or treated as complete.
  List<ArcRaidObjective> expandObjectives(List<ArcRaidObjective> objectives) {
    final expanded = <String, ArcRaidObjective>{};
    for (final objective in objectives) {
      expanded[objective.id] = objective;
      if (objective.missingCount <= 0 || objective.questLocationOnly) continue;
      final requested = key(objective.itemName.isEmpty ? objective.label : objective.itemName);
      for (final recipe in UagResearchCatalogue.recipes) {
        if (requested != key(recipe.title) && requested != key(recipe.unlocks)) continue;
        for (final material in [...recipe.materials, ...recipe.crafting]) {
          final id = 'research:${recipe.id}:${key(material.name)}';
          expanded.putIfAbsent(id, () => ArcRaidObjective(
            id: id, label: '${recipe.title}: ${material.name}',
            reason: 'Research/crafting dependency for ${recipe.title}; verify current inventory before farming.',
            category: ArcRaidMapMarkerCategory.upgrade,
            system: 'Research', itemName: material.name,
            missingCount: material.quantity * objective.missingCount,
            weight: objective.weight * 0.85,
          ));
        }
      }
    }
    return List.unmodifiable(expanded.values);
  }

  List<ArcUniversalMatch> matchesForMarker({
    required ArcRaidMapMarker marker,
    required List<ArcRaidObjective> objectives,
  }) {
    if (!marker.enabled || marker.isCluster) return const [];
    final poiEntries = ArcPoiLootIntelCatalog.forMarker(marker);
    final labelKey = key(marker.label);
    final structured = marker.tags.where((t) => t.startsWith('uag:')).toList();
    String? field(String name) {
      final prefix = 'uag:$name:';
      for (final tag in structured) {
        if (tag.startsWith(prefix)) return tag.substring(prefix.length);
      }
      return null;
    }
    final subtype = key(field('subtype') ?? marker.label);
    final explicitItem = key(field('item') ?? '');
    final explicitQuest = field('quest');
    final matches = <String, ArcUniversalMatch>{};

    void offer(ArcRaidObjective objective, String item, ArcUniversalEvidence evidence,
        double confidence, String source) {
      final candidate = ArcUniversalMatch(
        objective: objective, markerId: marker.id, evidence: evidence,
        itemName: item, source: source,
        score: confidence * (objective.weight <= 0 ? 1 : objective.weight),
      );
      final previous = matches[objective.id];
      if (previous == null || candidate.score > previous.score) matches[objective.id] = candidate;
    }

    for (final goal in objectives) {
      if (goal.questLocationOnly) {
        // Exact quest binding only; label similarity must never invent a quest location.
        if (goal.questId != null && explicitQuest == goal.questId) {
          offer(goal, goal.label, ArcUniversalEvidence.explicitMarker, 95, 'Published quest pin');
        }
        continue;
      }
      if (goal.missingCount <= 0) continue;
      final need = key(goal.itemName.isEmpty ? goal.label : goal.itemName);
      if (need.isEmpty) continue;
      if (explicitItem.isNotEmpty && explicitItem == need) {
        offer(goal, goal.itemName, ArcUniversalEvidence.explicitMarker, 90, 'Published item pin');
      }
      for (final entry in poiEntries) {
        if (key(entry.itemName) != need) continue;
        final isNamed = entry.evidence == ArcPoiLootEvidence.namedGuide;
        offer(goal, entry.itemName,
          isNamed ? ArcUniversalEvidence.namedPoi : ArcUniversalEvidence.researchedPool,
          isNamed ? 45 : 12, entry.sourceUrl);
      }
      // Canonical item records may identify named locations or specific
      // containers. Only exact matches are eligible; broad loot categories do
      // not establish a drop at every container on the map.
      for (final record in _itemIndex[need] ?? const <ArcPersonalItemRecord>[]) {
        if (marker.category == ArcRaidMapMarkerCategory.poi &&
            record.pois.any((poi) => key(poi) == labelKey)) {
          offer(goal, record.name, ArcUniversalEvidence.researchedPool, 28,
            'UAG item catalogue: named POI');
        }
        if (marker.category != ArcRaidMapMarkerCategory.poi &&
            record.containers.any((container) => key(container) == subtype)) {
          offer(goal, record.name, ArcUniversalEvidence.researchedPool, 22,
            'UAG item catalogue: container type');
        }
      }
      // ARC unit component names suggest a source, but are not independently
      // verified drop evidence. Keep such suggestions deliberately low-scored.
      if (marker.category == ArcRaidMapMarkerCategory.arcThreat &&
          subtype.isNotEmpty && subtype.length >= 3 &&
          (need.startsWith('$subtype ') || need == '$subtype cell' ||
           (subtype == 'queen' && need.startsWith('queen ')))) {
        offer(goal, goal.itemName, ArcUniversalEvidence.inferredSource, 9,
          'ARC type-name relationship; drop unverified');
      }
      if (marker.category == ArcRaidMapMarkerCategory.arcThreat &&
          need == 'arc alloy') {
        offer(goal, goal.itemName, ArcUniversalEvidence.inferredSource, 5,
          'General ARC salvage possibility; not guaranteed');
      }
      // A resource pin whose published name exactly identifies the needed
      // item is usable without guessing an ARC drop table.
      if (marker.category == ArcRaidMapMarkerCategory.upgrade && labelKey == need) {
        offer(goal, goal.itemName, ArcUniversalEvidence.explicitMarker, 70,
          'Published resource pin');
      }
    }
    return List.unmodifiable(matches.values.toList()
      ..sort((a, b) {
        final order = b.score.compareTo(a.score);
        return order != 0 ? order : a.objective.id.compareTo(b.objective.id);
      }));
  }

  /// Every objective is rewarded once per map, regardless of how many duplicate
  /// ARC/POI markers it matches. Additional covered goals improve a map's rank.
  List<ArcUniversalMapScore> rankMaps({
    required List<ArcRaidMapMarker> publishedMarkers,
    required List<ArcRaidObjective> objectives,
    int maxStopsPerMap = 16,
  }) {
    final expanded = expandObjectives(objectives);
    final grouped = <String, List<ArcRaidMapMarker>>{};
    for (final marker in publishedMarkers.where((m) => m.enabled && !m.isCluster)) {
      (grouped[marker.mapId] ??= []).add(marker);
    }
    final results = <ArcUniversalMapScore>[];
    for (final entry in grouped.entries) {
      final all = <ArcUniversalMatch>[];
      final best = <String, ArcUniversalMatch>{};
      final stopScores = <String, double>{};
      for (final marker in entry.value) {
        final matches = matchesForMarker(marker: marker, objectives: expanded);
        for (final match in matches) {
          all.add(match);
          if (best[match.objective.id] == null || best[match.objective.id]!.score < match.score) {
            best[match.objective.id] = match;
          }
          stopScores[marker.id] = (stopScores[marker.id] ?? 0) + match.score;
        }
      }
      // A verified quest-to-map binding informs map choice, but never creates
      // a fake quest waypoint. Only an actual linked quest pin can be routed.
      final mapQuestIds = objectives.where((o) => o.questLocationOnly &&
        o.questId != null && ArcQuestMapBinding.questSupportsMap(o.questId!, entry.key))
          .map((o) => o.questId!).toSet();
      if (best.isEmpty && mapQuestIds.isEmpty) continue;
      final sortedStops = stopScores.keys.toList()
        ..sort((a, b) {
          final order = stopScores[b]!.compareTo(stopScores[a]!);
          return order != 0 ? order : a.compareTo(b);
        });
      final bestMatches = best.values.toList();
      final questCount = bestMatches.where((m) => m.objective.questLocationOnly).length;
      final diversity = bestMatches.map((m) => m.objective.system).toSet().length;
      results.add(ArcUniversalMapScore(
        mapId: entry.key,
        score: bestMatches.fold<double>(0, (sum, m) => sum + m.score) +
          questCount * 25 + mapQuestIds.length * 150 +
          (diversity > 1 ? (diversity - 1) * 7 : 0),
        matchedObjectiveIds: List.unmodifiable(best.keys),
        stopIds: List.unmodifiable(sortedStops.take(maxStopsPerMap < 0 ? 0 : maxStopsPerMap)),
        matches: List.unmodifiable(all),
      ));
    }
    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.mapId.compareTo(b.mapId);
    });
    return List.unmodifiable(results);
  }
}
