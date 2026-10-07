import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_research_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_trade_value_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_research_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

@immutable
class ArcBlueprintMapDefaults {
  const ArcBlueprintMapDefaults({
    required this.containerFamilies,
    required this.conditionIds,
    required this.researchVersion,
    required this.researchSummary,
  });

  final List<ArcBlueprintContainerFamily> containerFamilies;
  final List<String> conditionIds;
  final String researchVersion;
  final String researchSummary;

  ArcBlueprintContainerFamily get containerFamily {
    if (containerFamilies.contains(ArcBlueprintContainerFamily.security) &&
        containerFamilies.contains(ArcBlueprintContainerFamily.medical)) {
      return ArcBlueprintContainerFamily.securityMedical;
    }
    return containerFamilies.firstWhere(
      (value) => value != ArcBlueprintContainerFamily.anywhere,
      orElse: () => containerFamilies.isEmpty
          ? ArcBlueprintContainerFamily.unknown
          : containerFamilies.first,
    );
  }
}

@immutable
class ArcBlueprintMarkerMatch {
  const ArcBlueprintMarkerMatch({
    required this.marker,
    required this.score,
    required this.reason,
    required this.fallback,
  });

  final ArcAdminMapMarker marker;
  final double score;
  final String reason;
  final bool fallback;
}

/// Bridges canonical Blueprint research with editable UAG map markers.
///
/// The Blueprint research catalogue answers "what type of place/source should
/// this Blueprint come from?" while admin map markers answer "where is that
/// source on this map?". This keeps exact historical finds, container-density
/// intel and probability fallbacks in one routing path without pretending a
/// fallback area is a guaranteed Blueprint spawn.
class ArcBlueprintMapBackend {
  const ArcBlueprintMapBackend._();

  static ArcBlueprintMapDefaults? defaultsForBlueprintOnMap(
    String blueprintId,
    String mapId,
  ) {
    final research = ArcBlueprintResearchCatalog.forBlueprintOnMap(
      blueprintId,
      mapId,
    );
    if (research == null) return null;
    return ArcBlueprintMapDefaults(
      containerFamilies: containerFamiliesForResearch(research.container),
      conditionIds: conditionIdsForResearch(research.condition),
      researchVersion: ArcBlueprintResearchCatalog.dataVersion,
      researchSummary: research.evidenceSummary,
    );
  }

  static List<ArcBlueprintContainerFamily> containerFamiliesForResearch(
    String value,
  ) {
    final text = _normalize(value);
    if (text.isEmpty ||
        text.contains('notresolved') ||
        text.contains('unknown') ||
        text.contains('questonly')) {
      return const <ArcBlueprintContainerFamily>[];
    }

    final out = <ArcBlueprintContainerFamily>[];
    void add(ArcBlueprintContainerFamily value) {
      if (!out.contains(value)) out.add(value);
    }

    if (text.contains('anywhere')) add(ArcBlueprintContainerFamily.anywhere);
    if (text.contains('firstwave')) {
      add(ArcBlueprintContainerFamily.firstWaveCache);
    }
    if (text.contains('assessor')) add(ArcBlueprintContainerFamily.assessor);
    if (text.contains('harvester')) add(ArcBlueprintContainerFamily.harvester);
    if (text.contains('security')) add(ArcBlueprintContainerFamily.security);
    if (text.contains('medical')) add(ArcBlueprintContainerFamily.medical);
    if (text.contains('residential')) {
      add(ArcBlueprintContainerFamily.residential);
    }
    if (text.contains('industrial')) {
      add(ArcBlueprintContainerFamily.industrial);
    }
    if (text.contains('electrical')) {
      add(ArcBlueprintContainerFamily.electrical);
    }
    if (text.contains('raider')) add(ArcBlueprintContainerFamily.raider);

    return List<ArcBlueprintContainerFamily>.unmodifiable(out);
  }

  static ArcBlueprintContainerFamily containerFamilyForResearch(String value) {
    final families = containerFamiliesForResearch(value);
    if (families.contains(ArcBlueprintContainerFamily.security) &&
        families.contains(ArcBlueprintContainerFamily.medical)) {
      return ArcBlueprintContainerFamily.securityMedical;
    }
    return families.firstWhere(
      (family) => family != ArcBlueprintContainerFamily.anywhere,
      orElse: () => families.isEmpty
          ? ArcBlueprintContainerFamily.unknown
          : families.first,
    );
  }

  static List<String> conditionIdsForResearch(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty || text == 'any' || text.contains('any condition')) {
      return const <String>[];
    }
    final out = <String>[];
    void addIf(String label, String id) {
      if (text.contains(label.toLowerCase()) && !out.contains(id)) out.add(id);
    }

    addIf('Night Raid', 'night_raid');
    addIf('Electromagnetic Storm', 'electromagnetic_storm');
    addIf('Hurricane', 'hurricane');
    addIf('Locked Gate', 'locked_gate');
    addIf('Hidden Bunker', 'hidden_bunker');
    addIf('Close Scrutiny', 'close_scrutiny');
    addIf('Harvester', 'harvester');
    addIf('Uncovered Caches', 'uncovered_caches');
    addIf('Prospecting Probes', 'prospecting_probes');
    addIf('Cold Snap', 'cold_snap');
    addIf('Bloom', 'bloom');
    return List<String>.unmodifiable(out);
  }

  static List<ArcBlueprintMarkerMatch> matchesForBlueprint({
    required ArcBlueprint blueprint,
    required String mapId,
    required Iterable<ArcAdminMapMarker> markers,
    int limit = 4,
  }) {
    final onMap = markers.where(
      (marker) =>
          marker.mapId == mapId &&
          marker.isLive &&
          marker.state != ArcAdminMapMarkerState.archived,
    );
    final research = ArcBlueprintResearchCatalog.forBlueprintOnMap(
      blueprint.id,
      mapId,
    );

    final exact = <ArcBlueprintMarkerMatch>[];
    for (final marker in onMap) {
      if (marker.blueprintId != blueprint.id) continue;
      exact.add(
        ArcBlueprintMarkerMatch(
          marker: marker,
          score: 1000 + marker.confidence.score + _markerQuality(marker),
          reason:
              marker.effectiveBlueprintIntelType ==
                  ArcBlueprintMapIntelType.exactFind
              ? 'Admin-linked historical Blueprint find.'
              : 'Admin-linked Blueprint opportunity.',
          fallback: false,
        ),
      );
    }
    if (exact.isNotEmpty) return _top(exact, limit);

    if (research != null && !_canUseSourceRouting(research)) {
      return const <ArcBlueprintMarkerMatch>[];
    }

    final families = research == null
        ? const <ArcBlueprintContainerFamily>[]
        : containerFamiliesForResearch(research.container);
    final conditions = research == null
        ? const <String>[]
        : conditionIdsForResearch(research.condition);
    final sourceMatches = <ArcBlueprintMarkerMatch>[];
    final specificFamilies = families
        .where((family) => family != ArcBlueprintContainerFamily.anywhere)
        .toList(growable: false);
    if (specificFamilies.isNotEmpty) {
      for (final marker in onMap) {
        if (!specificFamilies.any(
          (family) =>
              _familyMatches(family, marker.effectiveBlueprintContainerFamily),
        )) {
          continue;
        }
        if (!_conditionCompatible(
          conditions,
          marker.blueprintConditionIds,
          requireExplicit:
              research?.eligibility ==
              ArcBlueprintResearchEligibility.eventOnly,
        )) {
          continue;
        }
        final score =
            420 +
            marker.confidence.score +
            _markerQuality(marker) +
            (ArcBlueprintTradeValueCatalog.tradePointsFor(blueprint) * 3);
        sourceMatches.add(
          ArcBlueprintMarkerMatch(
            marker: marker,
            score: score.toDouble(),
            reason:
                '${marker.effectiveBlueprintContainerFamily.label} matches the researched Blueprint source${conditions.isEmpty ? '' : ' and condition profile'}.',
            fallback: false,
          ),
        );
      }
    }
    if (sourceMatches.isNotEmpty) return _top(sourceMatches, limit);

    // Do not invent a generic route for a Blueprint known to be tied to a
    // quest/event/unavailable pool. Generic probability fallback is only for
    // normal/unverified pools or genuinely new Blueprints without research.
    if (research != null && !_canUseGenericFallback(research)) {
      return const <ArcBlueprintMarkerMatch>[];
    }

    final fallback = <ArcBlueprintMarkerMatch>[];
    for (final marker in onMap.where(
      (item) => item.supportsBlueprintFallback,
    )) {
      var score = 100.0 + marker.confidence.score + _markerQuality(marker);
      score += _rarityFallbackWeight(blueprint.rarity);
      score += ArcBlueprintTradeValueCatalog.tradePointsFor(blueprint) * 2;
      fallback.add(
        ArcBlueprintMarkerMatch(
          marker: marker,
          score: score,
          reason:
              'Probability fallback: ${marker.effectiveBlueprintLootTier.label.toLowerCase()} / ${marker.effectiveKind.label.toLowerCase()} with no exact Blueprint location available.',
          fallback: true,
        ),
      );
    }
    return _top(fallback, limit);
  }

  static bool _canUseSourceRouting(ArcBlueprintResearchEntry research) {
    return research.eligibility ==
            ArcBlueprintResearchEligibility.generalCandidate ||
        research.eligibility ==
            ArcBlueprintResearchEligibility.conditionCandidate ||
        research.eligibility == ArcBlueprintResearchEligibility.eventOnly ||
        research.eligibility == ArcBlueprintResearchEligibility.unverifiedPool;
  }

  static bool _canUseGenericFallback(ArcBlueprintResearchEntry research) {
    return research.eligibility ==
            ArcBlueprintResearchEligibility.generalCandidate ||
        research.eligibility ==
            ArcBlueprintResearchEligibility.conditionCandidate ||
        research.eligibility == ArcBlueprintResearchEligibility.unverifiedPool;
  }

  static bool _familyMatches(
    ArcBlueprintContainerFamily expected,
    ArcBlueprintContainerFamily actual,
  ) {
    if (expected == ArcBlueprintContainerFamily.anywhere) {
      return actual != ArcBlueprintContainerFamily.unknown;
    }
    if (expected == actual) return true;
    if (expected == ArcBlueprintContainerFamily.securityMedical) {
      return actual == ArcBlueprintContainerFamily.security ||
          actual == ArcBlueprintContainerFamily.medical ||
          actual == ArcBlueprintContainerFamily.securityMedical;
    }
    if (actual == ArcBlueprintContainerFamily.securityMedical) {
      return expected == ArcBlueprintContainerFamily.security ||
          expected == ArcBlueprintContainerFamily.medical;
    }
    return false;
  }

  static bool _conditionCompatible(
    List<String> expected,
    List<String> actual, {
    bool requireExplicit = false,
  }) {
    if (expected.isEmpty) return true;
    if (actual.isEmpty) return !requireExplicit;
    return expected.any(actual.contains);
  }

  static double _markerQuality(ArcAdminMapMarker marker) {
    final density = marker.blueprintContainerDensity.clamp(0, 5);
    final tier = switch (marker.effectiveBlueprintLootTier) {
      ArcBlueprintLootTier.standard => 0,
      ArcBlueprintLootTier.highValue => 18,
      ArcBlueprintLootTier.lockedRoom => 24,
      ArcBlueprintLootTier.epicLockedRoom => 34,
      ArcBlueprintLootTier.dynamicHotZone => 28,
    };
    final routingRole = switch (marker.effectiveBlueprintIntelType) {
      ArcBlueprintMapIntelType.none => 0,
      ArcBlueprintMapIntelType.exactFind => 50,
      ArcBlueprintMapIntelType.containerOpportunity => 24,
      ArcBlueprintMapIntelType.lootZoneFallback => 12,
    };
    return (density * 8 + tier + routingRole).toDouble();
  }

  static double _rarityFallbackWeight(ArcBlueprintRarity rarity) =>
      switch (rarity) {
        ArcBlueprintRarity.legendary => 36,
        ArcBlueprintRarity.epic => 28,
        ArcBlueprintRarity.rare => 18,
        ArcBlueprintRarity.uncommon => 10,
        ArcBlueprintRarity.common => 4,
      };

  static List<ArcBlueprintMarkerMatch> _top(
    List<ArcBlueprintMarkerMatch> values,
    int limit,
  ) {
    values.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.marker.name.compareTo(b.marker.name);
    });
    return List<ArcBlueprintMarkerMatch>.unmodifiable(values.take(limit));
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
