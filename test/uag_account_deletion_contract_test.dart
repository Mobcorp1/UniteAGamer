import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_data_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Privacy & Data is directly discoverable and routed', () {
    final account = ArcCompactNavigationCatalog.groups.singleWhere(
      (group) => group.label == 'ACCOUNT & UAG',
    );
    final privacy = account.items.singleWhere(
      (item) => item.label == 'Privacy & Data',
    );

    expect(privacy.routeName, UagPrivacyDataScreen.routeName);
    expect(UagPrivacyDataScreen.routeName, '/privacy-data');

    final mainSource = read('lib/main.dart');
    expect(
      mainSource,
      contains('features/legal/screens/privacy_data_screen.dart'),
    );
    expect(mainSource, contains('case UagPrivacyDataScreen.routeName:'));
    expect(
      mainSource,
      contains('builder: (_) => const UagPrivacyDataScreen()'),
    );
  });

  test('in-app deletion requires password, acknowledgement and DELETE', () {
    final screen = read('lib/features/legal/screens/privacy_data_screen.dart');
    final service = read(
      'lib/features/legal/data/uag_account_deletion_service.dart',
    );

    expect(screen, contains("_confirmationController.text.trim() == 'DELETE'"));
    expect(screen, contains('_understands'));
    expect(screen, contains('Current password'));
    expect(screen, contains('Deleting UAG does not cancel'));
    expect(service, contains('reauthenticateWithCredential'));
    expect(service, contains('EmailAuthProvider.credential'));
    expect(service, contains("'confirmation': 'DELETE'"));
    expect(service, contains('clearAccountAndDeviceState'));
    expect(service, contains('await _auth.signOut()'));
    expect(service, isNot(contains('FirebaseAuthException.toString()')));
  });

  test(
    'backend owns deletion, retention minimisation and resurrection guard',
    () {
      final lifecycle = read('functions/account_deletion.js');
      final index = read('functions/index.js');

      expect(lifecycle, contains('account_deletion_tombstones'));
      expect(lifecycle, contains("await auth.deleteUser(uid)"));
      expect(lifecycle, contains("`users/\${uid}/`"));
      expect(lifecycle, contains("`legal_exports/\${uid}/`"));
      expect(lifecycle, contains("'arc_raider_reports'"));
      expect(lifecycle, contains("'arc_raider_contracts'"));
      expect(lifecycle, contains('DELETED_RAIDER_LABEL'));
      expect(lifecycle, contains("'supporter_entitlements'"));
      expect(lifecycle, contains("['uag_ids', 'uid']"));
      expect(index, contains('exports.deleteUagAccount = onCall'));
      expect(index, contains('preventDeletedAccountResurrection'));
      expect(index, contains('preventDeletedSupporterEntitlementResurrection'));
    },
  );

  test('public policy and support point users to the live in-app route', () {
    final privacy = read(
      'lib/features/legal/screens/privacy_policy_screen.dart',
    );
    final support = read('lib/features/legal/screens/support_screen.dart');

    expect(privacy, contains('Privacy & Data > Delete My Account'));
    expect(support, contains('Privacy & Data > Delete My Account'));
    expect(
      privacy,
      contains('https://unite-a-gamer.web.app/support#account-deletion'),
    );
    expect(
      support,
      contains('https://unite-a-gamer.web.app/support#account-deletion'),
    );
    expect(privacy, contains('Subscription cancellation is a separate'));
  });
}
