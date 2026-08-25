import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcRaidersTheme {
  const ArcRaidersTheme._();

  static const Color background = ArcUiTokens.background;
  static const Color panel = ArcUiTokens.surfacePanel;
  static const Color panelAlt = ArcUiTokens.surfaceRaised;
  static const Color textPrimary = ArcUiTokens.textPrimary;
  static const Color textSecondary = ArcUiTokens.textSecondary;

  static const Color stripeBlue = ArcUiTokens.primaryAccent;
  static const Color stripePink = ArcUiTokens.secondaryAccent;
  static const Color stripePurple = ArcUiTokens.tertiaryAccent;
  static const Color stripeYellow = ArcUiTokens.attentionAccent;

  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: <Color>[stripeBlue, stripePurple, stripePink],
  );

  static List<BoxShadow> outerGlow([Color color = stripeBlue]) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: 0.07),
        blurRadius: 18,
        spreadRadius: 0.2,
      ),
    ];
  }

  static BoxDecoration panelDecoration({
    Color? borderColor,
    Color? backgroundColor,
    double radius = 18,
  }) {
    return ArcUiTokens.surfaceDecoration(
      role: ArcSurfaceRole.panel,
      accent: borderColor ?? stripeBlue,
      backgroundColor: backgroundColor ?? panel,
      radius: radius,
      borderOpacity: 0.22,
      glow: borderColor != null,
    );
  }

  static BoxDecoration subtlePanel({
    Color? backgroundColor,
    double radius = 18,
  }) {
    return ArcUiTokens.surfaceDecoration(
      role: ArcSurfaceRole.raised,
      backgroundColor: backgroundColor ?? panelAlt,
      radius: radius,
      borderOpacity: 0.10,
    );
  }

  static TextStyle hubTitle({double fontSize = 24, Color color = textPrimary}) {
    return ArcUiTokens.pageTitle(fontSize: fontSize, color: color);
  }

  static TextStyle label({double fontSize = 12, Color color = textSecondary}) {
    return ArcUiTokens.label(color: color).copyWith(fontSize: fontSize);
  }

  static TextStyle value({
    double fontSize = 14,
    Color color = textPrimary,
    bool bold = true,
  }) {
    return ArcUiTokens.body(
      fontSize: fontSize,
      weight: bold ? FontWeight.w700 : FontWeight.w500,
      color: color,
    );
  }

  static InputDecoration inputDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return ArcUiTokens.inputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
    );
  }
}
