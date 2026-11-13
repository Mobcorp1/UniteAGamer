import 'uag_creator_commercial_policy.dart';

class UagCreatorMonthlyInventory {
  const UagCreatorMonthlyInventory({
    required this.monthKey,
    this.essential7DayGranted = 0,
    this.essential7DayUsed = 0,
    this.essentialMonthGranted = 0,
    this.essentialMonthUsed = 0,
    this.premium7DayGranted = 0,
    this.premium7DayUsed = 0,
    this.premiumMonthGranted = 0,
    this.premiumMonthUsed = 0,
    this.annualPremiumGranted = 0,
    this.annualPremiumUsed = 0,
    this.seasonalCampaignAccess = false,
  });

  final String monthKey;
  final int essential7DayGranted;
  final int essential7DayUsed;
  final int essentialMonthGranted;
  final int essentialMonthUsed;
  final int premium7DayGranted;
  final int premium7DayUsed;
  final int premiumMonthGranted;
  final int premiumMonthUsed;
  final int annualPremiumGranted;
  final int annualPremiumUsed;
  final bool seasonalCampaignAccess;

  int get essential7DayRemaining =>
      _remaining(essential7DayGranted, essential7DayUsed);
  int get essentialMonthRemaining =>
      _remaining(essentialMonthGranted, essentialMonthUsed);
  int get premium7DayRemaining =>
      _remaining(premium7DayGranted, premium7DayUsed);
  int get premiumMonthRemaining =>
      _remaining(premiumMonthGranted, premiumMonthUsed);
  int get annualPremiumRemaining =>
      _remaining(annualPremiumGranted, annualPremiumUsed);

  static int _remaining(int granted, int used) {
    final remaining = granted - used;
    if (remaining <= 0) return 0;
    return remaining > granted ? granted : remaining;
  }

  factory UagCreatorMonthlyInventory.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return UagCreatorMonthlyInventory(
      monthKey: _string(data['monthKey']),
      essential7DayGranted: _int(data['essential7DayGranted']),
      essential7DayUsed: _int(data['essential7DayUsed']),
      essentialMonthGranted: _int(data['essentialMonthGranted']),
      essentialMonthUsed: _int(data['essentialMonthUsed']),
      premium7DayGranted: _int(data['premium7DayGranted']),
      premium7DayUsed: _int(data['premium7DayUsed']),
      premiumMonthGranted: _int(data['premiumMonthGranted']),
      premiumMonthUsed: _int(data['premiumMonthUsed']),
      annualPremiumGranted: _int(data['annualPremiumGranted']),
      annualPremiumUsed: _int(data['annualPremiumUsed']),
      seasonalCampaignAccess: data['seasonalCampaignAccess'] == true,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'monthKey': monthKey,
    'essential7DayGranted': essential7DayGranted,
    'essential7DayUsed': essential7DayUsed,
    'essentialMonthGranted': essentialMonthGranted,
    'essentialMonthUsed': essentialMonthUsed,
    'premium7DayGranted': premium7DayGranted,
    'premium7DayUsed': premium7DayUsed,
    'premiumMonthGranted': premiumMonthGranted,
    'premiumMonthUsed': premiumMonthUsed,
    'annualPremiumGranted': annualPremiumGranted,
    'annualPremiumUsed': annualPremiumUsed,
    'seasonalCampaignAccess': seasonalCampaignAccess,
  };
}

class UagCreatorLiveDashboard {
  const UagCreatorLiveDashboard({
    required this.uid,
    this.creatorId = '',
    this.activeFreeUsers = 0,
    this.essentialSubscribers = 0,
    this.premiumSubscribers = 0,
    this.authoritativeCreatorPoints,
    this.pendingCommissionPence = 0,
    this.approvedCommissionPence = 0,
    this.paidCommissionPence = 0,
    this.monthlyInventory = const UagCreatorMonthlyInventory(monthKey: ''),
  });

  final String uid;
  final String creatorId;
  final int activeFreeUsers;
  final int essentialSubscribers;
  final int premiumSubscribers;
  final double? authoritativeCreatorPoints;
  final int pendingCommissionPence;
  final int approvedCommissionPence;
  final int paidCommissionPence;
  final UagCreatorMonthlyInventory monthlyInventory;

  double get creatorPoints =>
      authoritativeCreatorPoints ??
      UagCreatorCommercialPolicy.pointsFor(
        essential: essentialSubscribers,
        premium: premiumSubscribers,
      );
  UagCreatorLevel? get level =>
      UagCreatorCommercialPolicy.levelForPoints(creatorPoints);
  double get commissionPercent => level?.commissionPercent ?? 0;

  factory UagCreatorLiveDashboard.fromMap(
    String uid,
    Map<String, dynamic>? map,
  ) {
    final data = map ?? const <String, dynamic>{};
    return UagCreatorLiveDashboard(
      uid: uid,
      creatorId: _string(data['creatorId']),
      activeFreeUsers: _int(data['activeFreeUsers']),
      essentialSubscribers: _int(
        data['essentialActiveSubscribers'] ?? data['essentialSubscribers'],
      ),
      premiumSubscribers: _int(
        data['premiumActiveSubscribers'] ?? data['premiumSubscribers'],
      ),
      authoritativeCreatorPoints: data['creatorPoints'] is num
          ? (data['creatorPoints'] as num).toDouble()
          : null,
      pendingCommissionPence: _int(data['pendingCommissionPence']),
      approvedCommissionPence: _int(data['approvedCommissionPence']),
      paidCommissionPence: _int(data['paidCommissionPence']),
      monthlyInventory: UagCreatorMonthlyInventory.fromMap(
        data['communityArsenal'] is Map
            ? Map<String, dynamic>.from(data['communityArsenal'] as Map)
            : null,
      ),
    );
  }
}

class UagCreatorCodeRecord {
  const UagCreatorCodeRecord({
    required this.code,
    required this.status,
    this.creatorHandle = '',
  });

  final String code;
  final String status;
  final String creatorHandle;

  factory UagCreatorCodeRecord.fromMap(Map<String, dynamic> map) =>
      UagCreatorCodeRecord(
        code: _string(map['code']),
        status: _string(map['status'], fallback: 'pending_admin_approval'),
        creatorHandle: _string(map['creatorHandle']),
      );
}

class UagCreatorAttributionClaim {
  const UagCreatorAttributionClaim({
    required this.creatorUid,
    required this.creatorCode,
    required this.source,
    required this.capturedAtIso,
    this.status = 'pending_validation',
  });

  final String creatorUid;
  final String creatorCode;
  final String source;
  final String capturedAtIso;
  final String status;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'creatorUid': creatorUid,
    'creatorCode': creatorCode.trim().toUpperCase(),
    'source': source,
    'capturedAtIso': capturedAtIso,
    'status': status,
  };
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
