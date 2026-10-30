import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

void main() {
  const mutedProfile = ArcUserPersonalisationProfile(
    completed: true,
    reduceNoise: true,
    goals: <ArcPersonalisationGoal>{ArcPersonalisationGoal.planRaids},
    featureInterests:
        <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{
          ArcPersonalisationFeature.favouriteLoadout:
              ArcPersonalisationInterestLevel.off,
        },
  );

  test(
    'PASS27 R8 keeps SAVED favourite status with Reduce Noise and hidden loadout feature',
    () {
      expect(
        mutedProfile.interestFor(ArcPersonalisationFeature.favouriteLoadout),
        ArcPersonalisationInterestLevel.off,
      );

      final saved = ArcSavedLoadout.fromMap(
        'favourite-loadout',
        <String, dynamic>{
          'name': 'Favourite Raider Build',
          'category': 'saved',
          'playStyle': 'balanced',
          'augment': 'Survivor',
          'shield': 'Medium Shield',
          'primaryWeapon': 'Anvil',
          'secondaryWeapon': 'Stitcher',
          'primaryAttachments': <String>['Extended Barrel III'],
          'secondaryAttachments': <String>[
            'Extended Barrel III',
            'Angled Grip III',
          ],
          'equipment': <String>['Snap Hook'],
          'consumables': <String>['Vita Shot', 'Lure Grenade'],
          'quickUse': <String>[
            'Survivor',
            'Snap Hook',
            'Vita Shot',
            'Lure Grenade',
          ],
          'createdAt': '2026-10-28T23:44:53.130991',
          'updatedAt': '2026-10-28T23:44:53.130991',
        },
      );

      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: <ArcSavedLoadout>[saved],
        personalisation: mutedProfile,
      );

      final metrics = state.snapshots
          .where((snapshot) => snapshot.label == 'Favourite Loadout')
          .toList(growable: false);

      expect(metrics, hasLength(1));
      expect(metrics.single.value, 'Saved');
      expect(metrics.single.detail, 'Favourite Raider Build');
    },
  );

  test(
    'PASS27 R8 keeps NOT SAVED for a genuinely absent favourite document',
    () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const <ArcSavedLoadout>[],
        personalisation: mutedProfile,
      );

      final metrics = state.snapshots
          .where((snapshot) => snapshot.label == 'Favourite Loadout')
          .toList(growable: false);

      expect(metrics, hasLength(1));
      expect(metrics.single.value, 'Not saved');
    },
  );
}
