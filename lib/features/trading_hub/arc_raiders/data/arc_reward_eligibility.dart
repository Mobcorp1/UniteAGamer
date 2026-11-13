class ArcRewardEligibilityResult {
  const ArcRewardEligibilityResult({
    required this.rewardIds,
    required this.reasons,
  });

  final Set<String> rewardIds;
  final Map<String, String> reasons;

  bool get hasRewards => rewardIds.isNotEmpty;
}

class ArcRewardEligibilityEngine {
  const ArcRewardEligibilityEngine();

  ArcRewardEligibilityResult evaluate({
    Map<String, dynamic> userData = const <String, dynamic>{},
    Map<String, dynamic> telemetryData = const <String, dynamic>{},
  }) {
    final rewards = <String>{};
    final reasons = <String, String>{};

    void grant(String rewardId, String reason) {
      rewards.add(rewardId);
      reasons[rewardId] = reason;
    }

    if (_hasAnyFlag(userData, const <String>[
          'closedBetaParticipant',
          'closedBetaAccess',
          'betaAccess',
          'isClosedBetaUser',
        ]) ||
        _hasRole(userData, const <String>['closedBeta', 'betaTester'])) {
      grant('beta_access', 'Closed Beta eligibility flag');
    }

    final loginEvents = _int(telemetryData['loginEvents']);
    if (_hasAnyFlag(userData, const <String>[
          'closedBetaVeteran',
          'betaVeteran',
        ]) ||
        loginEvents >= 10) {
      grant('og_legend', 'Closed Beta veteran proof');
      grant('inner_circle', 'Closed Beta veteran proof');
      grant('beta_command_banner', 'Closed Beta veteran proof');
    }

    if (_hasAnyFlag(userData, const <String>[
          'founder',
          'foundingRaider',
          'earlySupporter',
          'isFounder',
        ]) ||
        _hasRole(userData, const <String>['founder', 'earlySupporter'])) {
      grant('founding_raider', 'Founder or Early Supporter eligibility flag');
    }

    return ArcRewardEligibilityResult(
      rewardIds: Set.unmodifiable(rewards),
      reasons: Map.unmodifiable(reasons),
    );
  }

  bool _hasAnyFlag(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (_bool(data[key])) return true;
    }
    final beta = _map(data['beta']);
    final supporter = _map(data['supporter']);
    for (final key in keys) {
      if (_bool(beta[key]) || _bool(supporter[key])) return true;
    }
    return false;
  }

  bool _hasRole(Map<String, dynamic> data, List<String> expectedRoles) {
    final normalizedExpected = expectedRoles
        .map(_normalize)
        .where((role) => role.isNotEmpty)
        .toSet();
    for (final role in _stringList(data['roles'])) {
      if (normalizedExpected.contains(_normalize(role))) return true;
    }
    for (final role in _stringList(data['arcRoles'])) {
      if (normalizedExpected.contains(_normalize(role))) return true;
    }
    return false;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return <String>[value.trim()];
    }
    return const <String>[];
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'enabled';
    }
    return false;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
