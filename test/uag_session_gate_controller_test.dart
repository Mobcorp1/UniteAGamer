import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';

void main() {
  group('UagSessionGateController onboarding handoff', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await UagSessionGateController.clearSession();
    });

    test('allows a new onboarding auth handoff before prefs are stored', () async {
      UagSessionGateController.markOnboardingAuthHandshakeStarted();

      expect(
        await UagSessionGateController.isSessionAllowed('new-raider'),
        isTrue,
      );
    });

    test('does not allow an expired onboarding auth handoff', () async {
      UagSessionGateController.markOnboardingAuthHandshakeStarted(
        window: const Duration(milliseconds: -1),
      );

      expect(
        await UagSessionGateController.isSessionAllowed('new-raider'),
        isFalse,
      );
    });

    test('keeps the current runtime session allowed without remember me', () async {
      await UagSessionGateController.markAuthenticated(
        uid: 'new-raider',
        keepSignedIn: false,
      );

      expect(
        await UagSessionGateController.isSessionAllowed('new-raider'),
        isTrue,
      );
    });
  });
}
