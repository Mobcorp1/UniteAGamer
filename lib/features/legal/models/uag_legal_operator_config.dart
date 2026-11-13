class UagLegalOperatorConfig {
  const UagLegalOperatorConfig({
    required this.operatorName,
    required this.tradingName,
    required this.legalContact,
    required this.contactEmail,
    required this.serviceAddress,
    required this.companyNumber,
    required this.privacyContact,
    required this.copyrightContact,
    required this.moderationContact,
    required this.billingSupportContact,
    required this.privacyPolicyUrl,
    required this.termsOfUseUrl,
    required this.subscriptionRefundsUrl,
    required this.supportUrl,
  });

  final String operatorName;
  final String tradingName;
  final String legalContact;
  final String contactEmail;
  final String serviceAddress;
  final String companyNumber;
  final String privacyContact;
  final String copyrightContact;
  final String moderationContact;
  final String billingSupportContact;
  final String privacyPolicyUrl;
  final String termsOfUseUrl;
  final String subscriptionRefundsUrl;
  final String supportUrl;

  bool get isComplete =>
      operatorName.trim().isNotEmpty &&
      tradingName.trim().isNotEmpty &&
      legalContact.trim().isNotEmpty &&
      contactEmail.trim().isNotEmpty &&
      serviceAddress.trim().isNotEmpty &&
      privacyContact.trim().isNotEmpty &&
      copyrightContact.trim().isNotEmpty &&
      moderationContact.trim().isNotEmpty &&
      billingSupportContact.trim().isNotEmpty &&
      privacyPolicyUrl.trim().isNotEmpty &&
      termsOfUseUrl.trim().isNotEmpty &&
      subscriptionRefundsUrl.trim().isNotEmpty &&
      supportUrl.trim().isNotEmpty;

  List<String> get missingFields {
    final missing = <String>[];
    void check(String label, String value) {
      if (value.trim().isEmpty) missing.add(label);
    }

    check('operatorName', operatorName);
    check('tradingName', tradingName);
    check('legalContact', legalContact);
    check('contactEmail', contactEmail);
    check('serviceAddress', serviceAddress);
    check('privacyContact', privacyContact);
    check('copyrightContact', copyrightContact);
    check('moderationContact', moderationContact);
    check('billingSupportContact', billingSupportContact);
    check('privacyPolicyUrl', privacyPolicyUrl);
    check('termsOfUseUrl', termsOfUseUrl);
    check('subscriptionRefundsUrl', subscriptionRefundsUrl);
    check('supportUrl', supportUrl);
    return missing;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'operatorName': operatorName,
      'tradingName': tradingName,
      'legalContact': legalContact,
      'contactEmail': contactEmail,
      'serviceAddress': serviceAddress,
      'companyNumber': companyNumber,
      'privacyContact': privacyContact,
      'copyrightContact': copyrightContact,
      'moderationContact': moderationContact,
      'billingSupportContact': billingSupportContact,
      'privacyPolicyUrl': privacyPolicyUrl,
      'termsOfUseUrl': termsOfUseUrl,
      'subscriptionRefundsUrl': subscriptionRefundsUrl,
      'supportUrl': supportUrl,
    };
  }

  factory UagLegalOperatorConfig.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return UagLegalOperatorConfig(
      operatorName: _readString(data['operatorName']),
      tradingName: _readString(data['tradingName']),
      legalContact: _readString(data['legalContact']),
      contactEmail: _readString(data['contactEmail']),
      serviceAddress: _readString(data['serviceAddress']),
      companyNumber: _readString(data['companyNumber']),
      privacyContact: _readString(data['privacyContact']),
      copyrightContact: _readString(data['copyrightContact']),
      moderationContact: _readString(data['moderationContact']),
      billingSupportContact: _readString(data['billingSupportContact']),
      privacyPolicyUrl: _readString(data['privacyPolicyUrl']),
      termsOfUseUrl: _readString(data['termsOfUseUrl']),
      subscriptionRefundsUrl: _readString(data['subscriptionRefundsUrl']),
      supportUrl: _readString(data['supportUrl']),
    );
  }

  static const production = UagLegalOperatorConfig(
    operatorName: 'MobCorp Limited',
    tradingName: 'Unite A Gamer / UAG ARC Raiders Hub',
    legalContact: 'Michael Marsh',
    contactEmail: 'contact@mobcorp.co.uk',
    serviceAddress: '107 Langley Hall Road, Solihull, B92 7HD, United Kingdom',
    companyNumber: '16857854',
    privacyContact: 'contact@mobcorp.co.uk',
    copyrightContact: 'contact@mobcorp.co.uk',
    moderationContact: 'contact@mobcorp.co.uk',
    billingSupportContact: 'contact@mobcorp.co.uk',
    privacyPolicyUrl: 'https://unite-a-gamer.web.app/privacy',
    termsOfUseUrl: 'https://unite-a-gamer.web.app/terms',
    subscriptionRefundsUrl:
        'https://unite-a-gamer.web.app/subscriptions-refunds',
    supportUrl: 'https://unite-a-gamer.web.app/support',
  );

  static const missing = UagLegalOperatorConfig(
    operatorName: '',
    tradingName: '',
    legalContact: '',
    contactEmail: '',
    serviceAddress: '',
    companyNumber: '',
    privacyContact: '',
    copyrightContact: '',
    moderationContact: '',
    billingSupportContact: '',
    privacyPolicyUrl: '',
    termsOfUseUrl: '',
    subscriptionRefundsUrl: '',
    supportUrl: '',
  );
}

String _readString(dynamic value) => value?.toString().trim() ?? '';
