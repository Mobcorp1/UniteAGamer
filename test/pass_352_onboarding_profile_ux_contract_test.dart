import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 352 keeps onboarding visible and previews deterministic', () {
    final admin = File(
      'lib/screens/build/admin_console_screen.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();
    final tools = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_beta_first_run.dart',
    ).readAsStringSync();

    expect(admin, contains("title: 'Onboarding & Beta Testing'"));
    expect(admin, contains('initiallyExpanded: true'));
    expect(onboarding, contains('final int initialStep;'));
    expect(onboarding, contains('initialStep: requestedStep.clamp(0, 3)'));
    expect(tools, contains("label: 'Preview Agreements Step'"));
    expect(tools, contains('_launchOnboardingPreview(step: 1)'));
    expect(tools, contains('initialStep: step.clamp(0, 3)'));
  });

  test('PASS 352 profile card deck starts from the leading edge on web', () {
    final deck = File(
      'lib/widgets/uag_adaptive_card_deck.dart',
    ).readAsStringSync();
    expect(deck, contains('keepPage: false'));
    expect(deck, contains('padEnds: vertical'));
    expect(deck, isNot(contains('padEnds: true')));
  });
}
