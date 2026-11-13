import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile account surfaces use the shared UAG visual language', () {
    final edit = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_profile_edit_screen.dart',
    ).readAsStringSync();
    final setup = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart',
    ).readAsStringSync();
    final availability = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart',
    ).readAsStringSync();
    final away = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_away_screen.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/features/profile/screens/profile_settings_screen.dart',
    ).readAsStringSync();

    for (final source in [edit, setup, availability, away, settings]) {
      expect(source, contains('UagAppBar('));
    }

    for (final source in [edit, setup, availability, away]) {
      expect(source, contains('ArcFormPageLead('));
    }

    expect(edit, contains('ArcExpandableFormSection('));
    expect(setup, contains('ArcExpandableFormSection('));
    expect(edit, isNot(contains('Trader Identity + Reputation')));
    expect(setup, isNot(contains('Build the public ARC Raiders profile')));
    expect(settings, isNot(contains('More profile controls will unlock')));
  });
}
