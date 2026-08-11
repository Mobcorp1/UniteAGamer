import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_match_intelligence_copy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_monetisation_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_plan.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_user_entitlement.dart';

void main() {
  group('Match Intelligence subscription copy', () {
    test('maps subscription tiers to customer-facing intelligence levels', () {
      expect(UagMatchIntelligenceCopy.free.label, 'Basic Match Intelligence');
      expect(
        UagMatchIntelligenceCopy.essential.label,
        'Enhanced Match Intelligence',
      );
      expect(
        UagMatchIntelligenceCopy.premium.label,
        'Advanced Match Intelligence',
      );
      expect(
        UagMatchIntelligenceCopy.forTier(UagSubscriptionTier.free).description,
        'Basic compatibility matching using core profile, platform and availability signals.',
      );
      expect(
        UagMatchIntelligenceCopy.forTier(
          UagSubscriptionTier.essential,
        ).description,
        'Deeper compatibility analysis using communication style, schedule, squad intent and play preferences.',
      );
      expect(
        UagMatchIntelligenceCopy.forTier(
          UagSubscriptionTier.premium,
        ).description,
        'Full UAG Decision Engine analysis using dozens of private compatibility signals to surface the strongest squad recommendations.',
      );
    });

    test('plan models both expose the shared match intelligence copy', () {
      expect(
        UagSubscriptionPlan.forTier(UagSubscriptionTier.free).features,
        contains(UagMatchIntelligenceCopy.free.description),
      );
      expect(
        UagSubscriptionPlan.forTier(UagSubscriptionTier.essential).features,
        contains(UagMatchIntelligenceCopy.essential.description),
      );
      expect(
        UagSubscriptionPlan.forTier(UagSubscriptionTier.premium).features,
        contains(UagMatchIntelligenceCopy.premium.description),
      );
      expect(
        UagPlans.free.benefits,
        contains(UagMatchIntelligenceCopy.free.description),
      );
      expect(
        UagPlans.essential.benefits,
        contains(UagMatchIntelligenceCopy.essential.description),
      );
      expect(
        UagPlans.premium.benefits,
        contains(UagMatchIntelligenceCopy.premium.description),
      );
    });

    test('comparison rows include each tier without private mechanics', () {
      final rows = UagMatchIntelligenceCopy.comparisonRows;
      final rowLabels = rows.map((row) => row.feature).toSet();
      final publicText = rows
          .expand(
            (row) => <String>[
              row.feature,
              row.free,
              row.essential,
              row.premium,
            ],
          )
          .join(' ')
          .toLowerCase();

      expect(rowLabels, contains('Match Intelligence'));
      expect(rowLabels, contains('Overall Match %'));
      expect(rowLabels, contains('Compatibility Ranking'));
      expect(rowLabels, contains('Availability Matching'));
      expect(rowLabels, contains('Communication Compatibility'));
      expect(rowLabels, contains('Squad Intent Matching'));
      expect(rowLabels, contains('Archetype Fit'));
      expect(rowLabels, contains('Reputation Weighting'));
      expect(rowLabels, contains('Favourite Raider Prioritisation'));
      expect(rowLabels, contains('Dynamic Re-ranking'));
      expect(rowLabels, contains('Advanced Decision Engine'));
      expect(publicText, isNot(contains('blueprint')));
      expect(publicText, isNot(contains('owned')));
      expect(publicText, isNot(contains('missing')));
      expect(publicText, isNot(contains('forced')));
      expect(publicText, isNot(contains('better players')));
    });

    test('entitlement helper respects admin and dev bypass', () {
      final free = UagUserEntitlement.fromUserDoc(
        uid: 'free',
        data: const <String, dynamic>{'subscriptionTier': 'free'},
      );
      final essential = UagUserEntitlement.fromUserDoc(
        uid: 'essential',
        data: const <String, dynamic>{'subscriptionTier': 'essential'},
      );
      final premium = UagUserEntitlement.fromUserDoc(
        uid: 'premium',
        data: const <String, dynamic>{'subscriptionTier': 'premium'},
      );
      final admin = UagUserEntitlement.fromUserDoc(
        uid: 'admin',
        data: const <String, dynamic>{
          'subscriptionTier': 'free',
          'isAdmin': true,
        },
      );
      final dev = UagUserEntitlement.fromUserDoc(
        uid: 'dev',
        data: const <String, dynamic>{
          'subscriptionTier': 'essential',
          'isDev': true,
        },
      );

      expect(free.matchIntelligence, UagMatchIntelligenceCopy.free);
      expect(essential.matchIntelligence, UagMatchIntelligenceCopy.essential);
      expect(premium.matchIntelligence, UagMatchIntelligenceCopy.premium);
      expect(admin.matchIntelligence, UagMatchIntelligenceCopy.premium);
      expect(dev.matchIntelligence, UagMatchIntelligenceCopy.premium);
    });
  });
}
