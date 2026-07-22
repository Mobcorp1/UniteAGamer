import 'package:flutter/services.dart';

class UagAuthAutofill {
  const UagAuthAutofill._();

  static const Iterable<String> displayName = <String>[AutofillHints.name];

  static const Iterable<String> loginEmail = <String>[
    AutofillHints.username,
    AutofillHints.email,
  ];

  static const Iterable<String> registrationEmail = <String>[
    AutofillHints.email,
    AutofillHints.username,
  ];

  static const Iterable<String> loginPassword = <String>[
    AutofillHints.password,
  ];

  static const Iterable<String> newPassword = <String>[
    AutofillHints.newPassword,
  ];

  static const Iterable<String> resetEmail = <String>[
    AutofillHints.username,
    AutofillHints.email,
  ];
}
