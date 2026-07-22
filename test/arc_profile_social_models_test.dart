import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';

void main() {
  group('profile social links', () {
    test('normalizes handles and rejects wrong platform hosts', () {
      const tiktok = ArcProfileSocialLink(
        platform: ArcSocialPlatform.tiktok,
        value: '@uag.raider',
      );
      const wrongHost = ArcProfileSocialLink(
        platform: ArcSocialPlatform.tiktok,
        value: 'https://example.com/uag.raider',
      );

      expect(tiktok.normalisedValue, 'uag.raider');
      expect(tiktok.destinationUrl, 'https://www.tiktok.com/@uag.raider');
      expect(tiktok.isValid, isTrue);
      expect(wrongHost.isValid, isFalse);
    });

    test('public profile maps exclude hidden links and private fields', () {
      final profile = ArcTraderProfile.empty('raider-1').copyWith(
        uagId: 'UAG000000001',
        uagName: 'Arc Mike',
        platform: 'PC',
        socialLinks: const <ArcProfileSocialLink>[
          ArcProfileSocialLink(
            platform: ArcSocialPlatform.youtube,
            value: '@arc-mike',
          ),
          ArcProfileSocialLink(
            platform: ArcSocialPlatform.discord,
            value: 'arc.mike',
            hidden: true,
          ),
        ],
      );

      final privateMap = profile.toMap();
      final publicMap = profile.toPublicProfileMap(
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(privateMap['socialLinks'], hasLength(2));
      expect(publicMap['publicSocialLinks'], hasLength(1));
      expect(publicMap.containsKey('embarkId'), isFalse);
      expect(publicMap.containsKey('payoutMethod'), isFalse);
      expect(publicMap.toString(), isNot(contains('arc.mike')));
    });
  });

  group('creator programme', () {
    test('keeps creator status private until admin approved', () {
      const pending = ArcCreatorProgrammeProfile(
        status: ArcCreatorProgrammeStatus.creator,
        publicTitle: 'Creator Raider',
        adminApproved: false,
        rewardEligible: true,
      );
      const approved = ArcCreatorProgrammeProfile(
        status: ArcCreatorProgrammeStatus.creator,
        publicTitle: 'Creator Raider',
        adminApproved: true,
        rewardEligible: true,
      );

      expect(pending.toPublicMap(), isEmpty);
      expect(approved.toPublicMap()['title'], 'Creator Raider');
    });

    test(
      'affiliate request becomes referral member without reward eligibility',
      () {
        final requested = const ArcCreatorProgrammeProfile().normalised(
          referralCode: 'ABC12345',
          affiliateRequested: true,
        );

        expect(requested.status, ArcCreatorProgrammeStatus.referralMember);
        expect(requested.referralAttributionCode, 'ABC12345');
        expect(requested.rewardEligible, isFalse);
        expect(requested.wallOfLegendsEligible, isFalse);
      },
    );
  });
}
