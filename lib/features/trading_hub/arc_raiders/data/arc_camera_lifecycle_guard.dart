/// Generation guard for asynchronous camera lifecycle work.
///
/// Camera initialisation, live-frame callbacks, retries and lifecycle resumes
/// are tagged with a generation. Pausing, retrying or disposing invalidates
/// older generations so stale async work cannot publish a controller that is
/// no longer owned by the live scanner.
class ArcCameraLifecycleGuard {
  int _generation = 0;

  int get currentGeneration => _generation;

  int beginGeneration() {
    _generation += 1;
    return _generation;
  }

  void invalidate() {
    _generation += 1;
  }

  bool isCurrent(int generation) => generation == _generation;
}
