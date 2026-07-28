import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_alignment_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_adapters.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_map_marker_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  group('Arc map marker import pipeline', () {
    const adapter = ArcPermittedJsonMapMarkerImportAdapter();
    const alignmentEngine = ArcMapMarkerAlignmentEngine();
    const importEngine = ArcMapMarkerImportEngine();

    test('auto publishes high-confidence permitted records', () {
      final payload = adapter.parse(
        '''
        {
          "source": {
            "id": "uag-permitted-fixture",
            "name": "UAG permitted fixture",
            "permissionState": "permitted",
            "attribution": "Internal QA"
          },
          "mapId": "blue_gate",
          "layer": "surface",
          "records": [
            {
              "id": "cache-1",
              "kind": "weapon_cache",
              "name": "Warehouse cache",
              "x": 0.44,
              "y": 0.52,
              "confidence": "strong"
            }
          ]
        }
        ''',
        defaultMapId: 'blue_gate',
        defaultLayer: ArcRaidMapLayer.surface,
      );
      final summary = importEngine.importRecords(
        payload: payload,
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        existingMarkers: const <ArcAdminMapMarker>[],
        alignment: alignmentEngine.identity(
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          sourceId: payload.source.id,
        ),
      );

      expect(summary.autoPublishedCount, 1);
      expect(summary.acceptedMarkers.single.isPublished, isTrue);
      expect(
        summary.acceptedMarkers.single.sourcePermission.canPublish,
        isTrue,
      );
      expect(summary.acceptedMarkers.single.point.x, closeTo(0.44, 0.0001));
    });

    test('keeps medium-confidence permitted records provisional', () {
      final payload = ArcMapMarkerImportPayload(
        source: const ArcMapMarkerSourceDescriptor(
          id: 'community_permitted',
          name: 'Community permitted dump',
          permission: ArcAdminMapMarkerSourcePermission.permitted,
        ),
        records: const [
          ArcExternalMapMarkerRecord(
            id: 'loot-1',
            mapId: 'blue_gate',
            layer: ArcRaidMapLayer.surface,
            kind: ArcAdminMapMarkerKind.lootContainer,
            name: 'Field crate',
            point: ArcNormalizedPoint(x: 42, y: 50),
            confidence: ArcRaidIntelConfidence.moderate,
            coordinateSpace: ArcMapMarkerCoordinateSpace.sourcePercent,
          ),
        ],
      );
      final summary = importEngine.importRecords(
        payload: payload,
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        existingMarkers: const <ArcAdminMapMarker>[],
        alignment: alignmentEngine.identity(
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          sourceId: payload.source.id,
        ),
      );

      expect(summary.provisionalCount, 1);
      expect(summary.acceptedMarkers.single.provisionalVisible, isTrue);
      expect(summary.acceptedMarkers.single.point.x, closeTo(0.42, 0.0001));
    });

    test('rejects sources without explicit publication permission', () {
      const payload = ArcMapMarkerImportPayload(
        source: ArcMapMarkerSourceDescriptor(
          id: 'unknown_source',
          name: 'Unknown source',
          permission: ArcAdminMapMarkerSourcePermission.unknown,
        ),
        records: [
          ArcExternalMapMarkerRecord(
            id: 'poi-1',
            mapId: 'blue_gate',
            layer: ArcRaidMapLayer.surface,
            kind: ArcAdminMapMarkerKind.poi,
            name: 'Unlicensed point',
            point: ArcNormalizedPoint(x: 0.2, y: 0.3),
            confidence: ArcRaidIntelConfidence.confirmed,
          ),
        ],
      );

      final summary = importEngine.importRecords(
        payload: payload,
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        existingMarkers: const <ArcAdminMapMarker>[],
        alignment: alignmentEngine.identity(
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          sourceId: payload.source.id,
        ),
      );

      expect(summary.rejectedCount, 1);
      expect(summary.acceptedMarkers, isEmpty);
    });

    test('deduplicates nearby records against existing admin markers', () {
      const existing = ArcAdminMapMarker(
        id: 'existing',
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.weaponCache,
        name: 'Warehouse cache',
        point: ArcNormalizedPoint(x: 0.44, y: 0.52),
      );
      const payload = ArcMapMarkerImportPayload(
        source: ArcMapMarkerSourceDescriptor(
          id: 'permitted',
          name: 'Permitted',
          permission: ArcAdminMapMarkerSourcePermission.permitted,
        ),
        records: [
          ArcExternalMapMarkerRecord(
            id: 'cache-1',
            mapId: 'blue_gate',
            layer: ArcRaidMapLayer.surface,
            kind: ArcAdminMapMarkerKind.weaponCache,
            name: 'Warehouse cache',
            point: ArcNormalizedPoint(x: 0.441, y: 0.519),
            confidence: ArcRaidIntelConfidence.strong,
          ),
        ],
      );

      final summary = importEngine.importRecords(
        payload: payload,
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        existingMarkers: const [existing],
        alignment: alignmentEngine.identity(
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          sourceId: payload.source.id,
        ),
      );

      expect(summary.duplicateCount, 1);
      expect(summary.acceptedMarkers, isEmpty);
    });
  });
}
