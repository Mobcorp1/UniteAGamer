import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  test('a previously saved Favourite appears Saved in Command Centre', () {
    final stored = ArcSavedLoadout.fromMap('favourite-loadout', {
      'name': 'My saved Raider build',
      'primaryWeapon': 'Anvil',
      'secondaryWeapon': 'Stitcher',
      'augment': 'Survivor',
      'updatedAt': '2026-10-28T21:00:00.000Z',
    });

    final state = ArcCommandCentreEngine.build(
      blueprintStates: const {},
      savedLoadouts: <ArcSavedLoadout>[stored],
    );
    final metric = state.snapshots.singleWhere(
      (snapshot) => snapshot.label == 'Favourite Loadout',
    );
    expect(metric.value, 'Saved');
    expect(metric.detail, 'My saved Raider build');
    expect(
      state.objectives.where((objective) =>
          objective.title == 'Finish Favourite Loadout'),
      isEmpty,
    );
  });

  test('legacy saved Favourite without updatedAt remains visible', () {
    final legacy = ArcSavedLoadout.fromMap('favourite-loadout', {
      'name': 'Legacy Favourite',
      'primaryWeapon': 'Bettina',
    });
    final state = ArcCommandCentreEngine.build(
      blueprintStates: const {},
      savedLoadouts: <ArcSavedLoadout>[legacy],
    );
    final metric = state.snapshots.singleWhere(
      (snapshot) => snapshot.label == 'Favourite Loadout',
    );
    expect(metric.value, 'Saved');
    expect(metric.detail, 'Legacy Favourite');
  });
}
