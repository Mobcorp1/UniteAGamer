import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_alignment_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_map_marker_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';

class ArcMapMarkerImportEngine {
  const ArcMapMarkerImportEngine({
    this.alignmentEngine = const ArcMapMarkerAlignmentEngine(),
  });

  final ArcMapMarkerAlignmentEngine alignmentEngine;

  ArcMapMarkerImportSummary importRecords({
    required ArcMapMarkerImportPayload payload,
    required String mapId,
    required ArcRaidMapLayer layer,
    required Iterable<ArcAdminMapMarker> existingMarkers,
    required ArcMapMarkerAlignmentCalibration alignment,
    ArcRaidMapAsset? mapAsset,
    DateTime? importedAt,
  }) {
    final now = importedAt ?? DateTime.now().toUtc();
    final results = <ArcMapMarkerImportRecordResult>[];
    final candidates = existingMarkers
        .where((marker) => marker.mapId == mapId && marker.layer == layer)
        .toList(growable: true);

    for (final record in payload.records) {
      if (record.mapId != mapId || record.layer != layer) continue;
      if (!payload.source.canImport) {
        results.add(
          ArcMapMarkerImportRecordResult(
            record: record,
            decision: ArcMapMarkerImportDecision.rejected,
            reason:
                'Source permission is ${payload.source.permission.label}; import requires explicit permission.',
          ),
        );
        continue;
      }

      final alignedPoint = alignmentEngine.alignRecord(
        record,
        calibration: alignment,
        mapAsset: mapAsset,
      );
      final duplicate = _duplicateFor(record, alignedPoint, candidates);
      if (duplicate != null) {
        results.add(
          ArcMapMarkerImportRecordResult(
            record: record,
            decision: ArcMapMarkerImportDecision.duplicate,
            reason: 'Merged with ${duplicate.name}.',
            duplicateOf: duplicate,
          ),
        );
        continue;
      }

      final publication = _decisionFor(
        record: record,
        source: payload.source,
        alignment: alignment,
      );
      final marker = _markerFor(
        record: record,
        source: payload.source,
        alignedPoint: alignedPoint,
        decision: publication.decision,
        reason: publication.reason,
        alignment: alignment,
        importedAt: now,
      );
      candidates.add(marker);
      results.add(
        ArcMapMarkerImportRecordResult(
          record: record,
          decision: publication.decision,
          reason: publication.reason,
          marker: marker,
        ),
      );
    }

    return ArcMapMarkerImportSummary(
      source: payload.source,
      mapId: mapId,
      layer: layer,
      alignment: alignment,
      results: results,
    );
  }

  ArcAdminMapMarker _markerFor({
    required ArcExternalMapMarkerRecord record,
    required ArcMapMarkerSourceDescriptor source,
    required ArcNormalizedPoint alignedPoint,
    required ArcMapMarkerImportDecision decision,
    required String reason,
    required ArcMapMarkerAlignmentCalibration alignment,
    required DateTime importedAt,
  }) {
    final published = decision == ArcMapMarkerImportDecision.autoPublished;
    final provisional =
        decision == ArcMapMarkerImportDecision.provisionalVisible;
    final exception = decision == ArcMapMarkerImportDecision.exception;
    final evidence = ArcWorldIntelEvidenceRecord(
      id: 'evidence_${source.id}_${record.id}',
      type: ArcWorldIntelEvidenceType.permittedExternalCoordinate,
      sourceId: source.id,
      sourceName: source.name,
      sourceRecordId: record.id,
      sourceUrl: source.sourceUrl,
      timestamp: importedAt,
      mapId: record.mapId,
      layer: record.layer,
      coordinate: alignedPoint,
      originalCoordinate: record.point,
      landmarkText: record.name,
      category: record.kind.label,
      blueprintId: record.blueprintId,
      trust: record.confidence.score / 100,
      attribution: source.attribution,
      permissionState: source.permission.name,
      notes: record.description,
    );
    return ArcAdminMapMarker(
      id: _markerId(record, source.id),
      mapId: record.mapId,
      layer: record.layer,
      kind: record.kind,
      name: record.name,
      description: record.description,
      point: alignedPoint,
      blueprintId: record.blueprintId,
      sourceLabel: source.name,
      confidence: record.confidence,
      state: published
          ? ArcAdminMapMarkerState.published
          : ArcAdminMapMarkerState.draft,
      adminVerified: false,
      sourceName: source.name,
      sourceRecordId: record.id,
      sourceAttribution: source.attribution,
      sourceUrl: source.sourceUrl,
      sourcePermission: source.permission,
      sourceLayerId: record.sourceLayerId,
      originalPoint: record.point,
      coordinateSpace: record.coordinateSpace.name,
      importBatchId:
          'import_${source.id}_${record.mapId}_${record.layer.name}_${importedAt.millisecondsSinceEpoch}',
      alignmentConfidence: alignment.confidence,
      alignmentResidual: alignment.residual,
      duplicateGroupId: _duplicateGroupKey(record, alignedPoint),
      evidenceCount: math.max(1, record.tags.length),
      evidence: <ArcWorldIntelEvidenceRecord>[evidence],
      provisionalVisible: provisional,
      exceptionReason: exception ? reason : null,
      createdAt: importedAt,
      updatedAt: importedAt,
    );
  }

  _ImportPublication _decisionFor({
    required ArcExternalMapMarkerRecord record,
    required ArcMapMarkerSourceDescriptor source,
    required ArcMapMarkerAlignmentCalibration alignment,
  }) {
    if (!source.canPublish) {
      return const _ImportPublication(
        ArcMapMarkerImportDecision.rejected,
        'Source is not permitted for publication.',
      );
    }
    if (alignment.confidence < 0.58) {
      return const _ImportPublication(
        ArcMapMarkerImportDecision.exception,
        'Alignment confidence is below the publication threshold.',
      );
    }
    if (record.confidence.score >= ArcRaidIntelConfidence.strong.score &&
        alignment.confidence >= 0.82) {
      return const _ImportPublication(
        ArcMapMarkerImportDecision.autoPublished,
        'High-confidence permitted source with aligned coordinates.',
      );
    }
    if (record.confidence.score >= ArcRaidIntelConfidence.moderate.score &&
        alignment.confidence >= 0.68) {
      return const _ImportPublication(
        ArcMapMarkerImportDecision.provisionalVisible,
        'Permitted source is visible provisionally until admin review.',
      );
    }
    return const _ImportPublication(
      ArcMapMarkerImportDecision.exception,
      'Marker confidence requires admin review before publication.',
    );
  }

  ArcAdminMapMarker? _duplicateFor(
    ArcExternalMapMarkerRecord record,
    ArcNormalizedPoint point,
    Iterable<ArcAdminMapMarker> existingMarkers,
  ) {
    for (final marker in existingMarkers) {
      if (marker.kind != record.kind) continue;
      final sameSource =
          marker.sourceRecordId != null && marker.sourceRecordId == record.id;
      final sameName = _normalise(marker.name) == _normalise(record.name);
      if (sameSource) return marker;
      if (sameName && _distance(marker.point, point) <= 0.03) return marker;
      if (_duplicateGroupKey(record, point) == marker.duplicateGroupId) {
        return marker;
      }
    }
    return null;
  }

  static String _markerId(ArcExternalMapMarkerRecord record, String sourceId) {
    return [
      'import',
      record.mapId,
      record.layer.name,
      _slug(sourceId),
      _slug(record.id),
    ].join('_');
  }

  static String _duplicateGroupKey(
    ArcExternalMapMarkerRecord record,
    ArcNormalizedPoint point,
  ) {
    final x = (point.x * 100).round();
    final y = (point.y * 100).round();
    return [
      record.mapId,
      record.layer.name,
      record.kind.name,
      _normalise(record.name),
      x,
      y,
    ].join(':');
  }

  static String _normalise(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  static String _slug(String value) {
    final slug = _normalise(value).replaceAll(RegExp(r'_+'), '_');
    return slug.isEmpty ? 'item' : slug;
  }

  static double _distance(ArcNormalizedPoint a, ArcNormalizedPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}

class _ImportPublication {
  const _ImportPublication(this.decision, this.reason);

  final ArcMapMarkerImportDecision decision;
  final String reason;
}
