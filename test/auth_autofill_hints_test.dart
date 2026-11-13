import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/build/auth/uag_auth_autofill.dart';

void main() {
  group('UagAuthAutofill', () {
    test(
      'login credentials expose browser-recognised email and password hints',
      () {
        expect(UagAuthAutofill.loginEmail, contains(AutofillHints.username));
        expect(UagAuthAutofill.loginEmail, contains(AutofillHints.email));
        expect(UagAuthAutofill.loginPassword, [AutofillHints.password]);
      },
    );

    test(
      'registration uses new-password hints without weakening reset fields',
      () {
        expect(
          UagAuthAutofill.registrationEmail,
          contains(AutofillHints.email),
        );
        expect(UagAuthAutofill.newPassword, [AutofillHints.newPassword]);
        expect(UagAuthAutofill.resetEmail, contains(AutofillHints.email));
        expect(
          UagAuthAutofill.resetEmail,
          isNot(contains(AutofillHints.password)),
        );
      },
    );
  });
}
