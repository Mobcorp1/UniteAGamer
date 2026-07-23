import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

void main() {
  group('Blueprint Intel report options', () {
    test('acquisition source labels and legacy parsing remain stable', () {
      expect(ArcBlueprintAcquisitionSource.lootDrop.label, 'Normal Drop');
      expect(ArcBlueprintAcquisitionSource.gifted.label, 'Gifted');
      expect(ArcBlueprintAcquisitionSource.trialReward.label, 'Trial');
      expect(
        ArcBlueprintAcquisitionSourceX.fromStorage('normal_drop'),
        ArcBlueprintAcquisitionSource.lootDrop,
      );
      expect(
        ArcBlueprintAcquisitionSourceX.fromStorage('questReward'),
        ArcBlueprintAcquisitionSource.questReward,
      );
      expect(
        ArcBlueprintAcquisitionSourceX.fromStorage('gift'),
        ArcBlueprintAcquisitionSource.gifted,
      );
      expect(
        ArcBlueprintAcquisitionSourceX.fromStorage('trial'),
        ArcBlueprintAcquisitionSource.trialReward,
      );
    });

    test('raid round labels are Full, Mid and Late with legacy aliases', () {
      expect(ArcRaidType.values.map((type) => type.label), [
        'Full',
        'Mid',
        'Late',
      ]);
      expect(ArcRaidTypeX.fromStorage('earlyRaid'), ArcRaidType.fullRaid);
      expect(ArcRaidTypeX.fromStorage('full'), ArcRaidType.fullRaid);
      expect(ArcRaidTypeX.fromStorage('mid_raid'), ArcRaidType.midRaid);
      expect(ArcRaidTypeX.fromStorage('late raid'), ArcRaidType.lateRaid);
    });

    test('neutral map condition is first and named as no map event', () {
      final options = ArcMapConditions.combinedOptionsForMap(
        ArcPoiDataStore.blueGate,
      );

      expect(options.first, ArcMapConditions.noSpecialCondition);
      expect(options.first.label, 'No Map Event');
    });

    test('Blue Gate POI catalogue exposes the canonical report locations', () {
      final names = ArcPoiDataStore.blueprintReportPoisForMap(
        ArcPoiDataStore.blueGate,
      ).map((poi) => poi.name).toSet();

      expect(
        names,
        containsAll(<String>[
          'Village',
          'Barracks Parking',
          "Raider's Refuge",
          "Trapper's Glade",
          'Adorned Wreckage',
          'Highway Collapse',
          'Olive Grove',
          'Ruined Homestead',
          'Ancient Fort',
          'Checkpoint',
          'Outer Gates',
          'Gate Control Room',
          'Warehouse Complex',
          'Reinforced Reception',
          'Headhouse',
          'Data Vault',
          'Maintenance Bunker',
          'Broken Earth',
          'Ridgeline',
          'Abandoned Housing Project',
        ]),
      );
      expect(names, isNot(contains('Abanndened Housing Project')));
      expect(names, isNot(contains('Olive Garden')));
      expect(names, isNot(contains('Maintenance Wing')));
    });

    test('Blue Gate aliases canonicalise legacy Intel reports', () {
      final report = ArcBlueprintDropReport.fromMap(<String, dynamic>{
        'id': 'report-1',
        'blueprintId': 'bobcat',
        'userId': 'user-1',
        'mapName': 'Blue Gate',
        'sourceType': 'poi',
        'locationName': 'Abanndened Housing Project',
        'acquisitionSource': 'gifted',
        'raidType': 'earlyRaid',
        'mode': 'dayRaid',
        'entryTime': 'unknown',
        'timeOfDay': 'unknown',
      });

      expect(report.mapName, 'Blue Gate');
      expect(report.poiName, 'Abandoned Housing Project');
      expect(report.acquisitionSource, ArcBlueprintAcquisitionSource.gifted);
      expect(report.raidType, ArcRaidType.fullRaid);
      expect(report.signature, contains('gifted'));
    });

    test('local time metadata round-trips through report maps', () {
      final report = ArcBlueprintDropReport(
        id: 'report-2',
        blueprintId: 'anvil',
        userId: 'user-1',
        mapName: ArcPoiDataStore.blueGate,
        sourceType: ArcDropSourceType.poi,
        poiName: 'Data Vault',
        mode: ArcRaidMode.dayRaid,
        raidType: ArcRaidType.midRaid,
        entryTime: ArcEntryTime.unknown,
        timeOfDay: ArcTimeOfDay.midAfternoon,
        acquisitionSource: ArcBlueprintAcquisitionSource.trade,
        localTimeLabel: '15:45',
        timezoneOffsetMinutes: -60,
        createdAt: DateTime.utc(2026),
        confirmationCount: 1,
        confirmedByUserIds: const <String>['user-1'],
      );

      final map = report.toMap();
      expect(map['localTimeLabel'], '15:45');
      expect(map['timezoneOffsetMinutes'], -60);

      final restored = ArcBlueprintDropReport.fromMap(map);
      expect(restored.localTimeLabel, '15:45');
      expect(restored.timezoneOffsetMinutes, -60);
      expect(restored.acquisitionSource, ArcBlueprintAcquisitionSource.trade);
    });
  });
}
