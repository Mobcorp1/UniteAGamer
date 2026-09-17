import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Blueprint family navigation is bottom anchored', () {
    final tracker = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );
    final loadout = read(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    );
    final watches = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart',
    );

    expect(
      tracker,
      contains(
        'ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.tracker)',
      ),
    );
    expect(
      loadout,
      contains(
        'ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.loadout)',
      ),
    );
    expect(
      watches,
      contains(
        'ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.watches)',
      ),
    );
  });

  test('landscape Blueprint overview is height-first and pannable', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(source, contains('Landscape is height-first'));
    expect(source, contains('heightScale.clamp(0.20, 1.20)'));
    expect(source, contains('constrained: !isLandscape'));
    expect(source, contains('viewportWidth = isLandscape'));
    expect(source, contains('reservedChromeHeight = isLandscape ? 128.0'));
    expect(
      source,
      contains("key: const Key('blueprint-authoritative-grid-viewport')"),
    );
  });
}
