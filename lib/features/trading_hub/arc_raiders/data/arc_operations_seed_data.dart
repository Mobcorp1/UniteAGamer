import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcOperationsSeedData {
  static const String _badgeRoot = 'assets/arc_raiders/operations/badges';

  static const rewards = <String, ArcOperationReward>{
    'beta_access': ArcOperationReward(
      id: 'beta_access',
      label: 'Beta Access Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/beta_access_plus.png',
      betaExclusive: true,
    ),
    'founding_raider': ArcOperationReward(
      id: 'founding_raider',
      label: 'Founding Raider Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/founding_raider.png',
      betaExclusive: true,
    ),
    'field_tester': ArcOperationReward(
      id: 'field_tester',
      label: 'Field Tester Title',
      type: ArcOperationRewardType.title,
      rarity: ArcCosmeticRarity.closedBeta,
      betaExclusive: true,
    ),
    'beta_signal_frame': ArcOperationReward(
      id: 'beta_signal_frame',
      label: 'Beta Signal Frame',
      type: ArcOperationRewardType.profileFrame,
      rarity: ArcCosmeticRarity.closedBeta,
      betaExclusive: true,
    ),
    'guardian_signal_frame': ArcOperationReward(
      id: 'guardian_signal_frame',
      label: 'Guardian Signal Frame',
      type: ArcOperationRewardType.profileFrame,
      rarity: ArcCosmeticRarity.community,
      betaExclusive: true,
    ),
    'beta_command_banner': ArcOperationReward(
      id: 'beta_command_banner',
      label: 'Beta Command Banner',
      type: ArcOperationRewardType.profileBanner,
      rarity: ArcCosmeticRarity.closedBeta,
      betaExclusive: true,
    ),
    'guardian_banner': ArcOperationReward(
      id: 'guardian_banner',
      label: 'Guardian Banner',
      type: ArcOperationRewardType.profileBanner,
      rarity: ArcCosmeticRarity.community,
      betaExclusive: true,
    ),
    'trade_pioneer': ArcOperationReward(
      id: 'trade_pioneer',
      label: 'Trade Pioneer Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/pathfinder.png',
      betaExclusive: true,
    ),
    'intel_officer': ArcOperationReward(
      id: 'intel_officer',
      label: 'Intel Officer Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/golden_pathfinder.png',
      betaExclusive: true,
    ),
    'community_raider': ArcOperationReward(
      id: 'community_raider',
      label: 'Community Raider Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/community_heart.png',
      betaExclusive: true,
    ),
    'og_legend': ArcOperationReward(
      id: 'og_legend',
      label: 'OG Legend Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/og_legend.png',
      betaExclusive: true,
    ),
    'inner_circle': ArcOperationReward(
      id: 'inner_circle',
      label: 'UAG Inner Circle Badge',
      type: ArcOperationRewardType.badge,
      assetPath: '$_badgeRoot/inner_circle.png',
      betaExclusive: true,
    ),
    'extra_trade': ArcOperationReward(
      id: 'extra_trade',
      label: '+1 Extra Trade Slot',
      type: ArcOperationRewardType.tradeSlot,
      amount: 1,
    ),
    'extra_match': ArcOperationReward(
      id: 'extra_match',
      label: '+1 Extra Match Request',
      type: ArcOperationRewardType.matchmakingSlot,
      amount: 1,
    ),
    'xp_5': ArcOperationReward(
      id: 'xp_5',
      label: '+5 Intel XP',
      type: ArcOperationRewardType.intelXp,
      amount: 5,
    ),
    'xp_10': ArcOperationReward(
      id: 'xp_10',
      label: '+10 Intel XP',
      type: ArcOperationRewardType.intelXp,
      amount: 10,
    ),
    'xp_25': ArcOperationReward(
      id: 'xp_25',
      label: '+25 Intel XP',
      type: ArcOperationRewardType.intelXp,
      amount: 25,
    ),
  };

  static List<ArcOperationTask> betaOperations = [
    _task(
      id: 'beta_complete_profile',
      title: 'First Contact',
      description:
          'Complete your Raider profile so trading, squads and Operations can personalise around you.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.onboarding,
      target: 1,
      progress: 0,
      rewards: [rewards['beta_access']!, rewards['xp_10']!],
      accent: AppTheme.neonCyan,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_first_listing',
      title: 'Open The Market',
      description:
          'Create your first trade listing and help seed the beta economy.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.trading,
      target: 1,
      progress: 0,
      rewards: [rewards['extra_trade']!, rewards['xp_10']!],
      accent: AppTheme.neonPink,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_first_trade',
      title: 'Trade Pioneer',
      description:
          'Complete your first successful trade during the closed beta.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.trading,
      target: 1,
      progress: 0,
      rewards: [rewards['trade_pioneer']!, rewards['xp_25']!],
      accent: Colors.amberAccent,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_verified_intel',
      title: 'Verified Intel',
      description:
          'Submit intel that is confirmed by the community. Raw reports are low value; verified reports earn real rewards.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.intel,
      target: 3,
      progress: 0,
      rewards: [rewards['intel_officer']!, rewards['xp_25']!],
      accent: Colors.lightGreenAccent,
      betaExclusive: true,
      verificationRequired: true,
    ),
    _task(
      id: 'beta_match_raider',
      title: 'Squad Signal',
      description:
          'Complete a Match Raider session and rate your squadmates afterwards.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.matchmaking,
      target: 1,
      progress: 0,
      rewards: [rewards['extra_match']!, rewards['xp_10']!],
      accent: AppTheme.neonCyan,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_loadout_saved',
      title: 'Personal Build Online',
      description:
          'Save your first Favourite Loadout so trades and goals can target your build.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.loadout,
      target: 1,
      progress: 0,
      rewards: [rewards['xp_10']!],
      accent: AppTheme.neonPink,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_feedback',
      title: 'Field Tester',
      description:
          'Submit actionable feedback during closed beta. Bugs, missing images, bad flows and unclear screens all count.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.beta,
      target: 3,
      progress: 0,
      rewards: [
        rewards['field_tester']!,
        rewards['beta_signal_frame']!,
        rewards['xp_25']!,
      ],
      accent: Colors.orangeAccent,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_guardian',
      title: 'Guardian Run',
      description:
          'Help another Raider complete a goal, trade or early build step with nothing expected back.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.guardian,
      target: 1,
      progress: 0,
      rewards: [
        rewards['community_raider']!,
        rewards['guardian_signal_frame']!,
        rewards['guardian_banner']!,
        rewards['xp_25']!,
      ],
      accent: Colors.lightGreenAccent,
      betaExclusive: true,
    ),
    _task(
      id: 'beta_return_days',
      title: 'Closed Beta Veteran',
      description:
          'Return on 10 separate beta days and help keep the hub active while systems are being tested.',
      cadence: ArcOperationCadence.beta,
      category: ArcOperationCategory.beta,
      target: 10,
      progress: 0,
      rewards: [
        rewards['og_legend']!,
        rewards['inner_circle']!,
        rewards['beta_command_banner']!,
      ],
      accent: Colors.amberAccent,
      betaExclusive: true,
    ),
  ];

  static List<ArcOperationTask> dailyOperations = [
    _task(
      id: 'daily_refresh_listing',
      title: 'Keep The Market Alive',
      description:
          'Create or refresh one active listing. Operations will prioritise this when marketplace activity is low.',
      cadence: ArcOperationCadence.daily,
      category: ArcOperationCategory.trading,
      target: 1,
      rewards: [rewards['xp_5']!],
      accent: AppTheme.neonPink,
    ),
    _task(
      id: 'daily_update_availability',
      title: 'Update Availability',
      description:
          'Set your current availability so Match Raider and Trade reminders can recommend active players.',
      cadence: ArcOperationCadence.daily,
      category: ArcOperationCategory.matchmaking,
      target: 1,
      rewards: [rewards['xp_5']!],
      accent: AppTheme.neonCyan,
    ),
    _task(
      id: 'daily_verify_intel',
      title: 'Confirm Intel',
      description:
          'Confirm a community blueprint report. Verified intel is worth more than raw report spam.',
      cadence: ArcOperationCadence.daily,
      category: ArcOperationCategory.intel,
      target: 1,
      rewards: [rewards['xp_5']!],
      accent: Colors.lightGreenAccent,
      verificationRequired: true,
    ),
  ];

  static List<ArcOperationTask> weeklyOperations = [
    _task(
      id: 'weekly_trade_run',
      title: 'Market Operator',
      description: 'Complete 3 successful trades this week.',
      cadence: ArcOperationCadence.weekly,
      category: ArcOperationCategory.trading,
      target: 3,
      rewards: [rewards['extra_trade']!, rewards['xp_25']!],
      accent: AppTheme.neonPink,
    ),
    _task(
      id: 'weekly_verified_intel',
      title: 'Intel Network',
      description:
          'Earn 5 confirmed intel interactions. This rewards quality instead of spam reports.',
      cadence: ArcOperationCadence.weekly,
      category: ArcOperationCategory.intel,
      target: 5,
      rewards: [rewards['xp_25']!],
      accent: Colors.lightGreenAccent,
      verificationRequired: true,
    ),
    _task(
      id: 'weekly_loadout_progress',
      title: 'Build Progress',
      description:
          'Acquire, craft or trade towards 50% completion on your Favourite Loadout.',
      cadence: ArcOperationCadence.weekly,
      category: ArcOperationCategory.loadout,
      target: 1,
      rewards: [rewards['xp_25']!],
      accent: AppTheme.neonCyan,
    ),
  ];

  static List<ArcOperationTask> monthlyOperations = [
    _task(
      id: 'monthly_trader_bronze',
      title: 'Trader Bronze',
      description: 'Complete 10 successful trades this month.',
      cadence: ArcOperationCadence.monthly,
      category: ArcOperationCategory.trading,
      target: 10,
      rewards: [rewards['extra_trade']!, rewards['xp_25']!],
      accent: AppTheme.neonPink,
    ),
    _task(
      id: 'monthly_guardian',
      title: 'Guardian Detail',
      description:
          'Help 5 Raiders through trades, advice, first builds or squad support.',
      cadence: ArcOperationCadence.monthly,
      category: ArcOperationCategory.guardian,
      target: 5,
      rewards: [rewards['community_raider']!, rewards['xp_25']!],
      accent: Colors.lightGreenAccent,
    ),
  ];

  static List<ArcOperationTask> lifetimeOperations = [
    _task(
      id: 'life_first_trade',
      title: 'First Trade',
      description: 'Complete your first successful trade.',
      cadence: ArcOperationCadence.lifetime,
      category: ArcOperationCategory.trading,
      target: 1,
      rewards: [rewards['trade_pioneer']!],
      accent: AppTheme.neonPink,
    ),
    _task(
      id: 'life_trader_50',
      title: 'Trader I',
      description:
          'Complete 50 successful trades. Lifetime progress never resets after wipes.',
      cadence: ArcOperationCadence.lifetime,
      category: ArcOperationCategory.trading,
      target: 50,
      rewards: [rewards['extra_trade']!, rewards['xp_25']!],
      accent: AppTheme.neonPink,
    ),
    _task(
      id: 'life_guardian_10',
      title: 'Guardian',
      description:
          'Help 10 Raiders through trades, matchmaking or early progression.',
      cadence: ArcOperationCadence.lifetime,
      category: ArcOperationCategory.guardian,
      target: 10,
      rewards: [rewards['community_raider']!],
      accent: Colors.lightGreenAccent,
    ),
    _task(
      id: 'life_recruit_3',
      title: 'Recruitment Cell',
      description:
          'Refer 3 active Raiders who complete profile setup and return on 3 separate days.',
      cadence: ArcOperationCadence.lifetime,
      category: ArcOperationCategory.referral,
      target: 3,
      rewards: [rewards['inner_circle']!],
      accent: Colors.amberAccent,
    ),
  ];

  static ArcOperationsSummary summary = const ArcOperationsSummary(
    rankLabel: 'Beta Pathfinder',
    intelXp: 125,
    completed: 0,
    available: 21,
    communityHealth: 0.62,
  );

  static ArcOperationTask _task({
    required String id,
    required String title,
    required String description,
    required ArcOperationCadence cadence,
    required ArcOperationCategory category,
    required int target,
    int progress = 0,
    required List<ArcOperationReward> rewards,
    required Color accent,
    bool betaExclusive = false,
    bool verificationRequired = false,
  }) {
    return ArcOperationTask(
      id: id,
      title: title,
      description: description,
      cadence: cadence,
      category: category,
      target: target,
      progress: progress,
      rewards: rewards,
      accent: accent,
      betaExclusive: betaExclusive,
      verificationRequired: verificationRequired,
    );
  }
}
