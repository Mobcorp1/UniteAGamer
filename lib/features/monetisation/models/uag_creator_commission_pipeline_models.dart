enum UagCreatorBillingEventType {
  subscriptionStarted,
  renewal,
  cancellation,
  refund,
  chargeback,
}

extension UagCreatorBillingEventTypeX on UagCreatorBillingEventType {
  String get label {
    switch (this) {
      case UagCreatorBillingEventType.subscriptionStarted:
        return 'Subscription started';
      case UagCreatorBillingEventType.renewal:
        return 'Renewal';
      case UagCreatorBillingEventType.cancellation:
        return 'Cancellation';
      case UagCreatorBillingEventType.refund:
        return 'Refund';
      case UagCreatorBillingEventType.chargeback:
        return 'Chargeback';
    }
  }

  static UagCreatorBillingEventType fromWire(String? value) {
    final normalised = (value ?? '').trim();
    return UagCreatorBillingEventType.values.firstWhere(
      (event) => event.name == normalised,
      orElse: () => UagCreatorBillingEventType.subscriptionStarted,
    );
  }
}

enum UagCreatorCommissionLifecycleStatus {
  pendingValidation,
  qualifying,
  payable,
  paid,
  reversed,
}

extension UagCreatorCommissionLifecycleStatusX
    on UagCreatorCommissionLifecycleStatus {
  String get label {
    switch (this) {
      case UagCreatorCommissionLifecycleStatus.pendingValidation:
        return 'Pending validation';
      case UagCreatorCommissionLifecycleStatus.qualifying:
        return 'Qualifying';
      case UagCreatorCommissionLifecycleStatus.payable:
        return 'Payable';
      case UagCreatorCommissionLifecycleStatus.paid:
        return 'Paid';
      case UagCreatorCommissionLifecycleStatus.reversed:
        return 'Reversed';
    }
  }
}

class UagCreatorValidatedBillingEvent {
  const UagCreatorValidatedBillingEvent({
    required this.id,
    required this.creatorUid,
    required this.referredUid,
    required this.subscriptionId,
    required this.eventType,
    required this.planTier,
    required this.grossAmountPence,
    required this.eligibleNetAmountPence,
    required this.commissionRatePercent,
    required this.occurredAt,
    this.currency = 'gbp',
    this.source = 'admin_validated_billing',
    this.reason = '',
  });

  final String id;
  final String creatorUid;
  final String referredUid;
  final String subscriptionId;
  final UagCreatorBillingEventType eventType;
  final String planTier;
  final int grossAmountPence;
  final int eligibleNetAmountPence;
  final double commissionRatePercent;
  final DateTime occurredAt;
  final String currency;
  final String source;
  final String reason;

  bool get isPositiveRevenueEvent =>
      eventType == UagCreatorBillingEventType.subscriptionStarted ||
      eventType == UagCreatorBillingEventType.renewal;

  bool get isReversalEvent =>
      eventType == UagCreatorBillingEventType.refund ||
      eventType == UagCreatorBillingEventType.chargeback;

  int get calculatedCommissionPence =>
      UagCreatorCommissionLifecyclePolicy.commissionPence(
        eligibleNetAmountPence: eligibleNetAmountPence,
        commissionRatePercent: commissionRatePercent,
      );

  DateTime get payableAt =>
      occurredAt.add(UagCreatorCommissionLifecyclePolicy.validationPeriod);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'creatorUid': creatorUid,
    'referredUid': referredUid,
    'subscriptionId': subscriptionId,
    'eventType': eventType.name,
    'planTier': planTier,
    'grossAmountPence': grossAmountPence,
    'eligibleNetAmountPence': eligibleNetAmountPence,
    'commissionRatePercent': commissionRatePercent,
    'commissionPence': calculatedCommissionPence,
    'currency': currency,
    'source': source,
    'reason': reason,
    'occurredAtIso': occurredAt.toUtc().toIso8601String(),
    'payableAtIso': payableAt.toUtc().toIso8601String(),
  };
}

class UagCreatorCommissionLifecyclePolicy {
  const UagCreatorCommissionLifecyclePolicy._();

  static const Duration validationPeriod = Duration(days: 30);

  static int commissionPence({
    required int eligibleNetAmountPence,
    required double commissionRatePercent,
  }) {
    if (eligibleNetAmountPence <= 0 || commissionRatePercent <= 0) {
      return 0;
    }
    return (eligibleNetAmountPence * commissionRatePercent / 100).round();
  }

  static UagCreatorCommissionLifecycleStatus lifecycleFor({
    required UagCreatorBillingEventType eventType,
    required DateTime occurredAt,
    required DateTime now,
    bool paid = false,
  }) {
    if (eventType == UagCreatorBillingEventType.refund ||
        eventType == UagCreatorBillingEventType.chargeback) {
      return UagCreatorCommissionLifecycleStatus.reversed;
    }
    if (eventType == UagCreatorBillingEventType.cancellation) {
      return UagCreatorCommissionLifecycleStatus.qualifying;
    }
    if (paid) {
      return UagCreatorCommissionLifecycleStatus.paid;
    }
    final payableAt = occurredAt.add(validationPeriod);
    if (now.isBefore(payableAt)) {
      return UagCreatorCommissionLifecycleStatus.pendingValidation;
    }
    return UagCreatorCommissionLifecycleStatus.payable;
  }
}

class UagCreatorCommissionLedgerView {
  const UagCreatorCommissionLedgerView({
    required this.id,
    required this.creatorUid,
    required this.referredUid,
    required this.subscriptionId,
    required this.eventType,
    required this.planTier,
    required this.status,
    required this.commissionPence,
    required this.currency,
    required this.occurredAtIso,
    required this.payableAtIso,
    this.reason = '',
  });

  final String id;
  final String creatorUid;
  final String referredUid;
  final String subscriptionId;
  final UagCreatorBillingEventType eventType;
  final String planTier;
  final UagCreatorCommissionLifecycleStatus status;
  final int commissionPence;
  final String currency;
  final String occurredAtIso;
  final String payableAtIso;
  final String reason;

  factory UagCreatorCommissionLedgerView.fromMap(Map<String, dynamic> map) {
    String text(dynamic value) => value?.toString().trim() ?? '';
    int integer(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(text(value)) ?? 0;
    }

    final statusText = text(map['lifecycleStatus']);
    final status = UagCreatorCommissionLifecycleStatus.values.firstWhere(
      (value) => value.name == statusText,
      orElse: () => UagCreatorCommissionLifecycleStatus.pendingValidation,
    );

    return UagCreatorCommissionLedgerView(
      id: text(map['id']),
      creatorUid: text(map['creatorUid']),
      referredUid: text(map['referredUid']),
      subscriptionId: text(map['subscriptionId']),
      eventType: UagCreatorBillingEventTypeX.fromWire(text(map['eventType'])),
      planTier: text(map['planTier']),
      status: status,
      commissionPence: integer(map['commissionPence']),
      currency: text(map['currency']).isEmpty ? 'gbp' : text(map['currency']),
      occurredAtIso: text(map['occurredAtIso']),
      payableAtIso: text(map['payableAtIso']),
      reason: text(map['reason']),
    );
  }
}
