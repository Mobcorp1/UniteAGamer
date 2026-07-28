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
          'contactEmail',
          'serviceAddress',
          'privacyContact',
          'copyrightContact',
          'moderationContact',
          'billingSupportContact',
        ]),
      );
    });

    test('keeps company number optional for non-company operators', () {
      final config = UagLegalOperatorConfig.fromMap({
        'operatorName': 'Example Operator',
        'tradingName': 'Example Trading Name',
        'contactEmail': 'support@example.test',
        'serviceAddress': 'Example Address',
        'privacyContact': 'privacy@example.test',
        'copyrightContact': 'copyright@example.test',
        'moderationContact': 'moderation@example.test',
        'billingSupportContact': 'billing@example.test',
      });

      expect(config.isComplete, isTrue);
      expect(config.companyNumber, isEmpty);
      expect(config.missingFields, isEmpty);
    });
  });
}
