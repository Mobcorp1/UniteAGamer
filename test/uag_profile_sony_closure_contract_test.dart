import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Sony Profile closure contracts are present', () {
    final profile = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    );
    expect(profile, contains("String? _openRaiderSection = 'raider_identity'"));
    expect(
      profile,
      contains("String? _openReputationSection = 'overall_reputation'"),
    );
    expect(profile, contains("title: 'Overall Reputation'"));
    expect(profile, contains('ArcLoadoutAssetRegistry.assetFor'));
    expect(profile, contains("label: 'PRIMARY'"));
    expect(profile, contains("label: 'SECONDARY'"));
    expect(profile, contains('extendBody: false'));
    expect(profile, contains('showAdBanner: true'));
  });

  test('Cosmetic Locker renders full collection synchronously', () {
    final locker = read(
      'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
    );
    expect(locker, isNot(contains('AnimatedSwitcher(')));
    expect(locker, contains("'COLLECTION'"));
    expect(locker, contains('final catalogue = _lockerCatalogue'));
    expect(locker, contains('.where((entry) => entry.type == type)'));
    expect(locker, contains('ownedById[entry.id]'));
    expect(locker, contains('_lockedCatalogueCard(entry, typeIcon)'));
    expect(locker, contains('_cosmeticCard('));
    expect(locker, contains('children: catalogue'));
    expect(locker, contains('.map((entry) {'));
    for (final tab in ['AVATARS', 'BADGES', 'TITLES', 'FRAMES', 'BANNERS']) {
      expect(locker, contains("'$tab'"));
    }
  });

  test('Discover participates in Free banner layout', () {
    final discover = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
    );
    expect(discover, contains('extendBody: false'));
    expect(discover, contains('showAdBanner: true'));
    expect(discover, contains("activeLabel: 'discover'"));
  });
}
