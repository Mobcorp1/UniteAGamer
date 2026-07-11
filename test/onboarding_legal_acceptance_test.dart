import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/reg/onboarding_basic_profile_screen.dart';

void main() {
  group('onboarding legal acceptance map', () {
    test('records all closed-beta acknowledgements when accepted', () {
      final map = buildOnboardingLegalAcceptedMap(
        traderCodeAccepted: true,
        termsOfServiceAccepted: true,
        dataSecurityAccepted: true,
      );

      expect(map['traderCodeAccepted'], isTrue);
      expect(map['traderCodeVersion'], 1);
      expect(map['traderCodeAcceptedAt'], isA<FieldValue>());
      expect(map['termsOfServiceAccepted'], isTrue);
      expect(map['termsOfServiceVersion'], 1);
      expect(map['termsOfServiceAcceptedAt'], isA<FieldValue>());
      expect(map['dataSecurityAccepted'], isTrue);
      expect(map['dataSecurityVersion'], 1);
      expect(map['dataSecurityAcceptedAt'], isA<FieldValue>());
    });

    test('does not stamp acknowledgements that were not accepted', () {
      final map = buildOnboardingLegalAcceptedMap(
        traderCodeAccepted: false,
        termsOfServiceAccepted: true,
        dataSecurityAccepted: false,
      );

      expect(map['traderCodeAccepted'], isFalse);
      expect(map.containsKey('traderCodeAcceptedAt'), isFalse);
      expect(map['termsOfServiceAccepted'], isTrue);
      expect(map.containsKey('termsOfServiceAcceptedAt'), isTrue);
      expect(map['dataSecurityAccepted'], isFalse);
      expect(map.containsKey('dataSecurityAcceptedAt'), isFalse);
    });
  });
}
