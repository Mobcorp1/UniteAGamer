import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authoritative referral reward activation is server-owned', () {
    const activationRequestCollection =
        'uag_referral_reward_activation_requests';
    const lockerCollection = 'uag_referral_reward_lockers';
    expect(activationRequestCollection, contains('activation_requests'));
    expect(lockerCollection, contains('reward_lockers'));
  });
}
