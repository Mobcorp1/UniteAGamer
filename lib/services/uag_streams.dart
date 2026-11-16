import 'dart:async';

/// Switches a long-lived subscription when its identity changes. asyncExpand
/// waits for the previous stream to close and therefore cannot follow sign-out.
extension UagSwitchLatest<T> on Stream<T> {
  Stream<R> switchLatest<R>(Stream<R> Function(T value) convert) {
    late StreamController<R> output;
    StreamSubscription<T>? source;
    StreamSubscription<R>? inner;
    var generation = 0;
    var sourceDone = false;
    var switching = 0;
    var cancelled = false;

    void finish() {
      if (!cancelled && sourceDone && switching == 0 && inner == null) {
        unawaited(output.close());
      }
    }

    Future<void> change(T value) async {
      final current = ++generation;
      switching++;
      final previous = inner;
      inner = null;
      try {
        await previous?.cancel();
        if (cancelled || current != generation) return;
        inner = convert(value).listen(
          (event) {
            if (!cancelled && current == generation) output.add(event);
          },
          onError: (Object error, StackTrace stack) {
            if (!cancelled && current == generation) {
              output.addError(error, stack);
            }
          },
          onDone: () {
            if (current == generation) {
              inner = null;
              finish();
            }
          },
        );
        if (output.isPaused) inner?.pause();
      } catch (error, stack) {
        if (!cancelled && current == generation) output.addError(error, stack);
      } finally {
        switching--;
        finish();
      }
    }

    output = StreamController<R>(
      onListen: () {
        source = listen(
          (value) => unawaited(change(value)),
          onError: (Object error, StackTrace stack) =>
              output.addError(error, stack),
          onDone: () {
            sourceDone = true;
            finish();
          },
        );
      },
      onPause: () {
        source?.pause();
        inner?.pause();
      },
      onResume: () {
        source?.resume();
        inner?.resume();
      },
      onCancel: () async {
        cancelled = true;
        generation++;
        await source?.cancel();
        await inner?.cancel();
      },
    );
    return output.stream;
  }
}

/// One live source while there are consumers. The last cancellation releases
/// Firestore and evicts the entry; reopening obtains a fresh subscription.
Stream<T> shareWhileListened<T>(
  Stream<T> Function() create,
  void Function() evict,
) {
  late StreamController<T> output;
  StreamSubscription<T>? subscription;
  output = StreamController<T>.broadcast(
    onListen: () {
      subscription = create().listen(
        output.add,
        onError: output.addError,
        onDone: () {
          evict();
          unawaited(output.close());
        },
      );
    },
    onCancel: () {
      evict();
      unawaited(subscription?.cancel());
    },
  );
  return output.stream;
}
