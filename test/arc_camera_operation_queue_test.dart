import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_camera_operation_queue.dart';

void main() {
  test('camera operations execute one at a time', () async {
    final queue = ArcCameraOperationQueue();
    final events = <String>[];
    final gate = Completer<void>();

    final first = queue.run<void>(() async {
      events.add('first-start');
      await gate.future;
      events.add('first-end');
    });

    final second = queue.run<void>(() async {
      events.add('second');
    });

    await Future<void>.delayed(Duration.zero);
    expect(events, <String>['first-start']);

    gate.complete();
    await Future.wait<void>(<Future<void>>[first, second]);

    expect(events, <String>['first-start', 'first-end', 'second']);
  });

  test('failed operation does not poison the queue', () async {
    final queue = ArcCameraOperationQueue();
    final events = <String>[];

    await expectLater(
      queue.run<void>(() async => throw StateError('boom')),
      throwsStateError,
    );

    await queue.run<void>(() async {
      events.add('next');
    });

    expect(events, <String>['next']);
  });
}
