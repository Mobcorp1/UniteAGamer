class ArcCommandCentreLayoutPolicy {
  const ArcCommandCentreLayoutPolicy._();

  static int moveColumns(double width) {
    if (width >= 900) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  static int dailyColumns(double width) {
    if (width >= 760) return 3;
    if (width >= 430) return 2;
    return 1;
  }

  static double moveTileHeight(double width) => width < 520 ? 104 : 96;

  static double dailyTileHeight(double width) => width < 430 ? 78 : 74;

  static double systemRingHeight(double width) => width < 620 ? 164 : 160;
}
