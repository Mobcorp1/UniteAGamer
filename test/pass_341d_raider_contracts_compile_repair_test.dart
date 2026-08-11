import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Raider Contracts encounter controller does not shadow State.context',
    () {
      final source = File(
        'lib/features/trust/screens/arc_raider_contracts_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        isNot(contains('final context = TextEditingController();')),
      );
      expect(
        source,
        contains('final encounterContextController = TextEditingController();'),
      );
      expect(
        source,
        contains('encounterContext: encounterContextController.text'),
      );
      expect(source, contains('encounterContextController,'));
      expect(source, contains("'Extra encounter context',"));

      // Framework BuildContext must remain available to dialogs/snackbars.
      expect(source, contains('context: context'));
      expect(source, contains('ScaffoldMessenger.of(context)'));
    },
  );
}
