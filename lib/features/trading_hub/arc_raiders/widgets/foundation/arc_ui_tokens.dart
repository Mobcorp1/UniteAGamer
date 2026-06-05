import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcUiTokens {
  const ArcUiTokens._();

  static const double radiusS = 12;
  static const double radiusM = 18;
  static const double radiusL = 24;
  static const double radiusXL = 32;

  static const double gapXS = 4;
  static const double gapS = 8;
  static const double gapM = 12;
  static const double gapL = 16;
  static const double gapXL = 24;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(18, 14, 18, 18);
  static const EdgeInsets panelPadding = EdgeInsets.all(16);
  static const EdgeInsets compactPanelPadding = EdgeInsets.all(12);

  static Color get surface =>
      AppTheme.cardBackgroundDeep.withValues(alpha: 0.90);
  static Color get surfaceRaised =>
      AppTheme.cardBackgroundAlt.withValues(alpha: 0.78);
  static Color get cyanBorder => AppTheme.neonCyan.withValues(alpha: 0.34);
  static Color get pinkBorder => AppTheme.neonPink.withValues(alpha: 0.34);
  static Color get mutedText => Colors.white.withValues(alpha: 0.68);

  static List<BoxShadow> glow(Color color, {double strength = 1}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.10 * strength),
        blurRadius: 22 * strength,
        spreadRadius: 1.5 * strength,
      ),
    ];
  }

  static LinearGradient darkGlassGradient({Color? accent}) {
    final glow = accent ?? AppTheme.neonCyan;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        glow.withValues(alpha: 0.10),
        AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
        Colors.black.withValues(alpha: 0.82),
      ],
    );
  }
}
