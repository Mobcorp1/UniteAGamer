import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default signed-in destination is Command Centre behind Raider Setup',
    () {
      final gate = File(
        'lib/screens/build/app_entry_gate.dart',
      ).readAsStringSync();

      expect(gate, contains('return ArcRaiderSetupGate('));
      expect(gate, contains('const ArcCommandCentreScreen();'));
      expect(gate, isNot(contains('const ArcRaidersHubScreen();')));
    },
  );

  test('Raider Setup remains role-agnostic after onboarding', () {
    final setupGate = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raider_setup_screen.dart',
    ).readAsStringSync();

    expect(
      setupGate,
      contains('if (!snapshot.data!.status.needsSetup) return widget.child;'),
    );
    expect(setupGate, isNot(contains('isAdmin')));
    expect(setupGate, isNot(contains('isDev')));
  });

  test('Command Centre keeps ad lane and persistent quick-access dock', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('showAdBanner: true'));
    expect(screen, contains("ArcCompanionBottomDock(activeLabel: 'run')"));
  });

  test('Command Centre sends trade activity into upcoming commitments', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
    ).readAsStringSync();
    final content = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    expect(screen, contains('tradeActivity: tradeActivity'));
    expect(content, contains('final ArcCommandTradeActivity tradeActivity;'));
    expect(content, contains("title: 'CALENDAR / UPCOMING'"));
  });
}
