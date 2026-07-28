class UagLegalOperatorConfig {
  const UagLegalOperatorConfig({
    required this.operatorName,
    required this.tradingName,
    required this.contactEmail,
    required this.serviceAddress,
    required this.companyNumber,
    required this.privacyContact,
    required this.copyrightContact,
    required this.moderationContact,
    required this.billingSupportContact,
  });

  final String operatorName;
  final String tradingName;
  final String contactEmail;
  final String serviceAddress;
  final String companyNumber;
  final String privacyContact;
  final String copyrightContact;
  final String moderationContact;
  final String billingSupportContact;

  bool get isComplete =>
      operatorName.trim().isNotEmpty &&
      tradingName.trim().isNotEmpty &&
      contactEmail.trim().isNotEmpty &&
      serviceAddress.trim().isNotEmpty &&
      privacyContact.trim().isNotEmpty &&
      copyrightContact.trim().isNotEmpty &&
      moderationContact.trim().isNotEmpty &&
      billingSupportContact.trim().isNotEmpty;

  List<String> get missingFields {
    final missing = <String>[];
    void check(String label, String value) {
      if (value.trim().isEmpty) missing.add(label);
    }

    check('operatorName', operatorName);
    check('tradingName', tradingName);
    check('contactEmail', contactEmail);
    check('serviceAddress', serviceAddress);
    check('privacyContact', privacyContact);
    check('copyrightContact', copyrightContact);
    check('moderationContact', moderationContact);
    check('billingSupportContact', billingSupportContact);
    return missing;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'operatorName': operatorName,
      'tradingName': tradingName,
      'contactEmail': contactEmail,
      'serviceAddress': serviceAddress,
      'companyNumber': companyNumber,
      'privacyContact': privacyContact,
      'copyrightContact': copyrightContact,
      'moderationContact': moderationContact,
      'billingSupportContact': billingSupportContact,
    };
  }

  factory UagLegalOperatorConfig.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return UagLegalOperatorConfig(
      operatorName: _readString(data['operatorName']),
      tradingName: _readString(data['tradingName']),
      contactEmail: _readString(data['contactEmail']),
      serviceAddress: _readString(data['serviceAddress']),
      companyNumber: _readString(data['companyNumber']),
      privacyContact: _readString(data['privacyContact']),
      copyrightContact: _readString(data['copyrightContact']),
      moderationContact: _readString(data['moderationContact']),
      billingSupportContact: _readString(data['billingSupportContact']),
    );
  }

  static const missing = UagLegalOperatorConfig(
    operatorName: '',
    tradingName: '',
    contactEmail: '',
    serviceAddress: '',
    companyNumber: '',
    privacyContact: '',
    copyrightContact: '',
    moderationContact: '',
    billingSupportContact: '',
  );
}

String _readString(dynamic value) => value?.toString().trim() ?? '';
