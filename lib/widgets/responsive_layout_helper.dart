import 'package:flutter/material.dart';

import 'arc_layout_system.dart';

class ResponsiveLayoutHelper {
  static const double mobileBreakpoint = ArcLayoutTokens.compactBreakpoint;
  static const double tabletBreakpoint = ArcLayoutTokens.tabletBreakpoint;
  static const double desktopBreakpoint = ArcLayoutTokens.desktopBreakpoint;
  static const double desktopMaxContentWidth = ArcLayoutTokens.wideContentWidth;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  static double horizontalPadding(BuildContext context) {
    return ArcLayoutTokens.pagePadding(context).horizontal / 2;
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= ArcLayoutTokens.wideDesktopBreakpoint) {
      return ArcLayoutTokens.wideContentWidth;
    }
    if (width >= desktopBreakpoint) {
      return ArcLayoutTokens.standardContentWidth;
    }
    if (width >= tabletBreakpoint) return 980;
    return width;
  }

  static int cardGridColumns(BuildContext context) {
    return ArcLayoutTokens.columns(
      context,
      compact: 1,
      tablet: 2,
      desktop: 3,
      wide: 4,
    );
  }

  static bool compactStatusRow(BuildContext context) => isDesktop(context);

  static EdgeInsets contentPadding(BuildContext context) {
    return ArcLayoutTokens.pagePadding(context);
  }
}

class ResponsiveContentWrapper extends StatelessWidget {
  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.width = ArcPageWidth.standard,
    this.padding,
  });

  final Widget child;
  final ArcPageWidth width;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ArcPageViewport(width: width, padding: padding, child: child);
  }
}
