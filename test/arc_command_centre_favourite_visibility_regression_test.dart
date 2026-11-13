import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

void main() {
  test('Reduce Noise never removes the persisted Favourite Loadout status', () {
    const preferences = ArcUserPersonalisationProfile(
      completed: true,
      reduceNoise: true,
      featureInterests: <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{
        ArcPersonalisationFeature.favouriteLoadout: ArcPersonalisationInterestLevel.off,
      },
    );
    final stored = ArcSavedLoadout.fromMap('favourite-loadout', {
      'name': 'My Raider build',
      'primaryWeapon': 'Anvil',
      'secondaryWeapon': 'Stitcher',
      'updatedAt': '2026-10-28T21:00:00.000Z',
    });
    final state = ArcCommandCentreEngine.build(
      blueprintStates: const {},
      savedLoadouts: <ArcSavedLoadout>[stored],
      personalisation: preferences,
    );
    final favourite = state.snapshots.where(
      (snapshot) => snapshot.label == 'Favourite Loadout',
    ).toList();
    expect(favourite, hasLength(1));
    expect(favourite.single.value, 'Saved');
  });
}
