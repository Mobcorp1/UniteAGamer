import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> buildOnboardingLegalAcceptedMap({
  required bool traderCodeAccepted,
  required bool termsOfServiceAccepted,
  required bool dataSecurityAccepted,
}) {
  final accepted = <String, dynamic>{
    'traderCodeAccepted': traderCodeAccepted,
    'termsOfServiceAccepted': termsOfServiceAccepted,
    'dataSecurityAccepted': dataSecurityAccepted,
  };

  if (traderCodeAccepted) {
    accepted
      ..['traderCodeVersion'] = 1
      ..['traderCodeAcceptedAt'] = FieldValue.serverTimestamp();
  }
  if (termsOfServiceAccepted) {
    accepted
      ..['termsOfServiceVersion'] = 1
      ..['termsOfServiceAcceptedAt'] = FieldValue.serverTimestamp();
  }
  if (dataSecurityAccepted) {
    accepted
      ..['dataSecurityVersion'] = 1
      ..['dataSecurityAcceptedAt'] = FieldValue.serverTimestamp();
  }

  return accepted;
}
