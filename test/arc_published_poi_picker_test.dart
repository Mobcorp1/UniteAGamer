import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_published_report_pois.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test(
    'published report POIs filter by map, publication state and POI kind',
    () {
      const poi = ArcAdminMapMarker(
        id: 'actual_document',
        mapId: 'stella_montis',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Live Town Hall',
        point: ArcNormalizedPoint(x: .2, y: .3),
        state: ArcAdminMapMarkerState.published,
      );

      final result = ArcPublishedReportPois.forMap('Stella Montis', [
        poi,
        poi.copyWith(
          id: 'draft',
          name: 'Draft Place',
          state: ArcAdminMapMarkerState.draft,
        ),
        poi.copyWith(
          id: 'other',
          name: 'Other Map Place',
          mapId: 'buried_city',
        ),
        poi.copyWith(
          id: 'loot',
          name: 'Weapon Case',
          kind: ArcAdminMapMarkerKind.weaponCase,
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.single.id, 'actual_document');
      expect(result.single.name, 'Live Town Hall');
    },
  );

  test('published report POI identity survives a live rename', () {
    const original = ArcAdminMapMarker(
      id: 'actual_document',
      mapId: 'stella_montis',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.poi,
      name: 'Live Town Hall',
      point: ArcNormalizedPoint(x: .2, y: .3),
      state: ArcAdminMapMarkerState.published,
    );

    const selectedId = 'actual_document';

    final first = ArcPublishedReportPois.forMap('Stella Montis', const [
      original,
    ]);
    expect(first.single.id, selectedId);
    expect(first.single.name, 'Live Town Hall');

    final renamed = original.copyWith(
      name: 'Renamed Town Hall',
      layer: ArcRaidMapLayer.underground,
    );
    final second = ArcPublishedReportPois.forMap('Stella Montis', [renamed]);

    final retained = second.singleWhere((marker) => marker.id == selectedId);
    expect(retained.name, 'Renamed Town Hall');
    expect(retained.layer, ArcRaidMapLayer.underground);
  });
}
