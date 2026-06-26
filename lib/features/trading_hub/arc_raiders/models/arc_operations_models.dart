import 'package:flutter/material.dart';

/// ARC Operations are adaptive reward goals that drive the player, community,
/// beta testing, referrals, trading, matchmaking and positive behaviour loops.
enum ArcOperationCadence { daily, weekly, monthly, lifetime, beta }

enum ArcOperationCategory {
  onboarding,
  trading,
  intel,
  matchmaking,
  loadout,
  community,
  guardian,
  referral,
  beta,
}

enum ArcOperationRewardType {
  intelXp,
  badge,
  title,
  profileFrame,
  tradeSlot,
  matchmakingSlot,
  premiumTrial,
  operationCredit,
}

class ArcOperationReward {
  const ArcOperationReward({
    required this.id,
    required this.label,
    required this.type,
    this.amount = 1,
    this.assetPath,
    this.betaExclusive = false,
  });

  final String id;
  final String label;
  final ArcOperationRewardType type;
  final int amount;
  final String? assetPath;
  final bool betaExclusive;
}

class ArcOperationTask {
  const ArcOperationTask({
    required this.id,
    required this.title,
    required this.description,
    required this.cadence,
    required this.category,
    required this.target,
    required this.rewards,
    this.progress = 0,
    this.actionLabel = 'Track progress',
    this.accent = const Color(0xFF00FFFF),
    this.betaExclusive = false,
    this.verificationRequired = false,
  });

  final String id;
  final String title;
  final String description;
  final ArcOperationCadence cadence;
  final ArcOperationCategory category;
  final int target;
  final int progress;
  final List<ArcOperationReward> rewards;
  final String actionLabel;
  final Color accent;
  final bool betaExclusive;
  final bool verificationRequired;

  double get completion {
    if (target <= 0) return 0;
    return (progress / target).clamp(0, 1).toDouble();
  }

  bool get isComplete => progress >= target;

  ArcOperationTask copyWith({int? progress}) {
    return ArcOperationTask(
      id: id,
      title: title,
      description: description,
      cadence: cadence,
      category: category,
      target: target,
      progress: progress ?? this.progress,
      rewards: rewards,
      actionLabel: actionLabel,
      accent: accent,
      betaExclusive: betaExclusive,
      verificationRequired: verificationRequired,
    );
  }
}

class ArcOperationsSummary {
  const ArcOperationsSummary({
    required this.rankLabel,
    required this.intelXp,
    required this.completed,
    required this.available,
    required this.communityHealth,
  });

  final String rankLabel;
  final int intelXp;
  final int completed;
  final int available;
  final double communityHealth;
}
