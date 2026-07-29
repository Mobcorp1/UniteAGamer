import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';

void main() {
  test('Admin map marker round-trips normalized position and metadata', () {
    const marker = ArcAdminMapMarker(
      id: 'admin_marker',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.weaponCache,
      name: 'Hidden Weapon Cache',
      aliases: <String>['Cache Room', 'Weapon Stash'],
      description: 'Behind the broken wall.',
      point: ArcNormalizedPoint(x: 0.42, y: 0.71),
      sourceLabel: 'Admin Intel',
      confidence: ArcRaidIntelConfidence.confirmed,
      sourceName: 'Permitted Atlas',
      sourceRecordId: 'atlas_cache_7',
      sourcePermission: ArcAdminMapMarkerSourcePermission.permitted,
      originalPoint: ArcNormalizedPoint(x: 420, y: 710),
      coordinateSpace: 'imagePixel',
      alignmentConfidence: 0.93,
      duplicateGroupId: 'blue_gate:surface:weaponCache:hidden:42:71',
      provisionalVisible: true,
      evidence: <ArcWorldIntelEvidenceRecord>[
        ArcWorldIntelEvidenceRecord(
          id: 'evidence-1',
          type: ArcWorldIntelEvidenceType.mikeAdminReport,
          sourceId: 'mike-admin',
          sourceName: 'Mike / Admin Intel',
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          coordinate: ArcNormalizedPoint(x: 0.42, y: 0.71),
          landmarkText: 'Hidden Weapon Cache',
          category: 'Weapon Cache',
          permissionState: 'uag_internal',
        ),
      ],
    );

    final restored = ArcAdminMapMarker.fromMap(marker.toJsonMap());

    expect(restored.id, marker.id);
    expect(restored.kind, ArcAdminMapMarkerKind.weaponCache);
    expect(restored.aliases, <String>['Cache Room', 'Weapon Stash']);
    expect(restored.point.x, closeTo(0.42, 0.0001));
    expect(restored.point.y, closeTo(0.71, 0.0001));
    expect(restored.adminVerified, isTrue);
    expect(restored.sourceName, 'Permitted Atlas');
    expect(restored.sourceRecordId, 'atlas_cache_7');
    expect(restored.sourcePermission.canPublish, isTrue);
    expect(restored.originalPoint?.x, 420);
    expect(restored.coordinateSpace, 'imagePixel');
    expect(restored.alignmentConfidence, closeTo(0.93, 0.0001));
    expect(restored.provisionalVisible, isTrue);
    expect(restored.isLive, isTrue);
    expect(restored.resolvedEvidenceCount, 1);
    expect(
      restored.evidence.single.type,
      ArcWorldIntelEvidenceType.mikeAdminReport,
    );
    expect(restored.evidence.single.landmarkText, 'Hidden Weapon Cache');
  });

  test('copyWith clamps through normalized point helper', () {
    const marker = ArcAdminMapMarker(
      id: 'marker',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.blueprint,
      name: 'Blueprint',
      point: ArcNormalizedPoint(x: 0.5, y: 0.5),
    );

    final moved = marker.copyWith(
      point: const ArcNormalizedPoint(x: 1.4, y: -0.2).clamp(),
    );

    expect(moved.point.x, 1);
    expect(moved.point.y, 0);
  });

  test('prepareDraftMarkersForSave writes durable admin metadata', () {
    final savedAt = DateTime.utc(2026, 7, 29, 12);
    const marker = ArcAdminMapMarker(
      id: 'admin_blue_gate_surface_marker',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.poi,
      name: 'Control Tower',
      aliases: <String>['Tower'],
      point: ArcNormalizedPoint(x: 0.25, y: 0.33),
      state: ArcAdminMapMarkerState.draft,
    );
    const archived = ArcAdminMapMarker(
      id: 'archived_marker',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.poi,
      name: 'Archived',
      point: ArcNormalizedPoint(x: 0.2, y: 0.2),
      state: ArcAdminMapMarkerState.archived,
    );

    final prepared = ArcAdminMapEditorRepository.prepareDraftMarkersForSave(
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      markers: <ArcAdminMapMarker>[marker, archived],
      uid: 'admin-uid',
      savedAt: savedAt,
    );

    expect(prepared, hasLength(1));
    expect(prepared.single.id, marker.id);
    expect(prepared.single.createdByUid, 'admin-uid');
    expect(prepared.single.updatedByUid, 'admin-uid');
    expect(prepared.single.createdAt, savedAt);
    expect(prepared.single.updatedAt, savedAt);
    expect(prepared.single.toMap()['aliases'], <String>['Tower']);
    expect(prepared.single.toMap()['state'], ArcAdminMapMarkerState.draft.name);
  });
}
