import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_live_models.dart';

void main() {
  test(
    'live dashboard derives Creator Points and tier from active paid users',
    () {
      final dashboard = UagCreatorLiveDashboard.fromMap(
        'creator-1',
        <String, dynamic>{'essentialSubscribers': 10, 'premiumSubscribers': 10},
      );
      expect(dashboard.creatorPoints, 25);
      expect(dashboard.level?.name, 'Commander');
      expect(dashboard.commissionPercent, 15);
    },
  );

  test('monthly inventory never exposes a negative remaining balance', () {
    final inventory = UagCreatorMonthlyInventory.fromMap(<String, dynamic>{
      'monthKey': '2026-09',
      'premiumMonthGranted': 2,
      'premiumMonthUsed': 5,
    });
    expect(inventory.premiumMonthRemaining, 0);
  });

  test('attribution claim normalises creator code', () {
    final claim = UagCreatorAttributionClaim(
      creatorUid: 'creator-1',
      creatorCode: ' ghost50-mike ',
      source: 'creator_link',
      capturedAtIso: '2026-09-06T00:00:00Z',
    );
    expect(claim.toMap()['creatorCode'], 'GHOST50-MIKE');
    expect(claim.toMap()['status'], 'pending_validation');
  });
}
