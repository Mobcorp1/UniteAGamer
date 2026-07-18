import 'dart:math' as math;

class ArcBlueprintGridFrameBounds {
  const ArcBlueprintGridFrameBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class ArcBlueprintGridJumpState {
  const ArcBlueprintGridJumpState({
    required this.canJumpUp,
    required this.canJumpDown,
    required this.translationY,
  });

  final bool canJumpUp;
  final bool canJumpDown;
  final double translationY;
}

class ArcBlueprintGridFittedLayout {
  const ArcBlueprintGridFittedLayout({
    required this.tileWidth,
    required this.tileHeight,
    required this.gridWidth,
    required this.gridHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.visibleRows,
  });

  final double tileWidth;
  final double tileHeight;
  final double gridWidth;
  final double gridHeight;
  final double viewportWidth;
  final double viewportHeight;
  final int visibleRows;
}

class ArcBlueprintGridLayoutMetrics {
  const ArcBlueprintGridLayoutMetrics({
    required this.itemCount,
    required this.columns,
    required this.tileWidth,
    required this.childAspectRatio,
    required this.spacing,
  });

  final int itemCount;
  final int columns;
  final double tileWidth;
  final double childAspectRatio;
  final double spacing;

  int get rowCount => itemCount <= 0 ? 0 : (itemCount / columns).ceil();

  double get tileHeight => tileWidth / childAspectRatio;

  double get naturalWidth => (tileWidth * columns) + (spacing * (columns - 1));

  double get naturalHeight {
    final rows = rowCount;
    if (rows == 0) return 0;
    return (tileHeight * rows) + (spacing * (rows - 1));
  }

  ArcBlueprintGridFrameBounds frameForTopRows({int rows = 5}) {
    final visibleRows = rowCount.clamp(0, rows).toInt();
    if (visibleRows == 0) {
      return const ArcBlueprintGridFrameBounds(
        left: 0,
        top: 0,
        width: 0,
        height: 0,
      );
    }

    final inset = spacing / 2;
    final height = (tileHeight * visibleRows) + (spacing * (visibleRows - 1));

    return ArcBlueprintGridFrameBounds(
      left: -inset,
      top: -inset,
      width: naturalWidth + spacing,
      height: height + spacing,
    );
  }

  static ArcBlueprintGridFittedLayout framedLayout({
    required int itemCount,
    required int columns,
    required double childAspectRatio,
    required double spacing,
    required double availableWidth,
    required double availableHeight,
    int requestedVisibleRows = 5,
  }) {
    final rowCount = itemCount <= 0 ? 0 : (itemCount / columns).ceil();
    final visibleRows = math.min(requestedVisibleRows, math.max(rowCount, 1));
    final safeWidth = math.max(availableWidth, 1);
    final safeHeight = math.max(availableHeight, 1);
    final widthForTiles = math.max(safeWidth - (spacing * (columns - 1)), 1);
    final heightForTiles = math.max(
      safeHeight - (spacing * (visibleRows - 1)),
      1,
    );
    final widthLimitedTileWidth = widthForTiles / columns;
    final heightLimitedTileWidth =
        (heightForTiles / visibleRows) * childAspectRatio;
    final tileWidth = math.max(
      math.min(widthLimitedTileWidth, heightLimitedTileWidth),
      1.0,
    );
    final tileHeight = tileWidth / childAspectRatio;
    final gridWidth = (tileWidth * columns) + (spacing * (columns - 1));
    final gridHeight = rowCount <= 0
        ? 0.0
        : (tileHeight * rowCount) + (spacing * (rowCount - 1));
    final viewportHeight =
        (tileHeight * visibleRows) + (spacing * (visibleRows - 1));

    return ArcBlueprintGridFittedLayout(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      viewportWidth: gridWidth,
      viewportHeight: viewportHeight,
      visibleRows: visibleRows,
    );
  }

  static double availableGridWidth({
    required double availableWidth,
    required double leftRailWidth,
    required double rightRailWidth,
    required double railGap,
  }) {
    final reservedWidth = leftRailWidth + rightRailWidth + (railGap * 2);
    return math.max(availableWidth - reservedWidth, 1.0);
  }

  static double fittedRowHeight({
    required double fittedGridHeight,
    required int rowCount,
  }) {
    if (rowCount <= 0) return 0;
    return fittedGridHeight / rowCount;
  }

  static ArcBlueprintGridJumpState jumpState({
    required double currentTranslationY,
    required double scale,
    required double viewportHeight,
    required double fittedGridHeight,
    required int rowCount,
  }) {
    final contentHeight = fittedGridHeight * scale;
    final minTranslation = (viewportHeight - contentHeight).clamp(
      double.negativeInfinity,
      0.0,
    );
    final translation = currentTranslationY.clamp(minTranslation, 0.0);

    return ArcBlueprintGridJumpState(
      canJumpUp: translation < -1,
      canJumpDown: translation > minTranslation + 1,
      translationY: translation.toDouble(),
    );
  }

  static double jumpTranslationY({
    required double currentTranslationY,
    required double scale,
    required double viewportHeight,
    required double fittedGridHeight,
    required int rowCount,
    required bool down,
    double rows = 5,
    double contextOverlapRows = 0.45,
  }) {
    final state = jumpState(
      currentTranslationY: currentTranslationY,
      scale: scale,
      viewportHeight: viewportHeight,
      fittedGridHeight: fittedGridHeight,
      rowCount: rowCount,
    );
    final rowHeight = fittedRowHeight(
      fittedGridHeight: fittedGridHeight,
      rowCount: rowCount,
    );
    final effectiveRows = math.max(rows - contextOverlapRows, 1);
    final step = rowHeight * effectiveRows * scale;
    final contentHeight = fittedGridHeight * scale;
    final minTranslation = (viewportHeight - contentHeight).clamp(
      double.negativeInfinity,
      0.0,
    );
    final target = down ? state.translationY - step : state.translationY + step;

    return target.clamp(minTranslation, 0.0).toDouble();
  }
}
