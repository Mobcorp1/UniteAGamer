import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String p) => File(p).readAsStringSync();

  test('Profile visual recovery contract', () {
    final p = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    );
    final l = read(
      'lib/features/trading_hub/arc_raiders/widgets/uag_profile_cosmetic_locker.dart',
    );
    final g = read(
      'lib/features/trading_hub/arc_raiders/widgets/foundation/uag_profile_glyph.dart',
    );

    expect(p, contains('final tileWidth = (constraints.maxWidth - gap) / 2'));
    expect(p, contains('width: double.infinity'));
    expect(p, contains('UagProfileGlyph('));
    expect(g, contains('class _UagProfileGlyphPainter extends CustomPainter'));

    expect(l, contains("key: const ValueKey<String>('locker-category-strip')"));
    expect(l, contains('child: Row('));
    expect(l, isNot(contains('ListView.separated(')));
    expect(l, contains("onTap: () => setState(() => _tabIndex = index)"));
    for (final x in ['AVATARS', 'BADGES', 'TITLES', 'FRAMES', 'BANNERS']) {
      expect(l, contains("'$x'"));
    }
    expect(l, contains('return _avatarPanel();'));
    expect(l, contains('final catalogue = _lockerCatalogue'));
    // Android/mobile reward cards live inside a Wrap with unbounded vertical
    // constraints. A Spacer here collapses the non-avatar tab body at runtime.
    expect(l, isNot(contains('const Spacer();')));
    expect(l, contains("id: 'beta_access',"));
    expect(l, contains("id: 'founding_raider',"));
    expect(l, contains("id: 'field_tester',"));
    expect(l, contains("'\$owned OWNED TOTAL'"));
    expect(l, contains('final totalSpacing = 8.0 * (columns - 1);'));
  });
}
