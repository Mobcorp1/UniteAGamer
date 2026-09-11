import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared ARC typography uses the tactical display family', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart',
    ).readAsStringSync();
    expect(source, contains('fontFamily: AppTheme.heroFontFamily'));
  });

  test('shared tactical panels carry the secondary UAG accent', () {
    final source = File('lib/widgets/arc_tactical_page.dart').readAsStringSync();
    expect(
      source,
      contains('ArcUiTokens.secondaryAccent.withValues(alpha: 0.92)'),
    );
  });

  test('profile settings uses compact expandable preference groups', () {
    final source = File(
      'lib/features/profile/screens/profile_settings_screen.dart',
    ).readAsStringSync();
    expect(source, contains("title: 'REGION & CROSSPLAY'"));
    expect(source, contains("title: 'PERSONALISATION'"));
    expect(source, contains("title: 'NOTIFICATIONS'"));
    expect(source, contains('ExpansionTile('));
  });

  test('Discover UAG restores magenta identity and tighter carousel', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('color: ArcUiTokens.secondaryAccent'),
    );
    expect(source, contains('isCompactHeight ? 300.0 : 338.0'));
  });
}
