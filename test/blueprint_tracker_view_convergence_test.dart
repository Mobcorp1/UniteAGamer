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
      expect(source, contains('vertical: true'));
      expect(source, isNot(contains('Widget _buildGridControlRail(')));
      expect(source, isNot(contains('Widget _buildViewModeRail(')));
      expect(source, contains("tooltip: 'In-game view'"));
      expect(source, contains("tooltip: 'Full grid overview'"));
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
    expect(source, contains('const ArcBlueprintWorkspaceBar('));
    expect(source, contains('bottomNavigationBar: compactMobileLandscape'));
    expect(source, contains('ArcCompanionBottomDock(activeLabel: \'Track\')'));
  });

  test('wide eligible compact landscape uses one right sponsor lane', () {
    final tracker = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(tracker, contains('maxWidth >= 1180'));
    expect(tracker, contains('UagAdService.instance.canShowBanner'));
    expect(tracker, contains('widget.bannerSlot != null'));
    expect(tracker, contains("Key('blueprint-landscape-side-layout')"));
    expect(tracker, isNot(contains("Key('blueprint-side-ad-left')")));
    expect(tracker, contains("Key('blueprint-side-ad-right')"));
    expect(tracker, contains('sideAdLaneWidth = 480.0'));
    expect(tracker, contains('commandRailWidth = 52.0'));
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
