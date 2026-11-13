import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UAG profile family completion contracts', () {
    test('cinematic loader uses canonical consolidated asset path', () {
      final source = File(
        'lib/widgets/uag_cinematic_loading_screen.dart',
      ).readAsStringSync();
      expect(source, contains('assets/arc_raiders/hub/auth_bg_landscape.webp'));
      expect(
        source,
        isNot(contains('assets/images/arc_raiders/hub/auth_bg_landscape.webp')),
      );
      expect(
        File('assets/arc_raiders/hub/auth_bg_landscape.webp').existsSync(),
        isTrue,
      );
    });

    test('profile family uses expandable information architecture', () {
      final shared = File(
        'lib/features/trading_hub/arc_raiders/widgets/foundation/arc_form_surface.dart',
      ).readAsStringSync();
      final edit = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_profile_edit_screen.dart',
      ).readAsStringSync();
      final setup = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart',
      ).readAsStringSync();
      final profile = File(
        'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
      ).readAsStringSync();

      expect(shared, contains('class ArcExpandableFormSection'));
      expect(edit, contains('ArcExpandableFormSection('));
      expect(setup, contains('ArcExpandableFormSection('));
      expect(profile, contains("title: 'Playstyle & Archetypes'"));
      expect(profile, contains("title: 'Guardian & Community Reputation'"));
      expect(profile, contains('ExpansionTile('));
    });

    test('main Raider Profile reserves canonical banner placement', () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
      ).readAsStringSync();
      expect(source, contains('showAdBanner: true'));
      expect(source, contains('SafeArea('));
    });

    test('cosmetic locker exposes full five-part catalogue', () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
      ).readAsStringSync();
      for (final tab in ['AVATARS', 'BADGES', 'TITLES', 'FRAMES', 'BANNERS']) {
        expect(source, contains("'$tab'"));
      }
      expect(source, contains("id: 'founding_raider'"));
      expect(source, contains("id: 'trusted_trader_title'"));
      expect(source, contains("id: 'pathfinder_frame'"));
      expect(source, contains("id: 'beta_command_banner'"));

      // Structural assertions deliberately tolerate dart format line wrapping.
      expect(source, contains('_sectionLabel('));
      expect(source, contains("'COLLECTION'"));
      expect(source, contains('_lockedCatalogueCard('));
      expect(source, contains("'LOCKED'"));
      expect(source, contains("'EQUIP'"));
    });
  });
}
