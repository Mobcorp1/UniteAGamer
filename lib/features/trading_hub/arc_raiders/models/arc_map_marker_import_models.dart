import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcMapMarkerCoordinateSpace { normalized, sourcePercent, imagePixel }

enum ArcMapMarkerImportDecision {
  autoPublished,
  provisionalVisible,
  exception,
  duplicate,
  rejected,
}

extension ArcMapMarkerCoordinateSpaceX on ArcMapMarkerCoordinateSpace {
  static ArcMapMarkerCoordinateSpace fromStorage(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
    return switch (normalized) {
      'image_pixel' ||
      'pixel' ||
      'pixels' => ArcMapMarkerCoordinateSpace.imagePixel,
      'source_percent' ||
      'percent' ||
      'percentage' => ArcMapMarkerCoordinateSpace.sourcePercent,
      _ => ArcMapMarkerCoordinateSpace.normalized,
    };
  }
}

extension ArcMapMarkerImportDecisionX on ArcMapMarkerImportDecision {
  String get label {
    switch (this) {
      case ArcMapMarkerImportDecision.autoPublished:
        return 'Auto Published';
      case ArcMapMarkerImportDecision.provisionalVisible:
        return 'Provisional';
      case ArcMapMarkerImportDecision.exception:
        return 'Needs Review';
      case ArcMapMarkerImportDecision.duplicate:
        return 'Duplicate';
      case ArcMapMarkerImportDecision.rejected:
        return 'Rejected';
    }
  }
}

@immutable
class ArcMapMarkerSourceDescriptor {
  const ArcMapMarkerSourceDescriptor({
    required this.id,
    required this.name,
    required this.permission,
    this.attribution = '',
    this.sourceUrl,
    this.licenseUrl,
    this.fetchedAt,
  });

  final String id;
  final String name;
  final ArcAdminMapMarkerSourcePermission permission;
  final String attribution;
  final String? sourceUrl;
  final String? licenseUrl;
  final DateTime? fetchedAt;

  bool get canImport => permission.canCache;
  bool get canPublish => permission.canPublish;
}

@immutable
class ArcExternalMapMarkerRecord {
  const ArcExternalMapMarkerRecord({
    required this.id,
    required this.mapId,
    required this.layer,
    required this.kind,
    required this.name,
    required this.point,
    this.description = '',
    this.blueprintId,
    this.confidence = ArcRaidIntelConfidence.limited,
    this.coordinateSpace = ArcMapMarkerCoordinateSpace.normalized,
    this.sourceWidth,
    this.sourceHeight,
    this.sourceLayerId,
    this.tags = const <String>[],
  });

  final String id;
  final String mapId;
  final ArcRaidMapLayer layer;
  final ArcAdminMapMarkerKind kind;
  final String name;
  final String description;
  final ArcNormalizedPoint point;
  final String? blueprintId;
  final ArcRaidIntelConfidence confidence;
  final ArcMapMarkerCoordinateSpace coordinateSpace;
  final double? sourceWidth;
  final double? sourceHeight;
  final String? sourceLayerId;
  final List<String> tags;
}

@immutable
class ArcMapMarkerImportPayload {
  const ArcMapMarkerImportPayload({
    required this.source,
    required this.records,
  });

  final ArcMapMarkerSourceDescriptor source;
  final List<ArcExternalMapMarkerRecord> records;
}

@immutable
class ArcMapMarkerAlignmentAnchor {
  const ArcMapMarkerAlignmentAnchor({
    required this.id,
    required this.sourcePoint,
    required this.canonicalPoint,
  });

  final String id;
  final ArcNormalizedPoint sourcePoint;
  final ArcNormalizedPoint canonicalPoint;
}

@immutable
class ArcMapMarkerAlignmentCalibration {
  const ArcMapMarkerAlignmentCalibration({
    required this.mapId,
    required this.layer,
    required this.sourceId,
    this.scaleX = 1,
    this.scaleY = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.residual = 0,
    this.confidence = 1,
    this.anchorCount = 0,
  });

  final String mapId;
  final ArcRaidMapLayer layer;
  final String sourceId;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;
  final double residual;
  final double confidence;
  final int anchorCount;

  ArcNormalizedPoint transform(ArcNormalizedPoint sourcePoint) {
    return ArcNormalizedPoint(
      x: (sourcePoint.x * scaleX) + offsetX,
      y: (sourcePoint.y * scaleY) + offsetY,
    ).clamp();
  }

  String get confidenceLabel {
    if (confidence >= 0.9) return 'High';
    if (confidence >= 0.72) return 'Medium';
    return 'Needs review';
  }
}

@immutable
class ArcMapMarkerImportRecordResult {
  const ArcMapMarkerImportRecordResult({
    required this.record,
    required this.decision,
    required this.reason,
    this.marker,
    this.duplicateOf,
  });

  final ArcExternalMapMarkerRecord record;
  final ArcMapMarkerImportDecision decision;
  final String reason;
  final ArcAdminMapMarker? marker;
  final ArcAdminMapMarker? duplicateOf;
}

@immutable
class ArcMapMarkerImportSummary {
  const ArcMapMarkerImportSummary({
    required this.source,
    required this.mapId,
    required this.layer,
    required this.alignment,
    required this.results,
  });

  final ArcMapMarkerSourceDescriptor source;
  final String mapId;
  final ArcRaidMapLayer layer;
  final ArcMapMarkerAlignmentCalibration alignment;
  final List<ArcMapMarkerImportRecordResult> results;

  int countFor(ArcMapMarkerImportDecision decision) =>
      results.where((result) => result.decision == decision).length;

  int get totalRecords => results.length;
  int get autoPublishedCount =>
      countFor(ArcMapMarkerImportDecision.autoPublished);
  int get provisionalCount =>
      countFor(ArcMapMarkerImportDecision.provisionalVisible);
  int get exceptionCount => countFor(ArcMapMarkerImportDecision.exception);
  int get duplicateCount => countFor(ArcMapMarkerImportDecision.duplicate);
  int get rejectedCount => countFor(ArcMapMarkerImportDecision.rejected);

  List<ArcAdminMapMarker> get acceptedMarkers => results
      .where(
        (result) =>
            result.decision == ArcMapMarkerImportDecision.autoPublished ||
            result.decision == ArcMapMarkerImportDecision.provisionalVisible ||
            result.decision == ArcMapMarkerImportDecision.exception,
      )
      .map((result) => result.marker)
      .whereType<ArcAdminMapMarker>()
      .toList(growable: false);

  List<ArcAdminMapMarker> get autoPublishedMarkers => results
      .where(
        (result) => result.decision == ArcMapMarkerImportDecision.autoPublished,
      )
      .map((result) => result.marker)
      .whereType<ArcAdminMapMarker>()
      .toList(growable: false);

  Map<ArcAdminMapMarkerKind, int> get countsByKind {
    final counts = <ArcAdminMapMarkerKind, int>{};
    for (final result in results) {
      counts[result.record.kind] = (counts[result.record.kind] ?? 0) + 1;
    }
    return counts;
  }
}
