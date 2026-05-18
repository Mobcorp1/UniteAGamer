class LegalAcceptance {
  final bool termsAccepted;
  final int termsVersion;
  final bool privacyAccepted;
  final int privacyVersion;
  final bool fanDisclaimerAccepted;
  final int fanDisclaimerVersion;

  LegalAcceptance({
    required this.termsAccepted,
    required this.termsVersion,
    required this.privacyAccepted,
    required this.privacyVersion,
    required this.fanDisclaimerAccepted,
    required this.fanDisclaimerVersion,
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
    );
  }
}
