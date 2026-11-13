enum UagCreatorApplicationStatus {
  notApplied,
  pending,
  approved,
  suspended,
  rejected,
  closed,
}

extension UagCreatorApplicationStatusX on UagCreatorApplicationStatus {
  String get label {
    switch (this) {
      case UagCreatorApplicationStatus.notApplied:
        return 'Not applied';
      case UagCreatorApplicationStatus.pending:
        return 'Application pending';
      case UagCreatorApplicationStatus.approved:
        return 'Approved';
      case UagCreatorApplicationStatus.suspended:
        return 'Suspended';
      case UagCreatorApplicationStatus.rejected:
        return 'Rejected';
      case UagCreatorApplicationStatus.closed:
        return 'Closed';
    }
  }

  static UagCreatorApplicationStatus fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagCreatorApplicationStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => UagCreatorApplicationStatus.notApplied,
    );
  }
}

enum UagCreatorCommissionStatus {
  pending,
  qualifying,
  approved,
  payable,
  paid,
  reversed,
  clawedBack,
  disputed,
}

extension UagCreatorCommissionStatusX on UagCreatorCommissionStatus {
  static UagCreatorCommissionStatus fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagCreatorCommissionStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => UagCreatorCommissionStatus.pending,
    );
  }
}

class UagCreatorCampaignCodePolicy {
  const UagCreatorCampaignCodePolicy({
    this.reservedTerms = const <String>[
      'ARC',
      'ARC RAIDERS',
      'EMBARK',
      'STRIPE',
      'GOOGLE',
      'ADMIN',
      'OFFICIAL',
    ],
    this.blockedTerms = const <String>[],
    this.minLength = 6,
    this.maxLength = 28,
  });

  final List<String> reservedTerms;
  final List<String> blockedTerms;
  final int minLength;
  final int maxLength;

  UagCreatorCodeValidationResult normalise({
    required String raw,
    String creatorHandle = '',
    Iterable<String> existingCodes = const <String>[],
  }) {
    final normalizedHandle = _clean(creatorHandle);
    var code = _clean(raw);
    if (code.isEmpty && normalizedHandle.isNotEmpty) {
      code = 'WELCOME$normalizedHandle';
    }
    final existing = existingCodes.map(_clean).toSet();
    final reasons = <String>[];

    if (code.length < minLength) {
      reasons.add('Code must be at least $minLength characters.');
    }
    if (code.length > maxLength) {
      reasons.add('Code must be $maxLength characters or fewer.');
    }
    if (existing.contains(code)) {
      reasons.add('Code is already reserved.');
    }
    for (final term in reservedTerms.map(_clean)) {
      if (term.isNotEmpty && code.contains(term) && code != normalizedHandle) {
        reasons.add('Code uses reserved term: $term.');
      }
    }
    for (final term in blockedTerms.map(_clean)) {
      if (term.isNotEmpty && code.contains(term)) {
        reasons.add('Code uses blocked term.');
      }
    }

    return UagCreatorCodeValidationResult(
      requestedCode: raw,
      normalizedCode: code,
      valid: reasons.isEmpty,
      reasons: reasons,
    );
  }

  static String _clean(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class UagCreatorCodeValidationResult {
  const UagCreatorCodeValidationResult({
    required this.requestedCode,
    required this.normalizedCode,
    required this.valid,
    required this.reasons,
  });

  final String requestedCode;
  final String normalizedCode;
  final bool valid;
  final List<String> reasons;
}

class UagCreatorProgrammeApplication {
  const UagCreatorProgrammeApplication({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.platforms,
    required this.socialHandles,
    required this.status,
    required this.agreedTermsVersion,
    this.audienceSize,
    this.creatorId = '',
    this.createdAtIso = '',
    this.approvedAtIso = '',
  });

  final String id;
  final String uid;
  final String creatorId;
  final String displayName;
  final List<String> platforms;
  final Map<String, String> socialHandles;
  final int? audienceSize;
  final UagCreatorApplicationStatus status;
  final int agreedTermsVersion;
  final String createdAtIso;
  final String approvedAtIso;

  bool get canSeeDashboard => status == UagCreatorApplicationStatus.approved;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'creatorId': creatorId,
      'displayName': displayName,
      'platforms': platforms,
      'socialHandles': socialHandles,
      if (audienceSize != null) 'audienceSize': audienceSize,
      'status': status.name,
      'agreedTermsVersion': agreedTermsVersion,
      'createdAtIso': createdAtIso,
      'approvedAtIso': approvedAtIso,
    };
  }

  factory UagCreatorProgrammeApplication.fromMap(Map<String, dynamic> map) {
    return UagCreatorProgrammeApplication(
      id: _readString(map['id']),
      uid: _readString(map['uid']),
      creatorId: _readString(map['creatorId']),
      displayName: _readString(map['displayName']),
      platforms: _readStringList(map['platforms']),
      socialHandles: _readStringMap(map['socialHandles']),
      audienceSize: map['audienceSize'] is num
          ? (map['audienceSize'] as num).toInt()
          : null,
      status: UagCreatorApplicationStatusX.fromWire(_readString(map['status'])),
      agreedTermsVersion: _readInt(map['agreedTermsVersion']),
      createdAtIso: _readString(map['createdAtIso']),
      approvedAtIso: _readString(map['approvedAtIso']),
    );
  }
}

class UagCreatorDashboardAggregate {
  const UagCreatorDashboardAggregate({
    required this.uid,
    this.totalLinkClicks = 0,
    this.uniqueClicks = 0,
    this.signUps = 0,
    this.verifiedSignUps = 0,
    this.activeFreeUsers = 0,
    this.essentialSubscribers = 0,
    this.premiumSubscribers = 0,
    this.foundingSupporters = 0,
    this.trials = 0,
    this.paidConversions = 0,
    this.cancelledSubscriptions = 0,
    this.refundedSubscriptions = 0,
    this.chargebacks = 0,
    this.pendingCommissionPence = 0,
    this.approvedCommissionPence = 0,
    this.paidCommissionPence = 0,
    this.clawbackPence = 0,
  });

  final String uid;
  final int totalLinkClicks;
  final int uniqueClicks;
  final int signUps;
  final int verifiedSignUps;
  final int activeFreeUsers;
  final int essentialSubscribers;
  final int premiumSubscribers;
  final int foundingSupporters;
  final int trials;
  final int paidConversions;
  final int cancelledSubscriptions;
  final int refundedSubscriptions;
  final int chargebacks;
  final int pendingCommissionPence;
  final int approvedCommissionPence;
  final int paidCommissionPence;
  final int clawbackPence;

  double get conversionRate {
    if (uniqueClicks <= 0) return 0;
    return paidConversions / uniqueClicks;
  }

  Map<String, dynamic> toPrivacySafeMap() {
    return <String, dynamic>{
      'uid': uid,
      'totalLinkClicks': totalLinkClicks,
      'uniqueClicks': uniqueClicks,
      'signUps': signUps,
      'verifiedSignUps': verifiedSignUps,
      'activeFreeUsers': activeFreeUsers,
      'essentialSubscribers': essentialSubscribers,
      'premiumSubscribers': premiumSubscribers,
      'foundingSupporters': foundingSupporters,
      'trials': trials,
      'paidConversions': paidConversions,
      'cancelledSubscriptions': cancelledSubscriptions,
      'refundedSubscriptions': refundedSubscriptions,
      'chargebacks': chargebacks,
      'pendingCommissionPence': pendingCommissionPence,
      'approvedCommissionPence': approvedCommissionPence,
      'paidCommissionPence': paidCommissionPence,
      'clawbackPence': clawbackPence,
      'conversionRate': conversionRate,
    };
  }

  factory UagCreatorDashboardAggregate.fromMap(Map<String, dynamic> map) {
    return UagCreatorDashboardAggregate(
      uid: _readString(map['uid']),
      totalLinkClicks: _readInt(map['totalLinkClicks']),
      uniqueClicks: _readInt(map['uniqueClicks']),
      signUps: _readInt(map['signUps']),
      verifiedSignUps: _readInt(map['verifiedSignUps']),
      activeFreeUsers: _readInt(map['activeFreeUsers']),
      essentialSubscribers: _readInt(map['essentialSubscribers']),
      premiumSubscribers: _readInt(map['premiumSubscribers']),
      foundingSupporters: _readInt(map['foundingSupporters']),
      trials: _readInt(map['trials']),
      paidConversions: _readInt(map['paidConversions']),
      cancelledSubscriptions: _readInt(map['cancelledSubscriptions']),
      refundedSubscriptions: _readInt(map['refundedSubscriptions']),
      chargebacks: _readInt(map['chargebacks']),
      pendingCommissionPence: _readInt(map['pendingCommissionPence']),
      approvedCommissionPence: _readInt(map['approvedCommissionPence']),
      paidCommissionPence: _readInt(map['paidCommissionPence']),
      clawbackPence: _readInt(map['clawbackPence']),
    );
  }
}

class UagCreatorCommissionLedgerEntry {
  const UagCreatorCommissionLedgerEntry({
    required this.id,
    required this.creatorUid,
    required this.status,
    required this.amountPence,
    required this.currency,
    this.referredAccountRef = '',
    this.subscriptionId = '',
    this.billingEventId = '',
    this.grossAmountPence = 0,
    this.discountPence = 0,
    this.netEligibleAmountPence = 0,
    this.commissionRatePercent = 0,
    this.reason = '',
    this.createdAtIso = '',
    this.qualificationDateIso = '',
    this.payoutDateIso = '',
  });

  final String id;
  final String creatorUid;
  final UagCreatorCommissionStatus status;
  final int amountPence;
  final String currency;
  final String referredAccountRef;
  final String subscriptionId;
  final String billingEventId;
  final int grossAmountPence;
  final int discountPence;
  final int netEligibleAmountPence;
  final int commissionRatePercent;
  final String reason;
  final String createdAtIso;
  final String qualificationDateIso;
  final String payoutDateIso;

  bool get visibleToCreator => creatorUid.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'creatorUid': creatorUid,
      'status': status.name,
      'amountPence': amountPence,
      'currency': currency,
      'referredAccountRef': referredAccountRef,
      'subscriptionId': subscriptionId,
      'billingEventId': billingEventId,
      'grossAmountPence': grossAmountPence,
      'discountPence': discountPence,
      'netEligibleAmountPence': netEligibleAmountPence,
      'commissionRatePercent': commissionRatePercent,
      'reason': reason,
      'createdAtIso': createdAtIso,
      'qualificationDateIso': qualificationDateIso,
      'payoutDateIso': payoutDateIso,
    };
  }

  factory UagCreatorCommissionLedgerEntry.fromMap(Map<String, dynamic> map) {
    return UagCreatorCommissionLedgerEntry(
      id: _readString(map['id']),
      creatorUid: _readString(map['creatorUid']),
      status: UagCreatorCommissionStatusX.fromWire(_readString(map['status'])),
      amountPence: _readInt(map['amountPence']),
      currency: _readString(map['currency'], fallback: 'gbp'),
      referredAccountRef: _readString(map['referredAccountRef']),
      subscriptionId: _readString(map['subscriptionId']),
      billingEventId: _readString(map['billingEventId']),
      grossAmountPence: _readInt(map['grossAmountPence']),
      discountPence: _readInt(map['discountPence']),
      netEligibleAmountPence: _readInt(map['netEligibleAmountPence']),
      commissionRatePercent: _readInt(map['commissionRatePercent']),
      reason: _readString(map['reason']),
      createdAtIso: _readString(map['createdAtIso']),
      qualificationDateIso: _readString(map['qualificationDateIso']),
      payoutDateIso: _readString(map['payoutDateIso']),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value)) ?? 0;
}

List<String> _readStringList(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _readStringMap(dynamic value) {
  if (value is! Map) return const <String, String>{};
  return value.map(
    (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
  );
}
