import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_legal_acceptance.dart';

void main() {
  group('onboarding legal acceptance map', () {
    test('records all closed-beta acknowledgements when accepted', () {
      final map = buildOnboardingLegalAcceptedMap(
        traderCodeAccepted: true,
        termsOfServiceAccepted: true,
        dataSecurityAccepted: true,
        userId: 'user-1',
        platform: 'web',
        appVersion: 'closed-beta',
      );

      expect(map['version'], arcOnboardingLegalAcceptanceVersion);
      expect(map['flow'], 'arcMandatoryOnboarding');
      expect(map['acceptedAt'], isA<FieldValue>());
      expect(map['userId'], 'user-1');
      expect(map['platform'], 'web');
      expect(map['appVersion'], 'closed-beta');
      expect(map['traderCodeAccepted'], isTrue);
      expect(map['traderCodeVersion'], 1);
      expect(map['traderCodeAcceptedAt'], isA<FieldValue>());
      expect(map['termsOfServiceAccepted'], isTrue);
      expect(map['termsOfServiceVersion'], 1);
      expect(map['termsOfServiceAcceptedAt'], isA<FieldValue>());
      expect(map['dataSecurityAccepted'], isTrue);
      expect(map['dataSecurityVersion'], 1);
      expect(map['dataSecurityAcceptedAt'], isA<FieldValue>());

      final policies = map['policies'] as Map<String, dynamic>;
      expect(policies.keys, {
        'trader_code_of_conduct',
        'terms_of_use',
        'privacy_policy',
      });
      expect(policies['trader_code_of_conduct']['accepted'], isTrue);
      expect(
        policies['trader_code_of_conduct']['acceptedAt'],
        isA<FieldValue>(),
      );
      expect(policies['terms_of_use']['accepted'], isTrue);
      expect(policies['privacy_policy']['accepted'], isTrue);
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

      final policies = map['policies'] as Map<String, dynamic>;
      expect(policies['trader_code_of_conduct']['accepted'], isFalse);
      expect(
        policies['trader_code_of_conduct'].containsKey('acceptedAt'),
        isFalse,
      );
      expect(policies['terms_of_use']['accepted'], isTrue);
      expect(policies['privacy_policy']['accepted'], isFalse);
    });
  });
}
