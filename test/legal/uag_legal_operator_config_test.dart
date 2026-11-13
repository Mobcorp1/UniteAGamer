import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_legal_operator_config.dart';

void main() {
  group('UagLegalOperatorConfig', () {
    test('does not treat missing launch identity as complete', () {
      expect(UagLegalOperatorConfig.missing.isComplete, isFalse);
      expect(
        UagLegalOperatorConfig.missing.missingFields,
        containsAll([
          'operatorName',
          'tradingName',
          'legalContact',
          'contactEmail',
          'serviceAddress',
          'privacyContact',
          'copyrightContact',
          'moderationContact',
          'billingSupportContact',
          'privacyPolicyUrl',
          'termsOfUseUrl',
          'subscriptionRefundsUrl',
          'supportUrl',
        ]),
      );
    });

    test('keeps company number optional for non-company operators', () {
      final config = UagLegalOperatorConfig.fromMap({
        'operatorName': 'Example Operator',
        'tradingName': 'Example Trading Name',
        'legalContact': 'Example Contact',
        'contactEmail': 'support@example.test',
        'serviceAddress': 'Example Address',
        'privacyContact': 'privacy@example.test',
        'copyrightContact': 'copyright@example.test',
        'moderationContact': 'moderation@example.test',
        'billingSupportContact': 'billing@example.test',
        'privacyPolicyUrl': 'https://example.test/privacy',
        'termsOfUseUrl': 'https://example.test/terms',
        'subscriptionRefundsUrl': 'https://example.test/refunds',
        'supportUrl': 'https://example.test/support',
      });

      expect(config.isComplete, isTrue);
      expect(config.companyNumber, isEmpty);
      expect(config.missingFields, isEmpty);
    });

    test(
      'production operator identity and public policy URLs are complete',
      () {
        const config = UagLegalOperatorConfig.production;

        expect(config.isComplete, isTrue);
        expect(config.operatorName, 'MobCorp Limited');
        expect(config.legalContact, 'Michael Marsh');
        expect(config.contactEmail, 'contact@mobcorp.co.uk');
        expect(config.companyNumber, '16857854');
        expect(config.serviceAddress, contains('107 Langley Hall Road'));
        expect(config.privacyPolicyUrl, endsWith('/privacy'));
        expect(config.termsOfUseUrl, endsWith('/terms'));
        expect(
          config.subscriptionRefundsUrl,
          endsWith('/subscriptions-refunds'),
        );
        expect(config.supportUrl, endsWith('/support'));
      },
    );
  });
}
