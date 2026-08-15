import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';

void main() {
  test('legacy completed accounts bypass mandatory onboarding and migrate', () {
    final legacy = <String, dynamic>{'onboardingComplete': true};

    expect(arcHasCompletedMandatoryOnboarding(legacy), isTrue);
    expect(arcNeedsMandatoryOnboarding(legacy), isFalse);
    expect(arcNeedsLegacyOnboardingMigration(legacy), isTrue);
  });

  test('canonical completed accounts bypass onboarding without migration', () {
    final canonical = <String, dynamic>{'arcMandatoryOnboardingComplete': true};

    expect(arcHasCompletedMandatoryOnboarding(canonical), isTrue);
    expect(arcNeedsMandatoryOnboarding(canonical), isFalse);
    expect(arcNeedsLegacyOnboardingMigration(canonical), isFalse);
  });

  test('genuinely incomplete accounts still require mandatory onboarding', () {
    final incomplete = <String, dynamic>{
      'onboardingComplete': false,
      'arcMandatoryOnboardingComplete': false,
    };

    expect(arcHasCompletedMandatoryOnboarding(incomplete), isFalse);
    expect(arcNeedsMandatoryOnboarding(incomplete), isTrue);
    expect(arcNeedsLegacyOnboardingMigration(incomplete), isFalse);
  });

  test('admin and dev accounts remain exempt from mandatory onboarding', () {
    expect(
      arcNeedsMandatoryOnboarding(<String, dynamic>{'isAdmin': true}),
      isFalse,
    );
    expect(
      arcNeedsMandatoryOnboarding(<String, dynamic>{'isDev': true}),
      isFalse,
    );
  });

  test('entry gate preserves the absolute unauthenticated login boundary', () {
    final source = File(
      'lib/screens/build/app_entry_gate.dart',
    ).readAsStringSync();

    expect(source, contains('if (user == null)'));
    expect(source, contains('return const AuthLandingScreen();'));
    expect(source, contains('if (sessionSnapshot.data != true)'));
    expect(source, contains('return const ArcMandatoryOnboardingScreen();'));
    expect(
      source,
      contains("'arcMandatoryOnboardingMigratedFromLegacy': true"),
    );
    expect(
      source,
      contains(
        "'arcMandatoryOnboardingMigratedAt': FieldValue.serverTimestamp()",
      ),
    );
  });
}
