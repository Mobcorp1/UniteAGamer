import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_commission_pipeline_models.dart';

void main() {
  test('commission uses eligible net revenue, not headline price', () {
    expect(
      UagCreatorCommissionLifecyclePolicy.commissionPence(
        eligibleNetAmountPence: 700,
        commissionRatePercent: 10,
      ),
      70,
    );
    expect(
      UagCreatorCommissionLifecyclePolicy.commissionPence(
        eligibleNetAmountPence: 0,
        commissionRatePercent: 20,
      ),
      0,
    );
  });

  test('positive revenue event stays pending for 30 days', () {
    final occurred = DateTime.utc(2026, 9, 1);
    final before = DateTime.utc(2026, 9, 30, 23, 59);
    final after = DateTime.utc(2026, 10, 1, 0, 1);

    expect(
      UagCreatorCommissionLifecyclePolicy.lifecycleFor(
        eventType: UagCreatorBillingEventType.subscriptionStarted,
        occurredAt: occurred,
        now: before,
      ),
      UagCreatorCommissionLifecycleStatus.pendingValidation,
    );
    expect(
      UagCreatorCommissionLifecyclePolicy.lifecycleFor(
        eventType: UagCreatorBillingEventType.renewal,
        occurredAt: occurred,
        now: after,
      ),
      UagCreatorCommissionLifecycleStatus.payable,
    );
  });

  test('refund and chargeback reverse commission lifecycle', () {
    final now = DateTime.utc(2026, 9, 6);
    expect(
      UagCreatorCommissionLifecyclePolicy.lifecycleFor(
        eventType: UagCreatorBillingEventType.refund,
        occurredAt: now,
        now: now,
      ),
      UagCreatorCommissionLifecycleStatus.reversed,
    );
    expect(
      UagCreatorCommissionLifecyclePolicy.lifecycleFor(
        eventType: UagCreatorBillingEventType.chargeback,
        occurredAt: now,
        now: now,
      ),
      UagCreatorCommissionLifecycleStatus.reversed,
    );
  });

  test(
    'annual and recurring renewals use the billing event amount received',
    () {
      final event = UagCreatorValidatedBillingEvent(
        id: 'renewal_2027',
        creatorUid: 'creator',
        referredUid: 'user',
        subscriptionId: 'annual-premium',
        eventType: UagCreatorBillingEventType.renewal,
        planTier: 'premium',
        grossAmountPence: 9999,
        eligibleNetAmountPence: 7083,
        commissionRatePercent: 17.5,
        occurredAt: DateTime.utc(2027, 9, 1),
      );
      expect(event.calculatedCommissionPence, 1240);
      expect(event.isPositiveRevenueEvent, isTrue);
    },
  );
}
