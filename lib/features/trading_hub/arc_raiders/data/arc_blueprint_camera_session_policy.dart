import 'package:flutter/foundation.dart';

bool arcBlueprintLiveAnalysisEnabled(
  TargetPlatform platform, {
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return true;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}
