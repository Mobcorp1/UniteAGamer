import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_endpoint_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_time_budget.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

const spawn = ArcAdminMapMarker(
  id: 'live-player-1',
  mapId: 'blue_gate',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.poi,
  subtypeId: 'player_spawn',
  name: 'Mike’s north courtyard',
  point: ArcNormalizedPoint(x: .23, y: .41),
  state: ArcAdminMapMarkerState.published,
);
const exit = ArcAdminMapMarker(
  id: 'live-exit-1',
  mapId: 'blue_gate',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.extraction,
  name: 'Chosen lift',
  point: ArcNormalizedPoint(x: .76, y: .69),
  state: ArcAdminMapMarkerState.published,
);
void main() {
  final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
  ArcRaidEndpoints resolve(
    List<ArcAdminMapMarker> markers, {
    ArcRaidMapLayer layer = ArcRaidMapLayer.surface,
  }) => const ArcRaidEndpointResolver().resolve(
    seedMap: map,
    layer: layer,
    markers: markers,
  );
  test(
    'published player POI and extraction replace schematic options with exact IDs/names/points',
    () {
      final endpoints = resolve([spawn, exit]);
      expect(endpoints.spawns.map((s) => s.id), [spawn.id]);
      expect(endpoints.spawns.single.label, spawn.name);
      expect(endpoints.spawns.single.point, same(spawn.point));
      expect(endpoints.extractions.map((e) => e.id), [exit.id]);
      expect(endpoints.extractions.single.point, same(exit.point));
    },
  );
  test('ARC enemy spawns are never player spawns', () {
    final endpoints = resolve([
      spawn.copyWith(kind: ArcAdminMapMarkerKind.arcSpawn),
    ]);
    expect(endpoints.authoritativeSpawns, isFalse);
    expect(endpoints.spawns.any((s) => s.id == spawn.id), isFalse);
  });
  test(
    'wrong map/layer, drafts, provisional records, and archived endpoints are excluded',
    () {
      final bad = [
        spawn.copyWith(mapId: 'buried_city'),
        spawn.copyWith(layer: ArcRaidMapLayer.underground),
        spawn.copyWith(
          state: ArcAdminMapMarkerState.draft,
          provisionalVisible: true,
        ),
        spawn.copyWith(state: ArcAdminMapMarkerState.archived),
        exit.copyWith(state: ArcAdminMapMarkerState.draft),
        exit.copyWith(layer: ArcRaidMapLayer.underground),
      ];
      final endpoints = resolve(bad);
      expect(endpoints.authoritativeSpawns, isFalse);
      expect(endpoints.authoritativeExtractions, isFalse);
      expect(
        endpoints.extractions.map((e) => e.id),
        map.extractions.map((e) => e.id),
      );
      expect(
        resolve([], layer: ArcRaidMapLayer.underground).extractions,
        isEmpty,
      );
    },
  );
  test(
    'deletion/unpublishing safely rejects saved endpoints while static fallback continues',
    () {
      final before = resolve([spawn, exit]);
      final after = resolve([]);
      expect(after.resolveSpawn(before.spawns.single), isNull);
      expect(after.resolveExtraction(before.extractions.single), isNull);
      expect(after.resolveSpawn(after.spawns.first), isNotNull);
      expect(after.resolveExtraction(after.extractions.first), isNotNull);
    },
  );
  test(
    'legacy extraction IDs resolve only through explicit published seed references',
    () {
      final legacy = map.extractions.first;
      final endpoints = resolve([exit.copyWith(seedReferenceId: legacy.id)]);
      final old = const ArcRaidIntelligenceEngine().stopFromExtraction(legacy);
      expect(endpoints.resolveExtraction(old)?.id, exit.id);
      expect(
        endpoints
            .resolveExtraction(
              ArcRaidRouteStop(
                id: 'admin_extraction_${exit.id}',
                label: 'Old',
                point: exit.point,
                order: 0,
              ),
            )
            ?.id,
        exit.id,
      );
    },
  );
  test(
    'new spawn-name suggestions never modify or renumber existing labels',
    () {
      final names = ['Player Spawn 1', 'Player Spawn 3', 'Custom north spawn'];
      expect(
        ArcRaidEndpointResolver.nextPlayerSpawnName(names),
        'Player Spawn 2',
      );
      expect(names.last, 'Custom north spawn');
    },
  );
  test('time reduces objective depth and chosen extraction is always last', () {
    const engine = ArcRaidIntelligenceEngine();
    final endpoints = resolve([spawn, exit]);
    final clusters = List.generate(
      9,
      (i) => ArcRaidIntelCluster(
        id: 'c$i',
        mapId: map.id,
        label: 'Objective $i',
        point: ArcNormalizedPoint(x: .25 + i * .04, y: .43 + i * .02),
        blueprintIds: const [],
        evidence: const [],
        confidence: ArcRaidIntelConfidence.confirmed,
      ),
    );
    ArcRaidRoutePlan plan(int minutes) => engine.generateRoute(
      map: map,
      clusters: clusters,
      spawn: endpoints.spawns.single,
      extraction: endpoints.extractions.single,
      remainingMinutes: minutes,
      routeStyle: ArcRaidRouteStyle.thorough,
    )!;
    final full = plan(60), short = plan(5), urgent = plan(1);
    expect(full.stops.length, greaterThan(short.stops.length));
    expect(urgent.stops, isEmpty);
    for (final p in [full, short, urgent]) {
      expect(p.orderedStops.first.id, spawn.id);
      expect(p.orderedStops.last.id, exit.id);
      expect(p.extraction.point, same(exit.point));
      if (p.stops.isNotEmpty) expect(p.stops.first.order, 1);
    }
    expect(
      engine.generateRoute(
        map: map,
        clusters: clusters,
        spawn: endpoints.spawns.single,
        extraction: endpoints.extractions.single,
        remainingMinutes: 10,
        usesRaiderHatch: true,
        hatchKeyConfirmed: false,
      ),
      isNull,
    );
  });
  test('duration policy is explicit, configurable, and keeps style limits', () {
    const budget = ArcRaidTimeBudget(
      fullMinutes: 45,
      minutesPerStop: 5,
      exitReserveMinutes: 3,
    );
    expect(budget.preset('Full'), 45);
    expect(
      budget.stopLimit(
        remainingMinutes: 2,
        style: ArcRaidRouteStyle.thorough,
        stage: 'Full',
      ),
      0,
    );
    expect(
      budget.stopLimit(
        remainingMinutes: 13,
        style: ArcRaidRouteStyle.thorough,
        stage: 'Full',
      ),
      2,
    );
  });
}
