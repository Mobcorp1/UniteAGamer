import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_rewarded_ad_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_ad_policy.dart';

void main() {
  final now = DateTime.utc(2026, 9, 14, 12);
  bool offer({
    bool enabled = true,
    UagAdPolicy tier = UagAdPolicy.free,
    bool consent = true,
    bool server = true,
    bool optIn = true,
    bool signedIn = true,
    int count = 0,
    DateTime? last,
  }) => UagRewardedAdPolicy(enabled: enabled).canOffer(
    policy: tier,
    signedIn: signedIn,
    consentGranted: consent,
    serverGrantReady: server,
    explicitlyRequested: optIn,
    verifiedCompletionsToday: count,
    now: now,
    lastVerifiedCompletion: last,
  );

  test('reward offers require every release and voluntary gate', () {
    expect(const UagRewardedAdPolicy().enabled, isFalse);
    expect(offer(enabled: false), isFalse);
    expect(offer(consent: false), isFalse);
    expect(offer(server: false), isFalse);
    expect(offer(optIn: false), isFalse);
    expect(offer(signedIn: false), isFalse);
    expect(offer(), isTrue);
  });
  test('reward caps reject overflow invalid counts and clock rollback', () {
    expect(offer(count: 2), isTrue);
    expect(offer(count: 3), isFalse);
    expect(offer(count: -1), isFalse);
    expect(offer(last: now.add(const Duration(minutes: 1))), isFalse);
    expect(offer(last: now.subtract(const Duration(minutes: 19))), isFalse);
    expect(offer(last: now.subtract(const Duration(minutes: 20))), isTrue);
  });
  test('paid tiers and premium reward inventory remain protected', () {
    expect(offer(tier: UagAdPolicy.essential), isFalse);
    expect(offer(tier: UagAdPolicy.premium), isFalse);
    expect(UagAdPolicy.free.rewardedBoosts, isEmpty);
  });
}
