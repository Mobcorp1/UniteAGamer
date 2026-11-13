import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raider_setup_evaluator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';

const setupProfile = <String, dynamic>{
  'embarkId': 'Raider#1234',
  'platforms': ['PlayStation'],
  'playStyle': 'Trader',
  'communicationStyle': 'Voice',
  'squadIntent': 'Squad up',
  'socialEnergy': 'Focused',
  'sessionIntent': 'Progression',
};
Map<String, dynamic> emptyConfirmations() => {
  'confirmationVersion': 1,
  'seasonId': 'season-1',
  'noBlueprintsConfirmed': true,
  'scrappyStartingConfirmed': true,
  'loadoutDeferred': true,
  'noActiveQuestsConfirmed': true,
  'unbuiltBenchIds': const ArcProgressionEngine().benchDefinitions
      .map((d) => d.benchId)
      .toSet()
      .toList(),
};
void main() {
  const evaluate = ArcRaiderSetupEvaluator();
  test(
    'empty/default documents and legacy completion booleans are not setup',
    () {
      final result = evaluate.evaluate(
        userData: {
          'hasCompletedProfileSetup': true,
          'arcRaiderSetup': {'version': 1},
        },
        availabilityData: ArcAvailability.initial().toMap(),
      );
      expect(result.completed, isEmpty);
      expect(result.missing.length, 7);
      expect(result.needsSetup, isTrue);
    },
  );
  test(
    'legacy account catches up only missing sections without changing agreements',
    () {
      final user = {
        'hasCompletedProfileSetup': true,
        'legalAccepted': {'termsAccepted': true, 'privacyAccepted': true},
      };
      final result = evaluate.evaluate(
        userData: user,
        profileData: setupProfile,
        hasOwnedBlueprints: true,
        hasConfiguredLoadout: true,
      );
      expect(
        result.completed,
        containsAll([
          ArcRaiderSetupSection.profile,
          ArcRaiderSetupSection.blueprints,
          ArcRaiderSetupSection.loadout,
        ]),
      );
      expect(result.missing.first, ArcRaiderSetupSection.availability);
      expect(result.needsSetup, isTrue);
      expect(user['legalAccepted'], {
        'termsAccepted': true,
        'privacyAccepted': true,
      });
    },
  );
  test(
    'explicit empty/default answers complete setup only after version acceptance',
    () {
      final metadata = emptyConfirmations();
      ArcRaiderSetupStatus result() => evaluate.evaluate(
        userData: {'arcRaiderSetup': metadata},
        profileData: setupProfile,
        availabilityData: {
          ...ArcAvailability.initial().toMap(),
          'scheduleType': 'flexible',
          'completed': true,
        },
      );
      expect(result().ready, isTrue);
      expect(result().needsSetup, isTrue);
      metadata['version'] = 1;
      expect(result().needsSetup, isFalse);
    },
  );
  test('default weekly save and unconfirmed flexible state do not count', () {
    for (final data in [
      {...ArcAvailability.initial().toMap(), 'completed': true},
      {'scheduleType': 'flexible'},
    ]) {
      expect(
        evaluate.evaluate(availabilityData: data).completed,
        isNot(contains(ArcRaiderSetupSection.availability)),
      );
    }
    final availability = ArcAvailability.initial();
    final week = availability.weeks.first;
    expect(
      evaluate
          .evaluate(
            availabilityData: availability
                .copyWith(
                  weeks: [
                    week.copyWith(
                      slots: [week.slots.first.copyWith(enabled: true)],
                    ),
                  ],
                )
                .toMap(),
          )
          .completed,
      contains(ArcRaiderSetupSection.availability),
    );
  });
  test(
    'actual canonical quest, Scrappy and all bench levels count without extra confirmations',
    () {
      final engine = const ArcProgressionEngine();
      final definitions = engine.benchDefinitions;
      final result = evaluate.evaluate(
        progression: ArcProgressionRecords(
          questRecords: const {},
          trackedQuestIds: {ArcQuestCatalogue.rootQuestId},
          scrappyState: const ArcScrappyProgressionState(
            seasonId: 'season-1',
            currentLevel: 2,
          ),
          benchRecords: {
            for (final d in definitions)
              d.benchId: ArcBenchProgressionRecord(
                benchId: d.benchId,
                station: d.station,
                seasonId: 'season-1',
                currentLevel: d.level,
              ),
          },
        ),
      );
      expect(
        result.completed,
        containsAll([
          ArcRaiderSetupSection.quests,
          ArcRaiderSetupSection.scrappy,
          ArcRaiderSetupSection.benches,
        ]),
      );
    },
  );
  test(
    'old season and old version confirmations cannot satisfy empty baselines',
    () {
      for (final override in [
        {'seasonId': 'old-season'},
        {'confirmationVersion': 0},
      ]) {
        final result = evaluate.evaluate(
          userData: {
            'arcRaiderSetup': {...emptyConfirmations(), ...override},
          },
        );
        expect(
          result.completed,
          isNot(contains(ArcRaiderSetupSection.blueprints)),
        );
        expect(
          result.completed,
          isNot(contains(ArcRaiderSetupSection.scrappy)),
        );
        expect(
          result.completed,
          isNot(contains(ArcRaiderSetupSection.benches)),
        );
      }
    },
  );
  test('admin and dev roles do not bypass Raider Setup', () {
    for (final role in ['isAdmin', 'isDev']) {
      final status = evaluate.evaluate(userData: {role: true});
      expect(status.needsSetup, isTrue);
      expect(status.completed, isEmpty);
      expect(status.preview, isFalse);
    }
  });
}
