import 'package:flutter/foundation.dart';

bool arcBlueprintLiveAnalysisEnabled(TargetPlatform platform) {
  return platform != TargetPlatform.android;
}
