import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_community_referral_link.dart';

void main() {
  test('parses normal referral parameters', () {
    final link = UagCommunityReferralLink.tryParse(
      Uri.parse(
        'https://unite-a-gamer.web.app/?referrer=abc123&refcode=raider123',
      ),
    );
    expect(link, isNotNull);
    expect(link!.referrerUid, 'abc123');
    expect(link.normalizedCode, 'RAIDER123');
  });

  test('ignores unrelated links', () {
    expect(
      UagCommunityReferralLink.tryParse(
        Uri.parse('https://unite-a-gamer.web.app/?creator=x&code=y'),
      ),
      isNull,
    );
  });

  test('creator and community parameters can coexist', () {
    final link = UagCommunityReferralLink.tryParse(
      Uri.parse(
        'uag://creator?creator=c1&code=creator1&referrer=r1&refcode=raider1',
      ),
    );
    expect(link, isNotNull);
    expect(link!.referrerUid, 'r1');
  });
}
