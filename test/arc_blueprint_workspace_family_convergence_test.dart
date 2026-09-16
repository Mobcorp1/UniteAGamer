import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Blueprint workspace bar exposes tracker, loadout and watches only', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_workspace_bar.dart',
    );

    expect(
      source,
      contains('enum ArcBlueprintWorkspace { tracker, loadout, watches }'),
    );
    expect(source, contains("return '/trading-hub/arc-raiders/blueprints';"));
    expect(source, contains("return '/favourite-loadout';"));
    expect(
      source,
      contains("return '/trading-hub/arc-raiders/blueprint-watches';"),
    );
    expect(source, contains('SingleChildScrollView'));
    expect(source, isNot(contains('ownership summary')));
  });

  test(
    'Blueprint tracker gains family navigation without replacing grid shell',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );

      expect(source, contains('ArcBlueprintWorkspace.tracker'));
      expect(
        source,
        contains("key: const Key('blueprint-authoritative-grid')"),
      );
      expect(
        source,
        contains('_buildOverviewGrid(context, filtered, states, loadout)'),
      );
      expect(source, contains('ArcBlueprintGridViewMode.inGameFramed'));
      expect(source, contains('BlueprintTile('));
    },
  );

  test('Favourite Loadout exposes family navigation in both orientations', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    );

    expect(
      RegExp('ArcBlueprintWorkspace\\.loadout').allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
    expect(source, contains('_buildPortraitRotationPrompt(blueprintStates)'));
    expect(source, contains('_buildLoadoutBoard(blueprintStates)'));
  });

  test('Blueprint Watches keeps empty and populated states inside family', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart',
    );

    expect(
      RegExp('ArcBlueprintWorkspace\\.watches').allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
    expect(source, contains("title: 'No active watches'"));
    expect(source, contains("title: 'BLUEPRINT WATCHES'"));
  });
}
