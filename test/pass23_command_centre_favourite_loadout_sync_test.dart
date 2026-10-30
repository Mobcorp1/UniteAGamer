import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  test('Command Centre reads the same favourite document as the editor', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart',
    ).readAsStringSync();

    expect(screen, contains('_loadoutRepository.watchFavouriteLoadout()'));
    expect(screen, isNot(contains('_loadoutRepository.watchSavedLoadouts()')));
    expect(repository, contains("doc('favourite-loadout').snapshots()"));
    expect(repository, contains("doc(loadout.id)"));
    expect(screen, contains('ConnectionState.active'));
    expect(screen, contains('_favouriteLoadoutReadFailed = true'));
  });

  test('a saved favourite document is shown as Saved', () {
    final now = DateTime.utc(2026, 10, 25);
    final stored = ArcSavedLoadout.fromMap('favourite-loadout', {
      'name': 'My raid build',
      'category': 'saved',
      'playStyle': 'balanced',
      'augment': 'Survivor',
      'shield': 'Medium Shield',
      'primaryWeapon': 'Anvil',
      'secondaryWeapon': 'Stitcher',
      'primaryAttachments': <String>[],
      'secondaryAttachments': <String>[],
      'quickUse': <String>[],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    final state = ArcCommandCentreEngine.build(
      blueprintStates: const {},
      savedLoadouts: <ArcSavedLoadout>[stored],
    );
    final loadout = state.snapshots.singleWhere(
      (snapshot) => snapshot.label == 'Favourite Loadout',
    );
    expect(loadout.value, 'Saved');
    expect(loadout.detail, 'My raid build');
  });

  test('Command Centre does not label unresolved/failed reads Not saved', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();
    expect(screen, contains("? 'UNAVAILABLE'"));
    expect(screen, contains("? 'CHECKING'"));
  });
}
