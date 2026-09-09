import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Locker controls are actionable and Favourite Loadout is live', () {
    final profile = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    );

    // Current compact Favourite Loadout UX:
    // - live repository stream
    // - actual visual asset registry
    // - BUILD when empty
    // - OPEN/edit actions when saved
    // - routes into FavouriteLoadoutScreen
    expect(
      profile,
      contains('_savedLoadoutRepository.watchFavouriteLoadout()'),
    );
    expect(profile, contains('ArcLoadoutAssetRegistry.assetFor'));
    expect(profile, contains("label: const Text('BUILD')"));
    expect(profile, contains("label: const Text('OPEN')"));
    expect(profile, contains('onEdit: _openFavouriteLoadout'));
    expect(profile, contains('onTap: _openFavouriteLoadout'));
    expect(profile, contains('void _openFavouriteLoadout()'));
    expect(profile, contains('const FavouriteLoadoutScreen()'));

    final locker = read(
      'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
    );
    expect(locker, contains('onManageAvatars'));
    expect(locker, contains('_equip(item)'));
    expect(locker, contains("'EQUIP'"));
    expect(locker, contains("'EQUIPPED'"));
    expect(locker, contains('_lockedCatalogueCard'));
  });
}
