import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';

class ArcProfileCompletionMissingField {
  const ArcProfileCompletionMissingField({
    required this.id,
    required this.label,
    required this.routeName,
    required this.section,
  });

  final String id;
  final String label;
  final String routeName;
  final String section;
}

class ArcProfileCompletionResult {
  const ArcProfileCompletionResult({required this.missingFields});

  static const completeResult = ArcProfileCompletionResult(
    missingFields: <ArcProfileCompletionMissingField>[],
  );

  final List<ArcProfileCompletionMissingField> missingFields;

  bool get complete => missingFields.isEmpty;

  List<String> get missingFieldIds =>
      missingFields.map((field) => field.id).toList(growable: false);

  List<String> get missingFieldLabels =>
      missingFields.map((field) => field.label).toList(growable: false);

  String? get resumeRouteName =>
      missingFields.isEmpty ? null : missingFields.first.routeName;

  String? get resumeSection =>
      missingFields.isEmpty ? null : missingFields.first.section;

  bool get identityComplete => !missingFieldIds.any(
    (id) => const <String>{
      'embarkId',
      'archetypes',
      'communicationStyle',
      'squadIntent',
      'socialSessionState',
    }.contains(id),
  );

  String get missingSummary {
    if (complete) return 'Profile complete';
    if (missingFields.length == 1) return missingFields.first.label;
    return missingFieldLabels.join(', ');
  }
}

class ArcProfileCompletionEvaluator {
  const ArcProfileCompletionEvaluator();

  static const profileSetupRouteName = '/trading-hub/arc-raiders/profile/setup';
  static const availabilityRouteName =
      '/trading-hub/arc-raiders/profile/availability';
  static const onboardingRouteName = '/trading-hub/arc-raiders/onboarding';

  ArcProfileCompletionResult evaluate({
    Map<String, dynamic> userData = const <String, dynamic>{},
    Map<String, dynamic> profileData = const <String, dynamic>{},
    ArcAvailability? availability,
  }) {
    final basicProfile = _map(userData['basicProfile']);
    final traderProfile = _map(userData['traderProfile']);
    final arcOnboarding = _map(userData['arcOnboarding']);
    final missing = <ArcProfileCompletionMissingField>[];

    final embarkId = _firstString(<dynamic>[
      profileData['embarkId'],
      traderProfile['embarkId'],
      basicProfile['embarkId'],
      arcOnboarding['embarkId'],
      userData['embarkId'],
    ]);
    if (!_hasText(embarkId)) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'embarkId',
          label: 'Embark ID',
          routeName: profileSetupRouteName,
          section: 'identity',
        ),
      );
    }

    final archetypes = ArcPlayerArchetypeCatalog.normalizeLabels(<dynamic>[
      ..._stringList(profileData['archetypes']),
      ..._stringList(traderProfile['archetypes']),
      ..._stringList(basicProfile['archetypes']),
      ..._stringList(arcOnboarding['archetypes']),
      profileData['playStyle'],
      traderProfile['playStyle'],
      basicProfile['playStyle'],
      arcOnboarding['playStyle'],
    ], includeDefaultWhenEmpty: false);
    if (archetypes.isEmpty) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'archetypes',
          label: 'At least one archetype',
          routeName: profileSetupRouteName,
          section: 'archetypes',
        ),
      );
    }

    if (!_hasText(
      _firstString(<dynamic>[
        profileData['communicationStyle'],
        traderProfile['communicationStyle'],
        basicProfile['communicationStyle'],
      ]),
    )) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'communicationStyle',
          label: 'Communication style',
          routeName: profileSetupRouteName,
          section: 'communication',
        ),
      );
    }

    if (!_hasText(
      _firstString(<dynamic>[
        profileData['squadIntent'],
        traderProfile['squadIntent'],
        basicProfile['squadIntent'],
        arcOnboarding['squadIntent'],
      ]),
    )) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'squadIntent',
          label: 'Squad intent',
          routeName: profileSetupRouteName,
          section: 'squad',
        ),
      );
    }

    final socialEnergy = _firstString(<dynamic>[
      profileData['socialEnergy'],
      traderProfile['socialEnergy'],
      basicProfile['socialEnergy'],
      arcOnboarding['socialEnergy'],
    ]);
    final sessionIntent = _firstString(<dynamic>[
      profileData['sessionIntent'],
      traderProfile['sessionIntent'],
      basicProfile['sessionIntent'],
      arcOnboarding['sessionIntent'],
    ]);
    if (!_hasText(socialEnergy) || !_hasText(sessionIntent)) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'socialSessionState',
          label: 'Session and social state',
          routeName: profileSetupRouteName,
          section: 'session',
        ),
      );
    }

    if (!_availabilityComplete(
      availability: availability,
      userData: userData,
      profileData: profileData,
      arcOnboarding: arcOnboarding,
    )) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'availability',
          label: 'Availability',
          routeName: availabilityRouteName,
          section: 'availability',
        ),
      );
    }

    if (!_onboardingComplete(userData, arcOnboarding)) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'onboarding',
          label: 'Onboarding completion',
          routeName: onboardingRouteName,
          section: 'onboarding',
        ),
      );
    }

    if (!_legalComplete(userData, arcOnboarding)) {
      missing.add(
        const ArcProfileCompletionMissingField(
          id: 'legal',
          label: 'Legal acceptance',
          routeName: onboardingRouteName,
          section: 'legal',
        ),
      );
    }

    if (missing.isEmpty) return ArcProfileCompletionResult.completeResult;
    return ArcProfileCompletionResult(
      missingFields: List.unmodifiable(missing),
    );
  }

  static bool hasActiveAvailability(ArcAvailability availability) {
    return availability.weeks.any(
      (week) => week.slots.any((slot) => slot.enabled),
    );
  }

  static bool _availabilityComplete({
    required ArcAvailability? availability,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> profileData,
    required Map<String, dynamic> arcOnboarding,
  }) {
    if (availability != null && hasActiveAvailability(availability)) {
      return true;
    }
    if (_stringList(profileData['availabilityDayKeys']).isNotEmpty ||
        _stringList(userData['availabilityDayKeys']).isNotEmpty) {
      return true;
    }
    final userTraderProfile = _map(userData['traderProfile']);
    final profileTraderProfile = _map(profileData['traderProfile']);
    if (profileData['availabilityCompleted'] == true ||
        userData['availabilityCompleted'] == true ||
        userTraderProfile['availabilityCompleted'] == true ||
        profileTraderProfile['availabilityCompleted'] == true) {
      return true;
    }
    final completedSteps = _map(arcOnboarding['completedSteps']);
    return completedSteps['availability'] == true;
  }

  static bool _onboardingComplete(
    Map<String, dynamic> userData,
    Map<String, dynamic> arcOnboarding,
  ) {
    return userData['arcMandatoryOnboardingComplete'] == true ||
        userData['onboardingComplete'] == true ||
        arcOnboarding['completedAt'] != null;
  }

  static bool _legalComplete(
    Map<String, dynamic> userData,
    Map<String, dynamic> arcOnboarding,
  ) {
    final legalAccepted = _map(userData['legalAccepted']);
    final appLegalComplete =
        legalAccepted['termsAccepted'] == true &&
        legalAccepted['privacyAccepted'] == true;

    final onboardingLegal = _map(arcOnboarding['legalAccepted']);
    final completedSteps = _map(arcOnboarding['completedSteps']);
    final policies = _map(onboardingLegal['policies']);
    final agePolicy = _map(policies['age_restriction_policy']);
    final ageRequired =
        onboardingLegal.containsKey('ageConfirmationAccepted') ||
        policies.containsKey('age_restriction_policy') ||
        completedSteps.containsKey('ageConfirmation');
    final ageComplete =
        !ageRequired ||
        onboardingLegal['ageConfirmationAccepted'] == true ||
        agePolicy['accepted'] == true ||
        completedSteps['ageConfirmation'] == true;
    final onboardingLegalComplete =
        (onboardingLegal['traderCodeAccepted'] == true ||
            completedSteps['traderCode'] == true) &&
        (onboardingLegal['termsOfServiceAccepted'] == true ||
            completedSteps['termsOfService'] == true) &&
        (onboardingLegal['dataSecurityAccepted'] == true ||
            completedSteps['dataSecurity'] == true) &&
        ageComplete;

    return appLegalComplete || onboardingLegalComplete;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static bool _hasText(String value) => value.trim().isNotEmpty;

  static String _firstString(Iterable<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value != null && value is! Iterable && value is! Map) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return <String>[value.trim()];
    }
    return const <String>[];
  }
}
