import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';

void main() {
  group('PASS 344 established-account classification', () {
    test('explicit incomplete flags always require onboarding', () {
      expect(
        arcNeedsMandatoryOnboarding(const {
          'arcMandatoryOnboardingComplete': false,
          'displayName': 'Existing Looking Name',
          'basicProfile': {'displayName': 'Existing Looking Name'},
        }),
        isTrue,
      );

      expect(
        arcNeedsMandatoryOnboarding(const {
          'onboardingComplete': false,
          'displayName': 'Legacy Looking Name',
          'traderProfile': {'uagName': 'Legacy Looking Name'},
        }),
        isTrue,
      );
    });

    test('canonical and legacy true flags remain complete', () {
      expect(
        arcNeedsMandatoryOnboarding(const {
          'arcMandatoryOnboardingComplete': true,
        }),
        isFalse,
      );
      expect(
        arcNeedsMandatoryOnboarding(const {'onboardingComplete': true}),
        isFalse,
      );
    });

    test('pre-schema established profile bypasses re-onboarding', () {
      const legacyProfile = <String, dynamic>{
        'displayName': 'Mike Raider',
        'basicProfile': <String, dynamic>{
          'displayName': 'Mike Raider',
          'email': 'mike@example.com',
        },
        'traderProfile': <String, dynamic>{'uagName': 'Mike Raider'},
      };

      expect(arcLooksLikeEstablishedLegacyAccount(legacyProfile), isTrue);
      expect(arcNeedsMandatoryOnboarding(legacyProfile), isFalse);
      expect(arcNeedsLegacyOnboardingMigration(legacyProfile), isTrue);
    });

    test('old completion-shaped profile fields are accepted', () {
      expect(
        arcNeedsMandatoryOnboarding(const {'hasCompletedOnboarding': true}),
        isFalse,
      );
      expect(
        arcNeedsMandatoryOnboarding(const {'hasCompletedProfileSetup': true}),
        isFalse,
      );
      expect(
        arcNeedsMandatoryOnboarding(const {
          'arcOnboarding': {'completedAt': 'legacy-timestamp'},
        }),
        isFalse,
      );
    });

    test('empty or identity-only user still requires onboarding', () {
      expect(arcNeedsMandatoryOnboarding(const {}), isTrue);
      expect(
        arcNeedsMandatoryOnboarding(const {
          'email': 'new@example.com',
          'displayName': 'New Raider',
        }),
        isTrue,
      );
    });

    test('new version-4 account creation remains incomplete', () {
      const newlyCreated = <String, dynamic>{
        'onboardingComplete': false,
        'arcMandatoryOnboardingComplete': false,
        'displayName': 'New Raider',
        'basicProfile': <String, dynamic>{'displayName': 'New Raider'},
        'traderProfile': <String, dynamic>{'uagName': 'New Raider'},
        'arcOnboarding': <String, dynamic>{
          'version': 4,
          'accountCreatedDuringOnboarding': true,
        },
      };

      expect(arcLooksLikeEstablishedLegacyAccount(newlyCreated), isFalse);
      expect(arcNeedsMandatoryOnboarding(newlyCreated), isTrue);
      expect(arcNeedsLegacyOnboardingMigration(newlyCreated), isFalse);
    });
  });

  test('PASS 344 migration writes both canonical and legacy completion', () {
    final source = File(
      'lib/screens/build/app_entry_gate.dart',
    ).readAsStringSync();

    expect(source, contains("'arcMandatoryOnboardingComplete': true"));
    expect(source, contains("'onboardingComplete': true"));
    expect(source, contains("'arcMandatoryOnboardingMigrationReason'"));
  });
}
