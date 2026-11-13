import 'package:cloud_firestore/cloud_firestore.dart';

enum UagConductReportType {
  scamAttempt,
  noShow,
  harassment,
  impersonation,
  unsafeCommunication,
  other,
}

extension UagConductReportTypeX on UagConductReportType {
  String get wireName => name;

  String get label {
    switch (this) {
      case UagConductReportType.scamAttempt:
        return 'Scam Attempt';
      case UagConductReportType.noShow:
        return 'No-show';
      case UagConductReportType.harassment:
        return 'Harassment';
      case UagConductReportType.impersonation:
        return 'Impersonation';
      case UagConductReportType.unsafeCommunication:
        return 'Unsafe Communication';
      case UagConductReportType.other:
        return 'Other';
    }
  }

  static UagConductReportType fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagConductReportType.values.firstWhere(
      (type) => type.name == normalized,
      orElse: () => UagConductReportType.other,
    );
  }
}

enum UagConductReportStatus {
  submitted,
  underReview,
  actionTaken,
  dismissed,
  withdrawn,
}

extension UagConductReportStatusX on UagConductReportStatus {
  String get wireName => name;

  static UagConductReportStatus fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagConductReportStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => UagConductReportStatus.submitted,
    );
  }
}

class UagConductReport {
  const UagConductReport({
    required this.id,
    required this.reporterUid,
    required this.subjectUid,
    required this.type,
    required this.status,
    this.relatedTradeId = '',
    this.relatedSessionId = '',
    this.description = '',
    this.evidenceUrls = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reporterUid;
  final String subjectUid;
  final UagConductReportType type;
  final UagConductReportStatus status;
  final String relatedTradeId;
  final String relatedSessionId;
  final String description;
  final List<String> evidenceUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasContext =>
      relatedTradeId.trim().isNotEmpty ||
      relatedSessionId.trim().isNotEmpty ||
      evidenceUrls.isNotEmpty;

  bool get isActionable =>
      reporterUid.trim().isNotEmpty &&
      subjectUid.trim().isNotEmpty &&
      reporterUid != subjectUid &&
      description.trim().length >= 12;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterUid': reporterUid,
      'subjectUid': subjectUid,
      'type': type.wireName,
      'status': status.wireName,
      'relatedTradeId': relatedTradeId,
      'relatedSessionId': relatedSessionId,
      'description': description,
      'evidenceUrls': evidenceUrls,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory UagConductReport.fromMap(Map<String, dynamic> map) {
    return UagConductReport(
      id: _readString(map['id']),
      reporterUid: _readString(map['reporterUid']),
      subjectUid: _readString(map['subjectUid']),
      type: UagConductReportTypeX.fromWire(_readString(map['type'])),
      status: UagConductReportStatusX.fromWire(_readString(map['status'])),
      relatedTradeId: _readString(map['relatedTradeId']),
      relatedSessionId: _readString(map['relatedSessionId']),
      description: _readString(map['description']),
      evidenceUrls: _readStringList(map['evidenceUrls']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

enum UagCommunityContractStatus {
  draft,
  offered,
  accepted,
  evidenceSubmitted,
  rewardReady,
  completed,
  disputed,
  cancelled,
}

extension UagCommunityContractStatusX on UagCommunityContractStatus {
  String get wireName => name;

  static UagCommunityContractStatus fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagCommunityContractStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => UagCommunityContractStatus.draft,
    );
  }
}

class UagCommunityContract {
  const UagCommunityContract({
    required this.id,
    required this.ownerUid,
    required this.assigneeUid,
    required this.status,
    required this.objective,
    this.rewardSummary = '',
    this.requiresEvidence = true,
    this.evidenceUrls = const <String>[],
    this.disputeReason = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String assigneeUid;
  final UagCommunityContractStatus status;
  final String objective;
  final String rewardSummary;
  final bool requiresEvidence;
  final List<String> evidenceUrls;
  final String disputeReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasParticipantConflict =>
      ownerUid.trim().isNotEmpty && ownerUid == assigneeUid;

  bool get evidenceSatisfied => !requiresEvidence || evidenceUrls.isNotEmpty;

  bool get canMarkRewardReady =>
      status == UagCommunityContractStatus.evidenceSubmitted &&
      evidenceSatisfied &&
      rewardSummary.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'assigneeUid': assigneeUid,
      'status': status.wireName,
      'objective': objective,
      'rewardSummary': rewardSummary,
      'requiresEvidence': requiresEvidence,
      'evidenceUrls': evidenceUrls,
      'disputeReason': disputeReason,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory UagCommunityContract.fromMap(Map<String, dynamic> map) {
    return UagCommunityContract(
      id: _readString(map['id']),
      ownerUid: _readString(map['ownerUid']),
      assigneeUid: _readString(map['assigneeUid']),
      status: UagCommunityContractStatusX.fromWire(_readString(map['status'])),
      objective: _readString(map['objective']),
      rewardSummary: _readString(map['rewardSummary']),
      requiresEvidence: map['requiresEvidence'] != false,
      evidenceUrls: _readStringList(map['evidenceUrls']),
      disputeReason: _readString(map['disputeReason']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

String _readString(dynamic value) => value?.toString().trim() ?? '';

List<String> _readStringList(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
