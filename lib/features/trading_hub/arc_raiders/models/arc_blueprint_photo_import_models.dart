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

enum ArcBlueprintPhotoCaptureStep {
  captureTop,
  captureBottomWithOverlap,
  review,
}

enum ArcBlueprintPhotoCellState { owned, missing, uncertain }

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

  Map<String, dynamic> toMap() => {
    'blueprintId': blueprintId,
    'label': label,
    'confidence': confidence,
    'sourceText': sourceText,
  };

  factory ArcBlueprintPhotoCandidate.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoCandidate(
      blueprintId: _readString(map['blueprintId']),
      label: _readString(map['label']),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      sourceText: _readString(map['sourceText']),
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

  Map<String, dynamic> toMap() => {
    'blueprintId': blueprintId,
    'owned': owned,
    'source': source,
    'confidence': confidence,
    'manualCorrection': manualCorrection,
  };

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

class ArcBlueprintPhotoCellDecision {
  const ArcBlueprintPhotoCellDecision({
    required this.blueprintId,
    required this.blueprintIndex,
    required this.state,
    required this.confidence,
    required this.sourceCaptureId,
    required this.rowIndex,
    required this.columnIndex,
    this.manuallyConfirmed = false,
  });

  final String blueprintId;
  final int blueprintIndex;
  final ArcBlueprintPhotoCellState state;
  final double confidence;
  final String sourceCaptureId;
  final int rowIndex;
  final int columnIndex;
  final bool manuallyConfirmed;

  bool get needsReview =>
      state == ArcBlueprintPhotoCellState.uncertain && !manuallyConfirmed;
  bool get owned => state == ArcBlueprintPhotoCellState.owned;

  ArcBlueprintPhotoCellDecision copyWith({
    ArcBlueprintPhotoCellState? state,
    double? confidence,
    bool? manuallyConfirmed,
  }) {
    return ArcBlueprintPhotoCellDecision(
      blueprintId: blueprintId,
      blueprintIndex: blueprintIndex,
      state: state ?? this.state,
      confidence: confidence ?? this.confidence,
      sourceCaptureId: sourceCaptureId,
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      manuallyConfirmed: manuallyConfirmed ?? this.manuallyConfirmed,
    );
  }

  Map<String, dynamic> toMap() => {
    'blueprintId': blueprintId,
    'blueprintIndex': blueprintIndex,
    'state': state.name,
    'confidence': confidence,
    'sourceCaptureId': sourceCaptureId,
    'rowIndex': rowIndex,
    'columnIndex': columnIndex,
    'manuallyConfirmed': manuallyConfirmed,
  };

  factory ArcBlueprintPhotoCellDecision.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoCellDecision(
      blueprintId: _readString(map['blueprintId']),
      blueprintIndex: _readInt(map['blueprintIndex']),
      state: ArcBlueprintPhotoCellState.values.firstWhere(
        (value) => value.name == _readString(map['state']),
        orElse: () => ArcBlueprintPhotoCellState.uncertain,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      sourceCaptureId: _readString(map['sourceCaptureId']),
      rowIndex: _readInt(map['rowIndex']),
      columnIndex: _readInt(map['columnIndex']),
      manuallyConfirmed: map['manuallyConfirmed'] == true,
    );
  }
}

class ArcBlueprintPhotoCapture {
  const ArcBlueprintPhotoCapture({
    required this.id,
    required this.imagePath,
    required this.sequenceIndex,
    this.startRow = 0,
    this.orientation = '',
    this.detectedRows = 0,
    this.detectedCells = 0,
    this.overlapRows = 0,
    this.overlapSignature = '',
    this.createdAt,
  });

  final String id;
  final String imagePath;
  final int sequenceIndex;
  final int startRow;
  final String orientation;
  final int detectedRows;
  final int detectedCells;
  final int overlapRows;
  final String overlapSignature;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'imagePath': imagePath,
    'sequenceIndex': sequenceIndex,
    'startRow': startRow,
    'orientation': orientation,
    'detectedRows': detectedRows,
    'detectedCells': detectedCells,
    'overlapRows': overlapRows,
    'overlapSignature': overlapSignature,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory ArcBlueprintPhotoCapture.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintPhotoCapture(
      id: _readString(map['id']),
      imagePath: _readString(map['imagePath']),
      sequenceIndex: _readInt(map['sequenceIndex']),
      startRow: _readInt(map['startRow']),
      orientation: _readString(map['orientation']),
      detectedRows: _readInt(map['detectedRows']),
      detectedCells: _readInt(map['detectedCells']),
      overlapRows: _readInt(map['overlapRows']),
      overlapSignature: _readString(map['overlapSignature']),
      createdAt: _readDate(map['createdAt']),
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
    this.decisions = const <ArcBlueprintPhotoCellDecision>[],
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
  final List<ArcBlueprintPhotoCellDecision> decisions;
  final bool confirmedByUser;
  final bool writePreviewOnly;
  final int retentionDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasProviderConfigured => provider.trim().isNotEmpty;
  int get requiredCaptureCount => 2;
  int get captureCount => captures.length;
  bool get captureSetComplete => captureCount >= requiredCaptureCount;
  bool get needsSecondCapture => captureCount == 1;
  bool get canRunLocalStitching => captureSetComplete;
  bool get hasUnresolvedDecisions => decisions.any((item) => item.needsReview);
  bool get hasDecisions => decisions.isNotEmpty;

  ArcBlueprintPhotoCaptureStep get nextCaptureStep {
    if (captureCount <= 0) return ArcBlueprintPhotoCaptureStep.captureTop;
    if (captureCount == 1) {
      return ArcBlueprintPhotoCaptureStep.captureBottomWithOverlap;
    }
    return ArcBlueprintPhotoCaptureStep.review;
  }

  String get nextCaptureInstruction {
    return switch (nextCaptureStep) {
      ArcBlueprintPhotoCaptureStep.captureTop =>
        'Capture the top section of your Blueprint grid.',
      ArcBlueprintPhotoCaptureStep.captureBottomWithOverlap =>
        'Capture the lower section with one overlapping row visible.',
      ArcBlueprintPhotoCaptureStep.review =>
        'Review uncertain slots before updating Blueprint ownership.',
    };
  }

  bool get providerConfigurationRequired =>
      status == ArcBlueprintPhotoImportStatus.providerConfigurationRequired ||
      (status == ArcBlueprintPhotoImportStatus.awaitingProvider &&
          !hasProviderConfigured);

  bool get _legacyMatchesResolved =>
      candidates.isEmpty ||
      (candidates.every((candidate) => !candidate.needsReview) &&
          reviewChanges.every((change) => !change.needsReview));

  bool get _occupancyResolved => !hasDecisions || !hasUnresolvedDecisions;

  bool get canWriteBlueprintState =>
      status == ArcBlueprintPhotoImportStatus.confirmed &&
      confirmedByUser &&
      !writePreviewOnly &&
      captureSetComplete &&
      (hasDecisions || candidates.isNotEmpty) &&
      _legacyMatchesResolved &&
      _occupancyResolved;

  String get writeBlockReason {
    if (canWriteBlueprintState) return '';
    if (providerConfigurationRequired) {
      return 'Configure the image provider before scanning.';
    }
    if (!captureSetComplete) return nextCaptureInstruction;
    if (!hasDecisions && candidates.isEmpty) {
      return 'Process both captures before reviewing.';
    }
    if (!_legacyMatchesResolved ||
        !_occupancyResolved ||
        status == ArcBlueprintPhotoImportStatus.needsUserReview) {
      return 'Review uncertain Blueprint slots before saving.';
    }
    if (!confirmedByUser) {
      return 'Confirm the reviewed Blueprint ownership before saving.';
    }
    if (writePreviewOnly) {
      return 'Preview-only sessions cannot update Blueprint ownership.';
    }
    return 'Blueprint import is not ready to save.';
  }

  ArcBlueprintPhotoImportSession copyWith({
    ArcBlueprintPhotoImportStatus? status,
    String? imagePath,
    String? provider,
    String? errorMessage,
    List<ArcBlueprintPhotoCandidate>? candidates,
    List<ArcBlueprintPhotoCapture>? captures,
    List<ArcBlueprintPhotoReviewChange>? reviewChanges,
    List<ArcBlueprintPhotoCellDecision>? decisions,
    bool? confirmedByUser,
    bool? writePreviewOnly,
    int? retentionDays,
    DateTime? updatedAt,
  }) {
    return ArcBlueprintPhotoImportSession(
      id: id,
      uid: uid,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      provider: provider ?? this.provider,
      errorMessage: errorMessage ?? this.errorMessage,
      candidates: candidates ?? this.candidates,
      captures: captures ?? this.captures,
      reviewChanges: reviewChanges ?? this.reviewChanges,
      decisions: decisions ?? this.decisions,
      confirmedByUser: confirmedByUser ?? this.confirmedByUser,
      writePreviewOnly: writePreviewOnly ?? this.writePreviewOnly,
      retentionDays: retentionDays ?? this.retentionDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'status': status.wireName,
    'imagePath': imagePath,
    'provider': provider,
    'errorMessage': errorMessage,
    'candidates': candidates.map((item) => item.toMap()).toList(),
    'captures': captures.map((item) => item.toMap()).toList(),
    'reviewChanges': reviewChanges.map((item) => item.toMap()).toList(),
    'decisions': decisions.map((item) => item.toMap()).toList(),
    'confirmedByUser': confirmedByUser,
    'writePreviewOnly': writePreviewOnly,
    'retentionDays': retentionDays,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

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
      decisions: _readDecisionList(map['decisions']),
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

List<ArcBlueprintPhotoCellDecision> _readDecisionList(dynamic value) {
  if (value is! Iterable) return const <ArcBlueprintPhotoCellDecision>[];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            ArcBlueprintPhotoCellDecision.fromMap(item.cast<String, dynamic>()),
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
