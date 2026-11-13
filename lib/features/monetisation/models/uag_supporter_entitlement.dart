import 'package:cloud_firestore/cloud_firestore.dart';

class UagSupporterProgrammeConfig {
  const UagSupporterProgrammeConfig({
    required this.monthlyPricePence,
    required this.minimumMonthlyPricePence,
    required this.maximumMonthlyPricePence,
    required this.currencyCode,
    required this.foundingWindowOpen,
    required this.maxFoundingSupporters,
    required this.futureDiscount,
  });

  final int monthlyPricePence;
  final int minimumMonthlyPricePence;
  final int maximumMonthlyPricePence;
  final String currencyCode;
  final bool foundingWindowOpen;
  final int maxFoundingSupporters;
  final UagFutureEcosystemDiscountConfig futureDiscount;

  String get monthlyPriceLabel =>
      '$currencyCode ${(monthlyPricePence / 100).toStringAsFixed(2)}/mo';

  bool get priceIsWithinApprovedRange =>
      monthlyPricePence >= minimumMonthlyPricePence &&
      monthlyPricePence <= maximumMonthlyPricePence;

  static const defaultConfig = UagSupporterProgrammeConfig(
    monthlyPricePence: 399,
    minimumMonthlyPricePence: 299,
    maximumMonthlyPricePence: 499,
    currencyCode: 'GBP',
    foundingWindowOpen: true,
    maxFoundingSupporters: 1000,
    futureDiscount: UagFutureEcosystemDiscountConfig(
      minimumPercent: 10,
      recommendedPercent: 15,
      maximumPercent: 20,
      finalised: false,
    ),
  );
}

class UagFutureEcosystemDiscountConfig {
  const UagFutureEcosystemDiscountConfig({
    required this.minimumPercent,
    required this.recommendedPercent,
    required this.maximumPercent,
    required this.finalised,
  });

  final int minimumPercent;
  final int recommendedPercent;
  final int maximumPercent;
  final bool finalised;

  bool get requiresCommercialApproval => !finalised;
}

class UagSupporterEntitlement {
  const UagSupporterEntitlement({
    required this.active,
    required this.foundingSupporter,
    required this.status,
    required this.monthlyPricePence,
    required this.discountPercent,
    this.supporterNumber,
    this.startedAt,
    this.cancelledAt,
  });

  final bool active;
  final bool foundingSupporter;
  final String status;
  final int monthlyPricePence;
  final int discountPercent;
  final int? supporterNumber;
  final DateTime? startedAt;
  final DateTime? cancelledAt;

  bool get hasFutureDiscount => active && discountPercent > 0;

  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'foundingSupporter': foundingSupporter,
      'status': status,
      'monthlyPricePence': monthlyPricePence,
      'discountPercent': discountPercent,
      if (supporterNumber != null) 'supporterNumber': supporterNumber,
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
    };
  }

  static const none = UagSupporterEntitlement(
    active: false,
    foundingSupporter: false,
    status: 'inactive',
    monthlyPricePence: 0,
    discountPercent: 0,
  );

  factory UagSupporterEntitlement.fromMap(Map<String, dynamic>? map) {
    if (map == null) return none;
    return UagSupporterEntitlement(
      active: _readBool(map['active']),
      foundingSupporter: _readBool(map['foundingSupporter']),
      status: _readString(map['status'], fallback: 'inactive'),
      monthlyPricePence:
          (map['monthlyPricePence'] as num?)?.toInt() ??
          UagSupporterProgrammeConfig.defaultConfig.monthlyPricePence,
      discountPercent:
          (map['discountPercent'] as num?)?.toInt() ??
          UagSupporterProgrammeConfig
              .defaultConfig
              .futureDiscount
              .recommendedPercent,
      supporterNumber: (map['supporterNumber'] as num?)?.toInt(),
      startedAt: _readDate(map['startedAt']),
      cancelledAt: _readDate(map['cancelledAt']),
    );
  }
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.trim().toLowerCase() == 'true';
  return false;
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
