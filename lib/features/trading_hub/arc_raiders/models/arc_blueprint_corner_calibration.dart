import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class ArcBlueprintCornerCalibration {
  const ArcBlueprintCornerCalibration({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  const ArcBlueprintCornerCalibration.defaults()
    : topLeft = const Offset(0.08, 0.12),
      topRight = const Offset(0.92, 0.12),
      bottomLeft = const Offset(0.08, 0.88),
      bottomRight = const Offset(0.92, 0.88);

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  List<Offset> get corners => [topLeft, topRight, bottomLeft, bottomRight];

  bool get isValid {
    final topWidth = topRight.dx - topLeft.dx;
    final bottomWidth = bottomRight.dx - bottomLeft.dx;
    final leftHeight = bottomLeft.dy - topLeft.dy;
    final rightHeight = bottomRight.dy - topRight.dy;
    return topWidth > 0.15 &&
        bottomWidth > 0.15 &&
        leftHeight > 0.15 &&
        rightHeight > 0.15;
  }

  ArcBlueprintCornerCalibration moveCorner(int index, Offset value) {
    final clamped = Offset(value.dx.clamp(0.0, 1.0), value.dy.clamp(0.0, 1.0));
    switch (index) {
      case 0:
        return ArcBlueprintCornerCalibration(
          topLeft: clamped,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );
      case 1:
        return ArcBlueprintCornerCalibration(
          topLeft: topLeft,
          topRight: clamped,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        );
      case 2:
        return ArcBlueprintCornerCalibration(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: clamped,
          bottomRight: bottomRight,
        );
      case 3:
        return ArcBlueprintCornerCalibration(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: clamped,
        );
      default:
        return this;
    }
  }

  Map<String, Object> toJson() => {
    'topLeftX': topLeft.dx,
    'topLeftY': topLeft.dy,
    'topRightX': topRight.dx,
    'topRightY': topRight.dy,
    'bottomLeftX': bottomLeft.dx,
    'bottomLeftY': bottomLeft.dy,
    'bottomRightX': bottomRight.dx,
    'bottomRightY': bottomRight.dy,
  };

  factory ArcBlueprintCornerCalibration.fromJson(Map<String, Object?> json) {
    double read(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    return ArcBlueprintCornerCalibration(
      topLeft: Offset(read('topLeftX', 0.08), read('topLeftY', 0.12)),
      topRight: Offset(read('topRightX', 0.92), read('topRightY', 0.12)),
      bottomLeft: Offset(read('bottomLeftX', 0.08), read('bottomLeftY', 0.88)),
      bottomRight: Offset(
        read('bottomRightX', 0.92),
        read('bottomRightY', 0.88),
      ),
    );
  }
}
