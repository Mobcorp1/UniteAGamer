enum UagCommunityReferralReward {
  premium7Days,
  premium30Days,
  creatorFastTrack,
}

class UagCommunityReferralMilestone {
  const UagCommunityReferralMilestone({
    required this.validatedReferrals,
    required this.reward,
    required this.label,
  });

  final int validatedReferrals;
  final UagCommunityReferralReward reward;
  final String label;
}

class UagCommunityReferralPolicy {
  const UagCommunityReferralPolicy._();

  static const int retentionValidationDays = 30;

  static const milestones = <UagCommunityReferralMilestone>[
    UagCommunityReferralMilestone(
      validatedReferrals: 1,
      reward: UagCommunityReferralReward.premium7Days,
      label: '7 days Premium',
    ),
    UagCommunityReferralMilestone(
      validatedReferrals: 3,
      reward: UagCommunityReferralReward.premium30Days,
      label: '1 month Premium',
    ),
    UagCommunityReferralMilestone(
      validatedReferrals: 5,
      reward: UagCommunityReferralReward.creatorFastTrack,
      label: 'Creator Programme fast-track review',
    ),
  ];

  static UagCommunityReferralMilestone? nextMilestone(int validated) {
    for (final milestone in milestones) {
      if (validated < milestone.validatedReferrals) return milestone;
    }
    return null;
  }

  static int earnedMilestoneCount(int validated) =>
      milestones.where((m) => validated >= m.validatedReferrals).length;
}

class UagCommunityGrowthPolicy {
  const UagCommunityGrowthPolicy._();

  // Active/retained community targets, deliberately not raw registrations.
  static const targets = <int>[10000, 25000, 50000, 100000, 250000];

  // Creator commission uplift in percentage points. The community helps
  // creators, but the uplift remains capped and admin-controlled.
  static double creatorGrowthBonusPercent(int qualifiedActiveUsers) {
    if (qualifiedActiveUsers >= 250000) return 2.5;
    if (qualifiedActiveUsers >= 100000) return 2.0;
    if (qualifiedActiveUsers >= 50000) return 1.5;
    if (qualifiedActiveUsers >= 25000) return 1.0;
    if (qualifiedActiveUsers >= 10000) return 0.5;
    return 0;
  }

  static int? nextTarget(int qualifiedActiveUsers) {
    for (final target in targets) {
      if (qualifiedActiveUsers < target) return target;
    }
    return null;
  }
}
