import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

@immutable
class ArcBlueprintLiveGridLockState {
  const ArcBlueprintLiveGridLockState({
    required this.detection,
    required this.stableFrames,
    required this.isStable,
  });

  final ArcBlueprintGridDetection? detection;
  final int stableFrames;
  final bool isStable;
}

class ArcBlueprintLiveGridLockTracker {
  ArcBlueprintLiveGridLockTracker({
    this.requiredStableFrames = 3,
    this.maximumCornerDrift = 0.035,
    this.minimumConfidence = 0.62,
  });

  final int requiredStableFrames;
  final double maximumCornerDrift;
  final double minimumConfidence;

  ArcBlueprintGridDetection? _previous;
  int _stableFrames = 0;

  ArcBlueprintLiveGridLockState update(ArcBlueprintGridDetection detection) {
    if (!detection.isValid ||
        !detection.hasSegmentedGrid ||
        detection.confidence < minimumConfidence) {
      _previous = null;
      _stableFrames = 0;
      return const ArcBlueprintLiveGridLockState(
        detection: null,
        stableFrames: 0,
        isStable: false,
      );
    }

    final previous = _previous;
    if (previous == null || !_sameGeometry(previous, detection)) {
      _stableFrames = 1;
    } else {
      _stableFrames++;
    }

    _previous = detection;

    return ArcBlueprintLiveGridLockState(
      detection: detection,
      stableFrames: _stableFrames,
      isStable: _stableFrames >= requiredStableFrames,
    );
  }

  void reset() {
    _previous = null;
    _stableFrames = 0;
  }

  bool _sameGeometry(ArcBlueprintGridDetection a, ArcBlueprintGridDetection b) {
    final aCorners = a.corners;
    final bCorners = b.corners;

    var worst = 0.0;
    for (var index = 0; index < aCorners.length; index++) {
      final distance = _distance(aCorners[index], bCorners[index]);
      worst = math.max(worst, distance);
    }

    return worst <= maximumCornerDrift;
  }

  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
