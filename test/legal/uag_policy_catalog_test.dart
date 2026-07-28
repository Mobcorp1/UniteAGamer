import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/legal_acceptance.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';

void main() {
  group('UAG policy catalog', () {
    test('covers the launch compliance policy set', () {
      expect(UagPolicyCatalog.documents.length, greaterThanOrEqualTo(20));
      expect(
        UagPolicyCatalog.documents.map((document) => document.id),
        containsAll(<String>[
          'terms_of_use',
          'privacy_policy',
          'fan_project_notice',
          'community_intel_policy',
          'blueprint_report_policy',
          'gifted_drop_policy',
          'conduct_report_policy',
          'contracts_rewards_policy',
          'subscriptions_ads_policy',
          'supporter_programme_policy',
          'notifications_policy',
          'voice_companion_policy',
          'image_import_ocr_policy',
          'copyright_takedown_policy',
        ]),
      );
    });

    test(
      'fan project notice is canonical and not over-claiming affiliation',
      () {
        expect(UagFanProjectNotice.text, contains('unofficial fan-made'));
        expect(UagFanProjectNotice.text, contains('not affiliated'));
        expect(UagFanProjectNotice.text, contains('endorsed'));
        expect(UagFanProjectNotice.text, contains('takedown requests'));
      },
    );

    test('draft policies flag legal review and missing operator details', () {
      expect(
        UagPolicyCatalog.documents.every(
          (document) => document.requiresLegalReview,
        ),
        isTrue,
      );
      expect(
        UagPolicyCatalog.documents.any(
          (document) => document.missingOperatorDetails,
        ),
        isTrue,
      );
    });

    test('policy acceptance reads nested policy versions', () {
      final acceptance = LegalAcceptance.fromMap(const <String, dynamic>{
        'policies': {
          'terms_of_use': {'accepted': true, 'version': 2, 'mandatory': true},
        },
      });

      expect(acceptance.hasAcceptedPolicy('terms_of_use', 1), isTrue);
      expect(acceptance.hasAcceptedPolicy('terms_of_use', 3), isFalse);
    });
  });
}
