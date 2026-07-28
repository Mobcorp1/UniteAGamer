import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcBlueprintPhotoImportStatus {
  draft,
  uploaded,
  awaitingProvider,
  providerConfigurationRequired,
  needsUserReview,
  confirmed,
  rejected,
  failed,
}

extension ArcBlueprintPhotoImportStatusX on ArcBlueprintPhotoImportStatus {
  String get wireName => name;

  static ArcBlueprintPhotoImportStatus fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return ArcBlueprintPhotoImportStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => ArcBlueprintPhotoImportStatus.draft,
    );
  }
}

class ArcBlueprintPhotoCandidate {
  const ArcBlueprintPhotoCandidate({
    required this.blueprintId,
    required this.label,
    required this.confidence,
    this.sourceText = '',
  });

  final String blueprintId;
  final String label;
  final double confidence;
  final String sourceText;

  bool get needsReview => confidence < 0.92;

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'label': label,
      'confidence': confidence,
      'sourceText': sourceText,
    };
  }

  factory ArcBlueprintPhotoCandidate.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoCandidate(
      blueprintId: _readString(map['blueprintId']),
      label: _readString(map['label']),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      sourceText: _readString(map['sourceText']),
    );
  }
}

class ArcBlueprintPhotoCapture {
  const ArcBlueprintPhotoCapture({
    required this.id,
    required this.imagePath,
    required this.sequenceIndex,
    this.orientation = '',
    this.detectedRows = 0,
    this.detectedCells = 0,
    this.overlapSignature = '',
    this.createdAt,
  });

  final String id;
  final String imagePath;
  final int sequenceIndex;
  final String orientation;
  final int detectedRows;
  final int detectedCells;
  final String overlapSignature;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'sequenceIndex': sequenceIndex,
      'orientation': orientation,
      'detectedRows': detectedRows,
      'detectedCells': detectedCells,
      'overlapSignature': overlapSignature,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory ArcBlueprintPhotoCapture.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoCapture(
      id: _readString(map['id']),
      imagePath: _readString(map['imagePath']),
      sequenceIndex: _readInt(map['sequenceIndex']),
      orientation: _readString(map['orientation']),
      detectedRows: _readInt(map['detectedRows']),
      detectedCells: _readInt(map['detectedCells']),
      overlapSignature: _readString(map['overlapSignature']),
      createdAt: _readDate(map['createdAt']),
    );
  }
}

class ArcBlueprintPhotoReviewChange {
  const ArcBlueprintPhotoReviewChange({
    required this.blueprintId,
    required this.owned,
    required this.source,
    this.confidence = 0,
    this.manualCorrection = false,
  });

  final String blueprintId;
  final bool owned;
  final String source;
  final double confidence;
  final bool manualCorrection;

  bool get needsReview => confidence < 0.92 && !manualCorrection;

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'owned': owned,
      'source': source,
      'confidence': confidence,
      'manualCorrection': manualCorrection,
    };
  }

  factory ArcBlueprintPhotoReviewChange.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoReviewChange(
      blueprintId: _readString(map['blueprintId']),
      owned: map['owned'] == true,
      source: _readString(map['source']),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      manualCorrection: map['manualCorrection'] == true,
    );
  }
}

class ArcBlueprintPhotoImportSession {
  const ArcBlueprintPhotoImportSession({
    required this.id,
    required this.uid,
    required this.status,
    this.imagePath = '',
    this.provider = '',
    this.errorMessage = '',
    this.candidates = const <ArcBlueprintPhotoCandidate>[],
    this.captures = const <ArcBlueprintPhotoCapture>[],
    this.reviewChanges = const <ArcBlueprintPhotoReviewChange>[],
    this.confirmedByUser = false,
    this.writePreviewOnly = true,
    this.retentionDays = 14,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String uid;
  final ArcBlueprintPhotoImportStatus status;
  final String imagePath;
  final String provider;
  final String errorMessage;
  final List<ArcBlueprintPhotoCandidate> candidates;
  final List<ArcBlueprintPhotoCapture> captures;
  final List<ArcBlueprintPhotoReviewChange> reviewChanges;
  final bool confirmedByUser;
  final bool writePreviewOnly;
  final int retentionDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasProviderConfigured => provider.trim().isNotEmpty;
  bool get canWriteBlueprintState =>
      status == ArcBlueprintPhotoImportStatus.confirmed &&
      confirmedByUser &&
      !writePreviewOnly &&
      candidates.isNotEmpty &&
      candidates.every((candidate) => !candidate.needsReview) &&
      reviewChanges.every((change) => !change.needsReview);

  bool get providerConfigurationRequired =>
      status == ArcBlueprintPhotoImportStatus.providerConfigurationRequired ||
      (status == ArcBlueprintPhotoImportStatus.awaitingProvider &&
          !hasProviderConfigured);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'status': status.wireName,
      'imagePath': imagePath,
      'provider': provider,
      'errorMessage': errorMessage,
      'candidates': candidates.map((candidate) => candidate.toMap()).toList(),
      'captures': captures.map((capture) => capture.toMap()).toList(),
      'reviewChanges': reviewChanges.map((change) => change.toMap()).toList(),
      'confirmedByUser': confirmedByUser,
      'writePreviewOnly': writePreviewOnly,
      'retentionDays': retentionDays,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory ArcBlueprintPhotoImportSession.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoImportSession(
      id: _readString(map['id']),
      uid: _readString(map['uid']),
      status: ArcBlueprintPhotoImportStatusX.fromWire(
        _readString(map['status']),
      ),
      imagePath: _readString(map['imagePath']),
      provider: _readString(map['provider']),
      errorMessage: _readString(map['errorMessage']),
      candidates: _readCandidateList(map['candidates']),
      captures: _readCaptureList(map['captures']),
      reviewChanges: _readReviewChangeList(map['reviewChanges']),
      confirmedByUser: map['confirmedByUser'] == true,
      writePreviewOnly: map['writePreviewOnly'] != false,
      retentionDays: _readInt(map['retentionDays'], fallback: 14),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

List<ArcBlueprintPhotoCandidate> _readCandidateList(dynamic value) {
  if (value is! Iterable) return const <ArcBlueprintPhotoCandidate>[];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            ArcBlueprintPhotoCandidate.fromMap(item.cast<String, dynamic>()),
      )
      .toList(growable: false);
}

List<ArcBlueprintPhotoCapture> _readCaptureList(dynamic value) {
  if (value is! Iterable) return const <ArcBlueprintPhotoCapture>[];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            ArcBlueprintPhotoCapture.fromMap(item.cast<String, dynamic>()),
      )
      .toList(growable: false);
}

List<ArcBlueprintPhotoReviewChange> _readReviewChangeList(dynamic value) {
  if (value is! Iterable) return const <ArcBlueprintPhotoReviewChange>[];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            ArcBlueprintPhotoReviewChange.fromMap(item.cast<String, dynamic>()),
      )
      .toList(growable: false);
}

String _readString(dynamic value) => value?.toString().trim() ?? '';

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value)) ?? fallback;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
