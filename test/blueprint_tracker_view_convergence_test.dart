import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'Blueprint Tracker uses responsive horizontal and vertical grid controls',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );

      expect(source, contains("'blueprint-grid-horizontal-command-bar'"));
      expect(source, contains("'blueprint-grid-vertical-command-rail'"));
      // PASS 33 moved compact landscape controls to the fitted bottom dock.
      // The older command-rail implementation remains a valid branch variant.
      if (source.contains("'blueprint-landscape-fitted-dock'")) {
        expect(source, contains("key: const Key('blueprint-landscape-fitted-dock')"));
        expect(source, contains('const verticalColumns = 2;'));
      } else {
        expect(source, contains('vertical: true'));
      }
      expect(source, isNot(contains('Widget _buildGridControlRail(')));
      expect(source, isNot(contains('Widget _buildViewModeRail(')));
      expect(
        source,
        contains("tooltip: 'In-game view - five-row game layout'"),
      );
      expect(
        source,
        contains("tooltip: 'Full grid overview - all Blueprint slots'"),
      );
      expect(source, contains("tooltip: 'Zoom in'"));
      expect(source, contains("tooltip: 'Reset grid view'"));
      expect(source, contains("tooltip: 'Zoom out'"));
    },
  );

  test('compact landscape moves Blueprint family tabs into header', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(source, contains('showWorkspaceInHeader'));
    expect(source, contains('ArcCollectionsCategoryBar('));
    expect(source, contains('bottomNavigationBar: AnimatedBuilder('));
    expect(
      source,
      anyOf(
        contains("'blueprint-landscape-static-ad'"),
        contains("key: const Key('blueprint-dock-fitted-ad')"),
      ),
    );
    expect(source, contains("ArcCompanionBottomDock(activeLabel: 'Track')"));
  });

  test('compact landscape uses one static bottom sponsor lane', () {
    final tracker = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    if (tracker.contains("'blueprint-landscape-fitted-dock'")) {
      expect(tracker, contains("key: const Key('blueprint-landscape-fitted-dock')"));
      expect(tracker, contains("key: const Key('blueprint-dock-fitted-ad')"));
      expect(tracker, contains("widget.bannerSlot ?? const ArcBlueprintBannerSlot()"));
      expect(tracker, contains("keyName: 'blueprint-dock-camera'"));
      expect(tracker, contains("keyName: 'blueprint-dock-share'"));
    } else {
      expect(tracker, contains("Key('blueprint-landscape-side-layout')"));
      expect(tracker, contains("'blueprint-landscape-static-ad'"));
      expect(tracker, contains('commandRailWidth = 106.0'));
    }
    expect(tracker, isNot(contains("Key('blueprint-side-ad-left')")));
    expect(tracker, isNot(contains("Key('blueprint-side-ad-right')")));
  });

  test('Wanted Blueprint target-pick flow remains present', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(source, contains('_isFavouriteLoadoutTargetPickMode'));
    expect(source, contains('_selectFavouriteLoadoutWantedBlueprint'));
    expect(source, contains('favouriteLoadoutTargetSlotIndex'));
  });
}
