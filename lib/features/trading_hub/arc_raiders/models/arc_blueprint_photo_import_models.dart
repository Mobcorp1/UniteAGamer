import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcBlueprintPhotoImportStatus {
  draft,
  uploaded,
  awaitingProvider,
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

class ArcBlueprintPhotoImportSession {
  const ArcBlueprintPhotoImportSession({
    required this.id,
    required this.uid,
    required this.status,
    this.imagePath = '',
    this.provider = '',
    this.errorMessage = '',
    this.candidates = const <ArcBlueprintPhotoCandidate>[],
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasProviderConfigured => provider.trim().isNotEmpty;
  bool get canWriteBlueprintState =>
      status == ArcBlueprintPhotoImportStatus.confirmed &&
      candidates.isNotEmpty &&
      candidates.every((candidate) => !candidate.needsReview);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'status': status.wireName,
      'imagePath': imagePath,
      'provider': provider,
      'errorMessage': errorMessage,
      'candidates': candidates.map((candidate) => candidate.toMap()).toList(),
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

String _readString(dynamic value) => value?.toString().trim() ?? '';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
