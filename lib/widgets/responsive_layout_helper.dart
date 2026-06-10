import 'package:flutter/material.dart';

class ResponsiveLayoutHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopMaxContentWidth = 1600;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 18;
    return 12;
  }

  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return desktopMaxContentWidth;
    if (isTablet(context)) return 1100;
    return MediaQuery.of(context).size.width;
  }

  static int cardGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 5;
    if (width >= 1280) return 4;
    if (width >= 1024) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  static bool compactStatusRow(BuildContext context) {
    return isDesktop(context);
  }

  static EdgeInsets contentPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: isDesktop(context) ? 20 : 12,
    );
  }
}

class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveContentWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayoutHelper.maxContentWidth(context),
        ),
        child: Padding(
          padding: ResponsiveLayoutHelper.contentPadding(context),
          child: child,
        ),
      ),
    );
  }
}
