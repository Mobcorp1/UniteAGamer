import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_loot_intel_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

/// Personal relevance is computed from the user's actual active tracker needs.
/// The immutable POI catalogue is *evidence*, not a player drop report.
class ArcPoiPersonalMatch {
  const ArcPoiPersonalMatch({
    required this.itemName,
    required this.reason,
    required this.evidence,
    required this.sourceUrl,
    required this.score,
  });

  final String itemName;
  final String reason;
  final ArcPoiLootEvidence evidence;
  final String sourceUrl;
  final int score;
  bool get isNamedPoiEvidence => evidence == ArcPoiLootEvidence.namedGuide;
}

class ArcPoiPersonalNeedResolver {
  const ArcPoiPersonalNeedResolver();

  static String normalise(String raw) => raw
      .toLowerCase()
      .replaceAll(RegExp(r'\bblueprint\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// Only actual visible/published markers can receive a POI recommendation.
  /// No implicit geo pin or duplicate Firestore report is generated.
  Map<String, List<ArcPoiPersonalMatch>> matchVisibleMarkers({
    required List<ArcRaidMapMarker> markers,
    required List<ArcRaidObjective> trackedObjectives,
    required Map<String, ArcBlueprintState> blueprintStates,
    int maxPerPoi = 4,
  }) {
    final needed = <String, ({String reason, int priority})>{};
    for (final objective in trackedObjectives) {
      if (objective.questLocationOnly || objective.missingCount <= 0) continue;
      final key = normalise(objective.itemName);
      if (key.isEmpty) continue;
      final score = objective.system.toLowerCase() == 'quest' ? 80 : 65;
      if (!needed.containsKey(key) || needed[key]!.priority < score) {
        needed[key] = (reason: objective.system, priority: score);
      }
    }
    // Prioritised, missing blueprints only. Do not flag all merely unowned blueprints.
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state = blueprintStates[blueprint.id];
      if (state == null || state.owned || state.priorityRank <= 0) continue;
      needed[normalise(blueprint.name)] =
          (reason: 'Priority blueprint', priority: 90 + (6 - state.priorityRank).clamp(0, 5));
    }
    if (needed.isEmpty || maxPerPoi <= 0) return const {};

    final results = <String, List<ArcPoiPersonalMatch>>{};
    for (final marker in markers) {
      final entries = ArcPoiLootIntelCatalog.forMarker(marker);
      if (entries.isEmpty) continue;
      final matches = <String, ArcPoiPersonalMatch>{};
      for (final entry in entries) {
        final key = normalise(entry.itemName);
        final request = needed[key];
        if (request == null) continue;
        final evidenceScore = entry.evidence == ArcPoiLootEvidence.namedGuide ? 50 : 5;
        final score = request.priority + evidenceScore;
        final previous = matches[key];
        if (previous == null || score > previous.score) {
          matches[key] = ArcPoiPersonalMatch(
            itemName: entry.itemName,
            reason: request.reason,
            evidence: entry.evidence,
            sourceUrl: entry.sourceUrl,
            score: score,
          );
        }
      }
      if (matches.isEmpty) continue;
      final sorted = matches.values.toList()
        ..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          return byScore != 0 ? byScore : a.itemName.compareTo(b.itemName);
        });
      results[marker.id] = List.unmodifiable(sorted.take(maxPerPoi));
    }
    return Map.unmodifiable(results);
  }
}
