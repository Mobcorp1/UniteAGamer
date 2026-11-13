import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_application_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_referral_link.dart';

void main() {
  test('creator application requires identity platform handle and terms', () {
    const policy = UagCreatorApplicationPolicy();
    final invalid = policy.validate(
      displayName: '',
      platforms: const <String>[],
      socialHandles: const <String, String>{},
      termsAccepted: false,
    );
    expect(invalid.valid, isFalse);
    expect(invalid.errors.length, 4);

    final valid = policy.validate(
      displayName: 'Mike Raider',
      platforms: const <String>['TikTok'],
      socialHandles: const <String, String>{'TikTok': '@mike'},
      termsAccepted: true,
    );
    expect(valid.valid, isTrue);
  });

  test('creator identity and default code are deterministic', () {
    const policy = UagCreatorApplicationPolicy();
    expect(
      policy.creatorIdFor(uid: 'abc123456', displayName: 'Mike Raider'),
      'UAG-MIKERAIDER-123456',
    );
    expect(policy.defaultCodeFor('Mike Raider'), 'UAGMIKERAIDER');
  });

  test('referral link round-trips creator uid and code', () {
    const link = UagCreatorReferralLink(
      creatorUid: 'creator-123',
      code: 'ghost50-mike',
    );
    final uri = link.toUri();
    final parsed = UagCreatorReferralLink.tryParse(uri);
    expect(parsed, isNotNull);
    expect(parsed!.creatorUid, 'creator-123');
    expect(parsed.normalizedCode, 'GHOST50-MIKE');
  });
}
