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

  static const Color background = Color(0xFF05070D);
  static const Color backgroundAlt = Color(0xFF081018);
  static const Color surfaceBase = Color(0xFF0A1118);
  static const Color surfacePanel = Color(0xFF0D151E);
  static const Color surfaceRaised = Color(0xFF111B25);
  static const Color surfaceInteractive = Color(0xFF13212D);
  static const Color surfaceOverlay = Color(0xF20A1118);

  static const Color primaryAccent = Color(0xFF22DDF2);
  static const Color secondaryAccent = Color(0xFFE052B7);
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
  static const Color missing = Color(0xFFFF9C66);
  static const Color premium = Color(0xFFE9C46A);
  static const Color admin = Color(0xFFB991FF);

  static Color get borderSubtle => Colors.white.withValues(alpha: 0.08);
  static Color get borderMedium => Colors.white.withValues(alpha: 0.14);
  static Color get focusRing => primaryAccent.withValues(alpha: 0.82);

  static const double radiusXS = 6;
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;

  static const double gapXS = 4;
  static const double gapS = 8;
  static const double gapM = 12;
  static const double gapL = 16;
  static const double gapXL = 20;
  static const double gapXXL = 24;
  static const double gapXXXL = 32;
  static const double gapXXXXL = 40;
  static const double gapPage = 48;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 14, 16, 18);
  static const EdgeInsets panelPadding = EdgeInsets.all(16);
  static const EdgeInsets compactPanelPadding = EdgeInsets.all(12);
  static const EdgeInsets densePanelPadding = EdgeInsets.all(10);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 11,
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

  static TextStyle pageTitle({double fontSize = 26, Color? color}) {
    return display(fontSize: fontSize, color: color ?? textPrimary);
  }

  static TextStyle sectionTitle({double fontSize = 18, Color? color}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: AppTheme.headingFontFamily,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.15,
      color: color ?? textPrimary,
    );
  }

  static TextStyle cardTitle({double fontSize = 16, Color? color}) {
    return sectionTitle(fontSize: fontSize, color: color ?? textPrimary);
  }

  static TextStyle body({
    double fontSize = 14,
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
      fontSize: 11,
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
        blurRadius: 18 * strength,
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
    double borderOpacity = 0.14,
    bool selected = false,
    bool glow = false,
  }) {
    final borderColor = accent == null
        ? Colors.white.withValues(alpha: selected ? 0.18 : borderOpacity)
        : accent.withValues(alpha: selected ? 0.54 : borderOpacity);

    return BoxDecoration(
      color: backgroundColor ?? surfaceFor(role).withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: selected ? 1.2 : 1),
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
      minimumSize: const Size(44, 44),
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
