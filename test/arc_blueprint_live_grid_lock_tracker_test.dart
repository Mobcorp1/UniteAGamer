import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_grid_lock_tracker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

ArcBlueprintGridDetection detection({
  double shift = 0,
  double confidence = 0.9,
}) {
  return ArcBlueprintGridDetection(
    topLeft: Offset(0.10 + shift, 0.20),
    topRight: Offset(0.90 + shift, 0.20),
    bottomLeft: Offset(0.10 + shift, 0.80),
    bottomRight: Offset(0.90 + shift, 0.80),
    confidence: confidence,
    message: 'Grid locked',
    columns: 10,
    rows: 5,
    verticalDividers: <double>[
      0.10 + shift,
      0.18 + shift,
      0.26 + shift,
      0.34 + shift,
      0.42 + shift,
      0.50 + shift,
      0.58 + shift,
      0.66 + shift,
      0.74 + shift,
      0.82 + shift,
      0.90 + shift,
    ],
    horizontalDividers: const <double>[0.20, 0.32, 0.44, 0.56, 0.68, 0.80],
  );
}

void main() {
  test('requires three stable detections before lock', () {
    final tracker = ArcBlueprintLiveGridLockTracker(requiredStableFrames: 3);

    expect(tracker.update(detection()).isStable, isFalse);
    expect(tracker.update(detection(shift: 0.005)).isStable, isFalse);
    expect(tracker.update(detection(shift: 0.008)).isStable, isTrue);
  });

  test('large geometry movement resets stability', () {
    final tracker = ArcBlueprintLiveGridLockTracker(requiredStableFrames: 3);

    tracker.update(detection());
    tracker.update(detection(shift: 0.005));

    final moved = tracker.update(detection(shift: 0.10));
    expect(moved.isStable, isFalse);
    expect(moved.stableFrames, 1);
  });

  test('low confidence clears live lock', () {
    final tracker = ArcBlueprintLiveGridLockTracker(
      requiredStableFrames: 2,
      minimumConfidence: 0.62,
    );

    tracker.update(detection());
    expect(tracker.update(detection()).isStable, isTrue);

    final weak = tracker.update(detection(confidence: 0.40));

    expect(weak.isStable, isFalse);
    expect(weak.detection, isNull);
  });
}
