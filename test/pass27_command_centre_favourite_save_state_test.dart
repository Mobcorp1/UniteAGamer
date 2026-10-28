import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  final screen = File(
    'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
  ).readAsStringSync();
  final repository = File(
    'lib/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart',
  ).readAsStringSync();

  test('PASS27 reloads favourite subscription when authentication changes', () {
    // Dart formatter can wrap the auth stream call across multiple lines.
    // Match the actual Firebase Auth API invocation without coupling to layout.
    expect(
      RegExp(
        r'FirebaseAuth\.instance\s*\.authStateChanges\(\)',
      ).hasMatch(screen),
      isTrue,
      reason: 'The Command Centre must subscribe to authStateChanges().',
    );
    expect(screen, contains('StreamBuilder<User?>('));
    expect(screen, contains('_bindFavouriteLoadoutSession(user?.uid)'));
    expect(screen, contains('if (_favouriteLoadoutUid == uid) {'));
    // dart format may split this ternary over several lines. Verify the
    // actual auth-to-Firestore binding instead of enforcing whitespace.
    expect(
      RegExp(
        r'uid\s*==\s*null\s*\?\s*null\s*:\s*_loadoutRepository\.watchFavouriteLoadout\(\)\s*;',
      ).hasMatch(screen),
      isTrue,
      reason:
          'An authenticated session must attach the favourite-document stream.',
    );
    expect(screen, contains('_loadoutRepository.watchFavouriteLoadout()'));
    expect(
      screen,
      isNot(
        contains('late final Stream<ArcSavedLoadout?> _favouriteLoadoutStream'),
      ),
    );
  });

  test('PASS27 resets old-account state before binding the new stream', () {
    final start = screen.indexOf('void _bindFavouriteLoadoutSession(');
    final end = screen.indexOf('\n  // A real document read', start);
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    final binding = screen.substring(start, end);
    expect(binding, contains('_cachedLoadouts = const <ArcSavedLoadout>[];'));
    expect(binding, contains('_favouriteLoadoutResolved = false;'));
    expect(binding, contains('_favouriteLoadoutReadFailed = false;'));
    expect(
      binding.indexOf('_cachedLoadouts ='),
      lessThan(binding.indexOf('watchFavouriteLoadout()')),
    );
    expect(screen, isNot(contains('command-centre-favourite-')));
    expect(screen, isNot(contains('_favouriteLoadoutRevision')));
  });

  test('PASS27 rereads the same document when returning from the editor', () {
    expect(screen, contains('unawaited(_refreshFavouriteAfterEditor())'));
    expect(screen, contains('_loadoutRepository.loadFavouriteLoadout()'));
    // Replacing the stream in setState keeps existing nested subscriptions.
    expect(
      RegExp(
        r'_favouriteLoadoutStream\s*=\s*_loadoutRepository\.watchFavouriteLoadout\(\);',
      ).allMatches(screen).length,
      2,
    );
    expect(screen, contains('uid != _favouriteLoadoutUid'));
    expect(repository, contains("doc('favourite-loadout').get()"));
    expect(repository, contains(".doc(loadout.id)"));
    expect(screen, isNot(contains('_loadoutRepository.watchSavedLoadouts()')));
  });

  test('PASS27 never interprets pending, signed-out, or failed reads as not saved', () {
    expect(screen, contains('ConnectionState.active'));
    expect(screen, contains('_favouriteLoadoutReadFailed = true'));
    expect(
      screen,
      contains('(_favouriteLoadoutUid == null || _favouriteLoadoutReadFailed)'),
    );
    // All Command Centre content paths must distinguish a pending read from
    // a resolved missing save. Layout/indentation are not part of the contract.
    final pendingPolicy = RegExp(
      r'loadoutPending\s*:\s*_favouriteLoadoutUid\s*!=\s*null\s*&&\s*!_favouriteLoadoutResolved\s*&&\s*!_favouriteLoadoutReadFailed\s*,',
    );
    expect(
      pendingPolicy.allMatches(screen).length,
      3,
      reason:
          'Every Command Centre render path must preserve pending-read status.',
    );
    final unavailablePolicy = RegExp(
      r'loadoutUnavailable\s*:\s*\(_favouriteLoadoutUid\s*==\s*null\s*\|\|\s*_favouriteLoadoutReadFailed\)\s*&&\s*_cachedLoadouts\.isEmpty\s*,',
    );
    expect(
      unavailablePolicy.allMatches(screen).length,
      3,
      reason: 'All render paths must distinguish unavailable from unsaved.',
    );
  });

  test(
    'PASS27 R4 refreshes the favourite stream without remounting the Operations subtree',
    () {
      final start = screen.indexOf('return StreamBuilder<ArcSavedLoadout?>(');
      expect(start, greaterThan(0));
      final end = screen.indexOf('builder: (context, loadoutSnapshot)', start);
      expect(end, greaterThan(start));
      final header = screen.substring(start, end);
      expect(header, contains('stream: _favouriteLoadoutStream,'));
      expect(header, isNot(contains('key:')));
      expect(screen, isNot(contains('_favouriteLoadoutRevision')));

      // The existing Operations repository uses a single-subscription stream.
      // Recreating the nested StreamBuilder would re-listen and throw at runtime.
      final operations = File(
        'lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          r'StreamController<ArcOperationsUserState>\s*\(',
        ).hasMatch(operations),
        isTrue,
      );
    },
  );

  testWidgets('PASS27 R7 refresh keeps the existing Operations subscription', (
    tester,
  ) async {
    // A synchronous controller removes frame/microtask timing ambiguity. The
    // regression under test is whether operations.stream gets listened to
    // *again* after the favourite stream is replaced, not the event schedule.
    var listenCount = 0;
    var cancelCount = 0;
    final operations = StreamController<int>(
      sync: true,
      onListen: () {
        listenCount++;
      },
      onCancel: () {
        cancelCount++;
      },
    );
    // The favourite streams need no manual teardown. Closing a single-
    // subscription controller after StreamBuilder cancelled its listener can
    // yield a close() future that never completes (the R5 test timeout).
    final favouriteStream = ValueNotifier<Stream<int>>(Stream<int>.value(1));

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<Stream<int>>(
          valueListenable: favouriteStream,
          builder: (context, stream, child) => StreamBuilder<int>(
            stream: stream,
            builder: (context, favouriteSnapshot) => StreamBuilder<int>(
              stream: operations.stream,
              builder: (context, operationsSnapshot) =>
                  Text('operations=${operationsSnapshot.data ?? 0}'),
            ),
          ),
        ),
      ),
    );

    expect(listenCount, 1);
    expect(cancelCount, 0);
    expect(operations.hasListener, isTrue);
    operations.add(1);
    await tester.pump();
    expect(find.text('operations=1'), findsOneWidget);

    // This reproduces the PASS27 refresh mechanism without changing a key on
    // the parent StreamBuilder. A forced key would unmount the child and
    // attempt a second, illegal listen to the single-subscription stream.
    favouriteStream.value = Stream<int>.value(2);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      listenCount,
      1,
      reason: 'Refreshing favourite must not subscribe to Operations again.',
    );
    expect(
      cancelCount,
      0,
      reason: 'Operations should not be torn down during a favourite refresh.',
    );
    expect(operations.hasListener, isTrue);

    operations.add(2);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('operations=2'), findsOneWidget);
    expect(listenCount, 1);

    // Unmount first. In testWidgets fake async, awaiting close() while the
    // StreamBuilder still owns the listener can deadlock until another pump,
    // which cannot run because close() is being awaited (R5/R6 timeout).
    // A single-subscription controller needs no close once its subscriber is
    // cancelled; there are no timers or external resources in this fixture.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      cancelCount,
      1,
      reason: 'Operations must cancel on normal teardown.',
    );
    expect(operations.hasListener, isFalse);
    favouriteStream.dispose();
  });

  test(
    'PASS27 retains the engine saved document status and original slot identity',
    () {
      final now = DateTime.utc(2026, 10, 28);
      final saved = ArcSavedLoadout.fromMap('favourite-loadout', {
        'name': 'My Sony loadout',
        'category': 'saved',
        'playStyle': 'balanced',
        'augment': 'Survivor',
        'shield': 'Medium Shield',
        'primaryWeapon': 'Anvil',
        'secondaryWeapon': 'Stitcher',
        'primaryAttachments': <String>[],
        'secondaryAttachments': <String>[],
        'quickUse': <String>[],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: <ArcSavedLoadout>[saved],
      );
      final status = state.snapshots.singleWhere(
        (entry) => entry.label == 'Favourite Loadout',
      );
      expect(status.value, 'Saved');
      expect(status.detail, 'My Sony loadout');
    },
  );
}
