import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_session_policy.dart';

void main() {
  test('Android and iOS enable genuine live scanner analysis', () {
    expect(
      arcBlueprintLiveAnalysisEnabled(
        TargetPlatform.android,
        isWeb: false,
      ),
      isTrue,
    );
    expect(
      arcBlueprintLiveAnalysisEnabled(
        TargetPlatform.iOS,
        isWeb: false,
      ),
      isTrue,
    );
  });

  test('web app enables live scanner analysis on every browser host platform', () {
    expect(
      arcBlueprintLiveAnalysisEnabled(
        TargetPlatform.windows,
        isWeb: true,
      ),
      isTrue,
    );
    expect(
      arcBlueprintLiveAnalysisEnabled(
        TargetPlatform.macOS,
        isWeb: true,
      ),
      isTrue,
    );
  });

  test('unsupported native desktop targets remain capture-only', () {
    expect(
      arcBlueprintLiveAnalysisEnabled(
        TargetPlatform.windows,
        isWeb: false,
      ),
      isFalse,
    );
    expect(
      arcBlueprintLiveAnalysisEnabled(
        TargetPlatform.linux,
        isWeb: false,
      ),
      isFalse,
    );
  });
}
