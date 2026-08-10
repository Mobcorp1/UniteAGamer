import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_session_policy.dart';

void main() {
  test(
    'Android uses preview plus still capture without live image analysis',
    () {
      expect(arcBlueprintLiveAnalysisEnabled(TargetPlatform.android), isFalse);
    },
  );

  test('non-Android platforms keep live analysis available', () {
    expect(arcBlueprintLiveAnalysisEnabled(TargetPlatform.iOS), isTrue);
    expect(arcBlueprintLiveAnalysisEnabled(TargetPlatform.windows), isTrue);
  });
}
