import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/trading/arc_trade_needs_panel.dart';

void main() {
  test('free tier bulk only', () {
    expect(ArcTradeNeedsPolicy.selectable(UagSubscriptionTier.free, 77), 0);
    expect(ArcTradeNeedsPolicy.permits(UagSubscriptionTier.free, 77, 1), isFalse);
  });
  test('essential rounds half up', () {
    expect(ArcTradeNeedsPolicy.selectable(UagSubscriptionTier.essential, 77), 39);
    expect(ArcTradeNeedsPolicy.permits(UagSubscriptionTier.essential, 77, 40), isFalse);
  });
  test('premium can customise every eligible need', () {
    expect(ArcTradeNeedsPolicy.selectable(UagSubscriptionTier.premium, 77), 77);
    expect(ArcTradeNeedsPolicy.permits(UagSubscriptionTier.premium, 77, 77), isTrue);
  });
}
