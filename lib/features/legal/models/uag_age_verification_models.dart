enum UagAgeVerificationStatus {
  notSubmitted,
  pending,
  accepted,
  rejected,
  appealed,
  expired,
}

extension UagAgeVerificationStatusX on UagAgeVerificationStatus {
  String get label {
    switch (this) {
      case UagAgeVerificationStatus.notSubmitted:
        return 'Not submitted';
      case UagAgeVerificationStatus.pending:
        return 'Pending review';
      case UagAgeVerificationStatus.accepted:
        return '18+ verified';
      case UagAgeVerificationStatus.rejected:
        return 'Age gate failed';
      case UagAgeVerificationStatus.appealed:
        return 'Appeal pending';
      case UagAgeVerificationStatus.expired:
        return 'Verification expired';
    }
  }

  static UagAgeVerificationStatus fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagAgeVerificationStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => UagAgeVerificationStatus.notSubmitted,
    );
  }
}

class UagAgeVerificationDecision {
  const UagAgeVerificationDecision({
    required this.status,
    required this.verifiedOver18,
    required this.reason,
    required this.ageYears,
    required this.requiresHumanReview,
  });

  final UagAgeVerificationStatus status;
  final bool verifiedOver18;
  final String reason;
  final int ageYears;
  final bool requiresHumanReview;
}

class UagAgeVerificationPolicy {
  const UagAgeVerificationPolicy({this.minimumAgeYears = 18});

  final int minimumAgeYears;

  UagAgeVerificationDecision evaluate({
    required String dateOfBirthIso,
    required DateTime now,
  }) {
    final dob = DateTime.tryParse(dateOfBirthIso.trim());
    if (dob == null) {
      return const UagAgeVerificationDecision(
        status: UagAgeVerificationStatus.rejected,
        verifiedOver18: false,
        reason: 'Date of birth is missing or invalid.',
        ageYears: 0,
        requiresHumanReview: false,
      );
    }
    final today = DateTime.utc(now.year, now.month, now.day);
    final birthDate = DateTime.utc(dob.year, dob.month, dob.day);
    if (birthDate.isAfter(today)) {
      return const UagAgeVerificationDecision(
        status: UagAgeVerificationStatus.rejected,
        verifiedOver18: false,
        reason: 'Date of birth cannot be in the future.',
        ageYears: 0,
        requiresHumanReview: false,
      );
    }
    var age = today.year - birthDate.year;
    final birthdayThisYear = DateTime.utc(
      today.year,
      birthDate.month,
      birthDate.day,
    );
    if (birthdayThisYear.isAfter(today)) age -= 1;
    if (age >= minimumAgeYears) {
      return UagAgeVerificationDecision(
        status: UagAgeVerificationStatus.accepted,
        verifiedOver18: true,
        reason: 'Account holder meets the 18+ service requirement.',
        ageYears: age,
        requiresHumanReview: false,
      );
    }
    return UagAgeVerificationDecision(
      status: UagAgeVerificationStatus.rejected,
      verifiedOver18: false,
      reason: 'UAG ARC Raiders Hub is an 18+ service.',
      ageYears: age,
      requiresHumanReview: false,
    );
  }
}

class UagAgeVerificationRequest {
  const UagAgeVerificationRequest({
    required this.id,
    required this.uid,
    required this.dateOfBirthIso,
    required this.status,
    this.createdAtIso = '',
    this.updatedAtIso = '',
    this.decisionReason = '',
    this.provider = 'server_dob_gate',
    this.appealReason = '',
  });

  final String id;
  final String uid;
  final String dateOfBirthIso;
  final UagAgeVerificationStatus status;
  final String createdAtIso;
  final String updatedAtIso;
  final String decisionReason;
  final String provider;
  final String appealReason;

  bool get verifiedOver18 => status == UagAgeVerificationStatus.accepted;

  Map<String, dynamic> toCreateMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'dateOfBirthIso': dateOfBirthIso,
      'status': UagAgeVerificationStatus.pending.name,
      'provider': provider,
      'appealReason': appealReason,
    };
  }

  factory UagAgeVerificationRequest.fromMap(Map<String, dynamic> map) {
    return UagAgeVerificationRequest(
      id: _readString(map['id']),
      uid: _readString(map['uid']),
      dateOfBirthIso: _readString(map['dateOfBirthIso']),
      status: UagAgeVerificationStatusX.fromWire(_readString(map['status'])),
      createdAtIso: _readString(map['createdAtIso']),
      updatedAtIso: _readString(map['updatedAtIso']),
      decisionReason: _readString(map['decisionReason']),
      provider: _readString(map['provider'], fallback: 'server_dob_gate'),
      appealReason: _readString(map['appealReason']),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
