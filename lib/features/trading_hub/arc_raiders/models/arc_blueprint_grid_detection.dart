import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class ArcBlueprintGridDetection {
  const ArcBlueprintGridDetection({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.confidence,
    required this.message,
    required this.columns,
    required this.rows,
    this.verticalDividers = const <double>[],
    this.horizontalDividers = const <double>[],
  });

  const ArcBlueprintGridDetection.notFound({
    this.message = 'Blueprint grid not locked.',
    this.columns = 10,
    this.rows = 5,
  }) : topLeft = Offset.zero,
       topRight = Offset.zero,
       bottomLeft = Offset.zero,
       bottomRight = Offset.zero,
       confidence = 0,
       verticalDividers = const <double>[],
       horizontalDividers = const <double>[];

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final double confidence;
  final String message;
  final int columns;
  final int rows;

  final List<double> verticalDividers;
  final List<double> horizontalDividers;

  bool get hasSegmentedGrid =>
      verticalDividers.length == columns + 1 &&
      horizontalDividers.length == rows + 1;

  bool get isLocked => confidence >= 0.58 && isValid && hasSegmentedGrid;

  bool get isValid {
    final topWidth = topRight.dx - topLeft.dx;
    final bottomWidth = bottomRight.dx - bottomLeft.dx;
    final leftHeight = bottomLeft.dy - topLeft.dy;
    final rightHeight = bottomRight.dy - topRight.dy;

    return topWidth > 0.25 &&
        bottomWidth > 0.25 &&
        leftHeight > 0.15 &&
        rightHeight > 0.15;
  }

  List<Offset> get corners => <Offset>[
    topLeft,
    topRight,
    bottomLeft,
    bottomRight,
  ];
}
