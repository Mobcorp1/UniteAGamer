import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

/// Turns live Quest / Scrappy / Bench tracker progress into cautious map
/// opportunities. This engine never claims a resource is guaranteed at a POI.
/// It only scores published/seeded locations whose known loot classification or
/// explicit admin marker metadata matches the tracker's current source guidance.
class ArcRaidObjectiveIntelligenceEngine {
  const ArcRaidObjectiveIntelligenceEngine();

  static const int defaultMaxClusters = 12;
  static const int _maxSitesPerObjective = 3;
  static const int _minimumSiteScore = 26;

  List<ArcRaidObjective> trackedObjectives({
    required ArcProgressionSnapshotBundle progression,
    required Map<String, ArcScrappyState> scrappyStates,
  }) {
    final objectives = <ArcRaidObjective>[];

    final activeQuest = progression.quest.activeQuest;
    if (progression.quest.trackingKnown &&
        activeQuest != null &&
        !activeQuest.completed &&
        !activeQuest.locked) {
      for (final objective in activeQuest.objectives) {
        if (objective.complete || objective.missingCount <= 0) continue;
        objectives.add(
          ArcRaidObjective(
            id: 'quest:${activeQuest.questId}:${objective.id}',
            label: '${activeQuest.questLabel}: ${objective.label}',
            reason:
                '${activeQuest.questLabel} needs ${objective.label} x${objective.missingCount}.',
            category: ArcRaidMapMarkerCategory.questObjective,
            system: 'Quest',
            itemName: objective.label,
            missingCount: objective.missingCount,
            sourceHint: objective.sourceHint,
            weight: 1.35,
          ),
        );
      }
    }

    final scrappyUpgrade = progression.scrappy.nextUpgrade;
    if (progression.scrappy.trackingKnown && scrappyUpgrade != null) {
      for (final objective in scrappyUpgrade.objectives) {
        final current =
            scrappyStates[objective.id]?.collectedCount ??
            objective.safeCurrentCount;
        final missing = math.max(0, objective.requiredCount - current);
        if (missing <= 0) continue;
        objectives.add(
          ArcRaidObjective(
            id: 'scrappy:${scrappyUpgrade.level}:${objective.id}',
            label: '${scrappyUpgrade.title}: ${objective.label}',
            reason:
                '${scrappyUpgrade.title} needs ${objective.label} x$missing.',
            category: ArcRaidMapMarkerCategory.operationObjective,
            system: 'Scrappy',
            itemName: objective.label,
            missingCount: missing,
            sourceHint: objective.sourceHint,
            weight: 1.15,
          ),
        );
      }
    }

    final benchUpgrade = progression.bench.nextUpgrade;
    if (progression.bench.trackingKnown && benchUpgrade != null) {
      for (final objective in benchUpgrade.objectives) {
        final current =
            scrappyStates[objective.id]?.collectedCount ??
            objective.safeCurrentCount;
        final missing = math.max(0, objective.requiredCount - current);
        if (missing <= 0) continue;
        objectives.add(
          ArcRaidObjective(
            id: 'bench:${benchUpgrade.benchId}:${benchUpgrade.level}:${objective.id}',
            label: '${benchUpgrade.upgradeLabel}: ${objective.label}',
            reason:
                '${benchUpgrade.upgradeLabel} needs ${objective.label} x$missing.',
            category: ArcRaidMapMarkerCategory.operationObjective,
            system: 'Bench',
            itemName: objective.label,
            missingCount: missing,
            sourceHint: objective.sourceHint,
            weight: 1.0,
          ),
        );
      }
    }

    return List<ArcRaidObjective>.unmodifiable(objectives);
  }

  List<ArcRaidIntelCluster> buildClusters({
    required ArcRaidMap map,
    required List<ArcRaidObjective> objectives,
    List<ArcAdminMapMarker> adminMarkers = const <ArcAdminMapMarker>[],
    int maxClusters = defaultMaxClusters,
  }) {
    if (objectives.isEmpty) return const <ArcRaidIntelCluster>[];

    final sites = _candidateSites(map, adminMarkers);
    if (sites.isEmpty) return const <ArcRaidIntelCluster>[];

    final accumulators = <String, _ObjectiveSiteAccumulator>{};
    for (final objective in objectives) {
      final ranked = <({int score, _ObjectiveSite site})>[];
      for (final site in sites) {
        final score = _siteScore(objective, site);
        if (score >= _minimumSiteScore) {
          ranked.add((score: score, site: site));
        }
      }
      ranked.sort((left, right) {
        final scoreCompare = right.score.compareTo(left.score);
        if (scoreCompare != 0) return scoreCompare;
        return left.site.name.compareTo(right.site.name);
      });

      for (final match in ranked.take(_maxSitesPerObjective)) {
        final accumulator = accumulators.putIfAbsent(
          match.site.identity,
          () => _ObjectiveSiteAccumulator(match.site),
        );
        accumulator.add(objective, match.score);
      }
    }

    final ordered =
        accumulators.values
            .where((entry) => entry.objectives.isNotEmpty)
            .toList(growable: false)
          ..sort((left, right) {
            final scoreCompare = right.totalScore.compareTo(left.totalScore);
            if (scoreCompare != 0) return scoreCompare;
            final objectiveCompare = right.objectives.length.compareTo(
              left.objectives.length,
            );
            if (objectiveCompare != 0) return objectiveCompare;
            return left.site.name.compareTo(right.site.name);
          });

    return List<ArcRaidIntelCluster>.unmodifiable(
      ordered.take(math.max(1, maxClusters)).map(_clusterForAccumulator),
    );
  }

  ArcRaidIntelCluster _clusterForAccumulator(
    _ObjectiveSiteAccumulator accumulator,
  ) {
    final objectives = accumulator.objectives.values.toList(growable: false)
      ..sort((left, right) {
        final weightCompare = right.weight.compareTo(left.weight);
        if (weightCompare != 0) return weightCompare;
        return left.label.compareTo(right.label);
      });
    final systems = objectives.map((objective) => objective.system).toSet();
    final category = objectives.any((objective) => objective.system == 'Quest')
        ? ArcRaidMapMarkerCategory.questObjective
        : ArcRaidMapMarkerCategory.operationObjective;
    final confidence =
        accumulator.bestScore >= 82 &&
            accumulator.site.confidence.score >=
                ArcRaidIntelConfidence.moderate.score
        ? ArcRaidIntelConfidence.moderate
        : ArcRaidIntelConfidence.limited;
    final source = systems.toList(growable: false)..sort();

    return ArcRaidIntelCluster(
      id: 'tracker_${accumulator.site.identity}',
      mapId: accumulator.site.mapId,
      label: accumulator.site.name,
      point: accumulator.site.point,
      layer: accumulator.site.layer,
      poiId: accumulator.site.poiId,
      blueprintIds: const <String>[],
      evidence: const <ArcRaidIntelEvidence>[],
      confidence: confidence,
      freshnessLabel: 'Live tracker guidance',
      commonSource: '${source.join(' + ')} tracker',
      conditionCorrelation: _conditionCorrelation(objectives),
      markerCategory: category,
      objectives: objectives,
      objectiveScore: accumulator.weightedScore,
    );
  }

  List<_ObjectiveSite> _candidateSites(
    ArcRaidMap map,
    List<ArcAdminMapMarker> adminMarkers,
  ) {
    final result = <String, _ObjectiveSite>{};

    for (final poi in map.pois) {
      final site = _ObjectiveSite(
        identity: 'poi:${poi.id}',
        mapId: map.id,
        name: poi.name,
        point: poi.point,
        layer: ArcRaidMapLayer.surface,
        poiId: poi.id,
        tags: <String>{...poi.lootTags, 'POI'},
        confidence: poi.approximate
            ? ArcRaidIntelConfidence.limited
            : ArcRaidIntelConfidence.moderate,
      );
      result[site.identity] = site;
    }

    for (final marker in map.markers) {
      if (!_seedMarkerCanSupportObjectives(marker.category)) continue;
      final identity = marker.payloadId?.trim().isNotEmpty == true
          ? 'seed:${marker.payloadId}'
          : 'seed:${marker.id}';
      result.putIfAbsent(
        identity,
        () => _ObjectiveSite(
          identity: identity,
          mapId: map.id,
          name: marker.label,
          point: marker.point,
          layer: marker.layer,
          poiId: marker.category == ArcRaidMapMarkerCategory.poi
              ? marker.payloadId
              : null,
          tags: <String>{marker.category.label, ...marker.tags, marker.detail},
          confidence: marker.confidence,
          markerCategory: marker.category,
        ),
      );
    }

    for (final marker in adminMarkers) {
      if (marker.mapId != map.id ||
          !marker.isPublished ||
          !_adminMarkerCanSupportObjectives(marker.kind)) {
        continue;
      }
      final stable = marker.seedReferenceId?.trim();
      final identity = stable != null && stable.isNotEmpty
          ? 'admin:$stable:${marker.kind.name}'
          : 'admin:${marker.id}';
      result[identity] = _ObjectiveSite(
        identity: identity,
        mapId: map.id,
        name: marker.name,
        point: marker.point,
        layer: marker.layer,
        poiId: marker.kind == ArcAdminMapMarkerKind.poi ? stable : null,
        tags: <String>{
          marker.kind.label,
          ...marker.aliases,
          marker.description,
          if (marker.subtypeId != null) marker.subtypeId!,
          if (marker.subtypeLabel != null) marker.subtypeLabel!,
          if (marker.sourceName != null) marker.sourceName!,
        },
        confidence: marker.confidence,
        adminKind: marker.kind,
      );
    }

    return result.values.toList(growable: false);
  }

  int _siteScore(ArcRaidObjective objective, _ObjectiveSite site) {
    final source = _normalize(
      '${objective.sourceHint ?? ''} ${objective.reason} ${objective.itemName}',
    );
    final name = _normalize(site.name);
    final siteText = _normalize('${site.name} ${site.tags.join(' ')}');
    final intentTags = _intentTags(source);
    var score = 0;

    if (name.length >= 4 && source.contains(name)) score += 90;
    final itemName = _normalize(objective.itemName);
    if (itemName.length >= 4 && siteText.contains(itemName)) score += 110;

    for (final tag in intentTags) {
      if (_siteHasTag(site, tag)) score += 34;
    }

    // Generic admin categories such as "Resource Node" or "Quest Location"
    // are not enough on their own to place an unrelated tracker objective.
    // Require a semantic item/name/loot-type match before category metadata can
    // strengthen the recommendation.
    final hasSemanticMatch = score > 0;

    if (hasSemanticMatch &&
        site.tags.any((tag) => _normalize(tag) == 'high loot')) {
      score += 12;
    }
    if (hasSemanticMatch &&
        site.tags.any((tag) => _normalize(tag) == 'medium loot')) {
      score += 6;
    }

    final kind = site.adminKind;
    if (kind != null) {
      if (kind == ArcAdminMapMarkerKind.questLocation) {
        if (hasSemanticMatch && objective.system == 'Quest') score += 48;
      } else if (kind == ArcAdminMapMarkerKind.resourceNode) {
        if (hasSemanticMatch) score += 42;
      } else if (kind == ArcAdminMapMarkerKind.naturalResource) {
        score += intentTags.contains(ArcBuildingType.nature.label) ? 46 : 18;
      } else if (kind == ArcAdminMapMarkerKind.arcSpawn) {
        score += intentTags.contains(ArcBuildingType.arc.label) ? 52 : 8;
      } else if (kind == ArcAdminMapMarkerKind.securityRoom) {
        score += intentTags.contains(ArcBuildingType.security.label) ? 42 : 12;
      } else if (kind == ArcAdminMapMarkerKind.weaponCase ||
          kind == ArcAdminMapMarkerKind.weaponCache) {
        score += intentTags.contains(ArcBuildingType.security.label) ? 34 : 15;
      } else if (kind == ArcAdminMapMarkerKind.highValueLoot ||
          kind == ArcAdminMapMarkerKind.lockedRoom ||
          kind == ArcAdminMapMarkerKind.keyRequiredLocation) {
        score += 20;
      } else if (kind == ArcAdminMapMarkerKind.lootContainer ||
          kind == ArcAdminMapMarkerKind.containerCluster ||
          kind == ArcAdminMapMarkerKind.fieldCrate ||
          kind == ArcAdminMapMarkerKind.raiderCache ||
          kind == ArcAdminMapMarkerKind.firstWaveCache) {
        score += 10;
      }
    }

    final category = site.markerCategory;
    if (category != null) {
      if (category == ArcRaidMapMarkerCategory.securityLocker ||
          category == ArcRaidMapMarkerCategory.weaponCase ||
          category == ArcRaidMapMarkerCategory.raiderCache) {
        score += intentTags.contains(ArcBuildingType.security.label) ? 20 : 8;
      } else if (category == ArcRaidMapMarkerCategory.fieldCrate ||
          category == ArcRaidMapMarkerCategory.containerCluster ||
          category == ArcRaidMapMarkerCategory.generalLoot) {
        score += 6;
      } else if (category == ArcRaidMapMarkerCategory.arcThreat &&
          intentTags.contains(ArcBuildingType.arc.label)) {
        score += 28;
      }
    }

    return score;
  }

  Set<String> _intentTags(String normalizedSource) {
    final tags = <String>{};

    void addIf(String tag, Iterable<String> needles) {
      if (needles.any(normalizedSource.contains)) tags.add(tag);
    }

    addIf(ArcBuildingType.medical.label, <String>[
      'medical',
      ' med ',
      'med crate',
      'clinic',
      'hospital',
      'treatment',
      'bioscanner',
      'antiseptic',
      'syringe',
      'laboratory',
      ' lab ',
    ]);
    addIf(ArcBuildingType.residential.label, <String>[
      'residential',
      'civilian',
      'apartment',
      'house',
      'bedroom',
      'wardrobe',
      'bathroom',
      'hotel',
      'school',
      'kitchen',
    ]);
    addIf(ArcBuildingType.commercial.label, <String>[
      'commercial',
      'office',
      'bar',
      'cafe',
      'counter',
      'market',
      'shop',
    ]);
    addIf(ArcBuildingType.oldWorld.label, <String>[
      'old world',
      'photograph',
      'film reel',
      'recorder',
    ]);
    addIf(ArcBuildingType.nature.label, <String>[
      'nature',
      'fruit',
      'garden',
      'orchard',
      'greenhouse',
      'plant',
      'organic',
      'swamp',
      'marsh',
      'vegetation',
      'olive grove',
      'park',
      'wicker basket',
      'lush blooms',
      'mushroom',
      'apricot',
      'lemon',
      'olive',
      'prickly pear',
    ]);
    addIf(ArcBuildingType.technological.label, <String>[
      'technological',
      ' tech ',
      'server',
      'electronics',
      'electronic',
      'sensor',
      'motherboard',
      'camera room',
      'surveillance',
    ]);
    addIf(ArcBuildingType.electrical.label, <String>[
      'electrical',
      'power room',
      'power generation',
      'battery',
      'wires',
      'circuit',
      'heat sink',
      'power cable',
    ]);
    addIf(ArcBuildingType.mechanical.label, <String>[
      'mechanical',
      'workshop',
      'garage',
      'machinery',
      'tool',
      'motor',
      'gear',
      'oil',
    ]);
    addIf(ArcBuildingType.industrial.label, <String>[
      'industrial',
      'loading area',
      'fuel storage',
      'chemical storage',
      'utility room',
      'rusted metal',
    ]);
    addIf(ArcBuildingType.security.label, <String>[
      'security',
      'weapon cache',
      'weapon case',
      'military',
      'locked room',
      'breach room',
      'high loot combat',
    ]);
    addIf(ArcBuildingType.exodus.label, <String>['exodus']);
    addIf(ArcBuildingType.arc.label, <String>[
      'defeated arc',
      'destroyed arc',
      'arc enemy',
      'arc enemies',
      'arc patrol',
      'arc heavy',
      'arc wreck',
      'wasp',
      'hornet',
      'snitch',
      'leaper',
      'surveyor',
      'rocketeer',
      'tick arc',
      'fireball',
      'sentinel',
      'bastion',
      'bombardier',
    ]);

    return tags;
  }

  bool _siteHasTag(_ObjectiveSite site, String desiredTag) {
    final desired = _normalize(desiredTag);
    return site.tags.any((tag) {
      final normalized = _normalize(tag);
      return normalized == desired || normalized.contains(desired);
    });
  }

  bool _seedMarkerCanSupportObjectives(ArcRaidMapMarkerCategory category) {
    return const <ArcRaidMapMarkerCategory>{
      ArcRaidMapMarkerCategory.weaponCase,
      ArcRaidMapMarkerCategory.securityLocker,
      ArcRaidMapMarkerCategory.firstWaveCache,
      ArcRaidMapMarkerCategory.raiderCache,
      ArcRaidMapMarkerCategory.fieldCrate,
      ArcRaidMapMarkerCategory.lockedRoom,
      ArcRaidMapMarkerCategory.keyRoom,
      ArcRaidMapMarkerCategory.containerCluster,
      ArcRaidMapMarkerCategory.generalLoot,
      ArcRaidMapMarkerCategory.arcThreat,
    }.contains(category);
  }

  bool _adminMarkerCanSupportObjectives(ArcAdminMapMarkerKind kind) {
    return const <ArcAdminMapMarkerKind>{
      ArcAdminMapMarkerKind.questLocation,
      ArcAdminMapMarkerKind.resourceNode,
      ArcAdminMapMarkerKind.naturalResource,
      ArcAdminMapMarkerKind.arcSpawn,
      ArcAdminMapMarkerKind.weaponCase,
      ArcAdminMapMarkerKind.weaponCache,
      ArcAdminMapMarkerKind.firstWaveCache,
      ArcAdminMapMarkerKind.raiderCache,
      ArcAdminMapMarkerKind.fieldCrate,
      ArcAdminMapMarkerKind.lootContainer,
      ArcAdminMapMarkerKind.containerCluster,
      ArcAdminMapMarkerKind.lockedRoom,
      ArcAdminMapMarkerKind.securityRoom,
      ArcAdminMapMarkerKind.highValueLoot,
      ArcAdminMapMarkerKind.keyRequiredLocation,
    }.contains(kind);
  }

  String _conditionCorrelation(List<ArcRaidObjective> objectives) {
    final hints = objectives
        .map((objective) => objective.sourceHint ?? '')
        .join(' ')
        .toLowerCase();
    if (hints.contains('lush blooms')) return 'Lush Blooms improves this run';
    return 'Current tracker objectives';
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _ObjectiveSiteAccumulator {
  _ObjectiveSiteAccumulator(this.site);

  final _ObjectiveSite site;
  final Map<String, ArcRaidObjective> objectives = <String, ArcRaidObjective>{};
  double weightedScore = 0;
  int totalScore = 0;
  int bestScore = 0;

  void add(ArcRaidObjective objective, int score) {
    if (objectives.containsKey(objective.id)) return;
    objectives[objective.id] = objective;
    weightedScore += score * objective.weight;
    totalScore += score;
    bestScore = math.max(bestScore, score);
  }
}

class _ObjectiveSite {
  const _ObjectiveSite({
    required this.identity,
    required this.mapId,
    required this.name,
    required this.point,
    required this.layer,
    required this.tags,
    required this.confidence,
    this.poiId,
    this.adminKind,
    this.markerCategory,
  });

  final String identity;
  final String mapId;
  final String name;
  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
  final String? poiId;
  final Set<String> tags;
  final ArcRaidIntelConfidence confidence;
  final ArcAdminMapMarkerKind? adminKind;
  final ArcRaidMapMarkerCategory? markerCategory;
}
