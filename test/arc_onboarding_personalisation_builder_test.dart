import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_personalisation_builder.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

void main() {
  group('progressive onboarding personalisation', () {
    test('marks primary goal features as primary', () {
      final profile = buildArcOnboardingPersonalisation(
        primaryGoal: ArcPersonalisationGoal.completeBlueprints,
        completedAt: DateTime.utc(2026, 8, 1),
      );

      expect(profile.completed, isTrue);
      expect(profile.source, 'progressive_onboarding_v4');
      expect(
        profile.featureInterests[ArcPersonalisationFeature.blueprintTracker],
        ArcPersonalisationInterestLevel.primary,
      );
      expect(
        profile.featureInterests[ArcPersonalisationFeature
            .blueprintIntelligence],
        ArcPersonalisationInterestLevel.primary,
      );
      expect(profile.commandCentre.progressionCards, isTrue);
      expect(profile.reduceNoise, isTrue);
    });

    test('keeps secondary goal features below primary priority', () {
      final profile = buildArcOnboardingPersonalisation(
        primaryGoal: ArcPersonalisationGoal.planRaids,
        secondaryGoals: const {
          ArcPersonalisationGoal.tradeBlueprints,
          ArcPersonalisationGoal.findSquads,
        },
      );

      expect(
        profile.featureInterests[ArcPersonalisationFeature.raidIntelligence],
        ArcPersonalisationInterestLevel.primary,
      );
      expect(
        profile.featureInterests[ArcPersonalisationFeature.trading],
        ArcPersonalisationInterestLevel.high,
      );
      expect(
        profile.featureInterests[ArcPersonalisationFeature.matchRider],
        ArcPersonalisationInterestLevel.high,
      );
      expect(profile.commandCentre.tradeActivity, isTrue);
      expect(profile.commandCentre.socialActivity, isTrue);
      expect(profile.commandCentre.raidPreparation, isTrue);
    });

    test('returns stable recommended systems for primary goals', () {
      expect(
        arcOnboardingRecommendedSystem(
          ArcPersonalisationGoal.completeBlueprints,
        ),
        'blueprintTracker',
      );
      expect(
        arcOnboardingRecommendedSystem(ArcPersonalisationGoal.findSquads),
        'matchRider',
      );
      expect(
        arcOnboardingRecommendedSystem(
          ArcPersonalisationGoal.exploreEverything,
        ),
        'commandCentre',
      );
    });
  });
}
