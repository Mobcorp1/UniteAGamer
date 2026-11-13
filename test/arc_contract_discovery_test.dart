import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_contract_projections.dart';
import 'package:uag_arc_raiders_hub/features/trust/widgets/arc_contract_discovery.dart';

const item = ArcContractDiscoveryItem(
  id: 'c',
  targetDisplayName: 'Raider Alpha',
  category: 'scam',
  rewardSummary: 'No reward offered',
  mapAffinity: 'UNKNOWN',
  confidence: 'LOW',
  regionMatch: 'UNKNOWN',
  evidenceState: 'VERIFIED',
);
Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));
void main() {
  testWidgets('loading is distinct from confirmed no eligible results', (
    tester,
  ) async {
    final pending = Completer<List<ArcContractDiscoveryItem>>();
    await tester.pumpWidget(
      host(
        ArcContractDiscovery(load: (_) => pending.future, accept: (_) async {}),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('No eligible Contracts match this search.'), findsNothing);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(
      find.text('No eligible Contracts match this search.'),
      findsOneWidget,
    );
  });
  testWidgets('initial repository error is not presented as empty data', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ArcContractDiscovery(
          load: (_) async => throw StateError('offline'),
          accept: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Contracts unavailable. Retry to refresh.'),
      findsOneWidget,
    );
    expect(find.text('No eligible Contracts match this search.'), findsNothing);
  });
  testWidgets(
    'refresh failure retains last usable cards and marks them stale',
    (tester) async {
      var fail = false;
      await tester.pumpWidget(
        host(
          ArcContractDiscovery(
            load: (_) async {
              if (fail) throw StateError('offline');
              return [item];
            },
            accept: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      fail = true;
      await tester.tap(find.text('Refresh contracts'));
      await tester.pumpAndSettle();
      expect(find.text('Raider Alpha'), findsOneWidget);
      expect(find.text('Showing the last loaded Contracts.'), findsOneWidget);
      expect(
        find.text('Contracts unavailable. Retry to refresh.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'search passes text to authority and accepting uses only contract ID',
    (tester) async {
      var search = '', accepted = '';
      await tester.pumpWidget(
        host(
          ArcContractDiscovery(
            load: (value) async {
              search = value;
              return [item];
            },
            accept: (id) async {
              accepted = id;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Alias#123');
      await tester.tap(find.text('Refresh contracts'));
      await tester.pumpAndSettle();
      expect(search, 'Alias#123');
      await tester.ensureVisible(find.text('Accept Contract'));
      await tester.tap(find.text('Accept Contract'));
      await tester.pumpAndSettle();
      expect(accepted, 'c');
    },
  );
  testWidgets('sparse intelligence is explicitly unknown at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        ArcContractDiscovery(load: (_) async => [item], accept: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TARGET ACTIVITY: UNKNOWN'), findsOneWidget);
    expect(find.text('INTELLIGENCE CONFIDENCE: LOW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed acceptance offers retry without claiming success', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ArcContractDiscovery(
          load: (_) async => [item],
          accept: (_) async => throw StateError('blocked'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Accept Contract'));
    await tester.tap(find.text('Accept Contract'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not accept this Contract. Refresh and retry.'),
      findsOneWidget,
    );
    expect(
      find.text('Contract accepted. Continue in Activity → Your hunts.'),
      findsNothing,
    );
  });
  testWidgets('free account status error never claims no account cases', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ArcContractAccountStatus(
          load: () async => throw StateError('offline'),
          challenge: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Account cases unavailable. Retry to refresh.'),
      findsOneWidget,
    );
    expect(find.text('No account cases.'), findsNothing);
  });
  testWidgets(
    'target projection shows status and challenge without operational fields',
    (tester) async {
      final target = ArcContractAccountCase.fromMap({
        'id': 'c',
        'category': 'scam',
        'status': 'available',
        'evidenceState': 'VERIFIED',
        'challengeStatus': 'none',
        'canChallenge': true,
        'hunterUid': 'SECRET_HUNTER',
        'reporterUid': 'SECRET_REPORTER',
        'activityHourBuckets': 'SECRET_WINDOW',
      });
      await tester.pumpWidget(
        host(
          ArcContractAccountStatus(
            load: () async => [target],
            challenge: (_, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.textContaining('SECRET'), findsNothing);
      expect(find.text('SCAM • AVAILABLE'), findsOneWidget);
    },
  );
}
