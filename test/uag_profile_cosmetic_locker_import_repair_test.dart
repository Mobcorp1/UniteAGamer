import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Profile imports and renders the cosmetic locker', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("import '../widgets/uag_profile_cosmetic_locker.dart';"),
    );
    expect(source, contains('UagProfileCosmeticLocker('));
    expect(
      source,
      contains('onManageAvatars: () => _openAvatarLocker(profile)'),
    );
    expect(source, contains('_loadoutPreview()'));
  });

  test('Cosmetic locker exposes all five collections', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
    ).readAsStringSync();

    for (final label in ['AVATARS', 'BADGES', 'TITLES', 'FRAMES', 'BANNERS']) {
      expect(source, contains("'$label'"));
    }
    expect(source, contains('equipCosmetic(item)'));
    expect(source, contains('ART INCOMING'));
  });
}
