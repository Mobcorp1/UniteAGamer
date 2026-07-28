import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';

@immutable
class ArcWorldIntelPopulationResult {
  const ArcWorldIntelPopulationResult({
    required this.markers,
    required this.coverageReport,
    required this.duplicateGroups,
    required this.townHallBridgeCandidates,
  });

  final List<ArcAdminMapMarker> markers;
  final ArcWorldIntelCoverageReport coverageReport;
  final List<ArcWorldIntelDuplicateGroup> duplicateGroups;
  final List<ArcWorldIntelTownHallCandidate> townHallBridgeCandidates;

  List<ArcAdminMapMarker> get liveMarkers =>
      markers.where((marker) => marker.isLive).toList(growable: false);

  List<ArcAdminMapMarker> get autoPublishedMarkers => markers
      .where((marker) => marker.state == ArcAdminMapMarkerState.published)
      .toList(growable: false);

  List<ArcAdminMapMarker> get provisionalMarkers => markers
      .where((marker) => marker.provisionalVisible && !marker.isPublished)
      .toList(growable: false);

  List<ArcAdminMapMarker> get exceptionMarkers => markers
      .where((marker) => marker.hasImportException)
      .toList(growable: false);
}

class ArcWorldIntelPopulationEngine {
  const ArcWorldIntelPopulationEngine();

  static const String uagPoiSourceId = 'uag_poi_catalogue';
  static const String uagPoiSourceName = 'UAG POI Catalogue';
  static const String uagDropReportSourceId = 'uag_blueprint_drop_reports';
  static const String uagCommunitySourceId = 'uag_community_intel';
  static const String mikeAdminSourceId = 'mike_admin_intel';

  ArcWorldIntelPopulationResult build({
    required List<ArcRaidMap> maps,
    List<ArcBlueprintDropReport> dropReports = const <ArcBlueprintDropReport>[],
    List<ArcCommunityIntelReport> communityReports =
        const <ArcCommunityIntelReport>[],
    List<ArcAdminMapMarker> adminMarkers = const <ArcAdminMapMarker>[],
    DateTime? now,
  }) {
    final generatedAt = (now ?? DateTime.now()).toUtc();
    final candidates = <ArcAdminMapMarker>[];
    var unmatchedBlueprintReports = 0;

    for (final map in maps) {
      final mapCandidates = _markersForMapCatalogue(map, generatedAt);
      candidates.addAll(mapCandidates);
    }

    for (final report in dropReports) {
      final map = _mapForReport(maps, report);
      if (map == null) {
        unmatchedBlueprintReports += 1;
        continue;
      }
      final marker = _markerForDropReport(map, report, generatedAt);
      if (marker == null) {
        unmatchedBlueprintReports += 1;
        continue;
      }
      candidates.add(marker);
    }

    for (final report in communityReports) {
      final map = maps.firstWhere(
        (item) => item.id == report.mapId,
        orElse: () => maps.first,
      );
      if (map.id != report.mapId) continue;
      candidates.add(_markerForCommunityReport(map, report, generatedAt));
    }

    for (final marker in adminMarkers) {
      if (maps.any((map) => map.id == marker.mapId)) {
        candidates.add(_withAdminEvidence(marker, generatedAt));
      }
    }

    final merge = _mergeCandidates(candidates);
    final scored =
        merge.markers
            .map((marker) => _applyPublicationState(marker, generatedAt))
            .toList(growable: false)
          ..sort((a, b) {
            final mapCompare = a.mapId.compareTo(b.mapId);
            if (mapCompare != 0) return mapCompare;
            final layerCompare = a.layer.name.compareTo(b.layer.name);
            if (layerCompare != 0) return layerCompare;
            return a.name.compareTo(b.name);
          });

    final townHallCandidates = _rankTownHallBridgeCandidates(scored);
    final coverage = _coverageReport(
      markers: scored,
      maps: maps,
      generatedAt: generatedAt,
      duplicateGroups: merge.duplicateGroups,
      unmatchedBlueprintReports: unmatchedBlueprintReports,
      townHallCandidates: townHallCandidates,
      uagReportsProcessed: dropReports.length + communityReports.length,
      uagReportsRequiringReview: unmatchedBlueprintReports,
    );

    return ArcWorldIntelPopulationResult(
      markers: scored,
      coverageReport: coverage,
      duplicateGroups: merge.duplicateGroups,
      townHallBridgeCandidates: townHallCandidates,
    );
  }

  List<ArcAdminMapMarker> _markersForMapCatalogue(
    ArcRaidMap map,
    DateTime generatedAt,
  ) {
    final sourcePois = ArcPoiDataStore.blueprintReportPoisForMap(
      map.displayName,
    );
    final markers = <ArcAdminMapMarker>[];

    for (final poi in sourcePois) {
      final layer = _layerForPoi(map, poi);
      final point = _pointForPoi(map, poi, layer);
      if (point == null) continue;
      final kind = _kindForPoi(poi);
      final evidenceType = _evidenceTypeForPoi(poi);
      final confidence = _confidenceForPoi(
        map: map,
        layer: layer,
        poi: poi,
        kind: kind,
        evidenceType: evidenceType,
      );
      final evidence = ArcWorldIntelEvidenceRecord(
        id: 'evidence_${map.id}_${poi.id}',
        type: evidenceType,
        sourceId: uagPoiSourceId,
        sourceName: uagPoiSourceName,
        sourceRecordId: poi.id,
        timestamp: generatedAt,
        mapId: map.id,
        layer: layer,
        coordinate: point,
        originalCoordinate: point,
        landmarkText: poi.resolvedAreaName,
        category: kind.label,
        trust: evidenceType == ArcWorldIntelEvidenceType.mikeAdminReport
            ? 1
            : 0.82,
        attribution: _sourceAttributionForPoi(poi),
        permissionState: evidenceType == ArcWorldIntelEvidenceType.writtenGuide
            ? 'research_lead_uag_summary'
            : 'uag_internal',
        notes: poi.notes ?? '',
      );
      markers.add(
        ArcAdminMapMarker(
          id: 'world_${map.id}_${layer.name}_${kind.name}_${_slug(poi.id)}',
          mapId: map.id,
          layer: layer,
          kind: kind,
          name: poi.name,
          description: _descriptionForPoi(
            map: map,
            layer: layer,
            poi: poi,
            kind: kind,
            evidenceType: evidenceType,
          ),
          point: point,
          confidence: confidence,
          state: ArcAdminMapMarkerState.draft,
          adminVerified: false,
          seedReferenceId: poi.id,
          sourceName: uagPoiSourceName,
          sourceRecordId: poi.id,
          sourceAttribution: evidence.attribution,
          sourcePermission: ArcAdminMapMarkerSourcePermission.permitted,
          originalPoint: point,
          coordinateSpace: 'uag_normalized',
          alignmentConfidence: _alignmentConfidence(map, layer),
          alignmentResidual: map.calibrationForLayer(layer)?.residualError,
          duplicateGroupId: _duplicateKey(
            mapId: map.id,
            layer: layer,
            kind: kind,
            name: poi.name,
            point: point,
            blueprintId: null,
          ),
          evidenceCount: 1,
          evidence: <ArcWorldIntelEvidenceRecord>[evidence],
          createdAt: generatedAt,
          updatedAt: generatedAt,
        ),
      );
    }

    markers.addAll(_layerAnchorMarkers(map, generatedAt, markers));
    return markers;
  }

  Iterable<ArcAdminMapMarker> _layerAnchorMarkers(
    ArcRaidMap map,
    DateTime generatedAt,
    List<ArcAdminMapMarker> existing,
  ) {
    if (!map.availableLayers.contains(ArcRaidMapLayer.underground)) {
      return const <ArcAdminMapMarker>[];
    }
    if (existing.any((marker) => marker.layer == ArcRaidMapLayer.underground)) {
      return const <ArcAdminMapMarker>[];
    }
    final anchor = map.hatches.isNotEmpty
        ? map.hatches.first.point
        : const ArcNormalizedPoint(x: 0.5, y: 0.5);
    final evidence = ArcWorldIntelEvidenceRecord(
      id: 'evidence_${map.id}_level2_registered_asset',
      type: ArcWorldIntelEvidenceType.mapLabelPoiAnchor,
      sourceId: 'uag_registered_map_assets',
      sourceName: 'UAG Map Asset Registry',
      sourceRecordId: '${map.id}_level_2',
      timestamp: generatedAt,
      mapId: map.id,
      layer: ArcRaidMapLayer.underground,
      coordinate: anchor,
      originalCoordinate: anchor,
      landmarkText: '${map.displayName} Level 2 registered layer',
      category: ArcAdminMapMarkerKind.raiderHatch.label,
      trust: 0.62,
      permissionState: 'uag_internal',
      notes:
          'Layer anchor generated from the registered Level 2 map asset. Coordinate remains provisional until UAG calibration improves.',
    );
    return <ArcAdminMapMarker>[
      ArcAdminMapMarker(
        id: 'world_${map.id}_underground_layer_anchor',
        mapId: map.id,
        layer: ArcRaidMapLayer.underground,
        kind: ArcAdminMapMarkerKind.raiderHatch,
        name: '${map.displayName} Level 2 Access',
        description:
            'UAG provisional Level 2 anchor. Use this for layer selection and review; final coordinate calibration is still required.',
        point: anchor,
        confidence: ArcRaidIntelConfidence.limited,
        state: ArcAdminMapMarkerState.draft,
        adminVerified: false,
        sourceName: 'UAG Map Asset Registry',
        sourceRecordId: '${map.id}_level_2',
        sourcePermission: ArcAdminMapMarkerSourcePermission.permitted,
        originalPoint: anchor,
        coordinateSpace: 'uag_layer_anchor',
        alignmentConfidence: _alignmentConfidence(
          map,
          ArcRaidMapLayer.underground,
        ),
        duplicateGroupId: _duplicateKey(
          mapId: map.id,
          layer: ArcRaidMapLayer.underground,
          kind: ArcAdminMapMarkerKind.raiderHatch,
          name: '${map.displayName} Level 2 Access',
          point: anchor,
          blueprintId: null,
        ),
        evidence: <ArcWorldIntelEvidenceRecord>[evidence],
        provisionalVisible: true,
        createdAt: generatedAt,
        updatedAt: generatedAt,
      ),
    ];
  }

  ArcAdminMapMarker? _markerForDropReport(
    ArcRaidMap map,
    ArcBlueprintDropReport report,
    DateTime generatedAt,
  ) {
    final resolution = _pointForReport(map, report);
    final point = resolution?.point;
    final layer = resolution?.layer ?? ArcRaidMapLayer.surface;
    final locationLabel = report.locationName.trim().isEmpty
        ? 'Unresolved report location'
        : report.locationName.trim();
    final hasPoint = point != null;
    final markerPoint = point ?? const ArcNormalizedPoint(x: 0.5, y: 0.5);
    final evidence = ArcWorldIntelEvidenceRecord(
      id: 'evidence_drop_${report.id}',
      type: ArcWorldIntelEvidenceType.uagDropReport,
      sourceId: uagDropReportSourceId,
      sourceName: 'UAG Blueprint Drop Reports',
      sourceRecordId: report.id,
      reporterId: report.userId,
      timestamp: report.lastConfirmedAt ?? report.foundAt ?? report.createdAt,
      mapId: map.id,
      layer: layer,
      coordinate: hasPoint ? markerPoint : null,
      originalCoordinate: hasPoint ? markerPoint : null,
      landmarkText: locationLabel,
      category: ArcAdminMapMarkerKind.blueprint.label,
      blueprintId: report.blueprintId,
      trust: math.max(1, report.confirmationCount) / 3,
      permissionState: 'uag_internal',
      confirmationCount: report.confirmationCount,
      notes: report.notes,
    );
    return ArcAdminMapMarker(
      id: 'world_drop_${map.id}_${_slug(report.blueprintId)}_${_slug(report.areaKey)}',
      mapId: map.id,
      layer: layer,
      kind: ArcAdminMapMarkerKind.blueprint,
      name: 'Blueprint report - $locationLabel',
      description:
          'UAG Blueprint report cluster for ${report.blueprintId} at $locationLabel. ${hasPoint ? 'Linked to a UAG POI anchor.' : 'Location requires admin matching before publication.'}',
      point: markerPoint,
      blueprintId: report.blueprintId,
      sourceLabel: 'UAG Drop Report',
      confidence: hasPoint
          ? ArcRaidIntelConfidence.moderate
          : ArcRaidIntelConfidence.unverified,
      state: ArcAdminMapMarkerState.draft,
      adminVerified: false,
      sourceName: 'UAG Blueprint Drop Reports',
      sourceRecordId: report.id,
      sourcePermission: ArcAdminMapMarkerSourcePermission.permitted,
      originalPoint: hasPoint ? markerPoint : null,
      coordinateSpace: hasPoint ? 'uag_poi_anchor' : 'unresolved_landmark',
      alignmentConfidence: hasPoint ? _alignmentConfidence(map, layer) : 0,
      duplicateGroupId: _duplicateKey(
        mapId: map.id,
        layer: layer,
        kind: ArcAdminMapMarkerKind.blueprint,
        name: locationLabel,
        point: markerPoint,
        blueprintId: report.blueprintId,
      ),
      evidenceCount: math.max(1, report.confirmationCount),
      evidence: <ArcWorldIntelEvidenceRecord>[evidence],
      exceptionReason: hasPoint ? null : 'Report location could not be mapped.',
      createdAt: generatedAt,
      updatedAt: generatedAt,
    );
  }

  ArcAdminMapMarker _markerForCommunityReport(
    ArcRaidMap map,
    ArcCommunityIntelReport report,
    DateTime generatedAt,
  ) {
    final kind = _kindForCommunityCategory(report.category);
    final evidence = ArcWorldIntelEvidenceRecord(
      id: 'evidence_community_${report.id}',
      type: ArcWorldIntelEvidenceType.uagCommunityIntelReport,
      sourceId: uagCommunitySourceId,
      sourceName: 'UAG Community Intel',
      sourceRecordId: report.id,
      reporterId: report.reporterUid,
      timestamp: report.lastConfirmedAt ?? report.updatedAt,
      mapId: report.mapId,
      layer: report.layer,
      coordinate: report.point,
      originalCoordinate: report.point,
      landmarkText: report.poiName ?? report.displayLabel,
      category: kind.label,
      blueprintId: report.blueprintId,
      trust: report.reporterTrustWeight,
      permissionState: 'uag_internal',
      confirmationCount: report.confirmationCount,
      disputeCount: report.disputeCount,
      notes: report.notes,
    );
    return ArcAdminMapMarker(
      id: 'world_community_${_slug(report.id)}',
      mapId: map.id,
      layer: report.layer,
      kind: kind,
      name: report.displayLabel,
      description:
          'UAG community Intel with ${report.confirmationCount} confirmation(s) and ${report.disputeCount} dispute(s).',
      point: report.point,
      blueprintId: report.blueprintId,
      sourceLabel: 'Community Intel',
      confidence: report.confidence,
      state: ArcAdminMapMarkerState.draft,
      adminVerified: false,
      sourceName: 'UAG Community Intel',
      sourceRecordId: report.id,
      sourcePermission: ArcAdminMapMarkerSourcePermission.permitted,
      originalPoint: report.point,
      coordinateSpace: 'uag_reported_normalized',
      alignmentConfidence: _alignmentConfidence(map, report.layer),
      duplicateGroupId: _duplicateKey(
        mapId: map.id,
        layer: report.layer,
        kind: kind,
        name: report.displayLabel,
        point: report.point,
        blueprintId: report.blueprintId,
      ),
      evidenceCount: report.confirmationCount,
      evidence: <ArcWorldIntelEvidenceRecord>[evidence],
      exceptionReason: report.disputeCount >= 2 ? 'Community disputed.' : null,
      createdAt: generatedAt,
      updatedAt: generatedAt,
    );
  }

  ArcAdminMapMarker _withAdminEvidence(
    ArcAdminMapMarker marker,
    DateTime generatedAt,
  ) {
    if (marker.evidence.isNotEmpty) return marker;
    final evidence = ArcWorldIntelEvidenceRecord(
      id: 'evidence_admin_${marker.id}',
      type: ArcWorldIntelEvidenceType.mikeAdminReport,
      sourceId: mikeAdminSourceId,
      sourceName: marker.sourceName ?? marker.sourceLabel,
      sourceRecordId: marker.sourceRecordId ?? marker.id,
      reporterId: marker.createdByUid,
      timestamp: marker.updatedAt ?? marker.createdAt ?? generatedAt,
      mapId: marker.mapId,
      layer: marker.layer,
      coordinate: marker.point,
      originalCoordinate: marker.originalPoint ?? marker.point,
      landmarkText: marker.name,
      category: marker.kind.label,
      blueprintId: marker.blueprintId,
      trust: marker.adminVerified ? 1 : 0.84,
      attribution: marker.sourceAttribution ?? '',
      permissionState: marker.sourcePermission.name,
      notes: marker.description,
    );
    return marker.copyWith(
      evidence: <ArcWorldIntelEvidenceRecord>[evidence],
      evidenceCount: math.max(1, marker.evidenceCount),
    );
  }

  _MergeResult _mergeCandidates(List<ArcAdminMapMarker> candidates) {
    final merged = <ArcAdminMapMarker>[];
    final groups = <ArcWorldIntelDuplicateGroup>[];

    for (final candidate in candidates) {
      final duplicateIndex = merged.indexWhere(
        (existing) => _duplicates(existing, candidate),
      );
      if (duplicateIndex == -1) {
        merged.add(candidate);
        continue;
      }
      final existing = merged[duplicateIndex];
      merged[duplicateIndex] = _mergeMarker(existing, candidate);
      groups.add(
        ArcWorldIntelDuplicateGroup(
          id: 'dup_${existing.duplicateGroupId ?? existing.id}_${candidate.id}',
          markerIds: <String>[existing.id, candidate.id],
          reason: 'Same map, layer, category and matching source/name radius.',
        ),
      );
    }

    return _MergeResult(markers: merged, duplicateGroups: groups);
  }

  ArcAdminMapMarker _mergeMarker(ArcAdminMapMarker a, ArcAdminMapMarker b) {
    final evidence = <String, ArcWorldIntelEvidenceRecord>{
      for (final record in a.evidence) record.id: record,
      for (final record in b.evidence) record.id: record,
    }.values.toList(growable: false);
    final best = b.confidence.score > a.confidence.score ? b : a;
    final published =
        a.state == ArcAdminMapMarkerState.published ||
        b.state == ArcAdminMapMarkerState.published;
    final provisional = a.provisionalVisible || b.provisionalVisible;
    final exception = a.exceptionReason ?? b.exceptionReason;
    return best.copyWith(
      id: a.id.compareTo(b.id) <= 0 ? a.id : b.id,
      description: _mergeDescription(a, b, evidence.length),
      point: best.point,
      state: published
          ? ArcAdminMapMarkerState.published
          : ArcAdminMapMarkerState.draft,
      evidence: evidence,
      evidenceCount: evidence.length,
      provisionalVisible: provisional,
      exceptionReason: exception,
      duplicateGroupId: a.duplicateGroupId ?? b.duplicateGroupId,
    );
  }

  ArcAdminMapMarker _applyPublicationState(
    ArcAdminMapMarker marker,
    DateTime generatedAt,
  ) {
    if (!marker.sourcePermission.canPublish) {
      return marker.copyWith(
        state: ArcAdminMapMarkerState.draft,
        provisionalVisible: false,
        exceptionReason: 'Source is not permitted for publication.',
        updatedAt: generatedAt,
      );
    }
    final score = _confidenceScore(marker);
    final confidence = _confidenceFromScore(score);
    if (score >= 82) {
      return marker.copyWith(
        confidence: confidence,
        state: ArcAdminMapMarkerState.published,
        provisionalVisible: false,
        adminVerified: marker.adminVerified,
        clearExceptionReason: marker.exceptionReason == null,
        updatedAt: generatedAt,
      );
    }
    if (score >= 54) {
      return marker.copyWith(
        confidence: confidence,
        state: marker.state == ArcAdminMapMarkerState.published
            ? ArcAdminMapMarkerState.published
            : ArcAdminMapMarkerState.draft,
        provisionalVisible: marker.state != ArcAdminMapMarkerState.published,
        clearExceptionReason: marker.exceptionReason == null,
        updatedAt: generatedAt,
      );
    }
    return marker.copyWith(
      confidence: confidence,
      state: ArcAdminMapMarkerState.draft,
      provisionalVisible: false,
      exceptionReason:
          marker.exceptionReason ?? 'Confidence below provisional threshold.',
      updatedAt: generatedAt,
    );
  }

  ArcWorldIntelCoverageReport _coverageReport({
    required List<ArcAdminMapMarker> markers,
    required List<ArcRaidMap> maps,
    required DateTime generatedAt,
    required List<ArcWorldIntelDuplicateGroup> duplicateGroups,
    required int unmatchedBlueprintReports,
    required int uagReportsProcessed,
    required int uagReportsRequiringReview,
    required List<ArcWorldIntelTownHallCandidate> townHallCandidates,
  }) {
    final markerCountByMap = <String, int>{};
    final markerCountByLayer = <String, int>{};
    final markerCountByCategory = <String, int>{};
    var multiSource = 0;
    var uagOnly = 0;
    var generatedDescriptions = 0;
    var permittedCoordinates = 0;
    var writtenLeads = 0;
    var videoLeads = 0;
    var externalResearch = 0;
    var linkedReports = 0;
    var mappedReports = 0;
    var clusteredReports = 0;

    for (final marker in markers) {
      markerCountByMap[marker.mapId] =
          (markerCountByMap[marker.mapId] ?? 0) + 1;
      final layerKey = '${marker.mapId}:${marker.layer.name}';
      markerCountByLayer[layerKey] = (markerCountByLayer[layerKey] ?? 0) + 1;
      markerCountByCategory[marker.kind.name] =
          (markerCountByCategory[marker.kind.name] ?? 0) + 1;
      if (marker.description.trim().isNotEmpty) generatedDescriptions += 1;
      final sourceIds = marker.evidence.map((item) => item.sourceId).toSet();
      if (sourceIds.length > 1) multiSource += 1;
      if (marker.evidence.every((record) => record.isUagOwned)) uagOnly += 1;
      for (final record in marker.evidence) {
        if (record.type ==
            ArcWorldIntelEvidenceType.permittedExternalCoordinate) {
          permittedCoordinates += 1;
          externalResearch += 1;
        }
        if (record.type == ArcWorldIntelEvidenceType.writtenGuide) {
          writtenLeads += 1;
          externalResearch += 1;
        }
        if (record.type == ArcWorldIntelEvidenceType.videoReference) {
          videoLeads += 1;
          externalResearch += 1;
        }
        if (record.type == ArcWorldIntelEvidenceType.uagDropReport ||
            record.type == ArcWorldIntelEvidenceType.uagBlueprintReport ||
            record.type == ArcWorldIntelEvidenceType.uagCommunityIntelReport) {
          linkedReports += 1;
          if (record.coordinate != null) mappedReports += 1;
        }
      }
      if (marker.evidence.length > 1) clusteredReports += 1;
    }

    final autoPublished = markers
        .where((marker) => marker.state == ArcAdminMapMarkerState.published)
        .length;
    final provisional = markers
        .where((marker) => marker.provisionalVisible && !marker.isPublished)
        .length;
    final exceptions = markers
        .where((marker) => marker.hasImportException)
        .length;
    final reviewPercentage = markers.isEmpty
        ? 0.0
        : (exceptions / markers.length * 100);

    return ArcWorldIntelCoverageReport(
      id: 'coverage_${generatedAt.millisecondsSinceEpoch}',
      generatedAt: generatedAt,
      uagReportsProcessed: uagReportsProcessed,
      uagReportsMapped: mappedReports,
      uagReportsClustered: clusteredReports,
      uagReportsLinkedToMarkers: linkedReports,
      uagReportsRequiringReview:
          uagReportsRequiringReview +
          markers.where((m) => m.hasImportException).length,
      externalResearchRecordsProcessed: externalResearch,
      permittedCoordinateRecordsUsed: permittedCoordinates,
      writtenGuideLeadsUsed: writtenLeads,
      videoLeadsUsed: videoLeads,
      multiSourceCorroboratedMarkerCount: multiSource,
      uagOnlyMarkerCount: uagOnly,
      generatedDescriptionCount: generatedDescriptions,
      autoPublishedCount: autoPublished,
      provisionalCount: provisional,
      exceptionCount: exceptions,
      duplicateCount: duplicateGroups.length,
      unmatchedBlueprintCount: unmatchedBlueprintReports,
      estimatedReviewPercentage: double.parse(
        reviewPercentage.toStringAsFixed(1),
      ),
      markerCountByMap: markerCountByMap,
      markerCountByLayer: markerCountByLayer,
      markerCountByCategory: markerCountByCategory,
      alignmentConfidenceByLayer: _alignmentConfidenceByLayer(maps),
      residualErrorByLayer: _residualErrorByLayer(maps),
      controlPointCountByLayer: _controlPointCountByLayer(maps),
      sourceAttribution: const <String, String>{
        uagPoiSourceId:
            'UAG first-party POI catalogue, map asset registry and curated local ARC Raiders research notes.',
        uagDropReportSourceId:
            'UAG player Blueprint/drop reports stored in arc_blueprint_drop_reports.',
        uagCommunitySourceId:
            'UAG Community Intel reports stored in arc_community_intel_reports.',
        mikeAdminSourceId:
            'Mike/admin Intel entered through the Admin Map and Intel Editor.',
      },
      townHallCandidates: townHallCandidates,
    );
  }

  List<ArcWorldIntelTownHallCandidate> _rankTownHallBridgeCandidates(
    List<ArcAdminMapMarker> markers,
  ) {
    const wording = 'The closest weapon cache to Town Hall on the bridge.';
    final candidates = markers
        .where(
          (marker) =>
              marker.mapId == 'buried_city' &&
              (marker.kind == ArcAdminMapMarkerKind.weaponCache ||
                  marker.kind == ArcAdminMapMarkerKind.weaponCase) &&
              (_containsAny(marker.name, const <String>[
                    'town hall',
                    'bridge',
                  ]) ||
                  _containsAny(marker.description, const <String>[
                    'town hall',
                    'bridge',
                  ])),
        )
        .toList(growable: false);
    final ranked =
        candidates
            .map((marker) {
              var score = marker.confidence.score;
              if (_containsAny(marker.name, const <String>['town hall'])) {
                score += 12;
              }
              if (_containsAny(marker.name, const <String>['bridge'])) {
                score += 12;
              }
              if (_containsAny(marker.description, const <String>[
                'player-reported',
              ])) {
                score += 10;
              }
              final confidence = _confidenceFromScore(score);
              return ArcWorldIntelTownHallCandidate(
                id: marker.id,
                label: marker.name,
                confidence: confidence,
                reason:
                    'Matches Town Hall and bridge wording with ${marker.resolvedEvidenceCount} retained evidence record(s).',
                point: marker.point,
                originalWording: wording,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.confidence.score.compareTo(a.confidence.score));
    if (ranked.isEmpty) return const <ArcWorldIntelTownHallCandidate>[];
    return <ArcWorldIntelTownHallCandidate>[
      ArcWorldIntelTownHallCandidate(
        id: ranked.first.id,
        label: ranked.first.label,
        confidence: ranked.first.confidence,
        reason: ranked.first.reason,
        point: ranked.first.point,
        originalWording: ranked.first.originalWording,
        selected:
            ranked.first.confidence.score >=
            ArcRaidIntelConfidence.moderate.score,
      ),
      ...ranked.skip(1),
    ];
  }

  ArcRaidMap? _mapForReport(
    List<ArcRaidMap> maps,
    ArcBlueprintDropReport report,
  ) {
    final normalized = _normalizeMapName(report.mapName);
    for (final map in maps) {
      final names = <String>{
        _normalizeMapName(map.id),
        _normalizeMapName(map.displayName),
        ...map.aliases.map(_normalizeMapName),
      };
      if (names.contains(normalized)) return map;
    }
    return null;
  }

  _ReportPointResolution? _pointForReport(
    ArcRaidMap map,
    ArcBlueprintDropReport report,
  ) {
    final poiId = report.poiId?.trim();
    if (poiId != null && poiId.isNotEmpty) {
      final match = map.pois.cast<ArcRaidMapPoi?>().firstWhere(
        (poi) => poi?.id == poiId,
        orElse: () => null,
      );
      if (match != null) {
        return _ReportPointResolution(
          point: match.point,
          layer: _layerForText(map, '${match.id} ${match.name}'),
        );
      }
    }
    final poiName = report.poiName?.trim();
    if (poiName != null && poiName.isNotEmpty) {
      final normalized = _normalize(poiName);
      final match = map.pois.cast<ArcRaidMapPoi?>().firstWhere(
        (poi) => poi != null && _normalize(poi.name) == normalized,
        orElse: () => null,
      );
      if (match != null) {
        return _ReportPointResolution(
          point: match.point,
          layer: _layerForText(map, '${match.id} ${match.name}'),
        );
      }
    }
    return null;
  }

  ArcNormalizedPoint? _pointForPoi(
    ArcRaidMap map,
    ArcPoiData poi,
    ArcRaidMapLayer layer,
  ) {
    final byId = map.pois.cast<ArcRaidMapPoi?>().firstWhere(
      (item) => item?.id == poi.id,
      orElse: () => null,
    );
    if (byId != null) return byId.point;
    final normalized = _normalize(poi.name);
    final byName = map.pois.cast<ArcRaidMapPoi?>().firstWhere(
      (item) => item != null && _normalize(item.name) == normalized,
      orElse: () => null,
    );
    if (byName != null) return byName.point;
    final layerMarker = map.markers.cast<ArcRaidMapMarker?>().firstWhere(
      (item) =>
          item != null &&
          item.layer == layer &&
          (item.payloadId == poi.id || _normalize(item.label) == normalized),
      orElse: () => null,
    );
    return layerMarker?.point;
  }

  ArcAdminMapMarkerKind _kindForPoi(ArcPoiData poi) {
    final text = _normalize('${poi.id} ${poi.name} ${poi.notes ?? ''}');
    if (text.contains('weapon cache') || text.contains('weapon_cache')) {
      return ArcAdminMapMarkerKind.weaponCache;
    }
    if (text.contains('weapon case') || text.contains('weapon crate')) {
      return ArcAdminMapMarkerKind.weaponCase;
    }
    if (text.contains('security room') || text.contains('security bridge')) {
      return ArcAdminMapMarkerKind.securityRoom;
    }
    if (text.contains('locked room')) return ArcAdminMapMarkerKind.lockedRoom;
    if (text.contains(' key ') || text.endsWith(' key')) {
      return ArcAdminMapMarkerKind.keyRequiredLocation;
    }
    if (poi.lootLevel == ArcLootLevel.high) {
      return ArcAdminMapMarkerKind.highValueLoot;
    }
    return ArcAdminMapMarkerKind.poi;
  }

  ArcAdminMapMarkerKind _kindForCommunityCategory(
    ArcCommunityIntelCategory category,
  ) {
    switch (category) {
      case ArcCommunityIntelCategory.blueprintFound:
        return ArcAdminMapMarkerKind.blueprint;
      case ArcCommunityIntelCategory.lockedRoom:
        return ArcAdminMapMarkerKind.lockedRoom;
      case ArcCommunityIntelCategory.lootContainer:
        return ArcAdminMapMarkerKind.lootContainer;
      case ArcCommunityIntelCategory.highValueLoot:
        return ArcAdminMapMarkerKind.highValueLoot;
      case ArcCommunityIntelCategory.arcThreat:
        return ArcAdminMapMarkerKind.arcThreat;
      case ArcCommunityIntelCategory.extractionDanger:
      case ArcCommunityIntelCategory.extractionActivity:
        return ArcAdminMapMarkerKind.extractionDanger;
      case ArcCommunityIntelCategory.raiderActivity:
      case ArcCommunityIntelCategory.clearedArea:
        return ArcAdminMapMarkerKind.customIntel;
    }
  }

  ArcWorldIntelEvidenceType _evidenceTypeForPoi(ArcPoiData poi) {
    final notes = poi.notes?.toLowerCase() ?? '';
    if (notes.contains('player-reported')) {
      return ArcWorldIntelEvidenceType.mikeAdminReport;
    }
    if (notes.contains('community guide')) {
      return ArcWorldIntelEvidenceType.writtenGuide;
    }
    return ArcWorldIntelEvidenceType.officialSeedMarker;
  }

  ArcRaidIntelConfidence _confidenceForPoi({
    required ArcRaidMap map,
    required ArcRaidMapLayer layer,
    required ArcPoiData poi,
    required ArcAdminMapMarkerKind kind,
    required ArcWorldIntelEvidenceType evidenceType,
  }) {
    if (map.hasCalibratedLayer(layer) && kind.isSeedDefinition) {
      return ArcRaidIntelConfidence.confirmed;
    }
    if (evidenceType == ArcWorldIntelEvidenceType.mikeAdminReport) {
      return ArcRaidIntelConfidence.strong;
    }
    if (poi.lootLevel == ArcLootLevel.high ||
        kind == ArcAdminMapMarkerKind.poi) {
      return ArcRaidIntelConfidence.strong;
    }
    if (evidenceType == ArcWorldIntelEvidenceType.writtenGuide) {
      return ArcRaidIntelConfidence.moderate;
    }
    return ArcRaidIntelConfidence.moderate;
  }

  ArcRaidMapLayer _layerForPoi(ArcRaidMap map, ArcPoiData poi) {
    return _layerForText(map, '${poi.id} ${poi.name} ${poi.notes ?? ''}');
  }

  ArcRaidMapLayer _layerForText(ArcRaidMap map, String value) {
    if (!map.availableLayers.contains(ArcRaidMapLayer.underground)) {
      return ArcRaidMapLayer.surface;
    }
    final text = _normalize(value);
    if (text.contains('level 2') ||
        text.contains('underground') ||
        text.contains('tunnel') ||
        text.contains('metro') ||
        text.contains('airshaft')) {
      return ArcRaidMapLayer.underground;
    }
    return ArcRaidMapLayer.surface;
  }

  String _descriptionForPoi({
    required ArcRaidMap map,
    required ArcRaidMapLayer layer,
    required ArcPoiData poi,
    required ArcAdminMapMarkerKind kind,
    required ArcWorldIntelEvidenceType evidenceType,
  }) {
    final precision = map.hasCalibratedLayer(layer)
        ? 'calibrated UAG map layer'
        : 'provisional UAG alignment';
    final source = evidenceType == ArcWorldIntelEvidenceType.writtenGuide
        ? 'curated public research lead rewritten as UAG Intel'
        : evidenceType == ArcWorldIntelEvidenceType.mikeAdminReport
        ? 'Mike/admin Intel'
        : 'UAG map and POI catalogue';
    final area = poi.resolvedAreaName == poi.name
        ? poi.name
        : '${poi.name} in ${poi.resolvedAreaName}';
    return 'UAG-generated ${kind.label.toLowerCase()} marker for $area on ${map.displayName}. Source basis: $source. Coordinate status: $precision.';
  }

  String _sourceAttributionForPoi(ArcPoiData poi) {
    final notes = poi.notes?.toLowerCase() ?? '';
    if (notes.contains('community guide')) {
      return 'UAG curated research lead; source URL not present in repository.';
    }
    if (notes.contains('player-reported')) {
      return 'Mike / UAG first-party Intel.';
    }
    return 'UAG first-party map and POI catalogue.';
  }

  bool _duplicates(ArcAdminMapMarker a, ArcAdminMapMarker b) {
    if (a.mapId != b.mapId || a.layer != b.layer || a.kind != b.kind) {
      return false;
    }
    if (a.sourceRecordId != null &&
        b.sourceRecordId != null &&
        a.sourceRecordId == b.sourceRecordId) {
      return true;
    }
    if (a.blueprintId != null &&
        b.blueprintId != null &&
        a.blueprintId == b.blueprintId &&
        a.point.distanceTo(b.point) <= 0.055) {
      return true;
    }
    if (_normalize(a.name) == _normalize(b.name) &&
        a.point.distanceTo(b.point) <= 0.04) {
      return true;
    }
    return a.duplicateGroupId != null &&
        a.duplicateGroupId == b.duplicateGroupId;
  }

  String _mergeDescription(
    ArcAdminMapMarker a,
    ArcAdminMapMarker b,
    int evidenceCount,
  ) {
    final base = a.description.trim().length >= b.description.trim().length
        ? a.description.trim()
        : b.description.trim();
    final prefix = base.isEmpty ? '${a.name} UAG marker.' : base;
    return '$prefix Evidence merged from $evidenceCount source record(s).';
  }

  int _confidenceScore(ArcAdminMapMarker marker) {
    var score = marker.confidence.score;
    final sourceIds = marker.evidence.map((item) => item.sourceId).toSet();
    score += math.min(sourceIds.length, 4) * 8;
    score += math.min(marker.resolvedEvidenceCount, 6) * 4;
    if (marker.adminVerified) score += 18;
    if (marker.kind.isSeedDefinition) score += 12;
    if (marker.evidence.any((record) => record.isUagOwned)) score += 8;
    final confirmations = marker.evidence.fold<int>(
      0,
      (total, record) => total + record.confirmationCount,
    );
    final disputes = marker.evidence.fold<int>(
      0,
      (total, record) => total + record.disputeCount,
    );
    score += math.min(confirmations, 6) * 3;
    score -= disputes * 14;
    final alignment = marker.alignmentConfidence ?? 0;
    if (alignment >= 0.82) {
      score += 10;
    } else if (alignment < 0.45) {
      score -= 16;
    }
    if (marker.exceptionReason?.trim().isNotEmpty == true) score -= 24;
    return score.clamp(0, 100).toInt();
  }

  static ArcRaidIntelConfidence _confidenceFromScore(int score) {
    if (score >= 92) return ArcRaidIntelConfidence.confirmed;
    if (score >= 72) return ArcRaidIntelConfidence.strong;
    if (score >= 50) return ArcRaidIntelConfidence.moderate;
    if (score >= 24) return ArcRaidIntelConfidence.limited;
    return ArcRaidIntelConfidence.unverified;
  }

  double _alignmentConfidence(ArcRaidMap map, ArcRaidMapLayer layer) {
    final calibration = map.calibrationForLayer(layer);
    if (calibration == null) return 0.48;
    if (calibration.valid && calibration.published) {
      return (1 - calibration.residualError).clamp(0.72, 0.98).toDouble();
    }
    return 0.56;
  }

  Map<String, double> _alignmentConfidenceByLayer(List<ArcRaidMap> maps) {
    return <String, double>{
      for (final map in maps)
        for (final layer in map.availableLayers)
          '${map.id}:${layer.name}': _alignmentConfidence(map, layer),
    };
  }

  Map<String, double> _residualErrorByLayer(List<ArcRaidMap> maps) {
    return <String, double>{
      for (final map in maps)
        for (final layer in map.availableLayers)
          '${map.id}:${layer.name}':
              map.calibrationForLayer(layer)?.residualError ?? 1,
    };
  }

  Map<String, int> _controlPointCountByLayer(List<ArcRaidMap> maps) {
    return <String, int>{
      for (final map in maps)
        for (final layer in map.availableLayers)
          '${map.id}:${layer.name}':
              map.calibrationForLayer(layer)?.anchors.length ?? 0,
    };
  }

  String _duplicateKey({
    required String mapId,
    required ArcRaidMapLayer layer,
    required ArcAdminMapMarkerKind kind,
    required String name,
    required ArcNormalizedPoint point,
    required String? blueprintId,
  }) {
    return [
      mapId,
      layer.name,
      kind.name,
      blueprintId?.trim().toLowerCase() ?? _slug(name),
      (point.x * 100).round(),
      (point.y * 100).round(),
    ].join(':');
  }

  static String _normalizeMapName(String value) {
    final normalized = _normalize(value).replaceAll('the ', '');
    return normalized.replaceAll(' ', '_');
  }

  static bool _containsAny(String value, List<String> needles) {
    final normalized = _normalize(value);
    return needles.any((needle) => normalized.contains(_normalize(needle)));
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String _slug(String value) {
    final slug = _normalize(value).replaceAll(' ', '_');
    return slug.isEmpty ? 'item' : slug;
  }
}

class _ReportPointResolution {
  const _ReportPointResolution({required this.point, required this.layer});

  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
}

class _MergeResult {
  const _MergeResult({required this.markers, required this.duplicateGroups});

  final List<ArcAdminMapMarker> markers;
  final List<ArcWorldIntelDuplicateGroup> duplicateGroups;
}
