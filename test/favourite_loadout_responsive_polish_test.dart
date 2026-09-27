import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
  ).readAsStringSync();

  test('Favourite Loadout owns ad and app nav as one bottom chrome stack', () {
    expect(source, contains('extendBody: false'));
    expect(source, contains('UagAdAwareBottomDock('));
    expect(source, contains("Key('favourite-loadout-ad-nav-stack')"));
    expect(source, contains('showAds: true'));
    expect(source, contains('reserveAdSpace: false'));
    expect(source, contains("ArcCompanionBottomDock(activeLabel: 'Loadout')"));
    expect(source, contains('showAdBanner: false'));
  });

  test('portrait and landscape equipment cards use aligned geometry', () {
    expect(
      source,
      contains('final slotHeight = compactLandscape ? 100.0 : 100.0'),
    );
    expect(
      source,
      contains('final imageFrameSize = compactLandscape ? 42.0 : 54.0'),
    );
    expect(source, contains("final itemVisualSize = slotLabel == 'AUGMENT'"));
    expect(source, contains('minHeight: compactLandscape ? 100.0 : 0'));
    expect(source, contains('width: double.infinity'));
  });

  test(
    'Wanted Blueprint grids stay readable without changing their counts',
    () {
      expect(source, contains('crossAxisCount: 2'));
      expect(source, contains('childAspectRatio: 1.05'));
      expect(source, contains('crossAxisCount: 5'));
      expect(source, contains('childAspectRatio: 3.00'));
      expect(source, contains(r"'WANTED BLUEPRINTS ${targets.length}/10'"));
      expect(source, contains('final compact = constraints.maxHeight < 82'));
      expect(source, contains('final imageSize = compact ? 20.0 : 30.0'));
    },
  );

  test(
    'mobile scroll padding no longer compensates for overlaid bottom chrome',
    () {
      expect(source, contains('EdgeInsets.fromLTRB(6, 4, 6, 18)'));
      expect(source, contains('EdgeInsets.fromLTRB(6, 4, 6, 12)'));
      expect(source, contains('bottomPadding: 24'));
    },
  );
}
