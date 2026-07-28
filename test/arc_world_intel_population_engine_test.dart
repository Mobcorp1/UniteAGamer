import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_world_intel_population_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';

void main() {
  group('ArcWorldIntelPopulationEngine', () {
    const engine = ArcWorldIntelPopulationEngine();
    final now = DateTime.utc(2026, 7, 28, 12);

    test('populates every registered map layer with UAG-owned markers', () {
      final result = engine.build(
        maps: ArcRaidIntelligenceSeedData.maps,
        now: now,
      );

      expect(result.markers, isNotEmpty);
      expect(result.coverageReport.autoPublishedCount, greaterThan(0));
      expect(
        result.coverageReport.generatedDescriptionCount,
        result.markers.length,
      );

      for (final map in ArcRaidIntelligenceSeedData.maps) {
        expect(result.coverageReport.markerCountByMap[map.id], greaterThan(0));
        for (final layer in map.availableLayers) {
          expect(
            result.coverageReport.markerCountByLayer['${map.id}:${layer.name}'],
            greaterThan(0),
            reason: '${map.displayName} ${layer.label} should be populated.',
          );
        }
      }

      expect(
        result.markers.any(
          (marker) =>
              marker.mapId == 'spaceport' &&
              marker.layer == ArcRaidMapLayer.underground,
        ),
        isTrue,
      );
      expect(
        result.markers.every((marker) => marker.evidence.isNotEmpty),
        isTrue,
      );
    });

    test('ranks Mike Town Hall bridge weapon-cache Intel', () {
      final result = engine.build(
        maps: ArcRaidIntelligenceSeedData.maps,
        now: now,
      );

      expect(result.townHallBridgeCandidates, isNotEmpty);
      final selected = result.townHallBridgeCandidates.first;
      expect(selected.selected, isTrue);
      expect(selected.label.toLowerCase(), contains('town hall'));
      expect(selected.label.toLowerCase(), contains('bridge'));
      expect(
        selected.originalWording,
        'The closest weapon cache to Town Hall on the bridge.',
      );
    });

    test(
      'clusters duplicate UAG drop reports into one evidence-backed marker',
      () {
        final reports = <ArcBlueprintDropReport>[
          _dropReport(id: 'report-a', userId: 'raider-a'),
          _dropReport(id: 'report-b', userId: 'raider-b'),
        ];
        final result = engine.build(
          maps: <ArcRaidMap>[
            ArcRaidIntelligenceSeedData.mapById('buried_city'),
          ],
          dropReports: reports,
          now: now,
        );

        final marker = result.markers.firstWhere(
          (item) =>
              item.kind == ArcAdminMapMarkerKind.blueprint &&
              item.blueprintId == 'tempest',
        );

        expect(marker.evidence.length, 2);
        expect(
          marker.evidence.map((item) => item.type),
          everyElement(ArcWorldIntelEvidenceType.uagDropReport),
        );
        expect(result.coverageReport.uagReportsProcessed, 2);
        expect(result.coverageReport.uagReportsLinkedToMarkers, 2);
        expect(result.coverageReport.duplicateCount, greaterThan(0));
      },
    );

    test('keeps unresolved reports in the exception queue', () {
      final result = engine.build(
        maps: <ArcRaidMap>[ArcRaidIntelligenceSeedData.mapById('buried_city')],
        dropReports: <ArcBlueprintDropReport>[
          _dropReport(id: 'unmapped', poiId: null, poiName: 'Unknown Bridge'),
        ],
        now: now,
      );

      final marker = result.markers.firstWhere(
        (item) => item.sourceRecordId == 'unmapped',
      );

      expect(marker.hasImportException, isTrue);
      expect(marker.isLive, isFalse);
      expect(result.coverageReport.exceptionCount, greaterThan(0));
      expect(result.coverageReport.uagReportsRequiringReview, 1);
    });

    test(
      'adds evidence to existing Mike admin markers without exposing privacy',
      () {
        const admin = ArcAdminMapMarker(
          id: 'mike-cache',
          mapId: 'buried_city',
          layer: ArcRaidMapLayer.surface,
          kind: ArcAdminMapMarkerKind.weaponCache,
          name: 'Mike cache',
          point: ArcNormalizedPoint(x: 0.42, y: 0.44),
          sourceLabel: 'Mike / Admin Intel',
          createdByUid: 'private-user-id',
        );
        final result = engine.build(
          maps: <ArcRaidMap>[
            ArcRaidIntelligenceSeedData.mapById('buried_city'),
          ],
          adminMarkers: const <ArcAdminMapMarker>[admin],
          now: now,
        );

        final marker = result.markers.firstWhere((item) => item.id == admin.id);

        expect(
          marker.evidence.single.type,
          ArcWorldIntelEvidenceType.mikeAdminReport,
        );
        expect(marker.evidence.single.reporterId, 'private-user-id');
        expect(marker.isLive, isTrue);
      },
    );
  });
}

ArcBlueprintDropReport _dropReport({
  required String id,
  String userId = 'raider-a',
  String? poiId = 'buried_city_weapon_cache_town_hall_broken_bridge',
  String? poiName = 'Weapon Cache - Town Hall Broken Bridge',
}) {
  return ArcBlueprintDropReport(
    id: id,
    blueprintId: 'tempest',
    userId: userId,
    mapName: 'Buried City',
    sourceType: ArcDropSourceType.poi,
    poiId: poiId,
    poiName: poiName,
    containerTypeId: 'weapon-cache',
    containerTypeLabel: 'Weapon Cache',
    mode: ArcRaidMode.dayRaid,
    raidType: ArcRaidType.fullRaid,
    entryTime: ArcEntryTime.early,
    timeOfDay: ArcTimeOfDay.midday,
    createdAt: DateTime.utc(2026, 7, 27),
    confirmationCount: 1,
    confirmedByUserIds: <String>[userId],
    signature: '$id-signature',
  );
}
