import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    UagSessionGateController.resetRuntimeForTest();
  });

  test(
    'legacy persisted session is rejected until explicit login reissues it',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'uag_keep_signed_in': true,
        'uag_session_allowed_uid': 'legacy-user',
      });

      expect(
        await UagSessionGateController.isSessionAllowed('legacy-user'),
        isFalse,
      );
    },
  );

  test('explicit authenticated keep-signed-in session is accepted', () async {
    await UagSessionGateController.markAuthenticated(
      uid: 'user-1',
      keepSignedIn: true,
    );

    UagSessionGateController.resetRuntimeForTest();

    expect(await UagSessionGateController.isSessionAllowed('user-1'), isTrue);
  });

  test('explicit login without keep signed in is runtime-only', () async {
    await UagSessionGateController.markAuthenticated(
      uid: 'user-2',
      keepSignedIn: false,
    );

    expect(await UagSessionGateController.isSessionAllowed('user-2'), isTrue);

    UagSessionGateController.resetRuntimeForTest();

    expect(await UagSessionGateController.isSessionAllowed('user-2'), isFalse);
  });

  test('persisted session never authorises a different Firebase uid', () async {
    await UagSessionGateController.markAuthenticated(
      uid: 'user-3',
      keepSignedIn: true,
    );

    UagSessionGateController.resetRuntimeForTest();

    expect(
      await UagSessionGateController.isSessionAllowed('other-user'),
      isFalse,
    );
  });
  test(
    'account deletion clears remembered login and biometric device state',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'uag_keep_signed_in': true,
        'uag_session_allowed_uid': 'deleted-user',
        'uag_session_contract_version': 2,
        'uag_biometric_login_enabled': true,
        'uag_biometric_allowed_uid': 'deleted-user',
        'uag_last_login_email': 'deleted@example.com',
        'uag_remember_email': true,
      });

      await UagSessionGateController.clearAccountAndDeviceState();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('uag_keep_signed_in'), isFalse);
      expect(prefs.getString('uag_session_allowed_uid'), isNull);
      expect(prefs.getInt('uag_session_contract_version'), isNull);
      expect(prefs.getBool('uag_biometric_login_enabled'), isFalse);
      expect(prefs.getString('uag_biometric_allowed_uid'), isNull);
      expect(prefs.getString('uag_last_login_email'), isNull);
      expect(prefs.getBool('uag_remember_email'), isFalse);
      expect(
        await UagSessionGateController.isSessionAllowed('deleted-user'),
        isFalse,
      );
    },
  );
}
