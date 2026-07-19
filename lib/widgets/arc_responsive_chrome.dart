import 'package:flutter/material.dart';

import 'arc_layout_system.dart';

class ArcResponsiveChrome {
  const ArcResponsiveChrome._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isCompact(BuildContext context) =>
      width(context) < ArcLayoutTokens.compactBreakpoint;
  static bool isTablet(BuildContext context) =>
      width(context) >= ArcLayoutTokens.compactBreakpoint &&
      width(context) < ArcLayoutTokens.desktopBreakpoint;
  static bool isDesktop(BuildContext context) =>
      width(context) >= ArcLayoutTokens.desktopBreakpoint;
  static bool isLargeDesktop(BuildContext context) =>
      width(context) >= ArcLayoutTokens.wideDesktopBreakpoint;

  static double maxContentWidth(BuildContext context) {
    if (isLargeDesktop(context)) return ArcLayoutTokens.wideContentWidth;
    if (isDesktop(context)) return ArcLayoutTokens.standardContentWidth;
    if (width(context) >= ArcLayoutTokens.tabletBreakpoint) return 980;
    if (width(context) >= ArcLayoutTokens.compactBreakpoint) return 760;
    return width(context);
  }

  static EdgeInsets pagePadding(BuildContext context) =>
      ArcLayoutTokens.pagePadding(context);

  static double dockHeight(BuildContext context) {
    final h = height(context);
    final w = width(context);
    if (w < ArcLayoutTokens.compactBreakpoint) return h < 720 ? 96 : 108;
    if (w < ArcLayoutTokens.desktopBreakpoint) return 100;
    return 72;
  }

  static double dockMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= ArcLayoutTokens.desktopBreakpoint) return 860;
    if (w >= ArcLayoutTokens.compactBreakpoint) return 760;
    return w;
  }

  static double adHeight(BuildContext context) {
    return width(context) < ArcLayoutTokens.compactBreakpoint ? 58 : 90;
  }

  static double adMaxWidth(BuildContext context) {
    return width(context) >= ArcLayoutTokens.compactBreakpoint ? 728 : 320;
  }

  static double bottomSafePadding(BuildContext context, {bool hasAd = true}) {
    final safe = MediaQuery.paddingOf(context).bottom;
    final gap = isDesktop(context) ? 16.0 : 22.0;
    return safe + dockHeight(context) + (hasAd ? adHeight(context) : 0) + gap;
  }

  static EdgeInsets scrollPadding(BuildContext context, {bool hasAd = true}) {
    final base = pagePadding(context);
    return base.copyWith(bottom: bottomSafePadding(context, hasAd: hasAd));
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
    int ultraWide = 5,
  }) {
    final w = width(context);
    if (w >= 1800) return ultraWide;
    if (w >= ArcLayoutTokens.wideDesktopBreakpoint) return largeDesktop;
    if (w >= ArcLayoutTokens.desktopBreakpoint) return desktop;
    if (w >= ArcLayoutTokens.compactBreakpoint) return tablet;
    return mobile;
  }
}
