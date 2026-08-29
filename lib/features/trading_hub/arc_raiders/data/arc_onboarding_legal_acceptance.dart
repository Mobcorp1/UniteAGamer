import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';

const arcOnboardingLegalAcceptanceVersion = 4;

Map<String, dynamic> buildOnboardingLegalAcceptedMap({
  required bool traderCodeAccepted,
  required bool termsOfServiceAccepted,
  required bool dataSecurityAccepted,
  bool ageConfirmationAccepted = false,
  String flow = 'arcMandatoryOnboarding',
  String? userId,
  String? platform,
  String? appVersion,
}) {
  final accepted = <String, dynamic>{
    'version': arcOnboardingLegalAcceptanceVersion,
    'flow': flow,
    'acceptedAt': FieldValue.serverTimestamp(),
    'traderCodeAccepted': traderCodeAccepted,
    'termsOfServiceAccepted': termsOfServiceAccepted,
    'dataSecurityAccepted': dataSecurityAccepted,
    'ageConfirmationAccepted': ageConfirmationAccepted,
    'policies': <String, dynamic>{
      'trader_code_of_conduct': _policyAcceptance(
        policyId: 'trader_code_of_conduct',
        accepted: traderCodeAccepted,
      ),
      'terms_of_use': _policyAcceptance(
        policyId: 'terms_of_use',
        accepted: termsOfServiceAccepted,
      ),
      'privacy_policy': _policyAcceptance(
        policyId: 'privacy_policy',
        accepted: dataSecurityAccepted,
      ),
      'age_restriction_policy': _policyAcceptance(
        policyId: 'age_restriction_policy',
        accepted: ageConfirmationAccepted,
      ),
    },
  };

  if (userId != null && userId.trim().isNotEmpty) {
    accepted['userId'] = userId.trim();
  }
  if (platform != null && platform.trim().isNotEmpty) {
    accepted['platform'] = platform.trim();
  }
  if (appVersion != null && appVersion.trim().isNotEmpty) {
    accepted['appVersion'] = appVersion.trim();
  }

  if (traderCodeAccepted) {
    accepted
      ..['traderCodeVersion'] = UagPolicyCatalog.byId(
        'trader_code_of_conduct',
      ).version
      ..['traderCodeAcceptedAt'] = FieldValue.serverTimestamp();
  }
  if (termsOfServiceAccepted) {
    accepted
      ..['termsOfServiceVersion'] = UagPolicyCatalog.byId(
        'terms_of_use',
      ).version
      ..['termsOfServiceAcceptedAt'] = FieldValue.serverTimestamp();
  }
  if (dataSecurityAccepted) {
    accepted
      ..['dataSecurityVersion'] = UagPolicyCatalog.byId(
        'privacy_policy',
      ).version
      ..['dataSecurityAcceptedAt'] = FieldValue.serverTimestamp();
  }
  if (ageConfirmationAccepted) {
    accepted
      ..['ageRestrictionVersion'] = UagPolicyCatalog.byId(
        'age_restriction_policy',
      ).version
      ..['ageConfirmationAcceptedAt'] = FieldValue.serverTimestamp();
  }

  return accepted;
}

Map<String, dynamic> _policyAcceptance({
  required String policyId,
  required bool accepted,
}) {
  final policy = UagPolicyCatalog.byId(policyId);
  return <String, dynamic>{
    'accepted': accepted,
    'version': policy.version,
    'mandatory': policy.mandatory,
    'optionalConsent': false,
    if (accepted) 'acceptedAt': FieldValue.serverTimestamp(),
  };
}
