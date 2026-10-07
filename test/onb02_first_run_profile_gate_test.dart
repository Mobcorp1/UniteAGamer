import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ONB02 converges account creation onto mandatory onboarding', () {
    final authLanding = File(
      'lib/screens/build/auth/auth_landing_screen.dart',
    ).readAsStringSync();

    expect(
      authLanding,
      contains('builder: (_) => const ArcMandatoryOnboardingScreen()'),
    );
    expect(
      authLanding,
      isNot(
        contains('builder: (_) => const AuthScreen(initialIsLogin: false)'),
      ),
    );
  });

  test('ONB02 production gate enforces profile completion after onboarding', () {
    final gate = File(
      'lib/screens/build/app_entry_gate.dart',
    ).readAsStringSync();

    final setup = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raider_setup_screen.dart',
    ).readAsStringSync();
    final evaluator = File(
      'lib/features/trading_hub/arc_raiders/data/arc_raider_setup_evaluator.dart',
    ).readAsStringSync();
    expect(gate, contains('return ArcRaiderSetupGate('));
    expect(setup, contains('snapshot.data!.status.needsSetup'));
    expect(evaluator, contains('if (profile.identityComplete)'));
    expect(evaluator, contains('version < ArcRaiderSetupEvaluator.version'));
    expect(gate, isNot(contains("prefs.getBool('hasCompletedProfileSetup')")));
  });

  test('ONB02 onboarding hands off through required profile setup', () {
    final onboarding = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();

    expect(
      onboarding,
      contains('const ArcProfileSetupScreen(firstRunFlow: true)'),
    );
    expect(onboarding, isNot(contains('_completionDestination')));
    expect(
      onboarding,
      contains("prefs.setBool('hasCompletedProfileSetup', false)"),
    );
  });

  test('ONB02 first-run profile requires Embark ID and availability', () {
    final profile = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_profile_setup_screen.dart',
    ).readAsStringSync();

    expect(profile, contains('this.firstRunFlow = false'));
    expect(profile, contains("v) => _required(v, 'Embark ID')"));
    expect(profile, contains('ArcAvailabilityScreen(firstRunFlow: true)'));
    expect(profile, contains('_repository.refreshProfileCompletion()'));
    expect(
      profile,
      contains("prefs.setBool('hasCompletedProfileSetup', true)"),
    );
    expect(
      profile,
      contains("pushNamedAndRemoveUntil('/app-entry-gate', (_) => false)"),
    );
  });

  test('ONB02 legacy entry gate is only a compatibility re-export', () {
    final legacy = File('lib/build/app_entry_gate.dart').readAsStringSync();

    expect(
      legacy,
      contains(
        "export 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';",
      ),
    );
    expect(legacy, isNot(contains('class AppEntryGate extends')));
  });

  test('ONB02 onboarding deep links re-enter the canonical gate', () {
    final main = File('lib/main.dart').readAsStringSync();

    expect(
      main,
      contains(
        'return ArcMandatoryOnboardingScreen.fromRouteSettings(settings);',
      ),
    );
    expect(main, contains('final adminPreview ='));
    expect(main, contains('return const AppEntryGate();'));
    expect(
      main,
      isNot(contains('return const AuthScreen(initialIsLogin: false);')),
    );
  });
}
