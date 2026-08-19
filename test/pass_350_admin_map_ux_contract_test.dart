import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PASS 350 admin console uses precision scroll and collapsed sections',
    () {
      final source = File(
        'lib/screens/build/admin_console_screen.dart',
      ).readAsStringSync();
      expect(source, contains("Key('admin-console-precision-scroll')"));
      expect(source, contains('scrollScale: 0.25'));
      expect(source, contains('showScrollbar: true'));
      expect(source, contains('initiallyExpanded: false'));
      expect(source, contains('_AdminExpandableSection'));
    },
  );

  test('PASS 350 map editor exposes a simple normal workflow', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart',
    ).readAsStringSync();
    expect(source, contains("Key('map-editor-precision-scroll')"));
    expect(source, contains('scrollScale: 0.25'));
    expect(source, contains("Text('Add Map Point')"));
    expect(source, contains("Text('Add Blueprint Location')"));
    expect(source, contains("Text('Edit Marker')"));
    expect(source, contains("Text('Delete Marker')"));
    expect(source, contains("Text('Save Changes')"));
    expect(source, contains("Text('Publish Marker')"));
    expect(source, contains("title: 'ADVANCED MAP TOOLS'"));
    expect(source, contains("Text('Export Marker Data')"));
    expect(source, contains("Text('Import Marker Data')"));
    expect(source, contains("Text('Process Imported Map Data')"));
  });

  test('PASS 350 nature assets use canonical in-game item artwork', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/arc_admin_marker_visual_registry.dart',
    ).readAsStringSync();
    for (final asset in <String>[
      'agave.webp',
      'apricots.webp',
      'fertilizer.webp',
      'great_mullein.webp',
      'lemons.webp',
      'moss.webp',
      'mushroom.webp',
      'olives.webp',
      'prickly_pears.webp',
      'roots.webp',
    ]) {
      expect(source, contains(asset));
      expect(
        File('assets/arc_raiders/items/$asset').existsSync(),
        isTrue,
        reason: 'Missing canonical nature asset: $asset',
      );
    }
  });
}
