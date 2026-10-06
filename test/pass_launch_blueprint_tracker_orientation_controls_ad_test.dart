import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  test('Blueprint Tracker opens in the five-row in-game view by default', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );
    final preferences = read(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart',
    );

    expect(
      grid,
      contains(
        'ArcBlueprintGridViewMode _viewMode = ArcBlueprintGridViewMode.inGameFramed;',
      ),
    );
    expect(preferences, contains('_ => ArcBlueprintGridViewMode.inGameFramed'));
    expect(preferences, contains("'arcBlueprintGridViewModeV2'"));
  });

  test('portrait no longer blocks either grid view behind a rotate prompt', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );
    final metrics = read(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_grid_layout_metrics.dart',
    );

    expect(grid, isNot(contains("'Rotate your device'")));
    expect(grid, isNot(contains('shouldShowInGameRotatePrompt(')));
    expect(grid, contains('ArcBlueprintGridLayoutMetrics.framedLayout('));
    expect(metrics, contains('int requestedVisibleRows = 5'));
  });

  test('portrait command panel is four small then two large then two large', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(grid, contains('const portraitSmallColumns = 4;'));
    expect(grid, contains("Key('blueprint-portrait-command-layout')"));
    expect(grid, contains("label: vertical ? null : 'IN-GAME VIEW'"));
    expect(grid, contains("subtitle: vertical ? null : '5-row game layout'"));
    expect(grid, contains("label: vertical ? null : 'FULL GRID'"));
    expect(grid, contains("subtitle: vertical ? null : 'All 83 Blueprints'"));
    expect(grid, contains("label: vertical ? null : 'RESET VIEW'"));
    expect(grid, contains("subtitle: vertical ? null : 'Fit & centre'"));
    expect(grid, contains("tooltip: 'Reset grid view'"));
    expect(grid, contains("subtitle: vertical ? null : 'Scan ownership'"));
    expect(grid, contains('const portraitLargeHeight = 58.0;'));
    expect(grid, contains('final panelHeight = vertical ? 270.0 : 190.0;'));
    expect(grid, contains('const commandBarHeight = 190.0;'));
  });

  test('portrait keeps the destructive clear action out of the primary pad', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(grid, contains("case 'clear-grid':"));
    expect(grid, contains("value: 'clear-grid'"));
    expect(grid, contains("'Clear Blueprint Grid'"));
    expect(grid, contains('Widget clearGridButton() => commandButton('));
    expect(
      grid,
      contains(
        "final controls = <Widget>[\n                  inGameButton(),\n                  fullGridButton(),",
      ),
    );
  });

  test('compact landscape keeps the static ad and two-column command rail', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(grid, contains("Key('blueprint-landscape-static-ad')"));
    expect(
      grid,
      contains('widget.bannerSlot ?? const ArcBlueprintBannerSlot()'),
    );
    expect(grid, contains('const verticalColumns = 2;'));
    expect(grid, contains('const commandRailWidth = 132.0;'));
    expect(grid, contains('mainAxisSize: MainAxisSize.min'));
    expect(
      grid,
      isNot(contains('SizedBox(width: availableGridWidth, child: viewport)')),
    );
    expect(grid, isNot(contains("Key('blueprint-side-ad-right')")));
  });
}
