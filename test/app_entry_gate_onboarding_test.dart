import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/build/app_entry_gate.dart';

void main() {
  group('progressive onboarding entry decision', () {
    test('new or reset users require onboarding', () {
      expect(arcNeedsProgressiveOnboarding(const {}), isTrue);
      expect(
        arcNeedsProgressiveOnboarding(const {'onboardingComplete': false}),
        isTrue,
      );
    });

    test('completed existing users continue into the app', () {
      expect(
        arcNeedsProgressiveOnboarding(const {'onboardingComplete': true}),
        isFalse,
      );
    });
  });
}
