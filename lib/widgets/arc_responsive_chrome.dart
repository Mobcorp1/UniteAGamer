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
    return 98;
  }

  static double adHeight(BuildContext context) {
    final w = width(context);
    if (w < 700) return 72;
    if (w < 1100) return 78;
    return 86;
  }

  static double bottomSafePadding(BuildContext context, {bool hasAd = true}) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return safe + dockHeight(context) + (hasAd ? adHeight(context) : 0) + 28;
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
