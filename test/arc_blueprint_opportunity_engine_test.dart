import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

void main() {
  ArcBlueprintDropReport report({
    required String id,
    required String userId,
    required DateTime createdAt,
    int confirmations = 1,
  }) {
    return ArcBlueprintDropReport(
      id: id,
      blueprintId: 'anvil',
      userId: userId,
      mapName: ArcPoiDataStore.blueGate,
      sourceType: ArcDropSourceType.poi,
      poiId: 'blue_gate_warehouse_complex',
      poiName: 'Warehouse Complex',
      containerTypeId: 'weapon_case',
      containerTypeLabel: 'Weapon Case',
      mode: ArcRaidMode.dayRaid,
      raidType: ArcRaidType.fullRaid,
      entryTime: ArcEntryTime.unknown,
      timeOfDay: ArcTimeOfDay.midday,
      createdAt: createdAt,
      confirmationCount: confirmations,
      confirmedByUserIds: <String>[userId],
    );
  }

  test('aggregates drop reports into one calibrated opportunity', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[
        report(
          id: 'r1',
          userId: 'u1',
          createdAt: DateTime.utc(2026, 7, 24),
          confirmations: 2,
        ),
        report(
          id: 'r2',
          userId: 'u2',
          createdAt: DateTime.utc(2026, 7, 25),
          confirmations: 2,
        ),
      ],
      now: DateTime.utc(2026, 7, 25),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.blueprintIds, <String>['anvil']);
    expect(clusters.single.reportCount, 4);
    expect(clusters.single.independentReporterCount, 2);
    expect(clusters.single.point.x, closeTo(0.313, 0.001));
    expect(clusters.single.point.y, closeTo(0.476, 0.001));
    expect(
      clusters.single.evidence.every(
        (item) => item.sourceCategory == 'community_drop_report',
      ),
      isTrue,
    );
  });

  test('prefers calibrated map marker over approximate POI fallback', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    expect(
      map.markers.any(
        (marker) => marker.label == 'Warehouse Complex' && marker.approximate,
      ),
      isTrue,
    );
    expect(
      map.markers.any(
        (marker) =>
            marker.id == 'blue_gate_poi_warehouse_complex' &&
            !marker.approximate,
      ),
      isTrue,
    );
    expect(
      map.markers.any(
        (marker) =>
            marker.payloadId == 'blue_gate_warehouse_complex' &&
            marker.approximate,
      ),
      isTrue,
    );

    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[
        report(
          id: 'calibrated',
          userId: 'u1',
          createdAt: DateTime.utc(2026, 7, 25),
        ),
      ],
      now: DateTime.utc(2026, 7, 25),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.point.x, closeTo(0.313, 0.001));
    expect(clusters.single.point.y, closeTo(0.476, 0.001));
    final evidencePoint = clusters.single.evidence.single.point;
    expect(evidencePoint, isNotNull);
    expect(evidencePoint!.x, closeTo(0.313, 0.001));
    expect(evidencePoint.y, closeTo(0.476, 0.001));
  });

  test('ignores reports for another map', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final other = report(
      id: 'r3',
      userId: 'u3',
      createdAt: DateTime.utc(2026, 7, 25),
    ).copyWith(mapName: ArcPoiDataStore.spaceport);

    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[other],
      now: DateTime.utc(2026, 7, 25),
    );

    expect(clusters, isEmpty);
  });
}
