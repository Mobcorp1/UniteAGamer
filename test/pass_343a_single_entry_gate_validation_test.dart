import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 343A production root uses AppEntryGate directly', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(
      mainSource,
      contains(
        'home: widget.testMode ? const AuthLandingScreen() : const AppEntryGate(),',
      ),
    );

    expect(mainSource, isNot(contains('home: StreamBuilder<User?>(')));
  });

  test('PASS 343A keeps AppEntryGate as auth onboarding routing authority', () {
    final gateSource = File(
      'lib/screens/build/app_entry_gate.dart',
    ).readAsStringSync();

    expect(
      gateSource,
      contains('stream: FirebaseAuth.instance.authStateChanges()'),
    );
    expect(gateSource, contains('return const AuthLandingScreen();'));
    expect(
      gateSource,
      contains('return const ArcMandatoryOnboardingScreen();'),
    );
    expect(gateSource, contains('return const ArcCommandCentreScreen();'));
  });

  test(
    'PASS 343A keeps test mode Firebase independent at MaterialApp home',
    () {
      final mainSource = File('lib/main.dart').readAsStringSync();

      expect(
        mainSource,
        contains(
          'widget.testMode ? const AuthLandingScreen() : const AppEntryGate()',
        ),
      );
    },
  );
}
