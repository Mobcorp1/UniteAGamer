import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mandatory onboarding keeps cinematic responsive convergence shell', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains('RAIDER INITIALIZATION'));
    expect(source, contains('UAG // ARC NETWORK'));
    expect(source, contains("assets/arc_raiders/hub/auth_bg_landscape.webp"));
    expect(source, contains('MediaQuery.sizeOf(context).width < 600'));
    expect(
      source,
      contains('constraints: const BoxConstraints(maxWidth: 920)'),
    );
    expect(source, contains('GridView.count('));
    expect(source, contains('NeverScrollableScrollPhysics'));
    expect(source, contains('showAdBanner: false'));
  });
}
