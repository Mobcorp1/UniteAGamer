import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_corner_calibration.dart';

void main() {
  test('corner calibration clamps handles and validates shape', () {
    const calibration = ArcBlueprintCornerCalibration.defaults();
    expect(calibration.isValid, isTrue);

    final moved = calibration.moveCorner(0, const Offset(-1, 2));
    expect(moved.topLeft, const Offset(0, 1));
  });

  test('corner calibration survives json round trip', () {
    const original = ArcBlueprintCornerCalibration.defaults();
    final restored = ArcBlueprintCornerCalibration.fromJson(original.toJson());
    expect(restored.topLeft, original.topLeft);
    expect(restored.bottomRight, original.bottomRight);
  });
}
