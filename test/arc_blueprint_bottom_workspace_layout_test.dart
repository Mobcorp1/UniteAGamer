import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'Blueprint family keeps one app dock and Loadout uses top workspace switching',
    () {
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
        matches(
          RegExp(
            r'ArcCollectionsCategoryBar\(',
          ),
        ),
      );
      expect(
        watches,
        matches(
          RegExp(
            r'ArcBlueprintWorkspaceDock\(\s*current:\s*ArcBlueprintWorkspace\.watches,?\s*\)',
          ),
        ),
      );
      expect(loadout, contains('ArcBlueprintWorkspaceBar('));
      expect(loadout, contains('UagAdAwareBottomDock('));
      expect(
        loadout,
        contains("ArcCompanionBottomDock(activeLabel: 'Loadout')"),
      );
      expect(
        loadout,
        isNot(
          contains(
            'ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.loadout)',
          ),
        ),
      );
    },
  );

  test(
    'landscape Blueprint overview uses bounded scale and remains pannable',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );

      expect(source, contains('math.min(widthScale, heightScale)'));
      expect(source, contains('0.05,'));
      expect(source, contains('constrained: !isLandscape'));
      expect(source, contains('final viewportWidth = fittedWidth;'));
      expect(
        source,
        contains('final bodyHeight = constraints.maxHeight.isFinite'),
      );
      expect(source, contains('bodyHeight -'));
      expect(source, contains('commandBarHeight -'));
      expect(source, contains('commandBarGap -'));
      expect(source, contains('gridVerticalSafetyInset'));
      expect(source, contains('const commandBarGap = 6.0;'));
      expect(source, contains('const gridVerticalSafetyInset = 10.0;'));
      expect(source, isNot(contains('reservedChromeHeight')));
      expect(source, contains('width: canvasWidth'));
      expect(source, contains('height: canvasHeight'));
      expect(
        source,
        contains("key: const Key('blueprint-authoritative-grid-viewport')"),
      );
    },
  );
}
