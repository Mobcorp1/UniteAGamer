import 'dart:async';

class ArcCameraOperationQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();

    _tail = _tail
        .then((_) async {
          try {
            completer.complete(await operation());
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        })
        .catchError((Object _) {
          // Keep later camera operations runnable after a failed operation.
        });

    return completer.future;
  }
}
