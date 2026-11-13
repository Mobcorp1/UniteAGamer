import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcWorldIntelEvidenceType {
  uagBlueprintReport,
  uagDropReport,
  uagCommunityIntelReport,
  mikeAdminReport,
  trustedContributorReport,
  permittedExternalCoordinate,
  writtenGuide,
  videoReference,
  screenshotEvidence,
  independentConfirmation,
  officialSeedMarker,
  mapLabelPoiAnchor,
}

extension ArcWorldIntelEvidenceTypeX on ArcWorldIntelEvidenceType {
  String get label {
    switch (this) {
      case ArcWorldIntelEvidenceType.uagBlueprintReport:
        return 'UAG Blueprint Report';
      case ArcWorldIntelEvidenceType.uagDropReport:
        return 'UAG Drop Report';
      case ArcWorldIntelEvidenceType.uagCommunityIntelReport:
        return 'Community Intel';
      case ArcWorldIntelEvidenceType.mikeAdminReport:
        return 'Mike / Admin Intel';
      case ArcWorldIntelEvidenceType.trustedContributorReport:
        return 'Trusted Contributor';
      case ArcWorldIntelEvidenceType.permittedExternalCoordinate:
        return 'Permitted External Coordinate';
      case ArcWorldIntelEvidenceType.writtenGuide:
        return 'Written Guide Lead';
      case ArcWorldIntelEvidenceType.videoReference:
        return 'Video Reference';
      case ArcWorldIntelEvidenceType.screenshotEvidence:
        return 'Screenshot Evidence';
      case ArcWorldIntelEvidenceType.independentConfirmation:
        return 'Independent Confirmation';
      case ArcWorldIntelEvidenceType.officialSeedMarker:
        return 'Official / Seed Marker';
      case ArcWorldIntelEvidenceType.mapLabelPoiAnchor:
        return 'Map Label / POI Anchor';
    }
  }

  static ArcWorldIntelEvidenceType fromStorage(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
    return ArcWorldIntelEvidenceType.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized,
      orElse: () => ArcWorldIntelEvidenceType.officialSeedMarker,
    );
  }
}

@immutable
class ArcWorldIntelEvidenceRecord {
  const ArcWorldIntelEvidenceRecord({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.sourceName,
    required this.mapId,
    required this.layer,
    this.sourceRecordId,
    this.sourceUrl,
    this.reporterId,
    this.timestamp,
    this.coordinate,
    this.originalCoordinate,
    this.landmarkText,
    this.category,
    this.blueprintId,
    this.trust = 1,
    this.attribution = '',
    this.permissionState = 'uag_internal',
    this.confirmationCount = 0,
    this.disputeCount = 0,
    this.notes = '',
  });

  final String id;
  final ArcWorldIntelEvidenceType type;
  final String sourceId;
  final String sourceName;
  final String? sourceRecordId;
  final String? sourceUrl;
  final String? reporterId;
  final DateTime? timestamp;
  final String mapId;
  final ArcRaidMapLayer layer;
  final ArcNormalizedPoint? coordinate;
  final ArcNormalizedPoint? originalCoordinate;
  final String? landmarkText;
  final String? category;
  final String? blueprintId;
  final double trust;
  final String attribution;
  final String permissionState;
  final int confirmationCount;
  final int disputeCount;
  final String notes;

  bool get isUagOwned =>
      type == ArcWorldIntelEvidenceType.uagBlueprintReport ||
      type == ArcWorldIntelEvidenceType.uagDropReport ||
      type == ArcWorldIntelEvidenceType.uagCommunityIntelReport ||
      type == ArcWorldIntelEvidenceType.mikeAdminReport ||
      type == ArcWorldIntelEvidenceType.trustedContributorReport ||
      permissionState == 'uag_internal';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'sourceRecordId': sourceRecordId,
      'sourceUrl': sourceUrl,
      'reporterId': reporterId,
      'timestamp': timestamp == null ? null : Timestamp.fromDate(timestamp!),
      'mapId': mapId,
      'layer': layer.name,
      'coordinate': coordinate?.toMap(),
      'originalCoordinate': originalCoordinate?.toMap(),
      'landmarkText': landmarkText,
      'category': category,
      'blueprintId': blueprintId,
      'trust': trust,
      'attribution': attribution,
      'permissionState': permissionState,
      'confirmationCount': confirmationCount,
      'disputeCount': disputeCount,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJsonMap() {
    final map = toMap();
    map['timestamp'] = timestamp?.toIso8601String();
    return map;
  }

  factory ArcWorldIntelEvidenceRecord.fromMap(Map<String, dynamic> map) {
    return ArcWorldIntelEvidenceRecord(
      id: map['id']?.toString() ?? '',
      type: ArcWorldIntelEvidenceTypeX.fromStorage(map['type']?.toString()),
      sourceId: map['sourceId']?.toString() ?? '',
      sourceName: map['sourceName']?.toString() ?? 'Unknown source',
      sourceRecordId: _stringOrNull(map['sourceRecordId']),
      sourceUrl: _stringOrNull(map['sourceUrl']),
      reporterId: _stringOrNull(map['reporterId']),
      timestamp: _dateFrom(map['timestamp']),
      mapId: map['mapId']?.toString() ?? '',
      layer: ArcRaidMapLayer.values.firstWhere(
        (item) => item.name == map['layer']?.toString(),
        orElse: () => ArcRaidMapLayer.surface,
      ),
      coordinate: _pointFrom(map['coordinate']),
      originalCoordinate: _pointFrom(map['originalCoordinate']),
      landmarkText: _stringOrNull(map['landmarkText']),
      category: _stringOrNull(map['category']),
      blueprintId: _stringOrNull(map['blueprintId']),
      trust: _doubleFrom(map['trust']) ?? 1,
      attribution: map['attribution']?.toString() ?? '',
      permissionState: map['permissionState']?.toString() ?? 'unknown',
      confirmationCount: _intFrom(map['confirmationCount']),
      disputeCount: _intFrom(map['disputeCount']),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static ArcNormalizedPoint? _pointFrom(dynamic value) {
    if (value is! Map) return null;
    return ArcNormalizedPoint.fromMap(Map<String, dynamic>.from(value));
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

@immutable
class ArcWorldIntelDuplicateGroup {
  const ArcWorldIntelDuplicateGroup({
    required this.id,
    required this.markerIds,
    required this.reason,
  });

  final String id;
  final List<String> markerIds;
  final String reason;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'markerIds': markerIds,
    'reason': reason,
    'reversible': true,
  };
}

@immutable
class ArcWorldIntelTownHallCandidate {
  const ArcWorldIntelTownHallCandidate({
    required this.id,
    required this.label,
    required this.confidence,
    required this.reason,
    required this.point,
    required this.originalWording,
    this.selected = false,
  });

  final String id;
  final String label;
  final ArcRaidIntelConfidence confidence;
  final String reason;
  final ArcNormalizedPoint point;
  final String originalWording;
  final bool selected;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'label': label,
    'confidence': confidence.name,
    'reason': reason,
    'point': point.toMap(),
    'originalWording': originalWording,
    'selected': selected,
  };
}

@immutable
class ArcWorldIntelCoverageReport {
  const ArcWorldIntelCoverageReport({
    required this.id,
    required this.generatedAt,
    required this.markerCountByMap,
    required this.markerCountByLayer,
    required this.markerCountByCategory,
    required this.alignmentConfidenceByLayer,
    required this.residualErrorByLayer,
    required this.controlPointCountByLayer,
    required this.sourceAttribution,
    this.uagReportsProcessed = 0,
    this.uagReportsMapped = 0,
    this.uagReportsClustered = 0,
    this.uagReportsLinkedToMarkers = 0,
    this.uagReportsRequiringReview = 0,
    this.externalResearchRecordsProcessed = 0,
    this.permittedCoordinateRecordsUsed = 0,
    this.writtenGuideLeadsUsed = 0,
    this.videoLeadsUsed = 0,
    this.multiSourceCorroboratedMarkerCount = 0,
    this.uagOnlyMarkerCount = 0,
    this.generatedDescriptionCount = 0,
    this.autoPublishedCount = 0,
    this.provisionalCount = 0,
    this.exceptionCount = 0,
    this.duplicateCount = 0,
    this.unmatchedBlueprintCount = 0,
    this.estimatedReviewPercentage = 0,
    this.townHallCandidates = const <ArcWorldIntelTownHallCandidate>[],
  });

  final String id;
  final DateTime generatedAt;
  final int uagReportsProcessed;
  final int uagReportsMapped;
  final int uagReportsClustered;
  final int uagReportsLinkedToMarkers;
  final int uagReportsRequiringReview;
  final int externalResearchRecordsProcessed;
  final int permittedCoordinateRecordsUsed;
  final int writtenGuideLeadsUsed;
  final int videoLeadsUsed;
  final int multiSourceCorroboratedMarkerCount;
  final int uagOnlyMarkerCount;
  final int generatedDescriptionCount;
  final int autoPublishedCount;
  final int provisionalCount;
  final int exceptionCount;
  final int duplicateCount;
  final int unmatchedBlueprintCount;
  final double estimatedReviewPercentage;
  final Map<String, int> markerCountByMap;
  final Map<String, int> markerCountByLayer;
  final Map<String, int> markerCountByCategory;
  final Map<String, double> alignmentConfidenceByLayer;
  final Map<String, double> residualErrorByLayer;
  final Map<String, int> controlPointCountByLayer;
  final Map<String, String> sourceAttribution;
  final List<ArcWorldIntelTownHallCandidate> townHallCandidates;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'uagReportsProcessed': uagReportsProcessed,
      'uagReportsMapped': uagReportsMapped,
      'uagReportsClustered': uagReportsClustered,
      'uagReportsLinkedToMarkers': uagReportsLinkedToMarkers,
      'uagReportsRequiringReview': uagReportsRequiringReview,
      'externalResearchRecordsProcessed': externalResearchRecordsProcessed,
      'permittedCoordinateRecordsUsed': permittedCoordinateRecordsUsed,
      'writtenGuideLeadsUsed': writtenGuideLeadsUsed,
      'videoLeadsUsed': videoLeadsUsed,
      'multiSourceCorroboratedMarkerCount': multiSourceCorroboratedMarkerCount,
      'uagOnlyMarkerCount': uagOnlyMarkerCount,
      'generatedDescriptionCount': generatedDescriptionCount,
      'autoPublishedCount': autoPublishedCount,
      'provisionalCount': provisionalCount,
      'exceptionCount': exceptionCount,
      'duplicateCount': duplicateCount,
      'unmatchedBlueprintCount': unmatchedBlueprintCount,
      'estimatedReviewPercentage': estimatedReviewPercentage,
      'markerCountByMap': markerCountByMap,
      'markerCountByLayer': markerCountByLayer,
      'markerCountByCategory': markerCountByCategory,
      'alignmentConfidenceByLayer': alignmentConfidenceByLayer,
      'residualErrorByLayer': residualErrorByLayer,
      'controlPointCountByLayer': controlPointCountByLayer,
      'sourceAttribution': sourceAttribution,
      'townHallCandidates': townHallCandidates
          .map((item) => item.toMap())
          .toList(growable: false),
    };
  }
}
