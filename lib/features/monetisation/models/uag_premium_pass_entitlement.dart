import 'package:cloud_firestore/cloud_firestore.dart';

enum UagPremiumPassType {
  day24,
  week7;

  String get value => switch (this) {
    UagPremiumPassType.day24 => 'day24',
    UagPremiumPassType.week7 => 'week7',
  };

  String get label => switch (this) {
    UagPremiumPassType.day24 => '24-Hour Premium Pass',
    UagPremiumPassType.week7 => '7-Day Premium Pass',
  };

  int get pricePence => switch (this) {
    UagPremiumPassType.day24 => 199,
    UagPremiumPassType.week7 => 249,
  };

  Duration get duration => switch (this) {
    UagPremiumPassType.day24 => const Duration(hours: 24),
    UagPremiumPassType.week7 => const Duration(days: 7),
  };

  static UagPremiumPassType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class UagPremiumPassEntitlement {
  const UagPremiumPassEntitlement({
    this.type,
    this.startedAt,
    this.expiresAt,
    this.paidPence = 0,
    this.usedDay24 = false,
    this.usedWeek7 = false,
  });

  static const none = UagPremiumPassEntitlement();

  final UagPremiumPassType? type;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int paidPence;
  final bool usedDay24;
  final bool usedWeek7;

  bool get active {
    final expiry = expiresAt;
    return type != null && expiry != null && expiry.isAfter(DateTime.now());
  }

  int get upgradeCreditPence => active ? paidPence.clamp(0, 999) : 0;

  bool canPurchase(UagPremiumPassType requested) => switch (requested) {
    UagPremiumPassType.day24 => !usedDay24,
    UagPremiumPassType.week7 => !usedWeek7,
  };

  Duration get remaining {
    final expiry = expiresAt;
    if (!active || expiry == null) return Duration.zero;
    return expiry.difference(DateTime.now());
  }

  factory UagPremiumPassEntitlement.fromMap(Map<String, dynamic>? data) {
    final value = data ?? const <String, dynamic>{};
    DateTime? date(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return UagPremiumPassEntitlement(
      type: UagPremiumPassType.fromValue(value['type']?.toString()),
      startedAt: date(value['startedAt']),
      expiresAt: date(value['expiresAt']),
      paidPence: (value['paidPence'] as num?)?.toInt() ?? 0,
      usedDay24: value['usedDay24'] == true,
      usedWeek7: value['usedWeek7'] == true,
    );
  }
}
