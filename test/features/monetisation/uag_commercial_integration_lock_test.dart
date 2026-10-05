import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('admin console exposes owner promotion controls', () {
    final source = read('lib/screens/admin_console_screen.dart');

    expect(source, contains('uag_commercial_campaign_admin_panel.dart'));
    expect(source, contains('const UagCommercialCampaignAdminPanel()'));
  });

  test('Founding Premium restore copy matches locked £44.99 annual rate', () {
    final source = read(
      'lib/features/monetisation/widgets/uag_beta_founder_admin_panel.dart',
    );

    expect(source, contains('RESTORE £44.99 FOUNDER RATE'));
    expect(source, isNot(contains('RESTORE £29.99 FOUNDER RATE')));
  });

  test(
    'usage watcher merges monthly core actions with weekly legacy actions',
    () {
      final source = read(
        'lib/features/monetisation/services/uag_entitlement_service.dart',
      );

      expect(source, contains('watchCurrentUsage()'));
      expect(source, contains("base.doc(_currentMonthKey()).snapshots()"));
      expect(source, contains("base.doc(_currentWeekKey()).snapshots()"));
      expect(
        source,
        contains('UagCommercialEconomy.usesMonthlyAllowance(action)'),
      );
    },
  );
}
