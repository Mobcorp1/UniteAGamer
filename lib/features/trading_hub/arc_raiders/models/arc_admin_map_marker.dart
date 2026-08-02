import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';

enum ArcAdminMapMarkerKind {
  poi,
  extraction,
  raiderHatch,
  blueprint,
  questLocation,
  mapEvent,
  resourceNode,
  naturalResource,
  arcSpawn,
  weaponCase,
  weaponCache,
  firstWaveCache,
  raiderCache,
  fieldCrate,
  lootContainer,
  containerCluster,
  lockedRoom,
  securityRoom,
  highValueLoot,
  arcThreat,
  extractionDanger,
  surfaceTransition,
  undergroundTransition,
  hazard,
  key,
  keyRequiredLocation,
  customIntel,
}

extension ArcAdminMapMarkerKindX on ArcAdminMapMarkerKind {
  String get label {
    switch (this) {
      case ArcAdminMapMarkerKind.poi:
        return 'POI';
      case ArcAdminMapMarkerKind.extraction:
        return 'Extraction';
      case ArcAdminMapMarkerKind.raiderHatch:
        return 'Raider Hatch';
      case ArcAdminMapMarkerKind.blueprint:
        return 'Blueprint Find';
      case ArcAdminMapMarkerKind.questLocation:
        return 'Quest Location';
      case ArcAdminMapMarkerKind.mapEvent:
        return 'Map Event';
      case ArcAdminMapMarkerKind.resourceNode:
        return 'Resource Node';
      case ArcAdminMapMarkerKind.naturalResource:
        return 'Natural Resource';
      case ArcAdminMapMarkerKind.arcSpawn:
        return 'ARC Spawn';
      case ArcAdminMapMarkerKind.weaponCase:
        return 'Weapon Case';
      case ArcAdminMapMarkerKind.weaponCache:
        return 'Weapon Cache';
      case ArcAdminMapMarkerKind.firstWaveCache:
        return 'First Wave Cache';
      case ArcAdminMapMarkerKind.raiderCache:
        return 'Raider Cache';
      case ArcAdminMapMarkerKind.fieldCrate:
        return 'Field Crate';
      case ArcAdminMapMarkerKind.lootContainer:
        return 'Loot Container';
      case ArcAdminMapMarkerKind.containerCluster:
        return 'Container Cluster';
      case ArcAdminMapMarkerKind.lockedRoom:
        return 'Locked Room';
      case ArcAdminMapMarkerKind.securityRoom:
        return 'Security Room';
      case ArcAdminMapMarkerKind.highValueLoot:
        return 'High-Value Loot';
      case ArcAdminMapMarkerKind.arcThreat:
        return 'ARC Threat';
      case ArcAdminMapMarkerKind.extractionDanger:
        return 'Extraction Danger';
      case ArcAdminMapMarkerKind.surfaceTransition:
        return 'Surface Transition';
      case ArcAdminMapMarkerKind.undergroundTransition:
        return 'Underground Transition';
      case ArcAdminMapMarkerKind.hazard:
        return 'Hazard';
      case ArcAdminMapMarkerKind.key:
        return 'Key';
      case ArcAdminMapMarkerKind.keyRequiredLocation:
        return 'Key-Required Location';
      case ArcAdminMapMarkerKind.customIntel:
        return 'Custom Intel';
    }
  }

  bool get isSeedDefinition =>
      this == ArcAdminMapMarkerKind.poi ||
      this == ArcAdminMapMarkerKind.extraction ||
      this == ArcAdminMapMarkerKind.raiderHatch;
}

enum ArcAdminMapMarkerState { draft, published, archived }

enum ArcAdminMapMarkerSourcePermission {
  permitted,
  restricted,
  unknown,
  prohibited,
}

extension ArcAdminMapMarkerSourcePermissionX
    on ArcAdminMapMarkerSourcePermission {
  String get label {
    switch (this) {
      case ArcAdminMapMarkerSourcePermission.permitted:
        return 'Permitted';
      case ArcAdminMapMarkerSourcePermission.restricted:
        return 'Restricted';
      case ArcAdminMapMarkerSourcePermission.unknown:
        return 'Unknown';
      case ArcAdminMapMarkerSourcePermission.prohibited:
        return 'Prohibited';
    }
  }

  bool get canCache => this == ArcAdminMapMarkerSourcePermission.permitted;

  bool get canPublish => this == ArcAdminMapMarkerSourcePermission.permitted;

  static ArcAdminMapMarkerSourcePermission fromStorage(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
    return switch (normalized) {
      'permitted' ||
      'approved' ||
      'authorized' ||
      'authorised' ||
      'open_license' ||
      'uag_internal' => ArcAdminMapMarkerSourcePermission.permitted,
      'restricted' || 'limited' => ArcAdminMapMarkerSourcePermission.restricted,
      'prohibited' ||
      'blocked' ||
      'denied' => ArcAdminMapMarkerSourcePermission.prohibited,
      _ => ArcAdminMapMarkerSourcePermission.unknown,
    };
  }
}

@immutable
class ArcAdminMapMarker {
  const ArcAdminMapMarker({
    required this.id,
    required this.mapId,
    required this.layer,
    required this.kind,
    required this.name,
    required this.point,
    this.aliases = const <String>[],
    this.description = '',
    this.blueprintId,
    this.sourceLabel = 'Admin Intel',
    this.confidence = ArcRaidIntelConfidence.confirmed,
    this.state = ArcAdminMapMarkerState.draft,
    this.adminVerified = true,
    this.seedReferenceId,
    this.sourceName,
    this.sourceRecordId,
    this.sourceAttribution,
    this.sourceUrl,
    this.sourcePermission = ArcAdminMapMarkerSourcePermission.permitted,
    this.sourceLayerId,
    this.originalPoint,
    this.coordinateSpace,
    this.importBatchId,
    this.alignmentConfidence,
    this.alignmentResidual,
    this.duplicateGroupId,
    this.evidenceCount = 1,
    this.evidence = const <ArcWorldIntelEvidenceRecord>[],
    this.provisionalVisible = false,
    this.exceptionReason,
    this.createdByUid,
    this.updatedByUid,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String mapId;
  final ArcRaidMapLayer layer;
  final ArcAdminMapMarkerKind kind;
  final String name;
  final List<String> aliases;
  final String description;
  final ArcNormalizedPoint point;
  final String? blueprintId;
  final String sourceLabel;
  final ArcRaidIntelConfidence confidence;
  final ArcAdminMapMarkerState state;
  final bool adminVerified;
  final String? seedReferenceId;
  final String? sourceName;
  final String? sourceRecordId;
  final String? sourceAttribution;
  final String? sourceUrl;
  final ArcAdminMapMarkerSourcePermission sourcePermission;
  final String? sourceLayerId;
  final ArcNormalizedPoint? originalPoint;
  final String? coordinateSpace;
  final String? importBatchId;
  final double? alignmentConfidence;
  final double? alignmentResidual;
  final String? duplicateGroupId;
  final int evidenceCount;
  final List<ArcWorldIntelEvidenceRecord> evidence;
  final bool provisionalVisible;
  final String? exceptionReason;
  final String? createdByUid;
  final String? updatedByUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => state == ArcAdminMapMarkerState.published;

  bool get isLive =>
      isPublished ||
      (provisionalVisible &&
          sourcePermission == ArcAdminMapMarkerSourcePermission.permitted &&
          state != ArcAdminMapMarkerState.archived);

  bool get hasImportException => exceptionReason?.trim().isNotEmpty == true;

  int get resolvedEvidenceCount =>
      evidence.isEmpty ? evidenceCount : evidence.length;

  ArcAdminMapMarker copyWith({
    String? id,
    String? mapId,
    ArcRaidMapLayer? layer,
    ArcAdminMapMarkerKind? kind,
    String? name,
    List<String>? aliases,
    String? description,
    ArcNormalizedPoint? point,
    String? blueprintId,
    bool clearBlueprintId = false,
    String? sourceLabel,
    ArcRaidIntelConfidence? confidence,
    ArcAdminMapMarkerState? state,
    bool? adminVerified,
    String? seedReferenceId,
    String? sourceName,
    bool clearSourceName = false,
    String? sourceRecordId,
    bool clearSourceRecordId = false,
    String? sourceAttribution,
    bool clearSourceAttribution = false,
    String? sourceUrl,
    bool clearSourceUrl = false,
    ArcAdminMapMarkerSourcePermission? sourcePermission,
    String? sourceLayerId,
    bool clearSourceLayerId = false,
    ArcNormalizedPoint? originalPoint,
    bool clearOriginalPoint = false,
    String? coordinateSpace,
    bool clearCoordinateSpace = false,
    String? importBatchId,
    bool clearImportBatchId = false,
    double? alignmentConfidence,
    bool clearAlignmentConfidence = false,
    double? alignmentResidual,
    bool clearAlignmentResidual = false,
    String? duplicateGroupId,
    bool clearDuplicateGroupId = false,
    int? evidenceCount,
    List<ArcWorldIntelEvidenceRecord>? evidence,
    bool? provisionalVisible,
    String? exceptionReason,
    bool clearExceptionReason = false,
    String? createdByUid,
    String? updatedByUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArcAdminMapMarker(
      id: id ?? this.id,
      mapId: mapId ?? this.mapId,
      layer: layer ?? this.layer,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      description: description ?? this.description,
      point: point ?? this.point,
      blueprintId: clearBlueprintId ? null : (blueprintId ?? this.blueprintId),
      sourceLabel: sourceLabel ?? this.sourceLabel,
      confidence: confidence ?? this.confidence,
      state: state ?? this.state,
      adminVerified: adminVerified ?? this.adminVerified,
      seedReferenceId: seedReferenceId ?? this.seedReferenceId,
      sourceName: clearSourceName ? null : (sourceName ?? this.sourceName),
      sourceRecordId: clearSourceRecordId
          ? null
          : (sourceRecordId ?? this.sourceRecordId),
      sourceAttribution: clearSourceAttribution
          ? null
          : (sourceAttribution ?? this.sourceAttribution),
      sourceUrl: clearSourceUrl ? null : (sourceUrl ?? this.sourceUrl),
      sourcePermission: sourcePermission ?? this.sourcePermission,
      sourceLayerId: clearSourceLayerId
          ? null
          : (sourceLayerId ?? this.sourceLayerId),
      originalPoint: clearOriginalPoint
          ? null
          : (originalPoint ?? this.originalPoint),
      coordinateSpace: clearCoordinateSpace
          ? null
          : (coordinateSpace ?? this.coordinateSpace),
      importBatchId: clearImportBatchId
          ? null
          : (importBatchId ?? this.importBatchId),
      alignmentConfidence: clearAlignmentConfidence
          ? null
          : (alignmentConfidence ?? this.alignmentConfidence),
      alignmentResidual: clearAlignmentResidual
          ? null
          : (alignmentResidual ?? this.alignmentResidual),
      duplicateGroupId: clearDuplicateGroupId
          ? null
          : (duplicateGroupId ?? this.duplicateGroupId),
      evidenceCount: evidenceCount ?? this.evidenceCount,
      evidence: evidence ?? this.evidence,
      provisionalVisible: provisionalVisible ?? this.provisionalVisible,
      exceptionReason: clearExceptionReason
          ? null
          : (exceptionReason ?? this.exceptionReason),
      createdByUid: createdByUid ?? this.createdByUid,
      updatedByUid: updatedByUid ?? this.updatedByUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'mapId': mapId,
      'layer': layer.name,
      'kind': kind.name,
      'name': name,
      'aliases': aliases,
      'description': description,
      'point': point.toMap(),
      'blueprintId': blueprintId,
      'sourceLabel': sourceLabel,
      'confidence': confidence.name,
      'state': state.name,
      'adminVerified': adminVerified,
      'seedReferenceId': seedReferenceId,
      'sourceName': sourceName,
      'sourceRecordId': sourceRecordId,
      'sourceAttribution': sourceAttribution,
      'sourceUrl': sourceUrl,
      'sourcePermission': sourcePermission.name,
      'sourceLayerId': sourceLayerId,
      'originalPoint': originalPoint?.toMap(),
      'coordinateSpace': coordinateSpace,
      'importBatchId': importBatchId,
      'alignmentConfidence': alignmentConfidence,
      'alignmentResidual': alignmentResidual,
      'duplicateGroupId': duplicateGroupId,
      'evidenceCount': resolvedEvidenceCount,
      'evidence': evidence.map((item) => item.toMap()).toList(growable: false),
      'provisionalVisible': provisionalVisible,
      'exceptionReason': exceptionReason,
      'createdByUid': createdByUid,
      'updatedByUid': updatedByUid,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  Map<String, dynamic> toJsonMap() {
    final map = toMap();
    map['createdAt'] = createdAt?.toIso8601String();
    map['updatedAt'] = updatedAt?.toIso8601String();
    map['evidence'] = evidence
        .map((item) => item.toJsonMap())
        .toList(growable: false);
    return map;
  }

  factory ArcAdminMapMarker.fromMap(Map<String, dynamic> map) {
    final rawMapId = map['mapId']?.toString();
    final rawLayer = map['layer']?.toString();
    final canonicalMapId =
        ArcMapAssetRegistry.canonicalMapIdFor(rawMapId) ?? '';
    final canonicalLayer = ArcMapAssetRegistry.resolveLayer(rawLayer);
    return ArcAdminMapMarker(
      id: map['id']?.toString() ?? '',
      mapId: canonicalMapId,
      layer: ArcRaidMapLayer.values.firstWhere(
        (value) => value.name == rawLayer,
        orElse: () => canonicalLayer,
      ),
      kind: ArcAdminMapMarkerKind.values.firstWhere(
        (value) => value.name == map['kind'],
        orElse: () => ArcAdminMapMarkerKind.customIntel,
      ),
      name: map['name']?.toString() ?? 'Unnamed marker',
      aliases: _stringListFrom(map['aliases']),
      description: map['description']?.toString() ?? '',
      point: ArcNormalizedPoint.fromMap(
        map['point'] is Map
            ? Map<String, dynamic>.from(map['point'] as Map)
            : null,
      ),
      blueprintId: map['blueprintId']?.toString(),
      sourceLabel: map['sourceLabel']?.toString() ?? 'Admin Intel',
      confidence: ArcRaidIntelConfidence.values.firstWhere(
        (value) => value.name == map['confidence'],
        orElse: () => ArcRaidIntelConfidence.confirmed,
      ),
      state: ArcAdminMapMarkerState.values.firstWhere(
        (value) => value.name == map['state'],
        orElse: () => ArcAdminMapMarkerState.draft,
      ),
      adminVerified: map['adminVerified'] != false,
      seedReferenceId: map['seedReferenceId']?.toString(),
      sourceName: map['sourceName']?.toString(),
      sourceRecordId: map['sourceRecordId']?.toString(),
      sourceAttribution: map['sourceAttribution']?.toString(),
      sourceUrl: map['sourceUrl']?.toString(),
      sourcePermission: ArcAdminMapMarkerSourcePermissionX.fromStorage(
        map['sourcePermission']?.toString(),
      ),
      sourceLayerId: map['sourceLayerId']?.toString(),
      originalPoint: map['originalPoint'] is Map
          ? _pointFromMapUnclamped(
              Map<String, dynamic>.from(map['originalPoint'] as Map),
            )
          : null,
      coordinateSpace: map['coordinateSpace']?.toString(),
      importBatchId: map['importBatchId']?.toString(),
      alignmentConfidence: _doubleFrom(map['alignmentConfidence']),
      alignmentResidual: _doubleFrom(map['alignmentResidual']),
      duplicateGroupId: map['duplicateGroupId']?.toString(),
      evidenceCount: _intFrom(map['evidenceCount'], fallback: 1),
      evidence: _evidenceFrom(map['evidence']),
      provisionalVisible: map['provisionalVisible'] == true,
      exceptionReason: map['exceptionReason']?.toString(),
      createdByUid: map['createdByUid']?.toString(),
      updatedByUid: map['updatedByUid']?.toString(),
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _intFrom(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<ArcWorldIntelEvidenceRecord> _evidenceFrom(dynamic value) {
    if (value is! List) return const <ArcWorldIntelEvidenceRecord>[];
    return value
        .whereType<Map>()
        .map(
          (item) => ArcWorldIntelEvidenceRecord.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  static List<String> _stringListFrom(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static ArcNormalizedPoint _pointFromMapUnclamped(Map<String, dynamic> map) {
    return ArcNormalizedPoint(
      x: _doubleFrom(map['x']) ?? 0.5,
      y: _doubleFrom(map['y']) ?? 0.5,
    );
  }
}
