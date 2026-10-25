import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'commercial tier protections, grid order and share art remain unchanged',
    () {
      final rules = File('firestore.rules').readAsStringSync();
      final source = File('functions/index.js').readAsStringSync();
      final share = File(
        'lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart',
      ).readAsStringSync();
      final catalogue = File(
        'lib/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart',
      ).readAsStringSync();
      expect(rules, contains('match /uag_trade_invites/{inviteDigest}'));
      expect(rules, contains("usageId != 'community_referral_attribution'"));
      expect(source, contains('commissionEligible: cashEligibleAtSignup'));
      expect(source, contains("source: 'uag_community_referral'"));
      expect(source, contains("source: 'uag_trade_invite'"));
      // Dart format may wrap the call arguments onto another line.
      // Verify the actual PNG export invocation instead of literal whitespace.
      expect(
        RegExp(
          r'ArcCollectionVisualShare\._exportPng\(\s*widget\.title',
        ).hasMatch(share),
        isTrue,
        reason: 'Blueprint trade image still exports with the card title.',
      );
      expect(share, contains('await rootBundle.load(path)'));
      expect(share, contains("#FYP"));
      expect(catalogue, contains('totalSlots: 91'));
      expect(catalogue, contains('slot: 60'));
      expect(catalogue, contains('slot: 62'));
      expect(catalogue, contains('slot: 89'));
      expect(
        File('assets/arc_raiders/blueprints/bantam.webp').lengthSync(),
        greaterThan(0),
      );
    },
  );
}
