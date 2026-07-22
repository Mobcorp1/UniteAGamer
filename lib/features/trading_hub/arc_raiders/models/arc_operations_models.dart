import 'package:flutter/material.dart';

class ArcSeasonDefaults {
  const ArcSeasonDefaults._();

  static const closedBetaSeasonOne = 'closed-beta-season-1';
}

/// ARC Operations are adaptive reward goals that drive the player, community,
/// beta testing, referrals, trading, matchmaking and positive behaviour loops.
enum ArcOperationCadence { daily, weekly, monthly, lifetime, beta }

enum ArcOperationDifficulty { starter, standard, demanding, elite }

enum ArcOperationAccessTier { free, essential, premium }

enum ArcOperationTrack {
  daily,
  weekly,
  monthly,
  lifetime,
  community,
  founder,
  closedBeta,
  seasonal,
}

enum ArcOperationCategory {
  onboarding,
  trading,
  intel,
  matchmaking,
  loadout,
  quest,
  progression,
  community,
  guardian,
  referral,
  beta,
  founder,
  seasonal,
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
    this.difficulty = ArcOperationDifficulty.standard,
    this.accessTier = ArcOperationAccessTier.free,
    this.weight = 100,
    this.tracks = const <ArcOperationTrack>[],
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
  final ArcOperationDifficulty difficulty;
  final ArcOperationAccessTier accessTier;
  final int weight;
  final List<ArcOperationTrack> tracks;

  double get completion {
    if (target <= 0) {
      return 0;
    }
    return (progress / target).clamp(0, 1).toDouble();
  }

  bool get isComplete => progress >= target;
  bool get resetsWithSeason => cadence != ArcOperationCadence.lifetime;
  bool get repeatableBySeason => resetsWithSeason;
  bool get permanentProgress => cadence == ArcOperationCadence.lifetime;
  bool get isFairForFreeTier => accessTier == ArcOperationAccessTier.free;
  bool get grantsPermanentRewards =>
      cadence == ArcOperationCadence.lifetime ||
      cadence == ArcOperationCadence.beta ||
      betaExclusive ||
      category == ArcOperationCategory.community ||
      category == ArcOperationCategory.guardian ||
      category == ArcOperationCategory.referral ||
      category == ArcOperationCategory.founder;

  ArcOperationTask copyWith({
    int? progress,
    int? target,
    List<ArcOperationReward>? rewards,
    String? actionLabel,
    bool? betaExclusive,
    bool? verificationRequired,
    ArcOperationDifficulty? difficulty,
    ArcOperationAccessTier? accessTier,
    int? weight,
    List<ArcOperationTrack>? tracks,
  }) {
    return ArcOperationTask(
      id: id,
      title: title,
      description: description,
      cadence: cadence,
      category: category,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      rewards: rewards ?? this.rewards,
      actionLabel: actionLabel ?? this.actionLabel,
      accent: accent,
      betaExclusive: betaExclusive ?? this.betaExclusive,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      difficulty: difficulty ?? this.difficulty,
      accessTier: accessTier ?? this.accessTier,
      weight: weight ?? this.weight,
      tracks: tracks ?? this.tracks,
    );
  }
}

class ArcOperationTuningConfig {
  const ArcOperationTuningConfig({
    this.enabled = true,
    this.seasonId = '',
    this.startsAt,
    this.endsAt,
    this.cadenceLimits = const <ArcOperationCadence, int>{},
    this.categoryWeights = const <ArcOperationCategory, int>{},
    this.taskWeightOverrides = const <String, int>{},
    this.taskTargetOverrides = const <String, int>{},
    this.disabledTaskIds = const <String>{},
    this.featuredTaskIds = const <String>{},
  });

  final bool enabled;
  final String seasonId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final Map<ArcOperationCadence, int> cadenceLimits;
  final Map<ArcOperationCategory, int> categoryWeights;
  final Map<String, int> taskWeightOverrides;
  final Map<String, int> taskTargetOverrides;
  final Set<String> disabledTaskIds;
  final Set<String> featuredTaskIds;

  static const fallback = ArcOperationTuningConfig(
    cadenceLimits: <ArcOperationCadence, int>{
      ArcOperationCadence.daily: 3,
      ArcOperationCadence.weekly: 4,
      ArcOperationCadence.monthly: 3,
      ArcOperationCadence.lifetime: 6,
      ArcOperationCadence.beta: 6,
    },
    categoryWeights: <ArcOperationCategory, int>{
      ArcOperationCategory.onboarding: 190,
      ArcOperationCategory.trading: 130,
      ArcOperationCategory.intel: 120,
      ArcOperationCategory.matchmaking: 120,
      ArcOperationCategory.loadout: 115,
      ArcOperationCategory.quest: 120,
      ArcOperationCategory.progression: 120,
      ArcOperationCategory.community: 115,
      ArcOperationCategory.guardian: 115,
      ArcOperationCategory.referral: 110,
      ArcOperationCategory.beta: 220,
      ArcOperationCategory.founder: 190,
      ArcOperationCategory.seasonal: 125,
    },
  );

  bool get hasActiveWindow {
    final now = DateTime.now().toUtc();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  int limitFor(ArcOperationCadence cadence) {
    return cadenceLimits[cadence] ?? fallback.cadenceLimits[cadence] ?? 3;
  }

  int categoryWeight(ArcOperationCategory category) {
    return categoryWeights[category] ??
        fallback.categoryWeights[category] ??
        100;
  }

  bool isTaskEnabled(ArcOperationTask task) {
    return enabled && hasActiveWindow && !disabledTaskIds.contains(task.id);
  }

  bool isTaskFeatured(ArcOperationTask task) =>
      featuredTaskIds.contains(task.id);

  ArcOperationTask applyToTask(ArcOperationTask task) {
    final target = taskTargetOverrides[task.id];
    return task.copyWith(
      target: target == null || target <= 0 ? null : target,
      weight: taskWeightOverrides[task.id] ?? task.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'seasonId': seasonId,
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'cadenceLimits': {
        for (final entry in cadenceLimits.entries) entry.key.name: entry.value,
      },
      'categoryWeights': {
        for (final entry in categoryWeights.entries)
          entry.key.name: entry.value,
      },
      'taskWeightOverrides': taskWeightOverrides,
      'taskTargetOverrides': taskTargetOverrides,
      'disabledTaskIds': disabledTaskIds.toList()..sort(),
      'featuredTaskIds': featuredTaskIds.toList()..sort(),
    };
  }

  factory ArcOperationTuningConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return fallback;
    return ArcOperationTuningConfig(
      enabled: _bool(map['enabled'], fallback: fallback.enabled),
      seasonId: _stringValue(map['seasonId']),
      startsAt: _dateValue(map['startsAt']),
      endsAt: _dateValue(map['endsAt']),
      cadenceLimits: _enumIntMap(
        map['cadenceLimits'],
        ArcOperationCadence.values,
        fallback.cadenceLimits,
      ),
      categoryWeights: _enumIntMap(
        map['categoryWeights'],
        ArcOperationCategory.values,
        fallback.categoryWeights,
      ),
      taskWeightOverrides: _stringIntMap(map['taskWeightOverrides']),
      taskTargetOverrides: _stringIntMap(map['taskTargetOverrides']),
      disabledTaskIds: _stringSet(map['disabledTaskIds']),
      featuredTaskIds: _stringSet(map['featuredTaskIds']),
    );
  }

  static Map<T, int> _enumIntMap<T extends Enum>(
    dynamic value,
    List<T> values,
    Map<T, int> fallback,
  ) {
    final raw = value is Map
        ? value.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    if (raw.isEmpty) return fallback;
    final result = <T, int>{};
    for (final enumValue in values) {
      final parsed = _intValue(raw[enumValue.name]);
      if (parsed != null) result[enumValue] = parsed;
    }
    return result.isEmpty ? fallback : result;
  }

  static Map<String, int> _stringIntMap(dynamic value) {
    if (value is! Map) return const <String, int>{};
    final result = <String, int>{};
    value.forEach((key, value) {
      final text = key.toString().trim();
      final parsed = _intValue(value);
      if (text.isNotEmpty && parsed != null) result[text] = parsed;
    });
    return result;
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    return const <String>{};
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool _bool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'enabled') {
        return true;
      }
      if (normalized == 'false' ||
          normalized == 'no' ||
          normalized == 'disabled') {
        return false;
      }
    }
    return fallback;
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }
}

class ArcOperationProgress {
  const ArcOperationProgress({
    required this.operationId,
    this.progress = 0,
    this.target = 1,
    this.claimed = false,
    this.seasonId,
    this.updatedAt,
    this.claimedAt,
  });

  final String operationId;
  final int progress;
  final int target;
  final bool claimed;
  final String? seasonId;
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
      'seasonId': seasonId,
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
      seasonId: _stringField(map, 'seasonId'),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()),
      claimedAt: DateTime.tryParse((map['claimedAt'] ?? '').toString()),
    );
  }

  static String? _stringField(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
    this.sourceSeasonId,
    this.sourceOperationId,
    this.permanent = true,
    this.historicalVisible = true,
    this.equipableAfterSeason = true,
    this.currentSeasonUnlock = true,
  });

  final String rewardId;
  final String label;
  final ArcOperationRewardType type;
  final String? assetPath;
  final ArcCosmeticRarity rarity;
  final bool betaExclusive;
  final DateTime? unlockedAt;
  final String? sourceSeasonId;
  final String? sourceOperationId;
  final bool permanent;
  final bool historicalVisible;
  final bool equipableAfterSeason;
  final bool currentSeasonUnlock;

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
      'sourceSeasonId': sourceSeasonId,
      'sourceOperationId': sourceOperationId,
      'permanent': permanent,
      'historicalVisible': historicalVisible,
      'equipableAfterSeason': equipableAfterSeason,
      'currentSeasonUnlock': currentSeasonUnlock,
    };
  }

  factory ArcRewardInventoryItem.fromReward(
    ArcOperationReward reward, {
    String? sourceSeasonId,
    String? sourceOperationId,
    bool permanent = true,
    bool historicalVisible = true,
    bool equipableAfterSeason = true,
    bool currentSeasonUnlock = true,
  }) {
    return ArcRewardInventoryItem(
      rewardId: reward.id,
      label: reward.label,
      type: reward.type,
      assetPath: reward.assetPath,
      rarity: reward.rarity,
      betaExclusive: reward.betaExclusive,
      unlockedAt: DateTime.now(),
      sourceSeasonId: sourceSeasonId,
      sourceOperationId: sourceOperationId,
      permanent: permanent,
      historicalVisible: historicalVisible,
      equipableAfterSeason: equipableAfterSeason,
      currentSeasonUnlock: currentSeasonUnlock,
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
      sourceSeasonId: _stringField(map, 'sourceSeasonId'),
      sourceOperationId: _stringField(map, 'sourceOperationId'),
      permanent: map['permanent'] != false,
      historicalVisible: map['historicalVisible'] != false,
      equipableAfterSeason: map['equipableAfterSeason'] != false,
      currentSeasonUnlock: map['currentSeasonUnlock'] != false,
    );
  }

  static String? _stringField(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
    this.seasonalXp = 0,
    this.operationCredits = 0,
    this.extraTradeSlots = 0,
    this.extraMatchmakingSlots = 0,
    this.currentSeasonId = ArcSeasonDefaults.closedBetaSeasonOne,
    this.lastCompletedSeasonId,
    this.telemetrySummary = const ArcOperationTelemetrySummary(),
    this.tuningConfig = ArcOperationTuningConfig.fallback,
  });

  final Map<String, ArcOperationProgress> progressById;
  final List<ArcRewardInventoryItem> inventory;
  final ArcEquippedCosmetics equippedCosmetics;
  final int intelXp;
  final int seasonalXp;
  final int operationCredits;
  final int extraTradeSlots;
  final int extraMatchmakingSlots;
  final String currentSeasonId;
  final String? lastCompletedSeasonId;
  final ArcOperationTelemetrySummary telemetrySummary;
  final ArcOperationTuningConfig tuningConfig;

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

  int get readyToClaimCount =>
      progressById.values.where((progress) => progress.readyToClaim).length;

  int get inProgressCount => progressById.values
      .where(
        (progress) =>
            progress.progress > 0 &&
            progress.progress < progress.target &&
            !progress.claimed,
      )
      .length;

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
  questCompleted,
  scrappyUpgradeCompleted,
  benchUpgradeCompleted,
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
    ArcOperationTelemetryType.questCompleted => 'quest_completed',
    ArcOperationTelemetryType.scrappyUpgradeCompleted =>
      'scrappy_upgrade_completed',
    ArcOperationTelemetryType.benchUpgradeCompleted =>
      'bench_upgrade_completed',
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
    this.loginEvents = 0,
    this.profileCompletions = 0,
    this.playersHelped = 0,
    this.guardianSessions = 0,
    this.referrals = 0,
    this.communityContributions = 0,
    this.favouriteLoadoutsSaved = 0,
    this.feedbackSubmitted = 0,
    this.availabilitySaved = 0,
    this.intelConfirmed = 0,
    this.questsCompleted = 0,
    this.scrappyUpgrades = 0,
    this.benchUpgrades = 0,
  });

  final int tradesCompleted;
  final int listingsCreated;
  final int matchmakingSessions;
  final int blueprintReports;
  final int loginEvents;
  final int profileCompletions;
  final int playersHelped;
  final int guardianSessions;
  final int referrals;
  final int communityContributions;
  final int favouriteLoadoutsSaved;
  final int feedbackSubmitted;
  final int availabilitySaved;
  final int intelConfirmed;
  final int questsCompleted;
  final int scrappyUpgrades;
  final int benchUpgrades;

  int get totalActivity =>
      tradesCompleted +
      listingsCreated +
      matchmakingSessions +
      blueprintReports +
      loginEvents +
      profileCompletions +
      playersHelped +
      guardianSessions +
      referrals +
      communityContributions +
      favouriteLoadoutsSaved +
      feedbackSubmitted +
      availabilitySaved +
      intelConfirmed +
      questsCompleted +
      scrappyUpgrades +
      benchUpgrades;

  int get verifiedIntelActivity => blueprintReports + intelConfirmed;
  int get progressionActivity =>
      questsCompleted + scrappyUpgrades + benchUpgrades;
  int get socialActivity =>
      playersHelped + guardianSessions + referrals + communityContributions;

  factory ArcOperationTelemetrySummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ArcOperationTelemetrySummary();
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return ArcOperationTelemetrySummary(
      tradesCompleted: read('tradesCompleted'),
      listingsCreated: read('listingsCreated'),
      matchmakingSessions: read('matchmakingSessions'),
      blueprintReports: read('blueprintReports'),
      loginEvents: read('loginEvents'),
      profileCompletions: read('profileCompletions'),
      playersHelped: read('playersHelped'),
      guardianSessions: read('guardianSessions'),
      referrals: read('referrals'),
      communityContributions: read('communityContributions'),
      favouriteLoadoutsSaved: read('favouriteLoadoutsSaved'),
      feedbackSubmitted: read('feedbackSubmitted'),
      availabilitySaved: read('availabilitySaved'),
      intelConfirmed: read('intelConfirmed'),
      questsCompleted: read('questsCompleted'),
      scrappyUpgrades: read('scrappyUpgrades'),
      benchUpgrades: read('benchUpgrades'),
    );
  }
}
