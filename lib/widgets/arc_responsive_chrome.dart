import 'package:flutter/material.dart';

class ArcResponsiveChrome {
  const ArcResponsiveChrome._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isCompact(BuildContext context) => width(context) < 700;
  static bool isTablet(BuildContext context) =>
      width(context) >= 700 && width(context) < 1100;
  static bool isDesktop(BuildContext context) => width(context) >= 1100;
  static bool isLargeDesktop(BuildContext context) => width(context) >= 1440;

  static double maxContentWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1800) return 1480;
    if (w >= 1440) return 1320;
    if (w >= 1100) return 1180;
    if (w >= 700) return 860;
    return w;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final w = width(context);
    if (w >= 1440) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
    }
    if (w >= 1100) {
      return const EdgeInsets.symmetric(horizontal: 18, vertical: 16);
    }
    if (w >= 700) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 14);
    }
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  }

  static double dockHeight(BuildContext context) {
    final h = height(context);
    final w = width(context);
    if (w < 700) return h < 720 ? 104 : 116;
    if (w < 1100) return 108;
    return 76;
  }

  static double dockMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1100) return 820;
    if (w >= 700) return 760;
    return w;
  }

  static double adHeight(BuildContext context) {
    final w = width(context);
    if (w < 700) return 58;
    return 90;
  }

  static double adMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= 700) return 728;
    return 320;
  }

  static double bottomSafePadding(BuildContext context, {bool hasAd = true}) {
    final safe = MediaQuery.paddingOf(context).bottom;
    final w = width(context);
    final gap = w >= 1100 ? 18.0 : 28.0;
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
    if (w >= 1440) return largeDesktop;
    if (w >= 1100) return desktop;
    if (w >= 700) return tablet;
    return mobile;
  }
}
