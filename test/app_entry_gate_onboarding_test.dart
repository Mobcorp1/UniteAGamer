import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';

void main() {
  group('mandatory onboarding entry decision', () {
    test('new or reset users require onboarding', () {
      expect(arcNeedsMandatoryOnboarding(const {}), isTrue);
      expect(
        arcNeedsMandatoryOnboarding(const {
          'arcMandatoryOnboardingComplete': false,
        }),
        isTrue,
      );
      expect(
        arcNeedsMandatoryOnboarding(const {'onboardingComplete': false}),
        isTrue,
      );
    });

    test('completed existing users continue into the app', () {
      expect(
        arcNeedsMandatoryOnboarding(const {
          'arcMandatoryOnboardingComplete': true,
        }),
        isFalse,
      );
    });

    test('legacy completed users continue and qualify for migration', () {
      const legacyComplete = <String, dynamic>{'onboardingComplete': true};

      expect(arcNeedsMandatoryOnboarding(legacyComplete), isFalse);
      expect(arcNeedsLegacyOnboardingMigration(legacyComplete), isTrue);
    });

    test('canonical completion supersedes legacy migration', () {
      const canonicalComplete = <String, dynamic>{
        'onboardingComplete': true,
        'arcMandatoryOnboardingComplete': true,
      };

      expect(arcNeedsMandatoryOnboarding(canonicalComplete), isFalse);
      expect(arcNeedsLegacyOnboardingMigration(canonicalComplete), isFalse);
    });

    test('progressive helper remains a compatibility alias', () {
      expect(
        arcNeedsProgressiveOnboarding(const {
          'arcMandatoryOnboardingComplete': false,
        }),
        isTrue,
      );
      expect(
        arcNeedsProgressiveOnboarding(const {
          'arcMandatoryOnboardingComplete': true,
        }),
        isFalse,
      );
      expect(
        arcNeedsProgressiveOnboarding(const {'onboardingComplete': true}),
        isFalse,
      );
    });

    test(
      'admin and dev accounts are not trapped by onboarding preview work',
      () {
        expect(
          arcNeedsMandatoryOnboarding(const {
            'isAdmin': true,
            'arcMandatoryOnboardingComplete': false,
          }),
          isFalse,
        );
        expect(
          arcNeedsMandatoryOnboarding(const {
            'isDev': true,
            'arcMandatoryOnboardingComplete': false,
          }),
          isFalse,
        );
      },
    );
  });
}
