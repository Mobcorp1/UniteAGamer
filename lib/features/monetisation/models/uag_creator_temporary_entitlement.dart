import 'uag_subscription_tier.dart';

class UagCreatorTemporaryEntitlement {
  const UagCreatorTemporaryEntitlement({
    required this.grantId,
    required this.tier,
    required this.startedAt,
    required this.expiresAt,
    required this.sourceCode,
    required this.sourceClaimPath,
    this.creatorUid = '',
    this.rewardType = '',
  });

  final String grantId;
  final UagSubscriptionTier tier;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String sourceCode;
  final String sourceClaimPath;
  final String creatorUid;
  final String rewardType;

  bool get active {
    final now = DateTime.now().toUtc();
    return !startedAt.isAfter(now) && expiresAt.isAfter(now);
  }

  Duration get remaining {
    final value = expiresAt.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  factory UagCreatorTemporaryEntitlement.fromMap(
    String grantId,
    Map<String, dynamic> map,
  ) {
    return UagCreatorTemporaryEntitlement(
      grantId: grantId,
      tier: UagSubscriptionTier.fromValue(map['tier']?.toString()),
      startedAt:
          _date(map['startedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt:
          _date(map['expiresAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceCode: map['sourceCode']?.toString().trim() ?? '',
      sourceClaimPath: map['sourceClaimPath']?.toString().trim() ?? '',
      creatorUid: map['creatorUid']?.toString().trim() ?? '',
      rewardType: map['rewardType']?.toString().trim() ?? '',
    );
  }
}

UagSubscriptionTier highestCreatorRewardTier(
  Iterable<UagCreatorTemporaryEntitlement> grants,
  UagSubscriptionTier fallback,
) {
  var result = fallback;
  for (final grant in grants) {
    if (!grant.active) continue;
    if (_rank(grant.tier) > _rank(result)) result = grant.tier;
  }
  return result;
}

DateTime? nextCreatorRewardExpiry(
  Iterable<UagCreatorTemporaryEntitlement> grants,
) {
  final now = DateTime.now().toUtc();
  DateTime? next;
  for (final grant in grants) {
    if (!grant.expiresAt.isAfter(now)) continue;
    if (next == null || grant.expiresAt.isBefore(next)) next = grant.expiresAt;
  }
  return next;
}

int _rank(UagSubscriptionTier tier) => switch (tier) {
  UagSubscriptionTier.free => 0,
  UagSubscriptionTier.essential => 1,
  UagSubscriptionTier.premium => 2,
};

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  try {
    final dynamic converted = value.toDate();
    if (converted is DateTime) return converted.toUtc();
  } catch (_) {}
  return DateTime.tryParse(value.toString())?.toUtc();
}
