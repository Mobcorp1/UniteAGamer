import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_camera_lifecycle_guard.dart';

void main() {
  test('new generation makes earlier camera work stale', () {
    final guard = ArcCameraLifecycleGuard();

    final first = guard.beginGeneration();
    expect(guard.isCurrent(first), isTrue);

    final second = guard.beginGeneration();
    expect(guard.isCurrent(first), isFalse);
    expect(guard.isCurrent(second), isTrue);
  });

  test('lifecycle invalidation rejects current callbacks', () {
    final guard = ArcCameraLifecycleGuard();

    final generation = guard.beginGeneration();
    guard.invalidate();

    expect(guard.isCurrent(generation), isFalse);
  });
}
