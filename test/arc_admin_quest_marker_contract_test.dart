import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_adapters.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';

void main() {
  const questId = 'quest-chain-apollo-paving-the-way';

  test('questId persists independently from Quest subtype metadata', () {
    const marker = ArcAdminMapMarker(
      id: 'quest-marker',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.questLocation,
      name: 'Paving The Way - antenna',
      subtypeId: 'quest_objective',
      subtypeLabel: 'Quest Objective',
      questId: questId,
      point: ArcNormalizedPoint(x: 0.25, y: 0.45),
      state: ArcAdminMapMarkerState.published,
    );

    final restored = ArcAdminMapMarker.fromMap(marker.toJsonMap());

    expect(restored.questId, questId);
    expect(restored.subtypeId, 'quest_objective');
    expect(restored.questId, isNot(restored.subtypeId));

    final cleared = restored.copyWith(clearQuestId: true);
    expect(cleared.questId, isNull);
    expect(cleared.subtypeId, 'quest_objective');
  });

  test('admin edit patch writes questId without replacing subtype', () {
    const original = ArcAdminMapMarker(
      id: 'quest-marker',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.questLocation,
      name: 'Quest point',
      subtypeId: 'quest_objective',
      point: ArcNormalizedPoint(x: 0.25, y: 0.45),
    );
    final edited = original.copyWith(questId: questId);

    final patch = ArcAdminMapEditorRepository.markerEditPatch(
      original: original,
      edited: edited,
    );

    expect(patch['questId'], questId);
    expect(patch.containsKey('subtypeId'), isFalse);
  });

  test('permitted JSON import preserves canonical questId', () {
    final json = jsonEncode({
      'records': [
        {
          'id': 'quest-record',
          'kind': 'quest_location',
          'name': 'Paving The Way',
          'questId': questId,
          'subtypeId': 'quest_objective',
          'x': 0.33,
          'y': 0.66,
        },
      ],
    });

    final payload = const ArcPermittedJsonMapMarkerImportAdapter().parse(
      json,
      defaultMapId: 'blue_gate',
      defaultLayer: ArcRaidMapLayer.surface,
    );

    expect(payload.records, hasLength(1));
    expect(payload.records.single.questId, questId);
  });

  test('multiple authored locations may share one canonical questId', () {
    const first = ArcAdminMapMarker(
      id: 'quest-marker-a',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.questLocation,
      name: 'Paving The Way - A',
      questId: questId,
      point: ArcNormalizedPoint(x: 0.2, y: 0.2),
    );
    const second = ArcAdminMapMarker(
      id: 'quest-marker-b',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.questLocation,
      name: 'Paving The Way - B',
      questId: questId,
      point: ArcNormalizedPoint(x: 0.7, y: 0.7),
    );

    expect(first.questId, second.questId);
    expect(first.id, isNot(second.id));
    expect(first.point.x, isNot(second.point.x));
  });
}
