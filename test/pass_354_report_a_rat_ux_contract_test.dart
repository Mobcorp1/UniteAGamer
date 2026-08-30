import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final screen = File(
    'lib/features/trust/screens/arc_raider_contracts_screen.dart',
  ).readAsStringSync();

  test('Report a Rat uses one screen username field', () {
    expect(screen, contains("title: 'Report a Rat'"));
    expect(screen, contains("labelText: 'Screen username *'"));
    expect(screen, contains("key: const Key('report-rat-screen-username')"));
    expect(screen, isNot(contains("labelText: 'Embark ID *'")));
    expect(screen, isNot(contains("'Raider display name *'")));
    expect(screen, isNot(contains("'Game identity / platform ID'")));
  });

  test('Report a Rat no longer exposes a thirteen-question wizard', () {
    expect(screen, contains('static const _stageCount = 5;'));
    expect(screen, isNot(contains(r'QUESTION ${step + 1} OF 13')));
    expect(screen, isNot(contains('Previous question')));
  });

  test('Continue is deterministic and validates on press', () {
    expect(screen, contains("key: const Key('report-rat-continue')"));
    expect(screen, contains('onPressed: _continue'));
    expect(screen, contains('bool _validateStage()'));
    expect(screen, contains("Enter the Rat\\'s screen username."));
  });

  test('report identity persists screen username without duplicate identity UI', () {
    expect(
      screen,
      contains('final reportedScreenUsername = screenUsername.text.trim();'),
    );
    expect(screen, contains('targetDisplayName: reportedScreenUsername'));
    expect(screen, contains("targetGameIdentity: ''"));
  });

  test('report workflow includes incident location contract and review stages', () {
    for (final label in <String>[
      "'Rat'",
      "'Incident'",
      "'Where & when'",
      "'Contract'",
      "'Review'",
    ]) {
      expect(screen, contains(label));
    }
  });
}
