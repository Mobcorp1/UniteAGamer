import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/uag_raider_avatar.dart';

void main() {
  test('canonical Raider avatar has deterministic initials fallback', () {
    expect(UagRaiderAvatar.initialsFor('Michael Marsh'), 'MM');
    expect(UagRaiderAvatar.initialsFor('Raider'), 'RA');
    expect(UagRaiderAvatar.initialsFor('A'), 'A');
    expect(UagRaiderAvatar.initialsFor('   '), '');
  });

  test('canonical avatar renderer owns asset fallback and edit affordance', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/uag_raider_avatar.dart',
    ).readAsStringSync();

    expect(source, contains('UagAvatarCatalog.byId(avatarId)'));
    expect(source, contains('errorBuilder:'));
    expect(source, contains('showEditBadge'));
    expect(
      source,
      contains("final resolvedTooltip = tooltip ?? 'Open Raider profile'"),
    );
  });

  test('profile setup and edit load, preview and persist the same avatar', () {
    final setup = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart',
    ).readAsStringSync();
    final edit = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_profile_edit_screen.dart',
    ).readAsStringSync();

    for (final source in [setup, edit]) {
      expect(source, contains('String _avatarId = UagAvatarCatalog.defaultId'));
      expect(source, contains('UagAvatarLockerSheet.show('));
      expect(source, contains('UagRaiderIdentityStrip('));
      expect(source, contains('avatarId: _avatarId'));
      expect(source, contains("avatarType: 'preset'"));
    }
    expect(setup, isNot(contains("title: 'Account'")));
    expect(edit, contains("title: 'Account'"));
  });

  test('Profile locker and Match Raider use converged identity/shell visuals', () {
    final locker = File(
      'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
    ).readAsStringSync();
    final match = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart',
    ).readAsStringSync();

    expect(locker, contains('UagRaiderAvatar('));
    expect(locker, contains("tooltip: 'Manage avatars'"));
    expect(match, contains('UagAppBar('));
    expect(match, isNot(contains('class _MatchRaiderVisualLead')));
    expect(match, isNot(contains('arc_hub_match_a_raider.webp')));
  });
}
