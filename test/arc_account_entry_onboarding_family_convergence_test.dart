import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_account_journey_bar.dart';

void main() {
  test('account entry family uses the shared account journey bar', () {
    final auth = File('lib/build/auth/auth_screen.dart').readAsStringSync();
    final onboarding = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();
    final agreement = File(
      'lib/features/onboarding/screens/uag_raider_agreement_screen.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart',
    ).readAsStringSync();

    expect(auth, contains('stage: ArcAccountJourneyStage.access'));
    expect(onboarding, contains('stage: ArcAccountJourneyStage.onboarding'));
    expect(agreement, contains('stage: ArcAccountJourneyStage.onboarding'));
    expect(profile, contains('stage: ArcAccountJourneyStage.profile'));
    expect(agreement, contains('ArcRaidersScreenShell('));
    expect(agreement, contains('showAdBanner: false'));
  });

  test('account journey convergence preserves routing and save authority', () {
    final auth = File('lib/build/auth/auth_screen.dart').readAsStringSync();
    final onboarding = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();
    final agreement = File(
      'lib/features/onboarding/screens/uag_raider_agreement_screen.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart',
    ).readAsStringSync();
    final bar = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_account_journey_bar.dart',
    ).readAsStringSync();

    expect(auth, contains('AppEntryGate.routeName'));
    expect(
      onboarding,
      contains('const ArcProfileSetupScreen(firstRunFlow: true)'),
    );
    expect(onboarding, isNot(contains('_completionDestination')));
    expect(agreement, contains('Navigator.of(context).pop(true)'));
    expect(profile, contains('await _repository.saveProfile(profile);'));
    expect(profile, contains('Navigator.of(context).pop(true)'));

    expect(bar, isNot(contains('Navigator.')));
    expect(bar, isNot(contains('onTap:')));
    expect(bar, isNot(contains('onPressed:')));
  });

  testWidgets('account journey bar is responsive at Sony-class mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: ArcAccountJourneyBar(
              stage: ArcAccountJourneyStage.onboarding,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACCESS'), findsOneWidget);
    expect(find.text('INITIALISE'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
