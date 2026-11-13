import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_alignment_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_adapters.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_map_marker_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';

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
        summary.acceptedMarkers.single.evidence.single.type,
        ArcWorldIntelEvidenceType.permittedExternalCoordinate,
      );
      expect(
        summary.acceptedMarkers.single.sourcePermission.canPublish,
        isTrue,
      );
      expect(summary.acceptedMarkers.single.point.x, closeTo(0.44, 0.0001));
    });

    test('preserves distinct new marker categories from source records', () {
      final payload = adapter.parse(
        '''
        {
          "source": {
            "id": "uag-kind-fixture",
            "name": "UAG kind fixture",
            "permissionState": "permitted"
          },
          "mapId": "blue_gate",
          "layer": "surface",
          "records": [
            {"id": "case", "kind": "weapon_case", "name": "Weapon case", "x": 0.1, "y": 0.2, "confidence": "strong"},
            {"id": "security", "kind": "security_room", "name": "Security room", "x": 0.2, "y": 0.3, "confidence": "strong"},
            {"id": "key", "kind": "key_required_location", "name": "Key room", "x": 0.3, "y": 0.4, "confidence": "strong"},
            {"id": "event", "kind": "map_event", "name": "Event", "x": 0.4, "y": 0.5, "confidence": "strong"},
            {"id": "resource", "kind": "natural_resource", "subcategory": "great_mullein", "name": "Resource", "x": 0.5, "y": 0.6, "confidence": "strong"},
            {"id": "arc", "kind": "arc_spawn", "name": "ARC spawn", "x": 0.6, "y": 0.7, "confidence": "strong"},
            {"id": "first", "kind": "first_wave_cache", "name": "First Wave", "x": 0.7, "y": 0.8, "confidence": "strong"},
            {"id": "raider", "kind": "raider_cache", "name": "Raider cache", "x": 0.8, "y": 0.2, "confidence": "strong"},
            {"id": "field", "kind": "field_crate", "name": "Field crate", "x": 0.2, "y": 0.8, "confidence": "strong"},
            {"id": "cluster", "kind": "container_cluster", "name": "Containers", "x": 0.3, "y": 0.8, "confidence": "strong"},
            {"id": "surface", "kind": "surface_transition", "name": "Surface access", "x": 0.4, "y": 0.8, "confidence": "strong"},
            {"id": "underground", "kind": "level_2_access", "name": "Level 2 access", "x": 0.5, "y": 0.8, "confidence": "strong"},
            {"id": "hazard", "kind": "danger_zone", "name": "Hazard", "x": 0.6, "y": 0.8, "confidence": "strong"}
          ]
        }
        ''',
        defaultMapId: 'blue_gate',
        defaultLayer: ArcRaidMapLayer.surface,
      );

      final kinds = payload.records.map((record) => record.kind);

      expect(kinds, contains(ArcAdminMapMarkerKind.weaponCase));
      expect(kinds, contains(ArcAdminMapMarkerKind.securityRoom));
      expect(kinds, contains(ArcAdminMapMarkerKind.keyRequiredLocation));
      expect(kinds, contains(ArcAdminMapMarkerKind.mapEvent));
      expect(kinds, contains(ArcAdminMapMarkerKind.naturalResource));
      expect(kinds, contains(ArcAdminMapMarkerKind.arcSpawn));
      expect(kinds, contains(ArcAdminMapMarkerKind.firstWaveCache));
      expect(kinds, contains(ArcAdminMapMarkerKind.raiderCache));
      expect(kinds, contains(ArcAdminMapMarkerKind.fieldCrate));
      expect(kinds, contains(ArcAdminMapMarkerKind.containerCluster));
      expect(kinds, contains(ArcAdminMapMarkerKind.surfaceTransition));
      expect(kinds, contains(ArcAdminMapMarkerKind.undergroundTransition));
      expect(kinds, contains(ArcAdminMapMarkerKind.hazard));
      final resourceRecord = payload.records.firstWhere(
        (record) => record.id == 'resource',
      );
      expect(resourceRecord.subtypeId, 'great_mullein');
      expect(resourceRecord.subtypeLabel, 'Great Mullein');
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

    test('imports permitted Spaceport Level 2 records through alignment', () {
      final payload = adapter.parse(
        '''
        {
          "source": {
            "id": "spaceport-permitted-fixture",
            "name": "Spaceport permitted fixture",
            "permissionState": "permitted"
          },
          "mapId": "spaceport",
          "layer": "underground",
          "coordinateSpace": "source_percent",
          "records": [
            {
              "id": "level-2-cache",
              "kind": "loot_container",
              "name": "Level 2 cache",
              "x": 58,
              "y": 44,
              "confidence": "moderate"
            }
          ]
        }
        ''',
        defaultMapId: 'blue_gate',
        defaultLayer: ArcRaidMapLayer.surface,
      );
      final summary = importEngine.importRecords(
        payload: payload,
        mapId: 'spaceport',
        layer: ArcRaidMapLayer.underground,
        existingMarkers: const <ArcAdminMapMarker>[],
        alignment: alignmentEngine.identity(
          mapId: 'spaceport',
          layer: ArcRaidMapLayer.underground,
          sourceId: payload.source.id,
        ),
      );

      expect(summary.mapId, 'spaceport');
      expect(summary.layer, ArcRaidMapLayer.underground);
      expect(summary.provisionalCount, 1);
      expect(summary.acceptedMarkers.single.mapId, 'spaceport');
      expect(summary.acceptedMarkers.single.layer, ArcRaidMapLayer.underground);
      expect(summary.acceptedMarkers.single.point.x, closeTo(0.58, 0.0001));
      expect(summary.acceptedMarkers.single.point.y, closeTo(0.44, 0.0001));
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
