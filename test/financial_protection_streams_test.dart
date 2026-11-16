import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/services/uag_streams.dart';
import 'package:uag_arc_raiders_hub/services/uag_app_check.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'auth change cancels old listener, clears sign-out and follows next account',
    () async {
      final auth = StreamController<String?>();
      final first = StreamController<int>();
      final second = StreamController<int>();
      final values = <int>[];
      var firstCancelled = false;
      first.onCancel = () {
        firstCancelled = true;
      };
      final sub = auth.stream
          .switchLatest(
            (uid) => uid == null
                ? Stream.value(-1)
                : uid == 'a'
                ? first.stream
                : second.stream,
          )
          .listen(values.add);
      auth.add('a');
      await settle();
      first.add(1);
      await settle();
      auth.add(null);
      await settle();
      await settle();
      expect(firstCancelled, isTrue);
      expect(values, [1, -1]);
      auth.add('b');
      await settle();
      second.add(2);
      await settle();
      expect(values, [1, -1, 2]);
      await sub.cancel();
      expect(auth.hasListener, isFalse);
      expect(second.hasListener, isFalse);
      await auth.close();
      await first.close();
      await second.close();
    },
  );

  test(
    'cancelling during asynchronous switch cannot start a leaked listener',
    () async {
      final source = StreamController<int>();
      final cancelled = Completer<void>();
      final old = StreamController<int>(onCancel: () => cancelled.future);
      var opened = 0;
      final sub = source.stream
          .switchLatest((key) {
            opened++;
            return key == 1 ? old.stream : const Stream<int>.empty();
          })
          .listen((_) {});
      source.add(1);
      await settle();
      source.add(2);
      await settle();
      await sub.cancel();
      cancelled.complete();
      await settle();
      expect(opened, 1);
      expect(source.hasListener, isFalse);
      await source.close();
      await old.close();
    },
  );

  test(
    'rapid switches discard obsolete sources and propagate errors',
    () async {
      final source = StreamController<int>();
      final values = <int>[];
      final errors = <Object>[];
      final sub = source.stream
          .switchLatest(
            (key) => key == 3
                ? Stream<int>.error(StateError('unavailable'))
                : Stream.value(key),
          )
          .listen(values.add, onError: errors.add);
      source.add(1);
      source.add(2);
      await settle();
      await settle();
      expect(values, [2]);
      source.add(3);
      await settle();
      await settle();
      expect(errors, hasLength(1));
      source.add(4);
      await settle();
      await settle();
      expect(values, [2, 4]);
      await source.close();
      await sub.cancel();
    },
  );

  test(
    'shared source is cancelled only after last consumer and refreshes on reopen',
    () async {
      var starts = 0;
      var cancels = 0;
      var evictions = 0;
      final inputs = <StreamController<int>>[];
      final shared = shareWhileListened(
        () {
          starts++;
          final input = StreamController<int>(
            onCancel: () {
              cancels++;
            },
          );
          inputs.add(input);
          return input.stream;
        },
        () {
          evictions++;
        },
      );
      final one = shared.listen((_) {});
      final two = shared.listen((_) {});
      expect(starts, 1);
      await one.cancel();
      expect(cancels, 0);
      await two.cancel();
      await settle();
      expect(cancels, 1);
      expect(evictions, 1);
      final three = shared.listen((_) {});
      expect(starts, 2);
      await three.cancel();
      for (final input in inputs) {
        await input.close();
      }
    },
  );

  test('App Check rollout excludes unsupported desktop attestation', () async {
    for (final p in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ]) {
      expect(UagAppCheck.supported(web: false, platform: p), isTrue);
    }
    expect(
      UagAppCheck.supported(web: false, platform: TargetPlatform.windows),
      isFalse,
    );
    expect(
      UagAppCheck.supported(web: true, platform: TargetPlatform.windows),
      isTrue,
    );
    expect(await UagAppCheck.headers(), isEmpty);
  });
}
