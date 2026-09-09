enum UagEntitlementTestMode {
  real,
  free,
  essential,
  premium,
  pass24Hour,
  pass7Day;

  static UagEntitlementTestMode fromValue(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'free' => UagEntitlementTestMode.free,
      'essential' => UagEntitlementTestMode.essential,
      'premium' => UagEntitlementTestMode.premium,
      'pass24hour' || 'pass_24_hour' => UagEntitlementTestMode.pass24Hour,
      'pass7day' || 'pass_7_day' => UagEntitlementTestMode.pass7Day,
      _ => UagEntitlementTestMode.real,
    };
  }

  String get value => switch (this) {
    UagEntitlementTestMode.real => 'real',
    UagEntitlementTestMode.free => 'free',
    UagEntitlementTestMode.essential => 'essential',
    UagEntitlementTestMode.premium => 'premium',
    UagEntitlementTestMode.pass24Hour => 'pass24Hour',
    UagEntitlementTestMode.pass7Day => 'pass7Day',
  };

  String get label => switch (this) {
    UagEntitlementTestMode.real => 'REAL',
    UagEntitlementTestMode.free => 'FREE',
    UagEntitlementTestMode.essential => 'ESSENTIAL',
    UagEntitlementTestMode.premium => 'PREMIUM',
    UagEntitlementTestMode.pass24Hour => '24H PASS',
    UagEntitlementTestMode.pass7Day => '7D PASS',
  };
}
