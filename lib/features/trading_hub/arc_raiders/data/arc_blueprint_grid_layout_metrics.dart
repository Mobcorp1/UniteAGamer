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
    int rows = 5,
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
    final step = rowHeight * rows * scale;
    final contentHeight = fittedGridHeight * scale;
    final minTranslation = (viewportHeight - contentHeight).clamp(
      double.negativeInfinity,
      0.0,
    );
    final target = down ? state.translationY - step : state.translationY + step;

    return target.clamp(minTranslation, 0.0).toDouble();
  }
}
