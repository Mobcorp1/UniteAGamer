import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('live report opportunity replaces seeded opportunity for blueprint', () {
    final report = ArcBlueprintDropReport(
      id: 'live_report',
      blueprintId: 'anvil',
      userId: 'raider_1',
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
      createdAt: DateTime.now(),
      confirmationCount: 3,
      confirmedByUserIds: const <String>['raider_1', 'raider_2'],
    );

    final state = const ArcRaidIntelligenceEngine().build(
      mapId: 'blue_gate',
      dropReports: <ArcBlueprintDropReport>[report],
    );

    final reportMarkers = state.visibleMarkers.where(
      (marker) =>
          marker.category == ArcRaidMapMarkerCategory.blueprintOpportunity &&
          marker.tags.contains('Drop Reports'),
    );

    expect(reportMarkers, isNotEmpty);
    expect(
      reportMarkers.any((marker) => marker.label.contains('Warehouse Complex')),
      isTrue,
    );
  });
}
