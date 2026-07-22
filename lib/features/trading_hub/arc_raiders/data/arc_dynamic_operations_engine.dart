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
    required this.fairnessLabel,
    required this.tasks,
    required this.accent,
    this.hiddenCompletedCount = 0,
    this.disabledCount = 0,
  });

  final ArcOperationCadence cadence;
  final String title;
  final String subtitle;
  final String strategy;
  final String rotationLabel;
  final String rewardLabel;
  final String priorityLabel;
  final String fairnessLabel;
  final List<ArcOperationTask> tasks;
  final Color accent;
  final int hiddenCompletedCount;
  final int disabledCount;
}

class ArcDynamicOperationsEngine {
  const ArcDynamicOperationsEngine._();

  static ArcDynamicOperationPlan generate({
    required ArcOperationsUserState userState,
    required ArcOperationCadence cadence,
    ArcOperationTuningConfig? config,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final tuning = config ?? userState.tuningConfig;
    final source = _sourceFor(cadence).map(tuning.applyToTask).toList();
    final hiddenCompletedCount = source
        .where(
          (task) =>
              userState.stateFor(task) == ArcOperationClaimState.completed,
        )
        .length;
    final disabledCount = source
        .where((task) => !tuning.isTaskEnabled(task))
        .length;
    final eligible = source
        .where((task) => tuning.isTaskEnabled(task))
        .where((task) {
          final state = userState.stateFor(task);
          return state != ArcOperationClaimState.completed;
        })
        .toList(growable: false);
    final scored =
        eligible
            .map(
              (task) => _ScoredOperationTask(
                task: task,
                score: _scoreTask(task, userState, generatedAt, tuning),
              ),
            )
            .toList()
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) return scoreCompare;
            return a.task.id.compareTo(b.task.id);
          });

    final selected = scored
        .take(tuning.limitFor(cadence))
        .map((entry) => entry.task)
        .toList();

    return ArcDynamicOperationPlan(
      cadence: cadence,
      title: _titleFor(cadence),
      subtitle: _subtitleFor(cadence),
      strategy: _strategyFor(cadence, userState),
      rotationLabel: _rotationLabelFor(cadence, generatedAt),
      rewardLabel: _rewardLabelFor(cadence, userState),
      priorityLabel: _priorityLabelFor(cadence, userState),
      fairnessLabel: _fairnessLabelFor(cadence, userState),
      tasks: selected,
      accent: _accentFor(cadence),
      hiddenCompletedCount: hiddenCompletedCount,
      disabledCount: disabledCount,
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
    ArcOperationTuningConfig tuning,
  ) {
    var score = task.weight;
    final state = userState.stateFor(task);
    final telemetry = userState.telemetrySummary;

    if (state == ArcOperationClaimState.completed) score -= 1000;
    if (state == ArcOperationClaimState.readyToClaim) score += 600;
    if (state == ArcOperationClaimState.inProgress) score += 220;

    score += tuning.categoryWeight(task.category);
    score += _needScore(task, userState, telemetry, now);

    if (task.verificationRequired) score -= 15;
    if (task.betaExclusive) score += 90;
    if (tuning.isTaskFeatured(task)) score += 350;
    if (task.accessTier != ArcOperationAccessTier.free) score -= 80;
    score += switch (task.difficulty) {
      ArcOperationDifficulty.starter => userState.operationLevel <= 2 ? 80 : 15,
      ArcOperationDifficulty.standard => 35,
      ArcOperationDifficulty.demanding => 55,
      ArcOperationDifficulty.elite => 70,
    };
    score += task.rewards.fold<int>(0, (total, reward) {
      final rewardScore = switch (reward.type) {
        ArcOperationRewardType.badge => 70,
        ArcOperationRewardType.title => 60,
        ArcOperationRewardType.profileFrame => 60,
        ArcOperationRewardType.profileBanner => 60,
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

  static int _needScore(
    ArcOperationTask task,
    ArcOperationsUserState userState,
    ArcOperationTelemetrySummary telemetry,
    DateTime now,
  ) {
    return switch (task.category) {
      ArcOperationCategory.onboarding =>
        telemetry.profileCompletions <= 0 && userState.operationLevel <= 2
            ? 230
            : 25,
      ArcOperationCategory.trading =>
        telemetry.listingsCreated <= 0 || telemetry.tradesCompleted <= 0
            ? 210
            : userState.extraTradeSlots <= 1
            ? 120
            : 45,
      ArcOperationCategory.intel =>
        telemetry.verifiedIntelActivity < 3 || userState.intelXp < 250
            ? 170
            : 55,
      ArcOperationCategory.matchmaking =>
        telemetry.matchmakingSessions <= 0 ||
                userState.extraMatchmakingSlots <= 1
            ? 180
            : 55,
      ArcOperationCategory.loadout =>
        telemetry.favouriteLoadoutsSaved <= 0 ? 175 : 55,
      ArcOperationCategory.quest => telemetry.questsCompleted <= 0 ? 160 : 60,
      ArcOperationCategory.progression =>
        telemetry.scrappyUpgrades <= 0 || telemetry.benchUpgrades <= 0
            ? 155
            : 55,
      ArcOperationCategory.community =>
        telemetry.communityContributions <= 0 ? 145 : 65,
      ArcOperationCategory.guardian => telemetry.socialActivity <= 0 ? 160 : 65,
      ArcOperationCategory.referral =>
        telemetry.referrals <= 0 && now.day.isOdd ? 150 : 60,
      ArcOperationCategory.beta =>
        telemetry.feedbackSubmitted < 3 || telemetry.loginEvents < 10
            ? 190
            : 80,
      ArcOperationCategory.founder => 165,
      ArcOperationCategory.seasonal => userState.seasonalXp < 100 ? 140 : 65,
    };
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
    final telemetry = userState.telemetrySummary;
    if (telemetry.listingsCreated <= 0 || telemetry.tradesCompleted <= 0) {
      return 'Prioritising marketplace health because live trade activity is still low.';
    }
    if (telemetry.matchmakingSessions <= 0) {
      return 'Prioritising squad activity because no completed Match Raider session is recorded yet.';
    }
    if (telemetry.verifiedIntelActivity < 3) {
      return 'Prioritising verified intel so Command Centre recommendations can trust more live signals.';
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
    if (userState.readyToClaimCount > 0) return 'CLAIM REWARD';
    if (userState.inventory.isEmpty) return 'UNLOCK FIRST BADGE';
    if (userState.extraTradeSlots <= 1) return 'MARKET HEALTH';
    if (userState.extraMatchmakingSlots <= 1) return 'SQUAD HEALTH';
    return 'BALANCED OPS';
  }

  static String _fairnessLabelFor(
    ArcOperationCadence cadence,
    ArcOperationsUserState userState,
  ) {
    if (cadence == ArcOperationCadence.beta) {
      return 'NO PAY-TO-WIN BETA REPUTATION';
    }
    if (userState.tuningConfig.disabledTaskIds.isNotEmpty) {
      return '${userState.tuningConfig.disabledTaskIds.length} ADMIN HOLD';
    }
    return 'FREE-TIER EARNABLE';
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
