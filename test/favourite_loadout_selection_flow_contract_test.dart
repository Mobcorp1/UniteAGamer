import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('Wanted Blueprint slot opens tracker target-pick mode', () {
    final loadout = source(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    );
    expect(loadout, contains('BlueprintGridTargetPickArgs(slotIndex: index)'));
    expect(loadout, contains('BlueprintGridScreen.routeName'));
  });

  test('Blueprint Tracker target-pick mode assigns rank and returns', () {
    final tracker = source(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );
    expect(tracker, contains('class BlueprintGridTargetPickArgs'));
    expect(tracker, contains('favouriteLoadoutTargetSlotIndex'));
    expect(tracker, contains('_isFavouriteLoadoutTargetPickMode'));
    expect(tracker, contains('final targetRank = slotIndex + 1'));
    expect(tracker, contains('priorityRank: 0'));
    expect(tracker, contains('priorityRank: targetRank'));
    expect(tracker, contains('Navigator.of(context).pop(blueprint.id)'));
    expect(tracker, contains('state.priorityRank > 0'));
  });

  test('named route forwards target-pick arguments through feature gate', () {
    final main = source('lib/main.dart');
    expect(main, contains('BlueprintGridTargetPickArgs'));
    expect(main, contains('favouriteLoadoutTargetSlotIndex: args?.slotIndex'));
    expect(main, contains('showFirstRunTutorial: args == null'));
  });

  test('Quick Use prepares state and image before picker closes', () {
    final loadout = source(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    );
    expect(loadout, contains('prepareSelection: (option) async'));
    expect(loadout, contains('precacheImage(AssetImage(assetPath), context)'));
    expect(
      loadout,
      contains('Future<void> Function(T item)? prepareSelection'),
    );
    expect(loadout, contains('await prepareSelection(item)'));
  });
}
