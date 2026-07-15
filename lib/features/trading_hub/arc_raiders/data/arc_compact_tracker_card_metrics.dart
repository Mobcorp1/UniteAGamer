class ArcCompactTrackerCardMetrics {
  const ArcCompactTrackerCardMetrics._();

  static double centreHeight({
    required double stageWidth,
    required int maxItemCount,
  }) {
    final isWide = stageWidth >= 980;
    final isTablet = stageWidth >= 680;
    final itemCount = maxItemCount.clamp(0, 8);

    if (itemCount <= 0) return 172;

    if (itemCount == 1) {
      return isWide
          ? 252
          : isTablet
          ? 244
          : 232;
    }

    if (itemCount == 2) {
      return isWide
          ? 306
          : isTablet
          ? 292
          : 278;
    }

    if (itemCount <= 4) {
      return isWide
          ? 348
          : isTablet
          ? 334
          : 322;
    }

    return isWide
        ? 382
        : isTablet
        ? 372
        : 356;
  }
}
