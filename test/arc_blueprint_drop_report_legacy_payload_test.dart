import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

void main() {
  group('ArcBlueprintDropReport historical payload parsing', () {
    test('parses supported legacy location label fields', () {
      const cases = <String, String>{
        'locationName': 'Town Hall',
        'locationLabel': 'Main Street',
        'reportedLocation': 'Gas Station',
        'dropLocation': 'Abandoned Highway Camp',
        'sourceLocation': 'Hospital',
        'landmark': 'Warehouse',
      };

      for (final entry in cases.entries) {
        final report = ArcBlueprintDropReport.fromMap(<String, dynamic>{
          'id': 'report_${entry.key}',
          'blueprintId': 'patina',
          'userId': 'raider',
          'mapId': 'buried_city',
          entry.key: entry.value,
        });

        expect(
          report.mapName,
          ArcPoiDataStore.buriedCity,
          reason: '${entry.key} should preserve the canonical map.',
        );
        expect(
          report.poiName,
          entry.value,
          reason: '${entry.key} should become the intelligence POI name.',
        );
      }
    });

    test('does not let notes or broad area override a real POI label', () {
      final report = ArcBlueprintDropReport.fromMap(const <String, dynamic>{
        'id': 'report_town_hall',
        'blueprintId': 'patina',
        'userId': 'raider',
        'map': 'Buried City',
        'poiName': 'Town Hall',
        'area': 'Central Route Web',
        'notes': 'Hospital was mentioned in a free-text note.',
      });

      expect(report.poiName, 'Town Hall');
      expect(report.locationName, 'Town Hall');
    });

    test('parses marker IDs and normalized historical coordinates safely', () {
      final report = ArcBlueprintDropReport.fromMap(const <String, dynamic>{
        'id': 'report_marker',
        'blueprintId': 'compensator_ii',
        'userId': 'raider',
        'mapId': 'buried_city',
        'mapMarkerId': 'admin_buried_city_main_street',
        'reportedLocation': 'Main Street',
        'coordinates': <String, dynamic>{
          'normalizedX': 0.21,
          'normalizedY': 0.62,
        },
      });

      expect(report.markerId, 'admin_buried_city_main_street');
      expect(report.historicalPoint?.x, closeTo(0.21, 0.0001));
      expect(report.historicalPoint?.y, closeTo(0.62, 0.0001));
      expect(report.intelligencePoiName, 'Main Street');
    });
  });
}
