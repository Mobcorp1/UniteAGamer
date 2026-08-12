import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin marker editor consumes canonical filter taxonomy and custom subtype',
    () {
      final editor = File(
        'lib/features/trading_hub/arc_raiders/screens/'
        'arc_admin_map_editor_screen.dart',
      ).readAsStringSync();
      final catalog = File(
        'lib/features/trading_hub/arc_raiders/data/'
        'arc_admin_marker_subtype_catalog.dart',
      ).readAsStringSync();

      expect(editor, contains("labelText: 'Category'"));
      expect(editor, contains("'Custom subtype...'"));
      expect(editor, contains("'Custom filter / subtype name'"));
      expect(editor, contains('ArcAdminMapMarkerSubtypeCatalog.slug'));
      expect(catalog, contains('ArcMapFilterTaxonomy.forKind'));
    },
  );

  test('editor preserves editable display name independent of subtype', () {
    final editor = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_admin_map_editor_screen.dart',
    ).readAsStringSync();

    expect(
      editor,
      contains("decoration: const InputDecoration(labelText: 'Name')"),
    );
    expect(editor, contains('name: result.name'));
    expect(editor, contains('subtypeId: result.subtypeId'));
    expect(editor, contains('subtypeLabel: result.subtypeLabel'));
  });
}
