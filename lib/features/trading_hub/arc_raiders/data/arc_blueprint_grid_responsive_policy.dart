import 'package:flutter/foundation.dart';

enum ArcBlueprintSearchResultSize { single, pair, compactSet, grid }

@immutable
class ArcBlueprintSearchLayout {
  const ArcBlueprintSearchLayout({
    required this.size,
    required this.columns,
    required this.maxTileWidth,
    required this.childAspectRatio,
  });

  final ArcBlueprintSearchResultSize size;
  final int columns;
  final double maxTileWidth;
  final double childAspectRatio;
}

class ArcBlueprintGridResponsivePolicy {
  const ArcBlueprintGridResponsivePolicy._();

  static const double _inGameMinimumWidth = 560;

  static bool shouldShowInGameRotatePrompt({
    required double width,
    required double height,
  }) {
    final effectiveWidth = width.isFinite ? width : 0;
    final effectiveHeight = height.isFinite ? height : 0;
    if (effectiveWidth <= 0 || effectiveHeight <= 0) return false;
    final portrait = effectiveHeight > effectiveWidth;
    return portrait && effectiveWidth < _inGameMinimumWidth;
  }

  static ArcBlueprintSearchLayout searchLayout({
    required int resultCount,
    required double width,
  }) {
    final safeWidth = width.isFinite ? width.clamp(260.0, 1440.0) : 360.0;
    if (resultCount <= 1) {
      return ArcBlueprintSearchLayout(
        size: ArcBlueprintSearchResultSize.single,
        columns: 1,
        maxTileWidth: safeWidth.clamp(260.0, 430.0),
        childAspectRatio: 0.86,
      );
    }

    if (resultCount == 2) {
      final columns = safeWidth < 520 ? 1 : 2;
      return ArcBlueprintSearchLayout(
        size: ArcBlueprintSearchResultSize.pair,
        columns: columns,
        maxTileWidth: columns == 1
            ? safeWidth.clamp(260.0, 390.0)
            : (safeWidth / 2).clamp(220.0, 330.0),
        childAspectRatio: 0.88,
      );
    }

    if (resultCount <= 4) {
      final columns = safeWidth < 500 ? 1 : 2;
      return ArcBlueprintSearchLayout(
        size: ArcBlueprintSearchResultSize.compactSet,
        columns: columns,
        maxTileWidth: columns == 1
            ? safeWidth.clamp(250.0, 360.0)
            : (safeWidth / 2).clamp(210.0, 310.0),
        childAspectRatio: 0.90,
      );
    }

    final columns = safeWidth >= 1080
        ? 5
        : safeWidth >= 820
        ? 4
        : safeWidth >= 560
        ? 3
        : 2;
    return ArcBlueprintSearchLayout(
      size: ArcBlueprintSearchResultSize.grid,
      columns: columns,
      maxTileWidth: (safeWidth / columns).clamp(150.0, 240.0),
      childAspectRatio: 0.92,
    );
  }
}
