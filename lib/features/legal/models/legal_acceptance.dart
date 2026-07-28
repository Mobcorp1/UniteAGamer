class LegalAcceptance {
  final bool termsAccepted;
  final int termsVersion;
  final bool privacyAccepted;
  final int privacyVersion;
  final bool fanDisclaimerAccepted;
  final int fanDisclaimerVersion;
  final Map<String, LegalPolicyAcceptance> policies;

  LegalAcceptance({
    required this.termsAccepted,
    required this.termsVersion,
    required this.privacyAccepted,
    required this.privacyVersion,
    required this.fanDisclaimerAccepted,
    required this.fanDisclaimerVersion,
    this.policies = const <String, LegalPolicyAcceptance>{},
  });

  factory LegalAcceptance.fromMap(Map<String, dynamic>? map) {
    map ??= {};
    return LegalAcceptance(
      termsAccepted: map['termsAccepted'] ?? false,
      termsVersion: map['termsVersion'] ?? 0,
      privacyAccepted: map['privacyAccepted'] ?? false,
      privacyVersion: map['privacyVersion'] ?? 0,
      fanDisclaimerAccepted: map['fanDisclaimerAccepted'] ?? false,
      fanDisclaimerVersion: map['fanDisclaimerVersion'] ?? 0,
      policies: _readPolicies(map['policies']),
    );
  }

  bool hasAcceptedPolicy(String policyId, int version) {
    final policy = policies[policyId];
    return policy != null && policy.accepted && policy.version >= version;
  }
}

class LegalPolicyAcceptance {
  const LegalPolicyAcceptance({
    required this.accepted,
    required this.version,
    required this.mandatory,
    required this.optionalConsent,
  });

  final bool accepted;
  final int version;
  final bool mandatory;
  final bool optionalConsent;
}

Map<String, LegalPolicyAcceptance> _readPolicies(dynamic value) {
  if (value is! Map) return const <String, LegalPolicyAcceptance>{};
  final out = <String, LegalPolicyAcceptance>{};
  for (final entry in value.entries) {
    final data = entry.value;
    if (data is! Map) continue;
    out[entry.key.toString()] = LegalPolicyAcceptance(
      accepted: data['accepted'] == true,
      version: (data['version'] as num?)?.toInt() ?? 0,
      mandatory: data['mandatory'] != false,
      optionalConsent: data['optionalConsent'] == true,
    );
  }
  return out;
}
