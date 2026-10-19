import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/uag_android_responsiveness_guard.dart';

void main() {
  test('slow frame logging threshold is deterministic', () {
    expect(UagAndroidFramePolicy.isSlowFrame(99, 99), isFalse);
    expect(UagAndroidFramePolicy.isSlowFrame(100, 0), isTrue);
    expect(UagAndroidFramePolicy.isSlowFrame(0, 100), isTrue);
    expect(UagAndroidFramePolicy.isSlowFrame(5000, 0), isTrue);
  });

  test('event loop gap threshold catches ANR-sized stalls', () {
    expect(UagAndroidFramePolicy.isEventLoopGap(1000), isFalse);
    expect(UagAndroidFramePolicy.isEventLoopGap(2499), isFalse);
    expect(UagAndroidFramePolicy.isEventLoopGap(2500), isTrue);
    expect(UagAndroidFramePolicy.isEventLoopGap(5000), isTrue);
  });

  test('retained image budget is bounded without touching state', () {
    expect(
      UagAndroidResponsivenessGuard.retainedImageCacheLimitBytes,
      greaterThanOrEqualTo(64 * 1024 * 1024),
    );
    expect(
      UagAndroidResponsivenessGuard.retainedImageCountLimit,
      greaterThanOrEqualTo(91),
    );
  });
}
