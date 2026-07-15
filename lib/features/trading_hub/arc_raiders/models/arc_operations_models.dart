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
  profileBanner,
  tradeSlot,
  matchmakingSlot,
  premiumTrial,
  operationCredit,
}

enum ArcOperationClaimState { locked, inProgress, readyToClaim, completed }

enum ArcCosmeticType { badge, title, profileFrame, profileBanner }

enum ArcCosmeticRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  founder,
  closedBeta,
  community,
  creator,
}

extension ArcCosmeticRarityLabel on ArcCosmeticRarity {
  String get label => switch (this) {
    ArcCosmeticRarity.common => 'Common',
    ArcCosmeticRarity.uncommon => 'Uncommon',
    ArcCosmeticRarity.rare => 'Rare',
    ArcCosmeticRarity.epic => 'Epic',
    ArcCosmeticRarity.legendary => 'Legendary',
    ArcCosmeticRarity.founder => 'Founder',
    ArcCosmeticRarity.closedBeta => 'Closed Beta',
    ArcCosmeticRarity.community => 'Community',
    ArcCosmeticRarity.creator => 'Creator',
  };

  bool get isExclusive =>
      this == ArcCosmeticRarity.founder ||
      this == ArcCosmeticRarity.closedBeta ||
      this == ArcCosmeticRarity.creator;
}

class ArcOperationReward {
  const ArcOperationReward({
    required this.id,
    required this.label,
    required this.type,
    this.amount = 1,
    this.assetPath,
    this.rarity = ArcCosmeticRarity.common,
    this.betaExclusive = false,
  });

  final String id;
  final String label;
  final ArcOperationRewardType type;
  final int amount;
  final String? assetPath;
  final ArcCosmeticRarity rarity;
  final bool betaExclusive;

  bool get isCosmetic =>
      type == ArcOperationRewardType.badge ||
      type == ArcOperationRewardType.title ||
      type == ArcOperationRewardType.profileFrame ||
      type == ArcOperationRewardType.profileBanner;

  ArcCosmeticType? get cosmeticType => switch (type) {
    ArcOperationRewardType.badge => ArcCosmeticType.badge,
    ArcOperationRewardType.title => ArcCosmeticType.title,
    ArcOperationRewardType.profileFrame => ArcCosmeticType.profileFrame,
    ArcOperationRewardType.profileBanner => ArcCosmeticType.profileBanner,
    _ => null,
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'amount': amount,
      'assetPath': assetPath,
      'rarity': rarity.name,
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
      rarity: ArcCosmeticRarity.values.firstWhere(
        (value) => value.name == map['rarity'],
        orElse: () => ArcCosmeticRarity.common,
      ),
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
    this.rarity = ArcCosmeticRarity.common,
    this.betaExclusive = false,
    this.unlockedAt,
  });

  final String rewardId;
  final String label;
  final ArcOperationRewardType type;
  final String? assetPath;
  final ArcCosmeticRarity rarity;
  final bool betaExclusive;
  final DateTime? unlockedAt;

  ArcCosmeticType? get cosmeticType => switch (type) {
    ArcOperationRewardType.badge => ArcCosmeticType.badge,
    ArcOperationRewardType.title => ArcCosmeticType.title,
    ArcOperationRewardType.profileFrame => ArcCosmeticType.profileFrame,
    ArcOperationRewardType.profileBanner => ArcCosmeticType.profileBanner,
    _ => null,
  };

  bool get isBadge => type == ArcOperationRewardType.badge;
  bool get isTitle => type == ArcOperationRewardType.title;
  bool get isProfileFrame => type == ArcOperationRewardType.profileFrame;
  bool get isProfileBanner => type == ArcOperationRewardType.profileBanner;
  bool get isExclusive => betaExclusive || rarity.isExclusive;
  String get rarityLabel => rarity.label;

  Map<String, dynamic> toMap() {
    return {
      'rewardId': rewardId,
      'label': label,
      'type': type.name,
      'assetPath': assetPath,
      'rarity': rarity.name,
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
      rarity: reward.rarity,
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
      rarity: ArcCosmeticRarity.values.firstWhere(
        (value) => value.name == map['rarity'],
        orElse: () => ArcCosmeticRarity.common,
      ),
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
    this.profileBannerId,
    this.badgeAssetPath,
    this.titleLabel,
    this.profileFrameAssetPath,
    this.profileBannerAssetPath,
  });

  final String? badgeId;
  final String? titleId;
  final String? profileFrameId;
  final String? profileBannerId;
  final String? badgeAssetPath;
  final String? titleLabel;
  final String? profileFrameAssetPath;
  final String? profileBannerAssetPath;

  bool get hasBadge => badgeId != null && badgeId!.isNotEmpty;
  bool get hasTitle => titleId != null && titleId!.isNotEmpty;
  bool get hasFrame => profileFrameId != null && profileFrameId!.isNotEmpty;
  bool get hasBanner => profileBannerId != null && profileBannerId!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'equippedBadgeId': badgeId,
      'equippedTitleId': titleId,
      'equippedProfileFrameId': profileFrameId,
      'equippedProfileBannerId': profileBannerId,
      'badgeId': badgeId,
      'titleId': titleId,
      'profileFrameId': profileFrameId,
      'profileBannerId': profileBannerId,
      'badgeAssetPath': badgeAssetPath,
      'titleLabel': titleLabel,
      'profileFrameAssetPath': profileFrameAssetPath,
      'profileBannerAssetPath': profileBannerAssetPath,
    };
  }

  ArcEquippedCosmetics copyWith({
    String? badgeId,
    String? titleId,
    String? profileFrameId,
    String? profileBannerId,
    String? badgeAssetPath,
    String? titleLabel,
    String? profileFrameAssetPath,
    String? profileBannerAssetPath,
  }) {
    return ArcEquippedCosmetics(
      badgeId: badgeId ?? this.badgeId,
      titleId: titleId ?? this.titleId,
      profileFrameId: profileFrameId ?? this.profileFrameId,
      profileBannerId: profileBannerId ?? this.profileBannerId,
      badgeAssetPath: badgeAssetPath ?? this.badgeAssetPath,
      titleLabel: titleLabel ?? this.titleLabel,
      profileFrameAssetPath:
          profileFrameAssetPath ?? this.profileFrameAssetPath,
      profileBannerAssetPath:
          profileBannerAssetPath ?? this.profileBannerAssetPath,
    );
  }

  factory ArcEquippedCosmetics.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ArcEquippedCosmetics();
    return ArcEquippedCosmetics(
      badgeId: _stringField(map, 'equippedBadgeId', 'badgeId'),
      titleId: _stringField(map, 'equippedTitleId', 'titleId'),
      profileFrameId: _stringField(
        map,
        'equippedProfileFrameId',
        'profileFrameId',
      ),
      profileBannerId: _stringField(
        map,
        'equippedProfileBannerId',
        'profileBannerId',
      ),
      badgeAssetPath: map['badgeAssetPath'] as String?,
      titleLabel: map['titleLabel'] as String?,
      profileFrameAssetPath: map['profileFrameAssetPath'] as String?,
      profileBannerAssetPath: map['profileBannerAssetPath'] as String?,
    );
  }

  static String? _stringField(
    Map<String, dynamic> map,
    String primary,
    String legacy,
  ) {
    final value = map[primary] ?? map[legacy];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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

  List<ArcRewardInventoryItem> get badges => inventory
      .where((item) => item.type == ArcOperationRewardType.badge)
      .toList(growable: false);

  List<ArcRewardInventoryItem> get titles => inventory
      .where((item) => item.type == ArcOperationRewardType.title)
      .toList(growable: false);

  List<ArcRewardInventoryItem> get profileFrames => inventory
      .where((item) => item.type == ArcOperationRewardType.profileFrame)
      .toList(growable: false);

  List<ArcRewardInventoryItem> get profileBanners => inventory
      .where((item) => item.type == ArcOperationRewardType.profileBanner)
      .toList(growable: false);

  bool ownsReward(String rewardId) =>
      inventory.any((item) => item.rewardId == rewardId);

  ArcRewardInventoryItem? equippedBadge() {
    final id = equippedCosmetics.badgeId;
    if (id == null) return null;
    for (final item in badges) {
      if (item.rewardId == id) return item;
    }
    return null;
  }

  ArcRewardInventoryItem? equippedTitle() {
    final id = equippedCosmetics.titleId;
    if (id == null) return null;
    for (final item in titles) {
      if (item.rewardId == id) return item;
    }
    return null;
  }

  ArcRewardInventoryItem? equippedProfileFrame() {
    final id = equippedCosmetics.profileFrameId;
    if (id == null) return null;
    for (final item in profileFrames) {
      if (item.rewardId == id) return item;
    }
    return null;
  }

  ArcRewardInventoryItem? equippedProfileBanner() {
    final id = equippedCosmetics.profileBannerId;
    if (id == null) return null;
    for (final item in profileBanners) {
      if (item.rewardId == id) return item;
    }
    return null;
  }

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

enum ArcOperationTelemetryType {
  tradeCompleted,
  listingCreated,
  matchmakingCompleted,
  blueprintReportSubmitted,
  loginRecorded,
  profileCompleted,
  referralCompleted,
  playerHelped,
  guardianSessionCompleted,
  communityContribution,
  favouriteLoadoutSaved,
  feedbackSubmitted,
  availabilitySaved,
  intelConfirmed,
}

class ArcOperationTelemetryEvent {
  const ArcOperationTelemetryEvent({
    required this.type,
    this.amount = 1,
    this.source = 'app',
    this.metadata = const <String, dynamic>{},
    this.createdAt,
  });

  final ArcOperationTelemetryType type;
  final int amount;
  final String source;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  String get eventName => switch (type) {
    ArcOperationTelemetryType.tradeCompleted => 'trade_completed',
    ArcOperationTelemetryType.listingCreated => 'listing_created',
    ArcOperationTelemetryType.matchmakingCompleted => 'match_completed',
    ArcOperationTelemetryType.blueprintReportSubmitted =>
      'blueprint_report_submitted',
    ArcOperationTelemetryType.loginRecorded => 'login_recorded',
    ArcOperationTelemetryType.profileCompleted => 'profile_completed',
    ArcOperationTelemetryType.referralCompleted => 'referral_completed',
    ArcOperationTelemetryType.playerHelped => 'player_helped',
    ArcOperationTelemetryType.guardianSessionCompleted =>
      'guardian_session_completed',
    ArcOperationTelemetryType.communityContribution =>
      'community_contribution_added',
    ArcOperationTelemetryType.favouriteLoadoutSaved =>
      'favourite_loadout_saved',
    ArcOperationTelemetryType.feedbackSubmitted => 'feedback_submitted',
    ArcOperationTelemetryType.availabilitySaved => 'availability_saved',
    ArcOperationTelemetryType.intelConfirmed => 'intel_confirmed',
  };

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'eventName': eventName,
      'amount': amount,
      'source': source,
      'metadata': metadata,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

class ArcOperationTelemetrySummary {
  const ArcOperationTelemetrySummary({
    this.tradesCompleted = 0,
    this.listingsCreated = 0,
    this.matchmakingSessions = 0,
    this.blueprintReports = 0,
    this.playersHelped = 0,
    this.guardianSessions = 0,
    this.referrals = 0,
    this.communityContributions = 0,
  });

  final int tradesCompleted;
  final int listingsCreated;
  final int matchmakingSessions;
  final int blueprintReports;
  final int playersHelped;
  final int guardianSessions;
  final int referrals;
  final int communityContributions;

  int get totalActivity =>
      tradesCompleted +
      listingsCreated +
      matchmakingSessions +
      blueprintReports +
      playersHelped +
      guardianSessions +
      referrals +
      communityContributions;

  factory ArcOperationTelemetrySummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ArcOperationTelemetrySummary();
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return ArcOperationTelemetrySummary(
      tradesCompleted: read('tradesCompleted'),
      listingsCreated: read('listingsCreated'),
      matchmakingSessions: read('matchmakingSessions'),
      blueprintReports: read('blueprintReports'),
      playersHelped: read('playersHelped'),
      guardianSessions: read('guardianSessions'),
      referrals: read('referrals'),
      communityContributions: read('communityContributions'),
    );
  }
}
