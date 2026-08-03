import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_profile_completion_evaluator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';

void main() {
  const evaluator = ArcProfileCompletionEvaluator();

  ArcAvailability activeAvailability() {
    final initial = ArcAvailability.initial();
    final week = initial.weeks.first;
    return initial.copyWith(
      weeks: [
        week.copyWith(
          slots: [
            week.slots.first.copyWith(enabled: true),
            ...week.slots.skip(1),
          ],
        ),
      ],
    );
  }

  group('ArcProfileCompletionEvaluator', () {
    test('reports exact missing fields for an empty profile', () {
      final result = evaluator.evaluate(
        userData: const {},
        profileData: const {},
        availability: ArcAvailability.initial(),
      );

      expect(result.complete, isFalse);
      expect(
        result.missingFieldIds,
        containsAll([
          'embarkId',
          'archetypes',
          'communicationStyle',
          'squadIntent',
          'socialSessionState',
          'availability',
          'onboarding',
          'legal',
        ]),
      );
      expect(
        result.resumeRouteName,
        ArcProfileCompletionEvaluator.profileSetupRouteName,
      );
    });

    test('accepts legacy single archetype values and active availability', () {
      final result = evaluator.evaluate(
        userData: const {
          'arcMandatoryOnboardingComplete': true,
          'legalAccepted': {'termsAccepted': true, 'privacyAccepted': true},
        },
        profileData: const {
          'embarkId': 'Raider#1234',
          'playStyle': 'Trader',
          'communicationStyle': 'Voice',
          'squadIntent': 'Squad up',
          'socialEnergy': 'Focused',
          'sessionIntent': 'Progression',
        },
        availability: activeAvailability(),
      );

      expect(result.complete, isTrue);
      expect(result.missingFieldIds, isEmpty);
    });

    test(
      'requires age confirmation when the onboarding age policy is present',
      () {
        final result = evaluator.evaluate(
          userData: const {
            'arcMandatoryOnboardingComplete': true,
            'arcOnboarding': {
              'completedAt': '2026-08-01T12:00:00Z',
              'legalAccepted': {
                'traderCodeAccepted': true,
                'termsOfServiceAccepted': true,
                'dataSecurityAccepted': true,
                'ageConfirmationAccepted': false,
                'policies': {
                  'age_restriction_policy': {'accepted': false},
                },
              },
            },
          },
          profileData: const {
            'embarkId': 'Raider#1234',
            'playStyle': 'Trader',
            'communicationStyle': 'Voice',
            'squadIntent': 'Squad up',
            'socialEnergy': 'Focused',
            'sessionIntent': 'Progression',
          },
          availability: activeAvailability(),
        );

        expect(result.complete, isFalse);
        expect(result.missingFieldIds, contains('legal'));
      },
    );

    test('does not treat the initial blank availability as complete', () {
      final result = evaluator.evaluate(
        userData: const {
          'arcMandatoryOnboardingComplete': true,
          'legalAccepted': {'termsAccepted': true, 'privacyAccepted': true},
        },
        profileData: const {
          'embarkId': 'Raider#1234',
          'archetypes': ['Trader', 'Explorer'],
          'communicationStyle': 'Voice',
          'squadIntent': 'Squad up',
          'socialEnergy': 'Focused',
          'sessionIntent': 'Progression',
        },
        availability: ArcAvailability.initial(),
      );

      expect(result.complete, isFalse);
      expect(result.missingFieldIds, contains('availability'));
    });

    test('saved availability flag clears availability without fixed slots', () {
      final result = evaluator.evaluate(
        userData: const {
          'arcMandatoryOnboardingComplete': true,
          'availabilityCompleted': true,
          'legalAccepted': {'termsAccepted': true, 'privacyAccepted': true},
        },
        profileData: const {
          'embarkId': 'Raider#1234',
          'archetypes': ['Trader', 'Explorer'],
          'communicationStyle': 'Voice',
          'squadIntent': 'Squad up',
          'socialEnergy': 'Focused',
          'sessionIntent': 'Progression',
        },
        availability: ArcAvailability.initial(),
      );

      expect(result.complete, isTrue);
      expect(result.missingFieldIds, isEmpty);
    });

    test('saved availability document clears availability field directly', () {
      final result = evaluator.evaluate(
        userData: const {
          'arcMandatoryOnboardingComplete': true,
          'legalAccepted': {'termsAccepted': true, 'privacyAccepted': true},
        },
        profileData: const {
          'embarkId': 'Raider#1234',
          'archetypes': ['Trader', 'Explorer'],
          'communicationStyle': 'Voice',
          'squadIntent': 'Squad up',
          'socialEnergy': 'Focused',
          'sessionIntent': 'Progression',
        },
        availabilityData: const {
          'completed': true,
          'availabilityDayKeys': <String>[],
        },
        availability: ArcAvailability.initial(),
      );

      expect(result.complete, isTrue);
      expect(result.missingFieldIds, isEmpty);
    });
  });
}
