import 'package:cloud_firestore/cloud_firestore.dart';

class RaidPlannerBlueprintRule {
  final String blueprintId;
  final String blueprintName;
  final String eventName;
  final String reason;

  const RaidPlannerBlueprintRule({
    required this.blueprintId,
    required this.blueprintName,
    required this.eventName,
    required this.reason,
  });

  bool get isExactEventRule {
    return blueprintId == 'surge-coil' ||
        blueprintId == 'canto' ||
        blueprintId == 'dolabra';
  }
}

class RaidPlannerEventSlot {
  final String mapName;
  final String eventName;
  final String lane;
  final int startHourGmt;
  final int endHourGmt;

  const RaidPlannerEventSlot({
    required this.mapName,
    required this.eventName,
    required this.lane,
    required this.startHourGmt,
    required this.endHourGmt,
  });

  DateTime startForDay(DateTime utcDay) {
    return DateTime.utc(utcDay.year, utcDay.month, utcDay.day, startHourGmt);
  }

  DateTime endForStart(DateTime startUtc) {
    final normalizedEndHour = endHourGmt == 24 ? 0 : endHourGmt;
    var end = DateTime.utc(
      startUtc.year,
      startUtc.month,
      startUtc.day,
      normalizedEndHour,
    );
    if (endHourGmt == 24 || !end.isAfter(startUtc)) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  bool isActiveAt(DateTime utcNow) {
    final start = startForDay(utcNow);
    final end = endForStart(start);
    return !utcNow.isBefore(start) && utcNow.isBefore(end);
  }

  DateTime nextStartAfter(DateTime utcNow) {
    final todayStart = startForDay(utcNow);
    if (todayStart.isAfter(utcNow)) return todayStart;
    return todayStart.add(const Duration(days: 1));
  }

  DateTime activeStartFor(DateTime utcNow) {
    if (isActiveAt(utcNow)) return startForDay(utcNow);
    return nextStartAfter(utcNow);
  }

  DateTime activeEndFor(DateTime utcNow) {
    return endForStart(activeStartFor(utcNow));
  }
}

enum RaidTargetTier {
  activeHunt,
  nextUp,
  later;

  String get label {
    switch (this) {
      case RaidTargetTier.activeHunt:
        return 'Active Hunt';
      case RaidTargetTier.nextUp:
        return 'Next Up';
      case RaidTargetTier.later:
        return 'Later';
    }
  }

  String get firestoreValue {
    switch (this) {
      case RaidTargetTier.activeHunt:
        return 'active_hunt';
      case RaidTargetTier.nextUp:
        return 'next_up';
      case RaidTargetTier.later:
        return 'later';
    }
  }

  static RaidTargetTier fromFirestore(String? value) {
    switch (value) {
      case 'active_hunt':
        return RaidTargetTier.activeHunt;
      case 'next_up':
        return RaidTargetTier.nextUp;
      case 'later':
        return RaidTargetTier.later;
      default:
        return RaidTargetTier.later;
    }
  }
}

class RaidBlueprintTarget {
  final String blueprintId;
  final RaidTargetTier tier;
  final int rank;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RaidBlueprintTarget({
    required this.blueprintId,
    required this.tier,
    required this.rank,
    this.createdAt,
    this.updatedAt,
  });

  RaidBlueprintTarget copyWith({
    String? blueprintId,
    RaidTargetTier? tier,
    int? rank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RaidBlueprintTarget(
      blueprintId: blueprintId ?? this.blueprintId,
      tier: tier ?? this.tier,
      rank: rank ?? this.rank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'tier': tier.firestoreValue,
      'rank': rank,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory RaidBlueprintTarget.fromMap(Map<String, dynamic> map) {
    return RaidBlueprintTarget(
      blueprintId: (map['blueprintId'] ?? '') as String,
      tier: RaidTargetTier.fromFirestore(map['tier'] as String?),
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

enum RaidPlannerTier {
  free,
  essential,
  premium;

  int get activeHuntSlots {
    switch (this) {
      case RaidPlannerTier.free:
        return 1;
      case RaidPlannerTier.essential:
        return 3;
      case RaidPlannerTier.premium:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case RaidPlannerTier.free:
        return 'Free';
      case RaidPlannerTier.essential:
        return 'Essential';
      case RaidPlannerTier.premium:
        return 'Premium';
    }
  }
}

class RaidPlannerEntitlement {
  final RaidPlannerTier tier;
  final int extraSlots;
  final DateTime? referralBoostExpiresAt;
  final bool isAdmin;

  const RaidPlannerEntitlement({
    required this.tier,
    this.extraSlots = 0,
    this.referralBoostExpiresAt,
    this.isAdmin = false,
  });

  int get activeHuntSlots {
    if (isAdmin) return 5;
    final now = DateTime.now();
    final boostActive =
        referralBoostExpiresAt != null && referralBoostExpiresAt!.isAfter(now);
    return tier.activeHuntSlots + (boostActive ? extraSlots : 0);
  }

  bool get hasReferralBoost =>
      referralBoostExpiresAt != null &&
      referralBoostExpiresAt!.isAfter(DateTime.now());

  bool get canUseEssentialProTools =>
      isAdmin ||
      tier == RaidPlannerTier.essential ||
      tier == RaidPlannerTier.premium;

  bool get canUseAdvancedProTools => isAdmin || tier == RaidPlannerTier.premium;

  int get playLikeAProHistoryLimit {
    if (isAdmin || tier == RaidPlannerTier.premium) return 50;
    if (tier == RaidPlannerTier.essential) return 15;
    return 3;
  }

  factory RaidPlannerEntitlement.fromUserMap(Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    final rawTier =
        (data['subscriptionTier'] ??
                data['plannerTier'] ??
                data['subscriptionStatus'] ??
                'free')
            .toString()
            .trim()
            .toLowerCase();

    final tier =
        rawTier == 'premium' || rawTier == 'active_premium' || rawTier == 'pro'
        ? RaidPlannerTier.premium
        : rawTier == 'essential' ||
              rawTier == 'active_essential' ||
              rawTier == 'standard'
        ? RaidPlannerTier.essential
        : RaidPlannerTier.free;

    return RaidPlannerEntitlement(
      tier: tier,
      extraSlots: (data['extraTargetSlots'] as num?)?.toInt() ?? 0,
      referralBoostExpiresAt: (data['referralBoostExpiresAt'] as Timestamp?)
          ?.toDate(),
      isAdmin: data['isAdmin'] == true || data['isDev'] == true,
    );
  }
}

class RaidPlannerOpportunity {
  final RaidPlannerBlueprintRule rule;
  final RaidPlannerEventSlot slot;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool isLive;

  const RaidPlannerOpportunity({
    required this.rule,
    required this.slot,
    required this.startUtc,
    required this.endUtc,
    required this.isLive,
  });

  Duration timeUntil(DateTime utcNow) => startUtc.difference(utcNow);
  Duration timeRemaining(DateTime utcNow) => endUtc.difference(utcNow);
}

class RaidPlannerSnapshot {
  final List<RaidPlannerOpportunity> live;
  final List<RaidPlannerOpportunity> upcoming;
  final List<RaidPlannerOpportunity> today;

  const RaidPlannerSnapshot({
    required this.live,
    required this.upcoming,
    required this.today,
  });
}
