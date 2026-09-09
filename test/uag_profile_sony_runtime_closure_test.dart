import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String p) => File(p).readAsStringSync();

  test('Sony runtime closure markers are present', () {
    final profile = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    );
    final locker = read(
      'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
    );

    expect(profile, contains("title: 'Overall Reputation'"));
    expect(profile, contains('AppTheme.neonPink'));
    expect(profile, contains('tileWidth'));
    expect(profile, contains("width: 156"));
    expect(profile, contains('showAdBanner: true'));

    expect(locker, contains('scrollDirection: Axis.horizontal'));
    expect(locker, contains('Widget _tabButton(int index)'));
    expect(locker, contains("onTap: () => setState(() => _tabIndex = index)"));
    for (final label in ['AVATARS', 'BADGES', 'TITLES', 'FRAMES', 'BANNERS']) {
      expect(locker, contains("'$label'"));
    }
    expect(locker, contains('final catalogue = _lockerCatalogue'));
    expect(locker, contains('_lockedCatalogueCard'));
    expect(locker, contains('_cosmeticCard('));
  });
}
