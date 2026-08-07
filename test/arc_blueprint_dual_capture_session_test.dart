import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_dual_capture_session.dart';

void main() {
  test('bottom capture never overwrites top capture', () {
    final top = Uint8List.fromList([1, 2, 3, 4]);
    final bottom = Uint8List.fromList([9, 8, 7, 6]);

    final topSession = const ArcBlueprintDualCaptureSession().captureTop(top);
    final complete = topSession.captureBottom(bottom);

    expect(complete.topImageBytes, [1, 2, 3, 4]);
    expect(complete.bottomImageBytes, [9, 8, 7, 6]);
    expect(complete.isComplete, isTrue);
  });

  test('captured byte buffers are defensive copies', () {
    final top = Uint8List.fromList([1, 2, 3]);
    final bottom = Uint8List.fromList([4, 5, 6]);

    final session = const ArcBlueprintDualCaptureSession()
        .captureTop(top)
        .captureBottom(bottom);

    top[0] = 99;
    bottom[0] = 88;

    expect(session.topImageBytes, [1, 2, 3]);
    expect(session.bottomImageBytes, [4, 5, 6]);
  });

  test('restarting top preserves bottom only when requested', () {
    final session = const ArcBlueprintDualCaptureSession()
        .captureTop(Uint8List.fromList([1]))
        .captureBottom(Uint8List.fromList([2]));

    final cleared = session.clearTop();

    expect(cleared.hasTop, isFalse);
    expect(cleared.bottomImageBytes, [2]);
  });
}
