class ArcBlueprintPreviewFrameGate {
  ArcBlueprintPreviewFrameGate({
    this.minimumInterval = const Duration(milliseconds: 250),
  });

  final Duration minimumInterval;
  int? _lastAcceptedMicros;

  bool shouldProcess(int nowMicros) {
    final last = _lastAcceptedMicros;
    if (last != null && nowMicros - last < minimumInterval.inMicroseconds) {
      return false;
    }
    _lastAcceptedMicros = nowMicros;
    return true;
  }

  void reset() {
    _lastAcceptedMicros = null;
  }
}
