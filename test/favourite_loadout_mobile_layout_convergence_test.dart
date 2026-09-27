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

  test('wanted Blueprint proportions are readable in both orientations', () {
    expect(source, contains('childAspectRatio: 1.25'));
    expect(source, contains('childAspectRatio: 3.00'));
    expect(source, isNot(contains('childAspectRatio: 1.70')));
    expect(source, isNot(contains('childAspectRatio: 4.00')));
    expect(source, contains('final compact = constraints.maxHeight < 82'));
  });

  test('augment and shield use one balanced auxiliary geometry', () {
    expect(
      source,
      contains('final slotHeight = compactLandscape ? 82.0 : 100.0'),
    );
    expect(source, contains("final itemVisualSize = slotLabel == 'AUGMENT'"));
    expect(source, contains('? imageFrameSize'));
    expect(source, contains(': imageFrameSize * 0.88'));
  });

  test('mobile intelligence is a compact horizontal rail', () {
    expect(source, contains('Widget _buildLoadoutIntelRail('));
    expect(source, contains('scrollDirection: Axis.horizontal'));
    expect(source, contains("'QUICK USE'"));
    expect(source, contains("'LEVEL IV BUILD COST'"));
    expect(source, contains("'CRAFT + REPAIR'"));
    expect(source, contains("'MISSING BLUEPRINTS'"));
    expect(source, contains('showModalBottomSheet<void>('));
  });

  test('mobile page no longer stacks four large detail panels', () {
    expect(source, contains('_buildLoadoutIntelRail(blueprintStates)'));
    expect(source, isNot(contains('Widget _buildMobileQuickUseTray(')));
  });
}
