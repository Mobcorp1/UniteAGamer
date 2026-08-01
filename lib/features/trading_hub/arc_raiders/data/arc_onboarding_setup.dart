import 'package:cloud_firestore/cloud_firestore.dart';

String normalizeArcOnboardingEmail(String value) => value.trim().toLowerCase();

String? validateArcOnboardingEmail(String value) {
  final email = normalizeArcOnboardingEmail(value);
  if (email.isEmpty) return 'Enter an email address.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validateArcOnboardingConfirmEmail({
  required String email,
  required String confirmEmail,
}) {
  final error = validateArcOnboardingEmail(confirmEmail);
  if (error != null) return error;
  if (normalizeArcOnboardingEmail(email) !=
      normalizeArcOnboardingEmail(confirmEmail)) {
    return 'Email addresses do not match.';
  }
  return null;
}

String? validateArcOnboardingPassword(String value) {
  final password = value.trim();
  if (password.length < 6) return 'Use at least 6 characters.';
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Add at least one capital letter.';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Add at least one number.';
  }
  return null;
}

String? validateArcOnboardingConfirmPassword({
  required String password,
  required String confirmPassword,
}) {
  final error = validateArcOnboardingPassword(confirmPassword);
  if (error != null) return error;
  if (password.trim() != confirmPassword.trim()) {
    return 'Passwords do not match.';
  }
  return null;
}

String? validateArcRiderName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Enter a Rider name.';
  if (trimmed.length < 3) return 'Use at least 3 characters.';
  if (trimmed.length > 24) return 'Use no more than 24 characters.';
  if (!RegExp(r"^[A-Za-z0-9 _.'-]+$").hasMatch(trimmed)) {
    return 'Use letters, numbers, spaces, apostrophes, dots or hyphens.';
  }
  return null;
}

Map<String, dynamic> buildArcOnboardingAccountCreationPayload({
  required String email,
  required String riderName,
}) {
  final normalizedEmail = normalizeArcOnboardingEmail(email);
  final normalizedName = riderName.trim();

  if (validateArcOnboardingEmail(normalizedEmail) != null) {
    throw ArgumentError.value(email, 'email', 'Invalid email address');
  }
  if (validateArcRiderName(normalizedName) != null) {
    throw ArgumentError.value(riderName, 'riderName', 'Invalid Rider name');
  }

  return <String, dynamic>{
    'email': normalizedEmail,
    'displayName': normalizedName,
    'uagName': normalizedName,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'onboardingComplete': false,
    'arcMandatoryOnboardingComplete': false,
    'modules': <String, dynamic>{'trader': true},
    'visibleInSearch': true,
    'basicProfile': <String, dynamic>{
      'displayName': normalizedName,
      'email': normalizedEmail,
      'bio': '',
      'games': <String>[],
      'platforms': <String>[],
    },
    'traderProfile': <String, dynamic>{
      'uagName': normalizedName,
      'uagId': '',
      'embarkId': '',
    },
    'arcOnboarding': <String, dynamic>{
      'version': 4,
      'accountCreatedDuringOnboarding': true,
      'accountCreatedAt': FieldValue.serverTimestamp(),
      'flow': <String>['account', 'legal', 'primaryGoal', 'blueprintSetup'],
    },
  };
}

Map<String, dynamic> buildArcOnboardingCompletionPayload({
  required String riderName,
  required String primaryGoal,
  required String blueprintSetupMode,
  required String recommendedFirstSystem,
  required Map<String, dynamic> legalAccepted,
  bool accountCreatedDuringOnboarding = false,
}) {
  final normalizedName = riderName.trim();
  if (validateArcRiderName(normalizedName) != null) {
    throw ArgumentError.value(riderName, 'riderName', 'Invalid Rider name');
  }

  return <String, dynamic>{
    'displayName': normalizedName,
    'onboardingComplete': true,
    'arcMandatoryOnboardingComplete': true,
    'updatedAt': FieldValue.serverTimestamp(),
    'arcOnboarding': <String, dynamic>{
      'version': 4,
      'completedAt': FieldValue.serverTimestamp(),
      'flow': <String>[
        accountCreatedDuringOnboarding ? 'account' : 'identity',
        'legal',
        'primaryGoal',
        'blueprintSetup',
      ],
      'accountCreatedDuringOnboarding': accountCreatedDuringOnboarding,
      'riderName': normalizedName,
      'primaryGoal': primaryGoal,
      'blueprintSetupMode': blueprintSetupMode,
      'recommendedFirstSystem': recommendedFirstSystem,
      'progressiveSetupEnabled': true,
      'legalAccepted': legalAccepted,
      'deferredSetup': <String>[
        'profileDetails',
        'availability',
        'communicationStyle',
        'tradePreferences',
        'notificationPreferences',
      ],
    },
  };
}
