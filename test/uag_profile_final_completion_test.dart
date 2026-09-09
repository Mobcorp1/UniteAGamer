import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('final Raider Profile architecture contract', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'Raider Profile'"));
    expect(source, contains("['OVERVIEW', 'RAIDER', 'REPUTATION', 'LOCKER']"));
    expect(source, contains('int _selectedProfileTab = 0'));
    expect(source, contains('arc_hub_profile_reputation.webp'));
    expect(source, contains('width: 118'));
    expect(source, contains("title: 'Reputation Snapshot'"));
    expect(source, contains("title: 'Avatar'"));
    expect(source, contains('Tap to open Avatar Locker'));
    expect(source, contains('maxLines: 2'));
  });

  test('global dock exposes Profile as a first-class destination', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'PROFILE'"));
    expect(source, contains("active == 'profile'"));
    expect(source, contains("'/trading-hub/arc-raiders/profile'"));
    expect(source, isNot(contains("label: 'MY HUB'")));
  });
}
