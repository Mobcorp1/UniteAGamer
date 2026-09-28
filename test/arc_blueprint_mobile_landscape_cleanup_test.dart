import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'native mobile Blueprint grid removes ownership tick and favourite star overlays',
    () {
      final grid = read(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );
      final tile = read(
        'lib/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart',
      );

      // Keep these checks formatting-agnostic. dart format is free to wrap the
      // platform expression across several lines.
      expect(grid, contains('final isNativeMobile ='));
      expect(grid, contains('!kIsWeb &&'));
      expect(grid, contains('defaultTargetPlatform == TargetPlatform.android'));
      expect(grid, contains('defaultTargetPlatform == TargetPlatform.iOS'));
      expect(grid, contains('showOwnershipBadge: !isNativeMobile'));
      expect(grid, contains('loadoutAction: isNativeMobile'));
      expect(tile, contains('this.showOwnershipBadge = true'));
      expect(tile, contains('if (showOwnershipBadge)'));
    },
  );

  test('landscape canvas uses body height and top-centers the pannable grid', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(grid, isNot(contains('reservedChromeHeight')));
    expect(grid, contains('final bodyHeight = constraints.maxHeight.isFinite'));
    expect(
      grid,
      contains('final canvasWidth = math.max(viewportWidth, fittedWidth)'),
    );
    expect(
      grid,
      contains('final canvasHeight = math.max(viewportHeight, fittedHeight)'),
    );
    expect(
      grid,
      matches(
        RegExp(
          r'child: isLandscape\s*\? SizedBox\(\s*width: canvasWidth,\s*height: canvasHeight,\s*child: Align\(\s*alignment: Alignment.topCenter,',
        ),
      ),
    );
    expect(grid, contains('constrained: !isLandscape'));
  });
}
