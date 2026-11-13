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

  test('gifted handoff-only reports do not create map opportunities', () {
    final report = ArcBlueprintDropReport(
      id: 'handoff_only',
      blueprintId: 'anvil',
      userId: 'raider_1',
      mapName: ArcPoiDataStore.spaceport,
      sourceType: ArcDropSourceType.other,
      handoverMapName: ArcPoiDataStore.blueGate,
      handoverPoiId: 'blue_gate_warehouse_complex',
      handoverPoiName: 'Warehouse Complex',
      acquisitionSource: ArcBlueprintAcquisitionSource.giftedByAnotherRaider,
      giftRelationship: ArcGiftedBlueprintRelationship.otherRaider,
      mode: ArcRaidMode.dayRaid,
      raidType: ArcRaidType.fullRaid,
      entryTime: ArcEntryTime.unknown,
      timeOfDay: ArcTimeOfDay.unknown,
      createdAt: DateTime.now(),
      confirmationCount: 1,
      confirmedByUserIds: const <String>['raider_1'],
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

    expect(reportMarkers, isEmpty);
  });

  test('gifted reports use original find location for map opportunities', () {
    final report = ArcBlueprintDropReport(
      id: 'gifted_original',
      blueprintId: 'anvil',
      userId: 'raider_1',
      mapName: ArcPoiDataStore.spaceport,
      sourceType: ArcDropSourceType.other,
      originalFindMapName: ArcPoiDataStore.blueGate,
      originalFindPoiId: 'blue_gate_warehouse_complex',
      originalFindPoiName: 'Warehouse Complex',
      handoverMapName: ArcPoiDataStore.spaceport,
      handoverPoiName: 'Launch Tower',
      acquisitionSource: ArcBlueprintAcquisitionSource.giftedBySquadmate,
      giftRelationship: ArcGiftedBlueprintRelationship.squadmate,
      mode: ArcRaidMode.dayRaid,
      raidType: ArcRaidType.fullRaid,
      entryTime: ArcEntryTime.unknown,
      timeOfDay: ArcTimeOfDay.unknown,
      createdAt: DateTime.now(),
      confirmationCount: 2,
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
