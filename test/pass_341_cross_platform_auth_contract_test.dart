import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'mandatory onboarding honours canonical and migrated legacy completion',
    () {
      expect(
        arcNeedsMandatoryOnboarding(<String, dynamic>{
          'onboardingComplete': true,
        }),
        isFalse,
      );
      expect(
        arcNeedsMandatoryOnboarding(<String, dynamic>{
          'arcMandatoryOnboardingComplete': true,
        }),
        isFalse,
      );
      expect(arcNeedsMandatoryOnboarding(<String, dynamic>{}), isTrue);
    },
  );

  test('stored keep-signed-in preference is readable', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'uag_keep_signed_in': true,
    });
    expect(await UagSessionGateController.keepSignedInPreference(), isTrue);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'uag_keep_signed_in': false,
    });
    expect(await UagSessionGateController.keepSignedInPreference(), isFalse);
  });

  test('PASS 341 source contracts remain wired after PASS 342', () {
    final appEntry = File(
      'lib/screens/build/app_entry_gate.dart',
    ).readAsStringSync();
    final authLanding = File(
      'lib/screens/build/auth/auth_landing_screen.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();
    final web = File('web/index.html').readAsStringSync();

    expect(
      appEntry,
      contains('UagSessionGateController.isSessionAllowed(user.uid)'),
    );
    expect(
      appEntry,
      contains("data['arcMandatoryOnboardingComplete'] == true"),
    );
    expect(appEntry, contains("data['onboardingComplete'] == true"));
    expect(authLanding, contains('const AuthScreen(initialIsLogin: false)'));
    expect(onboarding, contains('markAuthenticatedWithStoredPreference'));
    expect(web, contains('interactive-widget=resizes-content'));
    expect(web, isNot(contains('flt-glass-pane,')));
    expect(web, isNot(contains('body {\n      position: fixed;')));
  });
}
