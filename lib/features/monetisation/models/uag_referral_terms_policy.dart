class UagReferralTermsPolicy {
  const UagReferralTermsPolicy._();

  static const String version = '2026-09-06-v1';

  static const List<String> requiredPrinciples = <String>[
    'A qualifying referral must be a genuine new or previously unattributed UAG account.',
    'Self-referrals, duplicate accounts, automated accounts and fabricated activity do not qualify.',
    'The first valid referral attribution is retained and is not overwritten by later links or codes.',
    'Paid referral rewards and Creator commission remain subject to validation, refunds and chargebacks.',
    'Creator commission is calculated from eligible net subscription revenue actually received by UAG, not headline price.',
    'Giveaways, temporary entitlements and promotional discounts do not themselves generate commission.',
    'Discounts do not stack unless a campaign explicitly permits stacking.',
    'Community milestones use qualified active or retained users rather than raw registrations.',
    'Community Growth bonuses, reward pools and promotional bonuses do not create equity, ownership, dividends or employment rights.',
    'Tax obligations arising from cash Creator payments remain the recipient responsibility unless applicable law requires otherwise.',
    'UAG may investigate suspicious referral activity and withhold pending rewards while a review is completed.',
    'Changes to future programme rewards do not retrospectively remove commission already validated as payable.',
  ];
}
