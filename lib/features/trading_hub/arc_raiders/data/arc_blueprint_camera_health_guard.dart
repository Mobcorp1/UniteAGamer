class ArcBlueprintCameraHealthGuard {
  const ArcBlueprintCameraHealthGuard({
    this.minimumReadyAge = const Duration(milliseconds: 900),
  });

  final Duration minimumReadyAge;

  bool canCapture({
    required bool initialized,
    required bool hasError,
    required bool isTakingPicture,
    required bool capturing,
    required DateTime? readyAt,
    required DateTime now,
  }) {
    if (!initialized || hasError || isTakingPicture || capturing) {
      return false;
    }
    if (readyAt == null) {
      return false;
    }
    return now.difference(readyAt) >= minimumReadyAge;
  }

  Duration remainingReadyDelay({
    required DateTime? readyAt,
    required DateTime now,
  }) {
    if (readyAt == null) return minimumReadyAge;
    final elapsed = now.difference(readyAt);
    if (elapsed >= minimumReadyAge) return Duration.zero;
    return minimumReadyAge - elapsed;
  }
}
