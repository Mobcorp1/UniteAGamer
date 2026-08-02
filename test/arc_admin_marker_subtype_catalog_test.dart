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
  });
}
