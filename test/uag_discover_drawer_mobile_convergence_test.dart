import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('Discover UAG uses available mobile height and ARC typography', () {
    final hub = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
    );

    expect(
      hub,
      contains('final phoneReservedHeight = showQuickStrip ? 104.0 : 34.0;'),
    );
    expect(hub, contains('final stageHeight = isPhone'));
    expect(hub, contains('? availableHeight'));
    expect(hub, contains('math.max(232.0, centerHeight * 0.82)'));

    // Deliberately do not assert the preceding `style:` token on the same
    // physical line. `dart format` may wrap named-argument expressions.
    expect(hub, contains('ArcUiTokens.cardTitle('));
    expect(hub, contains('ArcUiTokens.body('));

    // Guard against regression to the old feature-card title styling.
    final cardStart = hub.indexOf('class _StaticRingFeatureCard');
    expect(cardStart, greaterThanOrEqualTo(0));
    final cardEnd = hub.indexOf('class _ArcHubStatusPill', cardStart);
    final cardSource = hub.substring(
      cardStart,
      cardEnd > cardStart ? cardEnd : hub.length,
    );
    expect(cardSource, contains('ArcUiTokens.cardTitle('));
  });

  test('mobile drawer is compact and keeps chevrons beside labels', () {
    final drawer = source('lib/build/app_drawer.dart');

    expect(drawer, contains('this.drawerWidth = 244'));
    expect(drawer, contains('widget.drawerWidth.clamp(228.0, 244.0)'));
    expect(drawer, contains('width: 44'));
    expect(drawer, contains('height: 1,'));
    expect(drawer, contains('Flexible('));
    expect(drawer, contains('fit: FlexFit.loose'));
    expect(drawer, contains('const SizedBox(width: 4)'));
    expect(drawer, contains('minimumSize: const Size.fromHeight(40)'));
  });
}
