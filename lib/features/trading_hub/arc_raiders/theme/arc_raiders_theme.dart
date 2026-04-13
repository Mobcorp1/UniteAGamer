import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRaidersTheme {
  const ArcRaidersTheme._();

  static const Color background = Color(0xFF060606);
  static const Color panel = Color(0xFF101114);
  static const Color panelAlt = Color(0xFF15171C);
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFFBFC5CC);

  static const Color stripeBlue = Color(0xFF22E7FF);
  static const Color stripePink = Color(0xFFFF4FBD);
  static const Color stripePurple = Color(0xFFA55CFF);
  static const Color stripeYellow = Color(0xFFF7D54B);

  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: <Color>[
      stripeBlue,
      stripePurple,
      stripePink,
    ],
  );

  static List<BoxShadow> outerGlow([Color color = stripeBlue]) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: 0.14),
        blurRadius: 18,
        spreadRadius: 0.6,
      ),
    ];
  }

  static BoxDecoration panelDecoration({
    Color? borderColor,
    Color? backgroundColor,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (borderColor ?? stripeBlue).withValues(alpha: 0.22),
        width: 1.0,
      ),
      boxShadow: outerGlow(borderColor ?? stripeBlue),
    );
  }

  static BoxDecoration subtlePanel({
    Color? backgroundColor,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? panelAlt,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  static TextStyle hubTitle({
    double fontSize = 24,
    Color color = textPrimary,
  }) {
    return AppTheme.heroTextStyle(fontSize: fontSize, color: color);
  }

  static TextStyle label({
    double fontSize = 12,
    Color color = textSecondary,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.bodyFontFamily,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      color: color,
    );
  }

  static TextStyle value({
    double fontSize = 14,
    Color color = textPrimary,
    bool bold = true,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.bodyFontFamily,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 0.15,
      color: color,
    );
  }

  static InputDecoration inputDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: panelAlt,
      labelStyle: ArcRaidersTheme.label(),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: stripeBlue.withValues(alpha: 0.88)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: stripeBlue.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: stripePink.withValues(alpha: 0.9)),
      ),
    );
  }
}
