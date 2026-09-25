import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Favourite Loadout uses the in-game portrait and landscape board', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    ).readAsStringSync();

    expect(source, contains('watchFavouriteLoadout()'));
    expect(source, contains('watchMyBlueprintStateSnapshot()'));
    expect(source, contains('Orientation.portrait'));
    expect(source, contains('_buildPortraitInGameBoard'));
    expect(source, contains('_buildCompactMobileBoard'));
    expect(source, contains('_buildCompactAugment'));
    expect(source, contains('_buildCompactShield'));
    expect(source, contains('_buildCompactWeaponRow(true, states)'));
    expect(source, contains('_buildCompactWeaponRow(false, states)'));
    expect(source, contains('_buildWantedBlueprintGrid'));
    expect(source, contains('crossAxisCount: 2'));
    expect(source, contains('crossAxisCount: 5'));
    expect(source, contains("Key('favourite-loadout-augment')"));
    expect(source, contains("Key('favourite-loadout-shield')"));
    expect(source, contains("'favourite-loadout-weapon-1'"));
    expect(source, contains("'favourite-loadout-weapon-2'"));
    expect(source, isNot(contains('_buildPortraitRotationPrompt')));
  });

  test('Favourite Loadout preserves intelligence and support workflows', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_startNewBuild'));
    expect(source, contains('New Build'));
    expect(source, contains('ArcLoadoutLayoutEngine.quickUseSlotCount'));
    expect(source, contains('_buildMobileQuickUseTray'));
    expect(source, contains("'LEVEL IV BUILD COST'"));
    expect(source, contains('ArcItemIntelligenceEngine.planForItem'));
    expect(source, contains("label: 'Quest Unlock Path'"));
    expect(source, contains('ArcBlueprintUnlockEngine.planForBlueprint'));
  });
}
