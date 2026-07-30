import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  ArcBlueprintDropReport report({
    String poiId = 'blue_gate_warehouse_complex',
    String poiName = 'Warehouse Complex',
  }) {
    return ArcBlueprintDropReport(
      id: 'historic_drop',
      blueprintId: 'anvil',
      userId: 'reporter',
      mapName: ArcPoiDataStore.blueGate,
      sourceType: ArcDropSourceType.poi,
      poiId: poiId,
      poiName: poiName,
      mode: ArcRaidMode.dayRaid,
      raidType: ArcRaidType.fullRaid,
      entryTime: ArcEntryTime.unknown,
      timeOfDay: ArcTimeOfDay.midday,
      createdAt: DateTime.utc(2026, 7, 1),
      confirmationCount: 1,
      confirmedByUserIds: const <String>['reporter'],
    );
  }

  const movedAnchor = ArcAdminMapMarker(
    id: 'admin_blue_gate_warehouse',
    mapId: 'blue_gate',
    layer: ArcRaidMapLayer.underground,
    kind: ArcAdminMapMarkerKind.poi,
    name: 'Warehouse Complex - Corrected',
    aliases: <String>['Warehouse Complex'],
    point: ArcNormalizedPoint(x: 0.81, y: 0.22),
    confidence: ArcRaidIntelConfidence.confirmed,
    state: ArcAdminMapMarkerState.published,
    adminVerified: true,
    seedReferenceId: 'blue_gate_warehouse_complex',
    sourceRecordId: 'blue_gate_warehouse_complex',
  );

  test('historical Blueprint reports follow a moved canonical POI anchor', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');

    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[report()],
      canonicalMarkers: const <ArcAdminMapMarker>[movedAnchor],
      now: DateTime.utc(2026, 7, 30),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.point.x, closeTo(0.81, 0.0001));
    expect(clusters.single.point.y, closeTo(0.22, 0.0001));
    expect(clusters.single.layer, ArcRaidMapLayer.underground);
    expect(clusters.single.evidence.single.point?.x, closeTo(0.81, 0.0001));
    expect(clusters.single.evidence.single.point?.y, closeTo(0.22, 0.0001));
  });

  test('historical POI names resolve through current marker aliases', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');

    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[
        report(poiId: '', poiName: 'Warehouse Complex'),
      ],
      canonicalMarkers: const <ArcAdminMapMarker>[movedAnchor],
      now: DateTime.utc(2026, 7, 30),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.point.x, closeTo(0.81, 0.0001));
    expect(clusters.single.point.y, closeTo(0.22, 0.0001));
    expect(clusters.single.layer, movedAnchor.layer);
  });

  test(
    'Raid Intelligence passes live admin anchors into Blueprint clusters',
    () {
      const engine = ArcRaidIntelligenceEngine();

      final state = engine.build(
        mapId: 'blue_gate',
        dropReports: <ArcBlueprintDropReport>[report()],
        adminMarkers: const <ArcAdminMapMarker>[movedAnchor],
        activeLayer: ArcRaidMapLayer.underground,
      );

      final cluster = state.opportunityClusters.singleWhere(
        (item) =>
            item.evidence.any((evidence) => evidence.id == 'historic_drop'),
      );
      expect(cluster.point.x, closeTo(0.81, 0.0001));
      expect(cluster.point.y, closeTo(0.22, 0.0001));
      expect(cluster.layer, movedAnchor.layer);
    },
  );
}
