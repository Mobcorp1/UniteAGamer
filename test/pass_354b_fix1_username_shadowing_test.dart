import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('screen username controller is not shadowed by submitted value', () {
    final source = File(
      'lib/features/trust/screens/arc_raider_contracts_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains('final screenUsername = screenUsername.text.trim();')),
    );
    expect(
      source,
      contains('final reportedScreenUsername = screenUsername.text.trim();'),
    );
    expect(
      source,
      contains('targetDisplayName: reportedScreenUsername'),
    );
  });
}
