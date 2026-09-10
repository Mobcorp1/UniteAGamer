import 'package:cloud_firestore/cloud_firestore.dart';

enum UagBetaCommercialOffer {
  premiumMonthly,
  premiumAnnual,
  premiumDayPass,
  premiumWeekPass,
  foundingRaiderAnnual;

  String get checkoutPlanId => switch (this) {
    UagBetaCommercialOffer.premiumMonthly => 'beta_premium_monthly',
    UagBetaCommercialOffer.premiumAnnual => 'beta_premium_yearly',
    UagBetaCommercialOffer.premiumDayPass => 'beta_premium_pass_day',
    UagBetaCommercialOffer.premiumWeekPass => 'beta_premium_pass_week',
    UagBetaCommercialOffer.foundingRaiderAnnual =>
      'founding_raider_premium_yearly',
  };

  String get label => switch (this) {
    UagBetaCommercialOffer.premiumMonthly => 'Beta Premium Monthly',
    UagBetaCommercialOffer.premiumAnnual => 'Beta Premium Annual',
    UagBetaCommercialOffer.premiumDayPass => 'Beta 24-Hour Premium',
    UagBetaCommercialOffer.premiumWeekPass => 'Beta 7-Day Premium',
    UagBetaCommercialOffer.foundingRaiderAnnual =>
      'Founding Raider Premium Annual',
  };

  int get pricePence => switch (this) {
    UagBetaCommercialOffer.premiumMonthly => 699,
    UagBetaCommercialOffer.premiumAnnual => 4999,
    UagBetaCommercialOffer.premiumDayPass => 149,
    UagBetaCommercialOffer.premiumWeekPass => 249,
    UagBetaCommercialOffer.foundingRaiderAnnual => 2999,
  };

  String get priceLabel => '£${(pricePence / 100).toStringAsFixed(2)}';
}

class UagBetaFounderStatus {
  const UagBetaFounderStatus({
    this.isBetaTester = false,
    this.isFoundingRaider = false,
    this.founderRateForfeited = false,
    this.wallOfLegendsEligible = false,
    this.wallOfLegendsInducted = false,
    this.betaPricingGrantedAt,
    this.founderGrantedAt,
    this.founderRateForfeitedAt,
  });

  static const none = UagBetaFounderStatus();

  final bool isBetaTester;
  final bool isFoundingRaider;
  final bool founderRateForfeited;
  final bool wallOfLegendsEligible;
  final bool wallOfLegendsInducted;
  final DateTime? betaPricingGrantedAt;
  final DateTime? founderGrantedAt;
  final DateTime? founderRateForfeitedAt;

  bool get hasBetaPricing => isBetaTester;
  bool get hasFoundingRaiderRate => isFoundingRaider && !founderRateForfeited;
  bool get hasAnyRecognition =>
      isBetaTester || isFoundingRaider || wallOfLegendsInducted;

  factory UagBetaFounderStatus.fromRecognitionDoc(Map<String, dynamic> data) {
    final beta = _map(data['beta']);
    final founder = _map(data['founderStatus']);
    return UagBetaFounderStatus(
      isBetaTester:
          _truthy(data['betaTester']) ||
          _truthy(data['closedBetaParticipant']) ||
          _truthy(beta['participant']) ||
          _truthy(beta['pricingEligible']),
      isFoundingRaider:
          _truthy(data['foundingRaider']) ||
          _truthy(data['founder']) ||
          _truthy(founder['active']),
      founderRateForfeited:
          _truthy(data['founderRateForfeited']) ||
          _truthy(founder['rateForfeited']),
      wallOfLegendsEligible:
          _truthy(data['wallOfLegendsEligible']) ||
          _truthy(founder['wallOfLegendsEligible']),
      wallOfLegendsInducted:
          _truthy(data['wallOfLegendsInducted']) ||
          _truthy(founder['wallOfLegendsInducted']),
      betaPricingGrantedAt: _date(
        data['betaPricingGrantedAt'] ?? beta['pricingGrantedAt'],
      ),
      founderGrantedAt: _date(data['founderGrantedAt'] ?? founder['grantedAt']),
      founderRateForfeitedAt: _date(
        data['founderRateForfeitedAt'] ?? founder['rateForfeitedAt'],
      ),
    );
  }

  factory UagBetaFounderStatus.fromUserDoc(Map<String, dynamic> data) {
    final beta = _map(data['beta']);
    final monetisation = _map(data['monetisation']);
    final founder = _map(data['founderStatus']);

    return UagBetaFounderStatus(
      isBetaTester:
          _truthy(data['closedBetaParticipant']) ||
          _truthy(data['betaParticipant']) ||
          _truthy(beta['participant']) ||
          _truthy(beta['pricingEligible']),
      isFoundingRaider:
          _truthy(data['foundingRaider']) ||
          _truthy(data['founder']) ||
          _truthy(data['founderEligible']) ||
          _truthy(founder['active']),
      founderRateForfeited:
          _truthy(data['founderRateForfeited']) ||
          _truthy(monetisation['founderRateForfeited']) ||
          _truthy(founder['rateForfeited']),
      wallOfLegendsEligible:
          _truthy(data['wallOfLegendsEligible']) ||
          _truthy(founder['wallOfLegendsEligible']),
      wallOfLegendsInducted:
          _truthy(data['wallOfLegendsInducted']) ||
          _truthy(founder['wallOfLegendsInducted']),
      betaPricingGrantedAt: _date(
        data['betaPricingGrantedAt'] ?? beta['pricingGrantedAt'],
      ),
      founderGrantedAt: _date(data['founderGrantedAt'] ?? founder['grantedAt']),
      founderRateForfeitedAt: _date(
        data['founderRateForfeitedAt'] ??
            monetisation['founderRateForfeitedAt'] ??
            founder['rateForfeitedAt'],
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static bool _truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
