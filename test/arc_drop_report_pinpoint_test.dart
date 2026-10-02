import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_drop_report_pinpoint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('Found is the player-facing label for direct loot finds', () {
    expect(ArcBlueprintAcquisitionSource.lootDrop.label, 'Found');
  });

  test('exact pinpoints and server region contribute to report identity', () {
    final first = ArcDropReportPinpoint.signatureSuffix(
      point: const ArcNormalizedPoint(x: .41234, y: .55876),
      serverRegion: 'europe',
    );
    final second = ArcDropReportPinpoint.signatureSuffix(
      point: const ArcNormalizedPoint(x: .45234, y: .55876),
      serverRegion: 'europe',
    );
    final otherRegion = ArcDropReportPinpoint.signatureSuffix(
      point: const ArcNormalizedPoint(x: .41234, y: .55876),
      serverRegion: 'north-america',
    );

    expect(first, isNot(second));
    expect(first, isNot(otherRegion));
    expect(first, contains('0.4123,0.5588'));
  });

  test('exact pin survives report parsing and serialization', () {
    final report = ArcBlueprintDropReport.fromMap(const <String, dynamic>{
      'id': 'pin-report',
      'blueprintId': 'patina',
      'userId': 'raider',
      'mapName': 'Buried City',
      'exactPin': true,
      'historicalPoint': <String, dynamic>{'x': 0.42, 'y': 0.61},
    });

    expect(report.exactPin, isTrue);
    expect(report.historicalPoint?.x, closeTo(0.42, 0.0001));
    expect(report.historicalPoint?.y, closeTo(0.61, 0.0001));
    expect(report.toMap()['exactPin'], isTrue);
  });

  test('exact report coordinates win over any nearby or named POI', () {
    final report = ArcBlueprintDropReport.fromMap(const <String, dynamic>{
      'id': 'exact-pin-wins',
      'blueprintId': 'patina',
      'userId': 'raider',
      'mapName': 'Buried City',
      'sourceType': 'poi',
      'poiName': 'Town Hall',
      'exactPin': true,
      'historicalPoint': <String, dynamic>{'x': 0.91, 'y': 0.87},
    });
    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: ArcRaidIntelligenceSeedData.mapById('buried_city'),
      reports: <ArcBlueprintDropReport>[report],
      now: DateTime.utc(2026, 10, 1),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.point.x, closeTo(0.91, 0.0001));
    expect(clusters.single.point.y, closeTo(0.87, 0.0001));
  });

}
