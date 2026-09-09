enum UagReferralBankedRewardType { premium7Days, premium30Days }

extension UagReferralBankedRewardTypeX on UagReferralBankedRewardType {
  String get label {
    switch (this) {
      case UagReferralBankedRewardType.premium7Days:
        return '7 days Premium';
      case UagReferralBankedRewardType.premium30Days:
        return '1 month Premium';
    }
  }

  Duration get duration {
    switch (this) {
      case UagReferralBankedRewardType.premium7Days:
        return const Duration(days: 7);
      case UagReferralBankedRewardType.premium30Days:
        return const Duration(days: 30);
    }
  }
}

enum UagReferralRewardStatus { banked, active, consumed, revoked }

class UagReferralBankedReward {
  const UagReferralBankedReward({
    required this.id,
    required this.type,
    required this.status,
    this.earnedAtIso = '',
    this.activatedAtIso = '',
    this.expiresAtIso = '',
    this.source = 'community_referral',
  });

  final String id;
  final UagReferralBankedRewardType type;
  final UagReferralRewardStatus status;
  final String earnedAtIso;
  final String activatedAtIso;
  final String expiresAtIso;
  final String source;

  factory UagReferralBankedReward.fromMap(Map<String, dynamic> map) {
    final typeName = map['type']?.toString() ?? '';
    final statusName = map['status']?.toString() ?? '';
    return UagReferralBankedReward(
      id: map['id']?.toString() ?? '',
      type: UagReferralBankedRewardType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => UagReferralBankedRewardType.premium7Days,
      ),
      status: UagReferralRewardStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => UagReferralRewardStatus.banked,
      ),
      earnedAtIso: map['earnedAtIso']?.toString() ?? '',
      activatedAtIso: map['activatedAtIso']?.toString() ?? '',
      expiresAtIso: map['expiresAtIso']?.toString() ?? '',
      source: map['source']?.toString() ?? 'community_referral',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'status': status.name,
    'earnedAtIso': earnedAtIso,
    'activatedAtIso': activatedAtIso,
    'expiresAtIso': expiresAtIso,
    'source': source,
  };
}

class UagReferralRewardLockerPolicy {
  const UagReferralRewardLockerPolicy._();

  static bool canActivate({
    required bool hasActiveLockerReward,
    required bool underlyingPremiumActive,
  }) {
    return !hasActiveLockerReward && !underlyingPremiumActive;
  }

  static DateTime activationExpiry({
    required UagReferralBankedRewardType type,
    required DateTime activatedAt,
  }) => activatedAt.toUtc().add(type.duration);

  static bool isExpired({required String expiresAtIso, required DateTime now}) {
    final expiry = DateTime.tryParse(expiresAtIso)?.toUtc();
    if (expiry == null) return false;
    return !now.toUtc().isBefore(expiry);
  }
}
