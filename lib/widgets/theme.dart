import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AppTheme {
  static const Color neonPink = Color.fromARGB(255, 255, 20, 147);
  static const Color neonCyan = Color.fromARGB(255, 0, 255, 255);
  static const Color darkBackground = Color.fromARGB(255, 10, 9, 37);
  static const Color cardBackground = Color(0xFF090529);
  static const Color cardBackgroundAlt = Color(0xFF0D1030);
  static const Color cardBackgroundDeep = Color(0xFF06071C);
  static const Color dangerRed = Color.fromARGB(255, 255, 80, 80);
  static const Color warningAmber = Color.fromARGB(255, 255, 190, 70);

  static const String heroFontFamily = 'VT323';
  static const String headingFontFamily = 'SpaceGrotesk';
  static const String bodyFontFamily = 'Inter';

  static const double buttonRadius = 12.0;
  static const double cardRadius = 20.0;
  static const double inputRadius = 8.0;
  static const double buttonBorderWidth = 1.2;
  static const double cardBorderWidth = 1.1;
  static const double pillBorderWidth = 1.0;

  static const double glowSoft = 4.0;
  static const double glowMedium = 6.0;
  static const double glowStrong = 12.0;

  static const double bodyLetterSpacing = 0.20;
  static const double titleLetterSpacing = 0.55;
  static const double heroLetterSpacing = 0.60;

  static const double pageMaxWidth = 720.0;

  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  static const double space = spaceS;

  static const EdgeInsets pagePadding = EdgeInsets.all(spaceL);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets sectionCardPadding = EdgeInsets.all(spaceL);
  static const EdgeInsets pillPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  static const Duration fastAnimation = Duration(milliseconds: 160);

  // No glass / no bleed, but keep names for compatibility.
  static Color get glassSurface => cardBackground;
  static Color get glassSurfaceStrong => cardBackgroundAlt;
  static Color get glassBorder => neonCyan.withValues(alpha: 0.24);
  static Color get glassInnerBorder => neonCyan.withValues(alpha: 0.72);
  static Color get glassShadow => Colors.black.withValues(alpha: 0.16);

  // Keep these so existing widgets do not break.
  static Color get cardPulseStartColor => neonCyan;
  static Color get cardPulseEndColor => neonPink;
  static Color get cardInnerBorderColor => neonCyan.withValues(alpha: 0.82);
  static Color get cardFillColor => cardBackgroundAlt;
  static Color get cardFillHighlight => cardBackgroundAlt;
  static const double cardOuterBorderWidth = 1.6;
  static const double cardInnerBorderWidth = 1.0;
  static const double cardOuterGap = 3.0;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonPink,
        secondary: neonCyan,
        surface: darkBackground,
      ),
      iconTheme: const IconThemeData(color: neonPink),
      textTheme: TextTheme(
        bodyLarge: bodyTextStyle(fontSize: 18, color: neonCyan),
        bodyMedium: bodyTextStyle(fontSize: 16, color: neonCyan),
        bodySmall: bodyTextStyle(
          fontSize: 14,
          color: neonCyan.withValues(alpha: 0.88),
        ),
        titleLarge: titleTextStyle(
          fontSize: 28.0,
          color: neonPink,
          isBold: true,
        ),
        titleMedium: titleTextStyle(
          fontSize: 22.0,
          color: neonCyan,
          isBold: true,
        ),
        titleSmall: titleTextStyle(
          fontSize: 18.0,
          color: neonPink,
          isBold: true,
        ),
        headlineSmall: heroTextStyle(
          fontSize: 32.0,
          color: neonPink,
        ),
        labelSmall: buttonTextStyle(
          color: neonCyan,
          fontSize: 13.0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: neonPink),
        titleTextStyle: titleTextStyle(
          fontSize: 22.0,
          color: neonCyan,
          isBold: true,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.all(neonPink.withValues(alpha: 0.14)),
          foregroundColor: WidgetStateProperty.all(neonPink),
          shadowColor:
              WidgetStateProperty.all(neonPink.withValues(alpha: 0.16)),
          elevation: WidgetStateProperty.all(0),
          overlayColor:
              WidgetStateProperty.all(neonPink.withValues(alpha: 0.08)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
              side: BorderSide(
                color: neonPink.withValues(alpha: 0.82),
                width: buttonBorderWidth,
              ),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            buttonTextStyle(
              color: neonPink,
              fontSize: 16,
            ),
          ),
          padding: WidgetStateProperty.all(buttonPadding),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(neonCyan),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkBackground;
          }
          return Colors.transparent;
        }),
        side: WidgetStateBorderSide.resolveWith(
          (_) => const BorderSide(
            color: neonPink,
            width: 2.0,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: neonBorder(),
        enabledBorder: neonBorder(),
        focusedBorder: neonBorder(width: 2.0),
        hintStyle: bodyTextStyle(
          fontSize: 14.0,
          color: neonCyan.withValues(alpha: 0.65),
        ),
        prefixIconColor: neonPink,
        labelStyle: bodyTextStyle(
          fontSize: 14.0,
          color: neonCyan,
          isBold: true,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkBackground,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: bodyTextStyle(
          fontSize: 16.0,
          color: neonCyan,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(cardBackground),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBackground,
          border: neonBorder(),
          enabledBorder: neonBorder(),
          focusedBorder: neonBorder(width: 2.0),
          hintStyle: bodyTextStyle(
            fontSize: 14.0,
            color: neonCyan.withValues(alpha: 0.65),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkBackground,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(neonCyan.withValues(alpha: 0.60)),
        trackColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(999),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shadowColor: glassShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(
            color: glassBorder,
            width: cardBorderWidth,
          ),
        ),
      ),
    );
  }

  static TextStyle bodyTextStyle({
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: bodyFontFamily,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: bodyLetterSpacing,
      color: color,
    );
  }

  static TextStyle neonTextStyle({
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: bodyFontFamily,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: bodyLetterSpacing,
      color: color,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.16),
          blurRadius: glowSoft,
        ),
      ],
    );
  }

  static TextStyle titleTextStyle({
    required double fontSize,
    required Color color,
    bool isBold = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: headingFontFamily,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: titleLetterSpacing,
      color: color,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: glowSoft,
        ),
      ],
    );
  }

  static TextStyle heroTextStyle({
    required double fontSize,
    required Color color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: heroFontFamily,
      fontWeight: FontWeight.w400,
      letterSpacing: heroLetterSpacing,
      height: 1.0,
      color: color,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: glowStrong,
        ),
      ],
    );
  }

  static TextStyle buttonTextStyle({
    required Color color,
    double fontSize = 16.0,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: bodyFontFamily,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.35,
      color: color,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: glowSoft,
        ),
      ],
    );
  }

  static OutlineInputBorder neonBorder({double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: BorderSide(
        color: neonPink,
        width: width,
      ),
    );
  }

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cardBackground,
      border: neonBorder(),
      enabledBorder: neonBorder(),
      focusedBorder: neonBorder(width: 2.0),
      hintStyle: bodyTextStyle(
        fontSize: 14.0,
        color: neonCyan.withValues(alpha: 0.65),
      ),
      prefixIconColor: neonPink,
      labelStyle: bodyTextStyle(
        fontSize: 14.0,
        color: neonCyan,
        isBold: true,
      ),
    );
  }

  static List<BoxShadow> dualOutlineGlow({
    Color glowColor = neonCyan,
    double outerBlur = 16,
    double outerOpacity = 0.14,
    double innerBlur = 8,
    double innerOpacity = 0.08,
  }) {
    return [
      BoxShadow(
        color: glowColor.withValues(alpha: outerOpacity),
        blurRadius: outerBlur,
        spreadRadius: 0.8,
      ),
      BoxShadow(
        color: glowColor.withValues(alpha: innerOpacity),
        blurRadius: innerBlur,
        spreadRadius: 0.15,
      ),
    ];
  }

  static BoxDecoration cardDecoration({
    Color glowColor = neonCyan,
    double radius = cardRadius,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackgroundAlt,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor.withValues(alpha: 0.78),
        width: cardBorderWidth,
      ),
      boxShadow: dualOutlineGlow(
        glowColor: glowColor,
      ),
    );
  }

  static BoxDecoration dualPillDecoration({
    Color borderColor = neonCyan,
    Color? fillColor,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: fillColor ?? cardBackgroundAlt,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor.withValues(alpha: 0.82),
        width: pillBorderWidth,
      ),
      boxShadow: dualOutlineGlow(
        glowColor: borderColor,
        outerBlur: 8,
        outerOpacity: 0.08,
        innerBlur: 4,
        innerOpacity: 0.05,
      ),
    );
  }

  static const LinearGradient dualToneGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      neonCyan,
      neonPink,
    ],
  );

  static BoxDecoration dualToneOuterDecoration({
    double radius = 16,
    double glowOpacity = 0.10,
    double glowBlur = 12,
  }) {
    return BoxDecoration(
      gradient: dualToneGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: neonCyan.withValues(alpha: glowOpacity),
          blurRadius: glowBlur,
          spreadRadius: 0.35,
        ),
        BoxShadow(
          color: neonPink.withValues(alpha: glowOpacity * 0.78),
          blurRadius: glowBlur * 0.92,
          spreadRadius: 0.18,
        ),
      ],
    );
  }

  static BoxDecoration dualToneInnerDecoration({
    double radius = 16,
    Color? backgroundColor,
    Color borderColor = neonCyan,
    double borderOpacity = 0.22,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground,
      borderRadius: BorderRadius.circular(radius - 2),
      border: Border.all(
        color: borderColor.withValues(alpha: borderOpacity),
        width: 1.0,
      ),
    );
  }

  static TypewriterAnimatedText animatedText(
    String text,
    TextStyle? textStyle,
  ) {
    return TypewriterAnimatedText(
      text,
      textStyle: textStyle ??
          titleTextStyle(
            fontSize: 20.0,
            color: neonCyan,
            isBold: true,
          ),
      speed: const Duration(milliseconds: 100),
    );
  }

  static TextStyle drawerItemTextStyle({required Color color}) {
    return buttonTextStyle(
      color: color,
      fontSize: 16.0,
    );
  }

  static Color primaryButtonBorder(bool enabled) => enabled
      ? neonPink.withValues(alpha: 0.92)
      : neonPink.withValues(alpha: 0.24);

  static Color primaryButtonText(bool enabled) =>
      enabled ? darkBackground : neonPink.withValues(alpha: 0.35);

  static Color primaryButtonFill(bool enabled) => enabled
      ? neonPink.withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.04);

  static Color primaryButtonGlow(bool enabled) =>
      enabled ? neonPink.withValues(alpha: 0.26) : Colors.transparent;

  static Color secondaryButtonBorder(bool enabled) => enabled
      ? neonCyan.withValues(alpha: 0.82)
      : neonCyan.withValues(alpha: 0.24);

  static Color secondaryButtonText(bool enabled) =>
      enabled ? neonCyan : neonCyan.withValues(alpha: 0.35);

  static Color secondaryButtonFill(bool enabled) =>
      enabled ? cardBackgroundAlt : Colors.white.withValues(alpha: 0.04);

  static Color secondaryButtonGlow(bool enabled) =>
      enabled ? neonCyan.withValues(alpha: 0.14) : Colors.transparent;

  static Color dangerButtonBorder(bool enabled) => enabled
      ? dangerRed.withValues(alpha: 0.78)
      : dangerRed.withValues(alpha: 0.24);

  static Color dangerButtonText(bool enabled) =>
      enabled ? dangerRed : dangerRed.withValues(alpha: 0.35);

  static Color dangerButtonFill(bool enabled) =>
      enabled ? cardBackgroundAlt : Colors.white.withValues(alpha: 0.04);

  static Color dangerButtonGlow(bool enabled) =>
      enabled ? dangerRed.withValues(alpha: 0.10) : Colors.transparent;

  static Color get cyanPillBorder => neonCyan.withValues(alpha: 0.35);
  static Color get cyanPillFill => neonCyan.withValues(alpha: 0.08);

  static Color get pinkPillBorder => neonPink.withValues(alpha: 0.35);
  static Color get pinkPillFill => neonPink.withValues(alpha: 0.08);

  static Color get warningPillBorder => warningAmber.withValues(alpha: 0.40);
  static Color get warningPillFill => warningAmber.withValues(alpha: 0.08);

  static Color get neutralPillBorder => Colors.white.withValues(alpha: 0.22);
  static Color get neutralPillFill => Colors.white.withValues(alpha: 0.05);

  static Color sectionCardBorder([Color? color]) => color ?? glassBorder;
  static Color sectionCardTitle([Color? color]) => color ?? neonPink;
  static Color sectionCardBackground([Color? color]) => color ?? glassSurface;

  static Color get tradingCardBackground => cardBackgroundAlt;
  static Color get tradingCardBorder => neonCyan.withValues(alpha: 0.20);
  static Color get tradingSoftBorder => neonCyan.withValues(alpha: 0.12);
  static Color get tradingMutedText => Colors.white70;
  static Color get tradingFaintText => Colors.white60;
  static Color get tradingDivider => neonCyan.withValues(alpha: 0.15);
  static Color get tradingSuccess => Colors.greenAccent;
  static Color get tradingWarning => Colors.amberAccent;
  static Color get tradingDanger => Colors.redAccent;

  static TextStyle tradingHeading({
    double fontSize = 24,
    Color? color,
    bool isBold = true,
  }) {
    return neonTextStyle(
      fontSize: fontSize,
      color: color ?? neonCyan,
      isBold: isBold,
    );
  }

  static BoxDecoration tradingCardDecoration({
    Color? borderColor,
    Color? backgroundColor,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? tradingCardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? tradingCardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: neonCyan.withValues(alpha: 0.05),
          blurRadius: 12,
          spreadRadius: 0.4,
        ),
      ],
    );
  }

  static BoxDecoration tradingPillDecoration({
    required Color color,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: color.withValues(alpha: 0.45),
        width: pillBorderWidth,
      ),
    );
  }

  static InputDecoration tradingInputDecoration({
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: neonPink),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: neonCyan.withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: neonPink),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  static ShapeBorder tradingDialogShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: neonCyan.withValues(alpha: 0.25),
      ),
    );
  }

  static Color tradingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return tradingWarning;
      case 'accepted':
        return tradingSuccess;
      case 'declined':
        return tradingDanger;
      case 'cancelled':
        return Colors.deepOrangeAccent;
      case 'expired':
        return tradingDanger;
      default:
        return neonCyan;
    }
  }
}
