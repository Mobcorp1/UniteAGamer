import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  test(
    'legacy AppTheme compatibility surface matches ARC Operations OS tokens',
    () {
      expect(AppTheme.neonCyan, ArcUiTokens.primaryAccent);
      expect(AppTheme.neonPink, ArcUiTokens.secondaryAccent);
      expect(AppTheme.darkBackground, ArcUiTokens.background);
      expect(AppTheme.cardBackground, ArcUiTokens.surfacePanel);
      expect(AppTheme.cardBackgroundAlt, ArcUiTokens.surfaceRaised);
      expect(AppTheme.cardBackgroundDeep, ArcUiTokens.surfaceBase);
      expect(AppTheme.dangerRed, ArcUiTokens.danger);
      expect(AppTheme.warningAmber, ArcUiTokens.warning);
      expect(AppTheme.cardRadius, ArcUiTokens.radiusXL);
      expect(AppTheme.headingFontFamily, 'SpaceGrotesk');
      expect(AppTheme.bodyFontFamily, 'Inter');
    },
  );

  test('canonical layout widths and breakpoints remain ordered', () {
    expect(
      ArcLayoutTokens.compactBreakpoint,
      lessThan(ArcLayoutTokens.tabletBreakpoint),
    );
    expect(
      ArcLayoutTokens.tabletBreakpoint,
      lessThan(ArcLayoutTokens.desktopBreakpoint),
    );
    expect(
      ArcLayoutTokens.desktopBreakpoint,
      lessThan(ArcLayoutTokens.wideDesktopBreakpoint),
    );
    expect(
      ArcLayoutTokens.compactContentWidth,
      lessThanOrEqualTo(ArcLayoutTokens.formContentWidth),
    );
    expect(
      ArcLayoutTokens.formContentWidth,
      lessThan(ArcLayoutTokens.standardContentWidth),
    );
    expect(
      ArcLayoutTokens.standardContentWidth,
      lessThan(ArcLayoutTokens.wideContentWidth),
    );
  });

  test('shared ARC shell does not paint a second global backdrop', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart',
    ).readAsStringSync();

    expect(source, contains('GLOBAL BACKDROP OWNERSHIP'));
    expect(
      source,
      isNot(contains('ArcUiTokens.primaryAccent.withValues(alpha: 0.045)')),
    );
    expect(
      source,
      isNot(contains('ArcUiTokens.secondaryAccent.withValues(alpha: 0.040)')),
    );
  });
}
