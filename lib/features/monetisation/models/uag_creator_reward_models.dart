enum UagCreatorRewardType {
  essential7Day,
  essentialMonth,
  premium7Day,
  premiumMonth,
  annualPremium;

  String get value => switch (this) {
    UagCreatorRewardType.essential7Day => 'essential_7_day',
    UagCreatorRewardType.essentialMonth => 'essential_month',
    UagCreatorRewardType.premium7Day => 'premium_7_day',
    UagCreatorRewardType.premiumMonth => 'premium_month',
    UagCreatorRewardType.annualPremium => 'annual_premium',
  };

  String get label => switch (this) {
    UagCreatorRewardType.essential7Day => 'Essential 7-day',
    UagCreatorRewardType.essentialMonth => 'Essential month',
    UagCreatorRewardType.premium7Day => 'Premium 7-day',
    UagCreatorRewardType.premiumMonth => 'Premium month',
    UagCreatorRewardType.annualPremium => 'Annual Premium',
  };

  static UagCreatorRewardType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class UagCreatorGiveawayCode {
  const UagCreatorGiveawayCode({
    required this.code,
    required this.creatorUid,
    required this.rewardType,
    required this.status,
    required this.monthKey,
    this.expiresAt,
    this.redeemedByUid = '',
  });

  final String code;
  final String creatorUid;
  final UagCreatorRewardType rewardType;
  final String status;
  final String monthKey;
  final DateTime? expiresAt;
  final String redeemedByUid;

  bool get active => status == 'active' && !expired && redeemedByUid.isEmpty;
  bool get expired {
    final value = expiresAt;
    return value != null && !value.isAfter(DateTime.now().toUtc());
  }

  factory UagCreatorGiveawayCode.fromMap(Map<String, dynamic> map) {
    return UagCreatorGiveawayCode(
      code: _string(map['code']).toUpperCase(),
      creatorUid: _string(map['uid']),
      rewardType:
          UagCreatorRewardType.fromValue(_string(map['rewardType'])) ??
          UagCreatorRewardType.essential7Day,
      status: _string(map['status'], fallback: 'pending_admin_approval'),
      monthKey: _string(map['monthKey']),
      expiresAt: _date(map['expiresAt']),
      redeemedByUid: _string(map['redeemedByUid']),
    );
  }
}

class UagCreatorRedemptionClaim {
  const UagCreatorRedemptionClaim({
    required this.code,
    required this.status,
    this.recipientUid = '',
    this.creatorUid = '',
    this.rewardType,
    this.rejectionReason = '',
  });

  final String code;
  final String status;
  final String recipientUid;
  final String creatorUid;
  final UagCreatorRewardType? rewardType;
  final String rejectionReason;

  bool get pending => status == 'pending_validation';
  bool get validated => status == 'validated_entitlement_pending';

  factory UagCreatorRedemptionClaim.fromMap(Map<String, dynamic> map) {
    return UagCreatorRedemptionClaim(
      code: _string(map['code']).toUpperCase(),
      status: _string(map['status'], fallback: 'pending_validation'),
      recipientUid: _string(map['recipientUid']),
      creatorUid: _string(map['creatorUid']),
      rewardType: UagCreatorRewardType.fromValue(_string(map['rewardType'])),
      rejectionReason: _string(map['rejectionReason']),
    );
  }
}

class UagCreatorReferralClaim {
  const UagCreatorReferralClaim({
    required this.creatorUid,
    required this.creatorCode,
    required this.status,
    this.referredUid = '',
  });

  final String creatorUid;
  final String creatorCode;
  final String status;
  final String referredUid;

  bool get pending => status == 'pending_validation';

  factory UagCreatorReferralClaim.fromMap(Map<String, dynamic> map) {
    return UagCreatorReferralClaim(
      creatorUid: _string(map['creatorUid']),
      creatorCode: _string(map['creatorCode']).toUpperCase(),
      status: _string(map['status'], fallback: 'pending_validation'),
      referredUid: _string(map['referredUid']),
    );
  }
}

String normaliseCreatorCode(String raw) =>
    raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  try {
    final dynamicDate = value.toDate();
    if (dynamicDate is DateTime) return dynamicDate.toUtc();
  } catch (_) {}
  return DateTime.tryParse(value.toString())?.toUtc();
}
