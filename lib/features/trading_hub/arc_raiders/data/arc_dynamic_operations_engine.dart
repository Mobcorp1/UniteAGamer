import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcDynamicOperationPlan {
  const ArcDynamicOperationPlan({
    required this.cadence,
    required this.title,
    required this.subtitle,
    required this.strategy,
    required this.rotationLabel,
    required this.rewardLabel,
    required this.priorityLabel,
    required this.tasks,
    required this.accent,
  });

  final ArcOperationCadence cadence;
  final String title;
  final String subtitle;
  final String strategy;
  final String rotationLabel;
  final String rewardLabel;
  final String priorityLabel;
  final List<ArcOperationTask> tasks;
  final Color accent;
}

class ArcDynamicOperationsEngine {
  const ArcDynamicOperationsEngine._();

  static ArcDynamicOperationPlan generate({
    required ArcOperationsUserState userState,
    required ArcOperationCadence cadence,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final source = _sourceFor(cadence);
    final scored =
        source
            .map(
              (task) => _ScoredOperationTask(
                task: task,
                score: _scoreTask(task, userState, generatedAt),
              ),
            )
            .toList()
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) return scoreCompare;
            return a.task.id.compareTo(b.task.id);
          });

    final limit = switch (cadence) {
      ArcOperationCadence.daily => 3,
      ArcOperationCadence.weekly => 4,
      ArcOperationCadence.monthly => 3,
      ArcOperationCadence.lifetime => 6,
      ArcOperationCadence.beta => 6,
    };

    final selected = scored.take(limit).map((entry) => entry.task).toList();

    return ArcDynamicOperationPlan(
      cadence: cadence,
      title: _titleFor(cadence),
      subtitle: _subtitleFor(cadence),
      strategy: _strategyFor(cadence, userState),
      rotationLabel: _rotationLabelFor(cadence, generatedAt),
      rewardLabel: _rewardLabelFor(cadence, userState),
      priorityLabel: _priorityLabelFor(cadence, userState),
      tasks: selected,
      accent: _accentFor(cadence),
    );
  }

  static List<ArcOperationTask> _sourceFor(ArcOperationCadence cadence) {
    return switch (cadence) {
      ArcOperationCadence.daily => ArcOperationsSeedData.dailyOperations,
      ArcOperationCadence.weekly => ArcOperationsSeedData.weeklyOperations,
      ArcOperationCadence.monthly => ArcOperationsSeedData.monthlyOperations,
      ArcOperationCadence.lifetime => ArcOperationsSeedData.lifetimeOperations,
      ArcOperationCadence.beta => ArcOperationsSeedData.betaOperations,
    };
  }

  static int _scoreTask(
    ArcOperationTask task,
    ArcOperationsUserState userState,
    DateTime now,
  ) {
    var score = 100;
    final state = userState.stateFor(task);

    if (state == ArcOperationClaimState.completed) score -= 1000;
    if (state == ArcOperationClaimState.readyToClaim) score += 600;
    if (state == ArcOperationClaimState.inProgress) score += 220;

    score += switch (task.category) {
      ArcOperationCategory.onboarding =>
        userState.operationLevel <= 2 ? 190 : 25,
      ArcOperationCategory.trading => userState.extraTradeSlots <= 1 ? 170 : 80,
      ArcOperationCategory.intel => userState.intelXp < 250 ? 140 : 75,
      ArcOperationCategory.matchmaking =>
        userState.extraMatchmakingSlots <= 1 ? 150 : 70,
      ArcOperationCategory.loadout => 130,
      ArcOperationCategory.community => userState.inventory.isEmpty ? 120 : 90,
      ArcOperationCategory.guardian => 115,
      ArcOperationCategory.referral => now.day.isOdd ? 160 : 80,
      ArcOperationCategory.beta => 220,
    };

    if (task.verificationRequired) score -= 15;
    if (task.betaExclusive) score += 90;
    score += task.rewards.fold<int>(0, (total, reward) {
      final rewardScore = switch (reward.type) {
        ArcOperationRewardType.badge => 70,
        ArcOperationRewardType.title => 60,
        ArcOperationRewardType.profileFrame => 60,
        ArcOperationRewardType.tradeSlot => 55,
        ArcOperationRewardType.matchmakingSlot => 50,
        ArcOperationRewardType.premiumTrial => 75,
        ArcOperationRewardType.operationCredit => 35,
        ArcOperationRewardType.intelXp => reward.amount,
      };
      return total + rewardScore;
    });

    return score;
  }

  static String _titleFor(ArcOperationCadence cadence) {
    return switch (cadence) {
      ArcOperationCadence.daily => 'Daily Adaptive Ops',
      ArcOperationCadence.weekly => 'Weekly Operations',
      ArcOperationCadence.monthly => 'Monthly Operations',
      ArcOperationCadence.lifetime => 'Lifetime Commendations',
      ArcOperationCadence.beta => 'Closed Beta Exclusives',
    };
  }

  static String _subtitleFor(ArcOperationCadence cadence) {
    return switch (cadence) {
      ArcOperationCadence.daily =>
        'Generated from player needs, community health and platform growth requirements.',
      ArcOperationCadence.weekly =>
        'Higher value goals that push trades, verified intel, squad activity and Guardian behaviour.',
      ArcOperationCadence.monthly =>
        'Longer operations with stronger rewards, reputation impact and retention value.',
      ArcOperationCadence.lifetime =>
        'Permanent trophies, status and reputation milestones that never reset after wipes.',
      ArcOperationCadence.beta =>
        'Unique closed beta rewards, founder progress and testing objectives that will never return.',
    };
  }

  static String _strategyFor(
    ArcOperationCadence cadence,
    ArcOperationsUserState userState,
  ) {
    final needsProfilePush = userState.operationLevel <= 2;
    final needsRewards = userState.inventory.length < 3;
    final needsTrading = userState.extraTradeSlots <= 1;

    if (cadence == ArcOperationCadence.beta) {
      return 'Prioritising permanent beta-only badges, first trade/listing actions, feedback and Guardian activity.';
    }
    if (needsProfilePush) {
      return 'Prioritising onboarding, profile progress and first meaningful community actions.';
    }
    if (needsRewards) {
      return 'Prioritising reward unlocks, visible profile status and community contribution loops.';
    }
    if (needsTrading) {
      return 'Prioritising marketplace health, active listings and trade-slot earning routes.';
    }
    return 'Balancing personal progression with marketplace, intel, matchmaking and growth needs.';
  }

  static String _rotationLabelFor(ArcOperationCadence cadence, DateTime now) {
    return switch (cadence) {
      ArcOperationCadence.daily =>
        'ROTATES DAILY ${now.day.toString().padLeft(2, '0')}',
      ArcOperationCadence.weekly =>
        'WEEK ${_weekOfYear(now).toString().padLeft(2, '0')}',
      ArcOperationCadence.monthly =>
        'MONTH ${now.month.toString().padLeft(2, '0')}',
      ArcOperationCadence.lifetime => 'NEVER RESETS',
      ArcOperationCadence.beta => 'BETA ONLY',
    };
  }

  static String _rewardLabelFor(
    ArcOperationCadence cadence,
    ArcOperationsUserState userState,
  ) {
    final multiplier = switch (cadence) {
      ArcOperationCadence.daily => '1.0X XP',
      ArcOperationCadence.weekly => '1.5X XP',
      ArcOperationCadence.monthly => '2.0X XP',
      ArcOperationCadence.lifetime => 'STATUS',
      ArcOperationCadence.beta => 'EXCLUSIVE',
    };

    if (userState.operationLevel <= 2 && cadence != ArcOperationCadence.beta) {
      return '$multiplier STARTER BOOST';
    }
    return multiplier;
  }

  static String _priorityLabelFor(
    ArcOperationCadence cadence,
    ArcOperationsUserState userState,
  ) {
    if (cadence == ArcOperationCadence.beta) return 'FOUNDER TRACK';
    if (userState.inventory.isEmpty) return 'UNLOCK FIRST BADGE';
    if (userState.extraTradeSlots <= 1) return 'MARKET HEALTH';
    if (userState.extraMatchmakingSlots <= 1) return 'SQUAD HEALTH';
    return 'BALANCED OPS';
  }

  static Color _accentFor(ArcOperationCadence cadence) {
    return switch (cadence) {
      ArcOperationCadence.daily => AppTheme.neonCyan,
      ArcOperationCadence.weekly => AppTheme.neonPink,
      ArcOperationCadence.monthly => Colors.amberAccent,
      ArcOperationCadence.lifetime => Colors.lightGreenAccent,
      ArcOperationCadence.beta => Colors.amberAccent,
    };
  }

  static int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final dayOffset = date.difference(firstDay).inDays;
    return ((dayOffset + firstDay.weekday) / 7).ceil().clamp(1, 53);
  }
}

class _ScoredOperationTask {
  const _ScoredOperationTask({required this.task, required this.score});

  final ArcOperationTask task;
  final int score;
}
