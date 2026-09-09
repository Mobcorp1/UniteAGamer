import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Favourite Loadout is portrait-gated and remains data-backed', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    ).readAsStringSync();

    expect(source, contains('watchFavouriteLoadout()'));
    expect(source, contains('watchMyBlueprintStateSnapshot()'));
    expect(source, contains('Orientation.portrait'));
    expect(source, contains('_buildPortraitRotationPrompt'));
    expect(source, contains('_startNewBuild'));
    expect(source, contains('New Build'));
    expect(source, contains('ArcLoadoutLayoutEngine.quickUseSlotCount'));
    expect(source, contains('_buildLoadoutBoard(blueprintStates)'));
  });
}
