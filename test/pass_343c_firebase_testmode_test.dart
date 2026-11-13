import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 343C operations repository is lazy in app state', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('ArcOperationsRepository? _operationsRepository;'));
    expect(
      source,
      isNot(
        contains(
          'final ArcOperationsRepository _operationsRepository = ArcOperationsRepository();',
        ),
      ),
    );
  });

  test('PASS 343C production init creates operations repository', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('_operationsRepository = ArcOperationsRepository();'),
    );
    expect(source, contains('if (!widget.testMode) {'));
  });

  test('PASS 343C preserves single root AppEntryGate', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains(
        'home: widget.testMode ? const AuthLandingScreen() : const AppEntryGate(),',
      ),
    );
    expect(source, isNot(contains('home: StreamBuilder<User?>(')));
  });
}
