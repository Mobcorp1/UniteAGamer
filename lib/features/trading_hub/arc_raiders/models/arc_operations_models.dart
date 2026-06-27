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

enum ArcOperationClaimState { locked, inProgress, readyToClaim, completed }

enum ArcCosmeticType { badge, title, profileFrame }

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

  bool get isCosmetic =>
      type == ArcOperationRewardType.badge ||
      type == ArcOperationRewardType.title ||
      type == ArcOperationRewardType.profileFrame;

  ArcCosmeticType? get cosmeticType => switch (type) {
    ArcOperationRewardType.badge => ArcCosmeticType.badge,
    ArcOperationRewardType.title => ArcCosmeticType.title,
    ArcOperationRewardType.profileFrame => ArcCosmeticType.profileFrame,
    _ => null,
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'amount': amount,
      'assetPath': assetPath,
      'betaExclusive': betaExclusive,
    };
  }

  factory ArcOperationReward.fromMap(Map<String, dynamic> map) {
    return ArcOperationReward(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      type: ArcOperationRewardType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ArcOperationRewardType.intelXp,
      ),
      amount: (map['amount'] as num?)?.toInt() ?? 1,
      assetPath: map['assetPath'] as String?,
      betaExclusive: map['betaExclusive'] == true,
    );
  }
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
    if (target <= 0) {
      return 0;
    }
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

class ArcOperationProgress {
  const ArcOperationProgress({
    required this.operationId,
    this.progress = 0,
    this.target = 1,
    this.claimed = false,
    this.updatedAt,
    this.claimedAt,
  });

  final String operationId;
  final int progress;
  final int target;
  final bool claimed;
  final DateTime? updatedAt;
  final DateTime? claimedAt;

  bool get readyToClaim => progress >= target && !claimed;
  bool get completed => progress >= target && claimed;

  ArcOperationClaimState get claimState {
    if (completed) return ArcOperationClaimState.completed;
    if (readyToClaim) return ArcOperationClaimState.readyToClaim;
    if (progress > 0) return ArcOperationClaimState.inProgress;
    return ArcOperationClaimState.locked;
  }

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'progress': progress,
      'target': target,
      'claimed': claimed,
      'updatedAt': updatedAt?.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
    };
  }

  factory ArcOperationProgress.fromMap(String id, Map<String, dynamic> map) {
    return ArcOperationProgress(
      operationId: (map['operationId'] ?? id).toString(),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 1,
      claimed: map['claimed'] == true,
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()),
      claimedAt: DateTime.tryParse((map['claimedAt'] ?? '').toString()),
    );
  }
}

class ArcRewardInventoryItem {
  const ArcRewardInventoryItem({
    required this.rewardId,
    required this.label,
    required this.type,
    this.assetPath,
    this.betaExclusive = false,
    this.unlockedAt,
  });

  final String rewardId;
  final String label;
  final ArcOperationRewardType type;
  final String? assetPath;
  final bool betaExclusive;
  final DateTime? unlockedAt;

  Map<String, dynamic> toMap() {
    return {
      'rewardId': rewardId,
      'label': label,
      'type': type.name,
      'assetPath': assetPath,
      'betaExclusive': betaExclusive,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory ArcRewardInventoryItem.fromReward(ArcOperationReward reward) {
    return ArcRewardInventoryItem(
      rewardId: reward.id,
      label: reward.label,
      type: reward.type,
      assetPath: reward.assetPath,
      betaExclusive: reward.betaExclusive,
      unlockedAt: DateTime.now(),
    );
  }

  factory ArcRewardInventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return ArcRewardInventoryItem(
      rewardId: (map['rewardId'] ?? id).toString(),
      label: (map['label'] ?? '').toString(),
      type: ArcOperationRewardType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ArcOperationRewardType.badge,
      ),
      assetPath: map['assetPath'] as String?,
      betaExclusive: map['betaExclusive'] == true,
      unlockedAt: DateTime.tryParse((map['unlockedAt'] ?? '').toString()),
    );
  }
}

class ArcEquippedCosmetics {
  const ArcEquippedCosmetics({
    this.badgeId,
    this.titleId,
    this.profileFrameId,
    this.badgeAssetPath,
    this.titleLabel,
    this.profileFrameAssetPath,
  });

  final String? badgeId;
  final String? titleId;
  final String? profileFrameId;
  final String? badgeAssetPath;
  final String? titleLabel;
  final String? profileFrameAssetPath;

  bool get hasBadge => badgeId != null && badgeId!.isNotEmpty;
  bool get hasTitle => titleId != null && titleId!.isNotEmpty;
  bool get hasFrame => profileFrameId != null && profileFrameId!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'titleId': titleId,
      'profileFrameId': profileFrameId,
      'badgeAssetPath': badgeAssetPath,
      'titleLabel': titleLabel,
      'profileFrameAssetPath': profileFrameAssetPath,
    };
  }

  factory ArcEquippedCosmetics.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ArcEquippedCosmetics();
    return ArcEquippedCosmetics(
      badgeId: map['badgeId'] as String?,
      titleId: map['titleId'] as String?,
      profileFrameId: map['profileFrameId'] as String?,
      badgeAssetPath: map['badgeAssetPath'] as String?,
      titleLabel: map['titleLabel'] as String?,
      profileFrameAssetPath: map['profileFrameAssetPath'] as String?,
    );
  }
}

class ArcOperationsUserState {
  const ArcOperationsUserState({
    required this.progressById,
    required this.inventory,
    required this.equippedCosmetics,
    this.intelXp = 0,
    this.operationCredits = 0,
    this.extraTradeSlots = 0,
    this.extraMatchmakingSlots = 0,
  });

  final Map<String, ArcOperationProgress> progressById;
  final List<ArcRewardInventoryItem> inventory;
  final ArcEquippedCosmetics equippedCosmetics;
  final int intelXp;
  final int operationCredits;
  final int extraTradeSlots;
  final int extraMatchmakingSlots;

  static const empty = ArcOperationsUserState(
    progressById: {},
    inventory: [],
    equippedCosmetics: ArcEquippedCosmetics(),
  );

  int get operationLevel {
    if (intelXp >= 1000) return 10;
    if (intelXp >= 750) return 8;
    if (intelXp >= 500) return 6;
    if (intelXp >= 250) return 4;
    if (intelXp >= 100) return 2;
    return 1;
  }

  int get completedCount =>
      progressById.values.where((progress) => progress.completed).length;

  int progressFor(ArcOperationTask task) =>
      progressById[task.id]?.progress ?? task.progress;

  bool isClaimed(ArcOperationTask task) =>
      progressById[task.id]?.claimed ?? false;

  ArcOperationClaimState stateFor(ArcOperationTask task) {
    final progress = progressFor(task);
    final claimed = isClaimed(task);
    if (progress >= task.target && claimed) {
      return ArcOperationClaimState.completed;
    }
    if (progress >= task.target) return ArcOperationClaimState.readyToClaim;
    if (progress > 0) return ArcOperationClaimState.inProgress;
    return ArcOperationClaimState.locked;
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
