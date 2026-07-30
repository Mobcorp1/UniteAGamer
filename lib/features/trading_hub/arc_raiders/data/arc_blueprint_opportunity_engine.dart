import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcBlueprintOpportunityEngine {
  const ArcBlueprintOpportunityEngine();

  List<ArcRaidIntelCluster> build({
    required ArcRaidMap map,
    required List<ArcBlueprintDropReport> reports,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    List<ArcAdminMapMarker> canonicalMarkers = const <ArcAdminMapMarker>[],
    DateTime? now,
  }) {
    final utcNow = (now ?? DateTime.now()).toUtc();
    final relevantReports = reports
        .where((report) {
          if (!report.countsForMapIntelligence) return false;
          if (ArcRaidIntelligenceSeedData.normalizeMapId(
                report.intelligenceMapName,
              ) !=
              map.id) {
            return false;
          }
          final state = blueprintStates[report.blueprintId];
          return blueprintStates.isEmpty || state?.owned != true;
        })
        .toList(growable: false);

    final grouped = <String, List<ArcBlueprintDropReport>>{};
    for (final report in relevantReports) {
      final locationKey = _locationKey(report);
      grouped
          .putIfAbsent(
            '${report.blueprintId}|$locationKey',
            () => <ArcBlueprintDropReport>[],
          )
          .add(report);
    }

    final clusters = <ArcRaidIntelCluster>[];
    for (final entry in grouped.entries) {
      final group = entry.value;
      if (group.isEmpty) continue;
      final first = group.first;
      final pointResolution = _resolvePoint(
        map,
        first,
        canonicalMarkers: canonicalMarkers,
      );
      if (pointResolution == null) continue;

      final reporterIds = <String>{
        for (final report in group)
          if (report.userId.trim().isNotEmpty) report.userId.trim(),
        for (final report in group)
          ...report.confirmedByUserIds
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
      };
      final reportCount = group.fold<int>(
        0,
        (total, report) => total + math.max(1, report.confirmationCount),
      );
      final newest = group
          .map(
            (report) =>
                report.lastConfirmedAt ??
                report.foundAt ??
                report.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          )
          .reduce((a, b) => a.isAfter(b) ? a : b)
          .toUtc();
      final age = utcNow.difference(newest);
      final confidence = _confidence(
        reportCount: reportCount,
        independentReporterCount: reporterIds.length,
        age: age,
        calibratedPoint: !pointResolution.approximate,
      );
      final blueprintName = _blueprintName(first.blueprintId);
      final sourceLabels = group
          .map((report) => report.resolvedContainerLabel)
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
      final commonSource = sourceLabels.isEmpty
          ? first.sourceType.label
          : _mostCommon(sourceLabels);
      final conditions = group
          .map((report) => report.conditionLabel?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final locationLabel = _intelligenceLocationName(first).trim().isEmpty
          ? pointResolution.label
          : _intelligenceLocationName(first).trim();

      final evidence = [
        for (final report in group)
          ArcRaidIntelEvidence(
            id: report.id,
            blueprintId: report.blueprintId,
            mapId: map.id,
            poiId: report.intelligencePoiId,
            approximateArea: locationLabel,
            point: pointResolution.point,
            containerSource: report.resolvedContainerLabel,
            conditionId: report.conditionId,
            acquisitionSource: report.acquisitionSource.name,
            claimSummary: _claimSummary(
              blueprintName: blueprintName,
              report: report,
              locationLabel: locationLabel,
            ),
            sourceCategory: 'community_drop_report',
            sourceReference: report.signature.isEmpty
                ? report.id
                : report.signature,
            publishedAt: report.createdAt,
            reviewedAt: report.lastConfirmedAt,
            direct:
                !report.isGiftedOrIndirect ||
                report.recipientWitnessedOriginalPickup,
            confidence: confidence,
            notes: report.notes,
          ),
      ];

      clusters.add(
        ArcRaidIntelCluster(
          id: 'reports_${map.id}_${first.blueprintId}_${_safeId(_locationKey(first))}',
          mapId: map.id,
          label: '$blueprintName near $locationLabel',
          point: pointResolution.point,
          layer: pointResolution.layer,
          poiId: first.intelligencePoiId,
          blueprintIds: <String>[first.blueprintId],
          evidence: evidence,
          confidence: confidence,
          reportCount: reportCount,
          independentReporterCount: reporterIds.length,
          freshnessLabel: _freshness(age),
          commonSource: commonSource,
          conditionCorrelation: conditions.isEmpty
              ? 'Any reported condition'
              : conditions.join(', '),
        ),
      );
    }

    clusters.sort((a, b) {
      final confidenceCompare = b.confidence.score.compareTo(
        a.confidence.score,
      );
      if (confidenceCompare != 0) return confidenceCompare;
      final reportCompare = b.reportCount.compareTo(a.reportCount);
      if (reportCompare != 0) return reportCompare;
      return a.label.compareTo(b.label);
    });
    return clusters;
  }

  _ResolvedReportPoint? _resolvePoint(
    ArcRaidMap map,
    ArcBlueprintDropReport report, {
    required List<ArcAdminMapMarker> canonicalMarkers,
  }) {
    final resolution = const ArcIntelligenceLocationResolver()
        .resolveBlueprintReport(
          map: map,
          adminMarkers: canonicalMarkers,
          poiId: report.intelligencePoiId,
          markerId: report.markerId,
          poiName: report.intelligencePoiName,
          fallbackLabel: report.locationName,
          legacyPoint: report.historicalPoint,
          preferredLayer: report.intelligenceLayer,
        );
    if (resolution == null || resolution.needsAdminReview) return null;
    return _ResolvedReportPoint(
      point: resolution.point,
      layer: resolution.layer,
      label: resolution.label,
      approximate: resolution.approximate,
    );
  }

  int _compareMarkerQuality(ArcRaidMapMarker a, ArcRaidMapMarker b) {
    if (a.approximate != b.approximate) {
      return a.approximate ? 1 : -1;
    }

    final confidenceCompare = b.confidence.index.compareTo(a.confidence.index);
    if (confidenceCompare != 0) return confidenceCompare;

    final poiCompare = (b.category == ArcRaidMapMarkerCategory.poi ? 1 : 0)
        .compareTo(a.category == ArcRaidMapMarkerCategory.poi ? 1 : 0);
    if (poiCompare != 0) return poiCompare;

    return a.id.compareTo(b.id);
  }

  bool _markerMatchesPoiId({
    required ArcRaidMapMarker marker,
    required String poiId,
  }) {
    if (marker.payloadId == poiId || marker.id == poiId) return true;

    final canonicalMarkerId = marker.id.replaceFirst('_poi_', '_');
    if (canonicalMarkerId == poiId) return true;

    final normalizedPoiId = _normalize(poiId);
    return _normalize(marker.id) == normalizedPoiId ||
        _normalize(canonicalMarkerId) == normalizedPoiId;
  }

  ArcRaidMapLayer layerForCluster(ArcRaidMap map, ArcRaidIntelCluster cluster) {
    final poiId = cluster.poiId;
    if (poiId != null) {
      final matches =
          map.markers
              .where(
                (marker) => _markerMatchesPoiId(marker: marker, poiId: poiId),
              )
              .toList(growable: false)
            ..sort(_compareMarkerQuality);

      if (matches.isNotEmpty) {
        return matches.first.layer;
      }
    }
    final normalizedLabel = _normalize(cluster.label);
    for (final marker in map.markers) {
      if (normalizedLabel.contains(_normalize(marker.label))) {
        return marker.layer;
      }
    }
    return ArcRaidMapLayer.surface;
  }

  ArcRaidIntelConfidence _confidence({
    required int reportCount,
    required int independentReporterCount,
    required Duration age,
    required bool calibratedPoint,
  }) {
    var score = math.min(reportCount, 8) * 8;
    score += math.min(independentReporterCount, 5) * 12;
    if (calibratedPoint) score += 10;
    if (age.inDays <= 7) {
      score += 18;
    } else if (age.inDays <= 30) {
      score += 10;
    } else if (age.inDays > 90) {
      score -= 18;
    }

    if (score >= 88) return ArcRaidIntelConfidence.confirmed;
    if (score >= 70) return ArcRaidIntelConfidence.strong;
    if (score >= 48) return ArcRaidIntelConfidence.moderate;
    if (score >= 24) return ArcRaidIntelConfidence.limited;
    return ArcRaidIntelConfidence.unverified;
  }

  String _blueprintName(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _locationKey(ArcBlueprintDropReport report) {
    final poiId = report.intelligencePoiId?.trim();
    if (poiId != null && poiId.isNotEmpty) return 'poi:$poiId';
    final poiName = report.intelligencePoiName?.trim();
    if (poiName != null && poiName.isNotEmpty) {
      return 'poi_name:${_normalize(poiName)}';
    }
    final enemyId = report.enemySourceId?.trim();
    if (enemyId != null && enemyId.isNotEmpty) return 'enemy:$enemyId';
    final enemyName = report.enemySourceName?.trim();
    if (enemyName != null && enemyName.isNotEmpty) {
      return 'enemy_name:${_normalize(enemyName)}';
    }
    return 'source:${report.sourceType.name}';
  }

  String _intelligenceLocationName(ArcBlueprintDropReport report) {
    final poiName = report.intelligencePoiName?.trim();
    if (poiName != null && poiName.isNotEmpty) return poiName;
    final poiId = report.intelligencePoiId?.trim();
    if (poiId != null && poiId.isNotEmpty) return poiId;
    return report.locationName;
  }

  String _claimSummary({
    required String blueprintName,
    required ArcBlueprintDropReport report,
    required String locationLabel,
  }) {
    if (report.isGiftedOrIndirect && report.hasOriginalFindLocation) {
      return '$blueprintName reported from original find location '
          '$locationLabel after ${report.acquisitionSource.label.toLowerCase()}.';
    }
    if (report.isGiftedOrIndirect) {
      return '$blueprintName indirect report at $locationLabel from '
          '${report.acquisitionSource.label.toLowerCase()}.';
    }
    return '$blueprintName reported at $locationLabel from '
        '${report.resolvedContainerLabel}.';
  }

  String _freshness(Duration age) {
    if (age.inHours < 24) return 'Reported today';
    if (age.inDays <= 7) return 'Reported this week';
    if (age.inDays <= 30) return 'Reported this month';
    if (age.inDays <= 90) return 'Reported within 90 days';
    return 'Older community evidence';
  }

  String _mostCommon(List<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });
    return sorted.first.key;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  String _safeId(String value) {
    return _normalize(value).replaceAll(' ', '_');
  }
}

class _ResolvedReportPoint {
  const _ResolvedReportPoint({
    required this.point,
    required this.layer,
    required this.label,
    required this.approximate,
  });

  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
  final String label;
  final bool approximate;
}
