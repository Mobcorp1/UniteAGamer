import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcSurfaceRole { base, panel, raised, interactive, overlay, warning }

enum ArcSemanticTone {
  neutral,
  primary,
  secondary,
  success,
  warning,
  danger,
  info,
  disabled,
  owned,
  missing,
  premium,
  admin,
}

class ArcUiTokens {
  const ArcUiTokens._();

  static const Color background = Color(0xFF03060A);
  static const Color backgroundAlt = Color(0xFF060D13);
  static const Color surfaceBase = Color(0xFF071017);
  static const Color surfacePanel = Color(0xFF0A141C);
  static const Color surfaceRaised = Color(0xFF0D1922);
  static const Color surfaceInteractive = Color(0xFF102330);
  static const Color surfaceOverlay = Color(0xF20A1118);

  static const Color primaryAccent = Color(0xFF19E6F2);
  static const Color secondaryAccent = Color(0xFFFF3B8D);
  static const Color tertiaryAccent = Color(0xFF9C7CFF);
  static const Color attentionAccent = Color(0xFFFFC857);

  static const Color textPrimary = Color(0xFFF2F6F8);
  static const Color textSecondary = Color(0xFFC6D3DA);
  static const Color textTertiary = Color(0xFF91A4AF);
  static const Color textDisabled = Color(0xFF5B6A73);

  static const Color success = Color(0xFF6EE7B7);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF7DD3FC);
  static const Color owned = Color(0xFF7CE7AC);
  static const Color missing = Color(0xFFFF3B8D);
  static const Color premium = Color(0xFFE9C46A);
  static const Color admin = Color(0xFFB991FF);

  static Color get borderSubtle => Colors.white.withValues(alpha: 0.08);
  static Color get borderMedium => Colors.white.withValues(alpha: 0.14);
  static Color get focusRing => primaryAccent.withValues(alpha: 0.82);

  static const double radiusXS = 6;
  static const double radiusS = 8;
  static const double radiusM = 10;
  static const double radiusL = 12;
  static const double radiusXL = 14;
  static const double radiusXXL = 16;

  static const double gapXS = 4;
  static const double gapS = 8;
  static const double gapM = 12;
  static const double gapL = 14;
  static const double gapXL = 18;
  static const double gapXXL = 22;
  static const double gapXXXL = 28;
  static const double gapXXXXL = 34;
  static const double gapPage = 38;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(12, 10, 12, 14);
  static const EdgeInsets panelPadding = EdgeInsets.all(12);
  static const EdgeInsets compactPanelPadding = EdgeInsets.all(10);
  static const EdgeInsets densePanelPadding = EdgeInsets.all(10);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 5,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );

  static Color get surface => surfacePanel.withValues(alpha: 0.92);
  static Color get cyanBorder => primaryAccent.withValues(alpha: 0.30);
  static Color get pinkBorder => secondaryAccent.withValues(alpha: 0.28);
  static Color get mutedText => textSecondary;

  static Color tone(ArcSemanticTone tone) {
    return switch (tone) {
      ArcSemanticTone.neutral => textSecondary,
      ArcSemanticTone.primary => primaryAccent,
      ArcSemanticTone.secondary => secondaryAccent,
      ArcSemanticTone.success => success,
      ArcSemanticTone.warning => warning,
      ArcSemanticTone.danger => danger,
      ArcSemanticTone.info => info,
      ArcSemanticTone.disabled => textDisabled,
      ArcSemanticTone.owned => owned,
      ArcSemanticTone.missing => missing,
      ArcSemanticTone.premium => premium,
      ArcSemanticTone.admin => admin,
    };
  }

  static TextStyle display({double fontSize = 32, Color color = textPrimary}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.headingFontFamily,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1.04,
      color: color,
    );
  }

  static TextStyle pageTitle({double fontSize = 18, Color? color}) {
    return display(fontSize: fontSize, color: color ?? textPrimary);
  }

  static TextStyle sectionTitle({double fontSize = 16, Color? color}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.headingFontFamily,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.15,
      color: color ?? textPrimary,
    );
  }

  static TextStyle cardTitle({double fontSize = 14, Color? color}) {
    return sectionTitle(fontSize: fontSize, color: color ?? textPrimary);
  }

  static TextStyle body({
    double fontSize = 13,
    Color color = textSecondary,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.bodyFontFamily,
      fontWeight: weight,
      letterSpacing: 0,
      height: 1.35,
      color: color,
    );
  }

  static TextStyle bodySmall({Color color = textTertiary}) {
    return body(fontSize: 12, color: color);
  }

  static TextStyle label({Color color = textTertiary}) {
    return body(
      fontSize: 10.5,
      color: color,
      weight: FontWeight.w700,
    ).copyWith(height: 1.15);
  }

  static TextStyle metadata({Color color = textTertiary}) {
    return body(fontSize: 11, color: color, weight: FontWeight.w600);
  }

  static TextStyle numeric({double fontSize = 18, Color? color}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.headingFontFamily,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1,
      color: color ?? primaryAccent,
    );
  }

  static TextStyle buttonLabel({Color? color}) {
    return body(
      fontSize: 13,
      color: color ?? textPrimary,
      weight: FontWeight.w700,
    ).copyWith(height: 1.15);
  }

  static List<BoxShadow> glow(Color color, {double strength = 1}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.055 * strength),
        blurRadius: 12 * strength,
        spreadRadius: 0.4 * strength,
      ),
    ];
  }

  static LinearGradient darkGlassGradient({Color? accent}) {
    final glow = accent ?? primaryAccent;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        glow.withValues(alpha: 0.055),
        surfacePanel.withValues(alpha: 0.94),
        background.withValues(alpha: 0.92),
      ],
    );
  }

  static Color surfaceFor(ArcSurfaceRole role) {
    return switch (role) {
      ArcSurfaceRole.base => surfaceBase,
      ArcSurfaceRole.panel => surfacePanel,
      ArcSurfaceRole.raised => surfaceRaised,
      ArcSurfaceRole.interactive => surfaceInteractive,
      ArcSurfaceRole.overlay => surfaceOverlay,
      ArcSurfaceRole.warning => const Color(0xFF20170C),
    };
  }

  static BoxDecoration surfaceDecoration({
    ArcSurfaceRole role = ArcSurfaceRole.panel,
    Color? accent,
    Color? backgroundColor,
    double radius = radiusL,
    double borderOpacity = 0.12,
    bool selected = false,
    bool glow = false,
  }) {
    final borderColor = accent == null
        ? Colors.white.withValues(alpha: selected ? 0.18 : borderOpacity)
        : accent.withValues(alpha: selected ? 0.54 : borderOpacity);

    return BoxDecoration(
      color: backgroundColor ?? surfaceFor(role).withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: selected ? 1.1 : 1),
      boxShadow: glow && accent != null ? ArcUiTokens.glow(accent) : null,
    );
  }

  static BoxDecoration chipDecoration({
    Color color = primaryAccent,
    bool selected = false,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: selected ? 0.16 : 0.09),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: color.withValues(alpha: selected ? 0.50 : 0.32),
      ),
    );
  }

  static ButtonStyle textButtonStyle({
    Color accent = primaryAccent,
    bool primary = false,
    bool destructive = false,
  }) {
    final foreground = destructive
        ? danger
        : primary
        ? background
        : accent;
    final buttonBackground = destructive
        ? danger.withValues(alpha: 0.10)
        : primary
        ? accent
        : accent.withValues(alpha: 0.08);

    return TextButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: buttonBackground,
      disabledForegroundColor: textDisabled,
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
      padding: buttonPadding,
      minimumSize: const Size(42, 40),
      textStyle: buttonLabel(color: foreground),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
        side: BorderSide(
          color: destructive
              ? danger.withValues(alpha: 0.42)
              : accent.withValues(alpha: primary ? 0.0 : 0.38),
        ),
      ),
    );
  }

  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: BorderSide(color: primaryAccent.withValues(alpha: 0.22)),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: surfaceRaised.withValues(alpha: 0.82),
      labelStyle: label(color: textTertiary),
      floatingLabelStyle: label(color: primaryAccent),
      hintStyle: bodySmall(color: textDisabled),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: primaryAccent.withValues(alpha: 0.82)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: focusRing, width: 1.3),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: danger.withValues(alpha: 0.72)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: danger, width: 1.3),
      ),
    );
  }
}
