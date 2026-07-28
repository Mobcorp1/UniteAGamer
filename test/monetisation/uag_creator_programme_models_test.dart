import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_programme_models.dart';

void main() {
  group('UagCreatorCampaignCodePolicy', () {
    const policy = UagCreatorCampaignCodePolicy();

    test('normalises approved creator templates without punctuation', () {
      final loyal = policy.normalise(
        raw: 'loyal unite-a-gamer',
        creatorHandle: 'UniteAGamer',
      );
      final follower = policy.normalise(
        raw: ' FOLLOWER uniteagamer ',
        creatorHandle: 'UniteAGamer',
      );
      final welcome = policy.normalise(raw: '', creatorHandle: 'UniteAGamer');

      expect(loyal.valid, isTrue);
      expect(loyal.normalizedCode, 'LOYALUNITEAGAMER');
      expect(follower.valid, isTrue);
      expect(follower.normalizedCode, 'FOLLOWERUNITEAGAMER');
      expect(welcome.normalizedCode, 'WELCOMEUNITEAGAMER');
    });

    test('rejects duplicates and reserved official terms', () {
      final duplicate = policy.normalise(
        raw: 'welcome raider',
        creatorHandle: 'Raider',
        existingCodes: const ['WELCOMERAIDER'],
      );
      final reserved = policy.normalise(
        raw: 'official embark',
        creatorHandle: 'Raider',
      );

      expect(duplicate.valid, isFalse);
      expect(reserved.valid, isFalse);
      expect(reserved.reasons.join(' '), contains('EMBARK'));
    });
  });

  group('creator dashboard and ledger privacy', () {
    test('aggregate exposes counts without private billing fields', () {
      const aggregate = UagCreatorDashboardAggregate(
        uid: 'creator-1',
        uniqueClicks: 10,
        paidConversions: 2,
        pendingCommissionPence: 500,
      );

      final map = aggregate.toPrivacySafeMap();

      expect(map['conversionRate'], 0.2);
      expect(map.containsKey('email'), isFalse);
      expect(map.containsKey('paymentMethod'), isFalse);
      expect(map['pendingCommissionPence'], 500);
    });

    test('commission ledger parses trusted backend states', () {
      final entry = UagCreatorCommissionLedgerEntry.fromMap(const {
        'id': 'invoice-1',
        'creatorUid': 'creator-1',
        'status': 'qualifying',
        'amountPence': 250,
        'currency': 'gbp',
        'referredAccountRef': 'user_abc123',
      });

      expect(entry.visibleToCreator, isTrue);
      expect(entry.status, UagCreatorCommissionStatus.qualifying);
      expect(entry.referredAccountRef, 'user_abc123');
    });
  });
}
