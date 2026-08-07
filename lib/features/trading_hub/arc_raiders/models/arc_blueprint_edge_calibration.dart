import 'dart:ui';

import 'package:flutter/foundation.dart';

enum ArcBlueprintCropEdge { top, bottom, left, right }

@immutable
class ArcBlueprintEdgeCalibration {
  const ArcBlueprintEdgeCalibration({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  const ArcBlueprintEdgeCalibration.defaults()
    : left = 0.08,
      top = 0.10,
      right = 0.92,
      bottom = 0.90;

  static const double minimumWidth = 0.20;
  static const double minimumHeight = 0.20;

  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect get normalizedRect => Rect.fromLTRB(left, top, right, bottom);

  bool get isValid =>
      left >= 0 &&
      top >= 0 &&
      right <= 1 &&
      bottom <= 1 &&
      right - left >= minimumWidth &&
      bottom - top >= minimumHeight;

  ArcBlueprintEdgeCalibration moveEdge(
    ArcBlueprintCropEdge edge,
    double normalizedPosition,
  ) {
    final value = normalizedPosition.clamp(0.0, 1.0);

    switch (edge) {
      case ArcBlueprintCropEdge.top:
      case ArcBlueprintCropEdge.bottom:
        final centre = (top + bottom) / 2;
        final requestedHalfHeight = edge == ArcBlueprintCropEdge.top
            ? centre - value
            : value - centre;
        final maximumHalfHeight = centre < 0.5 ? centre : 1 - centre;
        final halfHeight = requestedHalfHeight.abs().clamp(
          minimumHeight / 2,
          maximumHalfHeight,
        );
        return copyWith(top: centre - halfHeight, bottom: centre + halfHeight);

      case ArcBlueprintCropEdge.left:
      case ArcBlueprintCropEdge.right:
        final centre = (left + right) / 2;
        final requestedHalfWidth = edge == ArcBlueprintCropEdge.left
            ? centre - value
            : value - centre;
        final maximumHalfWidth = centre < 0.5 ? centre : 1 - centre;
        final halfWidth = requestedHalfWidth.abs().clamp(
          minimumWidth / 2,
          maximumHalfWidth,
        );
        return copyWith(left: centre - halfWidth, right: centre + halfWidth);
    }
  }

  ArcBlueprintEdgeCalibration copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return ArcBlueprintEdgeCalibration(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  Map<String, Object> toJson() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };

  factory ArcBlueprintEdgeCalibration.fromJson(Map<String, Object?> json) {
    double read(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;

    final left = json.containsKey('left')
        ? read('left', 0.08)
        : (read('topLeftX', 0.08) + read('bottomLeftX', 0.08)) / 2;
    final top = json.containsKey('top')
        ? read('top', 0.10)
        : (read('topLeftY', 0.10) + read('topRightY', 0.10)) / 2;
    final right = json.containsKey('right')
        ? read('right', 0.92)
        : (read('topRightX', 0.92) + read('bottomRightX', 0.92)) / 2;
    final bottom = json.containsKey('bottom')
        ? read('bottom', 0.90)
        : (read('bottomLeftY', 0.90) + read('bottomRightY', 0.90)) / 2;

    final calibration = ArcBlueprintEdgeCalibration(
      left: left.clamp(0.0, 1.0),
      top: top.clamp(0.0, 1.0),
      right: right.clamp(0.0, 1.0),
      bottom: bottom.clamp(0.0, 1.0),
    );
    return calibration.isValid
        ? calibration
        : const ArcBlueprintEdgeCalibration.defaults();
  }
}
