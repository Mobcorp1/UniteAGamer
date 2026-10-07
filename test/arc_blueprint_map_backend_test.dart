import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_map_backend.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  ArcBlueprint blueprint(String id) =>
      ArcBlueprintSeedData.blueprints.firstWhere((item) => item.id == id);

  ArcAdminMapMarker marker({
    required String id,
    required ArcAdminMapMarkerKind kind,
    String? blueprintId,
    ArcBlueprintMapIntelType intelType = ArcBlueprintMapIntelType.none,
    ArcBlueprintContainerFamily family = ArcBlueprintContainerFamily.unknown,
    List<String> conditionIds = const <String>[],
    ArcBlueprintLootTier lootTier = ArcBlueprintLootTier.standard,
    int density = 0,
    bool fallback = false,
  }) {
    return ArcAdminMapMarker(
      id: id,
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: kind,
      name: id,
      point: const ArcNormalizedPoint(x: 0.35, y: 0.45),
      blueprintId: blueprintId,
      blueprintIntelType: intelType,
      blueprintContainerFamily: family,
      blueprintConditionIds: conditionIds,
      blueprintLootTier: lootTier,
      blueprintContainerDensity: density,
      blueprintFallbackEligible: fallback,
      state: ArcAdminMapMarkerState.published,
      confidence: ArcRaidIntelConfidence.strong,
    );
  }

  test('research defaults map Wolfpack to Night Raid residential loot', () {
    final defaults = ArcBlueprintMapBackend.defaultsForBlueprintOnMap(
      'wolfpack',
      'blue_gate',
    );

    expect(defaults, isNotNull);
    expect(defaults!.containerFamily, ArcBlueprintContainerFamily.residential);
    expect(defaults.conditionIds, contains('night_raid'));
  });

  test(
    'multi-source research keeps both residential and First Wave options',
    () {
      final defaults = ArcBlueprintMapBackend.defaultsForBlueprintOnMap(
        'tempest',
        'blue_gate',
      );

      expect(defaults, isNotNull);
      expect(
        defaults!.containerFamilies,
        contains(ArcBlueprintContainerFamily.residential),
      );
      expect(
        defaults.containerFamilies,
        contains(ArcBlueprintContainerFamily.firstWaveCache),
      );
    },
  );

  test('exact linked Blueprint marker outranks generic map fallback', () {
    final wolfpack = blueprint('wolfpack');
    final matches = ArcBlueprintMapBackend.matchesForBlueprint(
      blueprint: wolfpack,
      mapId: 'blue_gate',
      markers: <ArcAdminMapMarker>[
        marker(
          id: 'generic_high_value',
          kind: ArcAdminMapMarkerKind.highValueLoot,
          lootTier: ArcBlueprintLootTier.highValue,
          fallback: true,
        ),
        marker(
          id: 'wolfpack_exact',
          kind: ArcAdminMapMarkerKind.blueprint,
          blueprintId: 'wolfpack',
          intelType: ArcBlueprintMapIntelType.exactFind,
        ),
      ],
    );

    expect(matches, isNotEmpty);
    expect(matches.first.marker.id, 'wolfpack_exact');
    expect(matches.first.fallback, isFalse);
  });

  test(
    'container family metadata turns map marker into Blueprint route intel',
    () {
      final wolfpack = blueprint('wolfpack');
      final matches = ArcBlueprintMapBackend.matchesForBlueprint(
        blueprint: wolfpack,
        mapId: 'blue_gate',
        markers: <ArcAdminMapMarker>[
          marker(
            id: 'village_residential_cluster',
            kind: ArcAdminMapMarkerKind.containerCluster,
            intelType: ArcBlueprintMapIntelType.containerOpportunity,
            family: ArcBlueprintContainerFamily.residential,
            conditionIds: const <String>['night_raid'],
            density: 5,
          ),
        ],
      );

      expect(matches, isNotEmpty);
      expect(matches.first.marker.id, 'village_residential_cluster');
      expect(matches.first.fallback, isFalse);
    },
  );

  test('unknown Legendary Blueprint can use high-value fallback marker', () {
    const futureBlueprint = ArcBlueprint(
      id: 'future-legendary-test',
      name: 'Future Legendary Test',
      category: 'Weapons',
      group: 'Test',
      sortOrder: 999,
      rarity: ArcBlueprintRarity.legendary,
      icon: nullIcon,
    );
    final matches = ArcBlueprintMapBackend.matchesForBlueprint(
      blueprint: futureBlueprint,
      mapId: 'blue_gate',
      markers: <ArcAdminMapMarker>[
        marker(
          id: 'epic_locked_room',
          kind: ArcAdminMapMarkerKind.lockedRoom,
          lootTier: ArcBlueprintLootTier.epicLockedRoom,
          density: 4,
          fallback: true,
        ),
      ],
    );

    expect(matches, isNotEmpty);
    expect(matches.first.fallback, isTrue);
  });

  test(
    'event-only Blueprint can use an explicitly conditioned event source marker',
    () {
      final bobcat = blueprint('bobcat');
      final matches = ArcBlueprintMapBackend.matchesForBlueprint(
        blueprint: bobcat,
        mapId: 'blue_gate',
        markers: <ArcAdminMapMarker>[
          marker(
            id: 'hurricane_first_wave',
            kind: ArcAdminMapMarkerKind.firstWaveCache,
            intelType: ArcBlueprintMapIntelType.containerOpportunity,
            family: ArcBlueprintContainerFamily.firstWaveCache,
            conditionIds: const <String>['hurricane'],
            density: 4,
            fallback: true,
          ),
        ],
      );

      expect(matches, isNotEmpty);
      expect(matches.first.marker.id, 'hurricane_first_wave');
      expect(matches.first.fallback, isFalse);
    },
  );

  test(
    'event-only Blueprint never degrades to a generic high-value fallback',
    () {
      final bobcat = blueprint('bobcat');
      final matches = ArcBlueprintMapBackend.matchesForBlueprint(
        blueprint: bobcat,
        mapId: 'blue_gate',
        markers: <ArcAdminMapMarker>[
          marker(
            id: 'generic_red_zone',
            kind: ArcAdminMapMarkerKind.highValueLoot,
            lootTier: ArcBlueprintLootTier.highValue,
            density: 5,
            fallback: true,
          ),
        ],
      );

      expect(matches, isEmpty);
    },
  );

  test(
    'legacy marker kinds infer Blueprint source traits without re-entry',
    () {
      final legacyFirstWave = marker(
        id: 'legacy_first_wave',
        kind: ArcAdminMapMarkerKind.firstWaveCache,
      );
      final legacyLocked = marker(
        id: 'legacy_locked_room',
        kind: ArcAdminMapMarkerKind.lockedRoom,
      );

      expect(
        legacyFirstWave.effectiveBlueprintContainerFamily,
        ArcBlueprintContainerFamily.firstWaveCache,
      );
      expect(legacyFirstWave.supportsBlueprintFallback, isTrue);
      expect(
        legacyLocked.effectiveBlueprintLootTier,
        ArcBlueprintLootTier.lockedRoom,
      );
      expect(legacyLocked.supportsBlueprintFallback, isTrue);
    },
  );

  test('marker Blueprint-routing metadata round-trips through storage map', () {
    final original = marker(
      id: 'round_trip',
      kind: ArcAdminMapMarkerKind.containerCluster,
      intelType: ArcBlueprintMapIntelType.containerOpportunity,
      family: ArcBlueprintContainerFamily.securityMedical,
      conditionIds: const <String>['night_raid', 'hurricane'],
      lootTier: ArcBlueprintLootTier.highValue,
      density: 5,
      fallback: true,
    );

    final restored = ArcAdminMapMarker.fromMap(original.toMap());
    expect(restored.blueprintIntelType, original.blueprintIntelType);
    expect(
      restored.blueprintContainerFamily,
      original.blueprintContainerFamily,
    );
    expect(restored.blueprintConditionIds, original.blueprintConditionIds);
    expect(restored.blueprintLootTier, original.blueprintLootTier);
    expect(restored.blueprintContainerDensity, 5);
    expect(restored.blueprintFallbackEligible, isTrue);
  });

  test(
    'Raid Intelligence consumes admin container metadata before POI fallback',
    () {
      final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
      final clusterMarker = marker(
        id: 'wolfpack_route_cluster',
        kind: ArcAdminMapMarkerKind.containerCluster,
        intelType: ArcBlueprintMapIntelType.containerOpportunity,
        family: ArcBlueprintContainerFamily.residential,
        conditionIds: const <String>['night_raid'],
        density: 5,
      );

      final clusters = const ArcRaidIntelligenceEngine().opportunityClusters(
        map: map,
        blueprintStates: <String, ArcBlueprintState>{
          'wolfpack': ArcBlueprintState.empty('wolfpack'),
        },
        canonicalMarkers: <ArcAdminMapMarker>[clusterMarker],
      );

      final wolfpackClusters = clusters
          .where((cluster) => cluster.blueprintIds.contains('wolfpack'))
          .toList(growable: false);
      expect(wolfpackClusters, isNotEmpty);
      expect(
        wolfpackClusters.any(
          (cluster) => cluster.label.contains('wolfpack_route_cluster'),
        ),
        isTrue,
      );
    },
  );
}

// Stable icon constant without pulling application theme state into this test.
const nullIcon = IconData(0xe000, fontFamily: 'MaterialIcons');
