import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
  ).readAsStringSync();

  test('mobile loadout embeds workspace navigation in its header', () {
    final headerStart = source.indexOf('Widget _buildCompactLoadoutHeader');
    final headerEnd = source.indexOf('Widget _buildCompactMobileBoard');
    final header = source.substring(headerStart, headerEnd);

    expect(header, contains('ArcBlueprintWorkspaceBar('));
    expect(header, contains('current: ArcBlueprintWorkspace.loadout'));
    expect(header, contains('Smart Build'));
    expect(header, contains('Save Favourite Loadout'));
  });

  test('portrait Wanted Blueprints are narrower and taller', () {
    expect(source, contains('flex: 5'));
    expect(source, contains('flex: 3'));
    expect(source, contains('childAspectRatio: 1.05'));
    expect(source, contains('crossAxisCount: 2'));
    expect(source, contains('crossAxisCount: 5'));
    expect(source, contains('childAspectRatio: 3.00'));
  });

  test('augment and shield use identical full-width outer geometry', () {
    expect(source, contains('width: double.infinity'));
    expect(
      source,
      contains('final slotHeight = compactLandscape ? 100.0 : 100.0'),
    );
    expect(source, contains("final itemVisualSize = slotLabel == 'AUGMENT'"));
    expect(source, contains('? imageFrameSize'));
    expect(source, contains(': imageFrameSize * 0.88'));
  });

  test('portrait and landscape use visible 2 by 2 intelligence grids', () {
    expect(source, contains('Widget _buildLoadoutIntelGrid('));
    expect(source, contains('compactLandscape: false'));
    expect(source, contains('compactLandscape: true'));
    expect(source, contains("'QUICK USE'"));
    expect(source, contains("'LEVEL IV BUILD COST'"));
    expect(source, contains("'CRAFT + REPAIR'"));
    expect(source, contains("'MISSING BLUEPRINTS'"));
    expect(source, isNot(contains('Widget _buildLoadoutIntelRail(')));
  });

  test(
    'landscape top board is auxiliary weapons intelligence three-column',
    () {
      expect(source, contains("Key('favourite-loadout-landscape-top-grid')"));
      expect(source, contains('width: 126'));
      expect(source, contains('flex: 7'));
      expect(source, contains('flex: 5'));
      expect(source, contains('minHeight: compactLandscape ? 100.0 : 0'));
    },
  );
}
