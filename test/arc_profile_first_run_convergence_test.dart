import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_session_catalog.dart';
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

  Map<String, dynamic> readyUser() => const <String, dynamic>{
    'arcMandatoryOnboardingComplete': true,
    'legalAccepted': <String, dynamic>{
      'termsAccepted': true,
      'privacyAccepted': true,
    },
  };

  test(
    'seeded friendly defaults are not treated as deliberate profile answers',
    () {
      final result = evaluator.evaluate(
        userData: readyUser(),
        profileData: <String, dynamic>{
          'embarkId': 'Raider#1234',
          'platforms': const <String>['PlayStation'],
          'archetypes': const <String>['Balanced Raider'],
          'playStyle': 'PvE defensive',
          'communicationStyle': 'Flexible',
          'squadIntent': 'Flexible',
          'socialEnergy': 'Depends on the day',
          'sessionIntent': ArcPlayerSessionCatalog.defaultIntent,
        },
        availability: activeAvailability(),
      );

      expect(
        result.missingFieldIds,
        containsAll(<String>[
          'archetypes',
          'communicationStyle',
          'squadIntent',
          'socialSessionState',
        ]),
      );
      expect(result.requiredFieldCount, 9);
      expect(result.completedFieldCount, 5);
      expect(result.completionPercent, 56);
    },
  );

  test('explicitly confirmed defaults count as valid player choices', () {
    final result = evaluator.evaluate(
      userData: readyUser(),
      profileData: <String, dynamic>{
        'profileSetupConfirmed': true,
        'embarkId': 'Raider#1234',
        'platforms': const <String>['PlayStation'],
        'archetypes': const <String>['Balanced Raider'],
        'playStyle': 'PvE defensive',
        'communicationStyle': 'Flexible',
        'squadIntent': 'Flexible',
        'socialEnergy': 'Depends on the day',
        'sessionIntent': ArcPlayerSessionCatalog.defaultIntent,
      },
      availability: activeAvailability(),
    );

    expect(result.complete, isTrue);
    expect(result.completedFieldCount, result.requiredFieldCount);
    expect(result.completionPercent, 100);
  });

  test('first-run onboarding converges through profile and availability', () {
    final onboarding = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();
    final profileSetup = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_profile_setup_screen.dart',
    ).readAsStringSync();
    final availability = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_availability_screen.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/trading_hub/arc_raiders/repositories/'
      'arc_trader_profile_repository.dart',
    ).readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      onboarding,
      contains('const ArcProfileSetupScreen(firstRunFlow: true)'),
    );
    expect(profileSetup, contains('requireCompletionFields'));
    expect(profileSetup, contains('ArcAvailabilityScreen(firstRunFlow: true)'));
    expect(availability, contains('ArcAccountJourneyStage.profile'));
    expect(profile, contains("title: 'Profile Completion'"));
    expect(profile, contains("label: const Text('Complete')"));
    expect(profile, contains('profileCompletion.completionPercent'));
    expect(profile, isNot(contains('missingFieldIds.length / 8')));
    expect(mainSource, contains('requireCompletionFields: true'));
    expect(repository, contains('bool confirmProfileSetup = false'));
    expect(
      profileSetup,
      contains('confirmProfileSetup: _requiresCompletionFields'),
    );
    expect(repository, contains("..['profileSetupConfirmed'] = true"));
    expect(
      repository,
      contains("'completionPercent': result.completionPercent"),
    );
  });
}
