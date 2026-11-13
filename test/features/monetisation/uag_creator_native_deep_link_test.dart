import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_referral_link.dart';

void main() {
  test('https creator referral parses for App Links and Universal Links', () {
    final parsed = UagCreatorReferralLink.tryParse(
      Uri.parse(
        'https://unite-a-gamer.web.app/?creator=creator-123&code=UAGMIKE',
      ),
    );
    expect(parsed, isNotNull);
    expect(parsed!.creatorUid, 'creator-123');
    expect(parsed.normalizedCode, 'UAGMIKE');
  });

  test('custom uag scheme preserves creator attribution parameters', () {
    final parsed = UagCreatorReferralLink.tryParse(
      Uri.parse('uag://creator?creator=creator-123&code=ghost50-mike'),
    );
    expect(parsed, isNotNull);
    expect(parsed!.creatorUid, 'creator-123');
    expect(parsed.normalizedCode, 'GHOST50-MIKE');
  });

  test('non creator links are ignored', () {
    expect(
      UagCreatorReferralLink.tryParse(
        Uri.parse('https://unite-a-gamer.web.app/'),
      ),
      isNull,
    );
  });
}
