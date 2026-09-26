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
    expect(source, contains('class ArcBlueprintWorkspaceDock'));
    expect(source, isNot(contains('ownership summary')));
  });

  test('Blueprint tracker gains family navigation without replacing grid shell', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(
      source,
      matches(
        RegExp(
          r'ArcBlueprintWorkspaceDock\(\s*current:\s*ArcBlueprintWorkspace.tracker,?\s*\)',
        ),
      ),
    );
    expect(source, contains("key: const Key('blueprint-authoritative-grid')"));
    expect(
      source,
      matches(
        RegExp(
          r'_buildOverviewGrid\(\s*context,\s*filtered,\s*states,\s*loadout,?\s*\)',
        ),
      ),
    );
    expect(source, contains('ArcBlueprintGridViewMode.inGameFramed'));
    expect(source, contains('BlueprintTile('));
  });

  test('Favourite Loadout exposes family navigation in both orientations', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    );

    expect(source, contains('ArcBlueprintWorkspaceBar('));
    expect(source, contains('_buildPortraitInGameBoard(blueprintStates)'));
    expect(source, contains('_buildLoadoutBoard(blueprintStates)'));
  });

  test('Blueprint Watches keeps empty and populated states inside family', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart',
    );

    expect(
      source,
      contains(
        'ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.watches)',
      ),
    );
    expect(source, contains("title: 'No active watches'"));
    expect(source, contains("title: 'BLUEPRINT WATCHES'"));
  });
}
