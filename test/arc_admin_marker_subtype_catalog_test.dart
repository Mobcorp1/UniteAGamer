import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_subtype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';

void main() {
  group('ArcAdminMapMarkerSubtypeCatalog', () {
    test('exposes corrected nature resource subsections', () {
      final labels = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.naturalResource,
      ).map((item) => item.label);

      expect(labels, contains('Great Mullein'));
      expect(labels, contains('Candleberries'));
      expect(labels, isNot(contains('Grape')));
    });

    test('resolves imported subcategory aliases to canonical labels', () {
      final subtype = ArcAdminMapMarkerSubtypeCatalog.resolve(
        ArcAdminMapMarkerKind.naturalResource,
        'great-mullein',
      );

      expect(subtype?.id, 'great_mullein');
      expect(subtype?.label, 'Great Mullein');
    });

    test('filters event subsections by selected map', () {
      final spaceport = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.mapEvent,
        mapName: 'Spaceport',
      ).map((item) => item.label);
      final buriedCity = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.mapEvent,
        mapName: 'Buried City',
      ).map((item) => item.label);
      final stellaMontis = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.mapEvent,
        mapName: 'Stella Montis',
      ).map((item) => item.label);
      final rivenTides = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.mapEvent,
        mapName: 'Riven Tides',
      ).map((item) => item.label);

      expect(spaceport, contains('Launch Tower Loot'));
      expect(spaceport, contains('Hidden Bunker'));
      expect(buriedCity, contains('Lush Blooms'));
      expect(buriedCity, isNot(contains('Launch Tower Loot')));
      expect(stellaMontis, ['Night Raid']);
      expect(rivenTides, contains('Beachcombing'));
      expect(rivenTides, isNot(contains('Launch Tower Loot')));
    });

    test('builds location subsections from UAG map seed data', () {
      final spaceportPois = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.poi,
        mapName: 'Spaceport',
      );
      final spaceportExtractions = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.extraction,
        mapName: 'Spaceport',
      );

      expect(
        spaceportPois.map((item) => item.label),
        contains('East Container Yard'),
      );
      expect(
        spaceportPois.map((item) => item.label),
        contains('West Container Yard'),
      );
      expect(
        spaceportPois.every((item) => item.kind == ArcAdminMapMarkerKind.poi),
        isTrue,
      );
      expect(spaceportExtractions, isNotEmpty);
      expect(
        spaceportExtractions.every(
          (item) => item.kind == ArcAdminMapMarkerKind.extraction,
        ),
        isTrue,
      );
    });

    test('keeps layer transition subsections matched to marker type', () {
      final surface = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.surfaceTransition,
        mapName: 'Blue Gate',
      );
      final underground = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.undergroundTransition,
        mapName: 'Blue Gate',
      );

      expect(surface.map((item) => item.label), contains('Surface Access'));
      expect(underground.map((item) => item.label), contains('Level 2 Access'));
      expect(
        surface.every(
          (item) => item.kind == ArcAdminMapMarkerKind.surfaceTransition,
        ),
        isTrue,
      );
      expect(
        underground.every(
          (item) => item.kind == ArcAdminMapMarkerKind.undergroundTransition,
        ),
        isTrue,
      );
    });
  });
}
