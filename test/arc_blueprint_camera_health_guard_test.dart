import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_health_guard.dart';

void main() {
  const guard = ArcBlueprintCameraHealthGuard(
    minimumReadyAge: Duration(milliseconds: 900),
  );

  test('blocks capture until camera has settled', () {
    final readyAt = DateTime(2026, 8, 9, 12);

    expect(
      guard.canCapture(
        initialized: true,
        hasError: false,
        isTakingPicture: false,
        capturing: false,
        readyAt: readyAt,
        now: readyAt.add(const Duration(milliseconds: 899)),
      ),
      isFalse,
    );

    expect(
      guard.canCapture(
        initialized: true,
        hasError: false,
        isTakingPicture: false,
        capturing: false,
        readyAt: readyAt,
        now: readyAt.add(const Duration(milliseconds: 900)),
      ),
      isTrue,
    );
  });

  test('blocks capture for plugin error and in-flight picture states', () {
    final now = DateTime(2026, 8, 9, 12);
    final readyAt = now.subtract(const Duration(seconds: 2));

    expect(
      guard.canCapture(
        initialized: true,
        hasError: true,
        isTakingPicture: false,
        capturing: false,
        readyAt: readyAt,
        now: now,
      ),
      isFalse,
    );

    expect(
      guard.canCapture(
        initialized: true,
        hasError: false,
        isTakingPicture: true,
        capturing: false,
        readyAt: readyAt,
        now: now,
      ),
      isFalse,
    );
  });
}
