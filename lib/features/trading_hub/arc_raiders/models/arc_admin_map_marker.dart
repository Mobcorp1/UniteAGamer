import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcAdminMapMarkerKind {
  poi,
  extraction,
  raiderHatch,
  blueprint,
  weaponCache,
  lootContainer,
  lockedRoom,
  highValueLoot,
  arcThreat,
  extractionDanger,
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
      case ArcAdminMapMarkerKind.weaponCache:
        return 'Weapon Cache';
      case ArcAdminMapMarkerKind.lootContainer:
        return 'Loot Container';
      case ArcAdminMapMarkerKind.lockedRoom:
        return 'Locked Room';
      case ArcAdminMapMarkerKind.highValueLoot:
        return 'High-Value Loot';
      case ArcAdminMapMarkerKind.arcThreat:
        return 'ARC Threat';
      case ArcAdminMapMarkerKind.extractionDanger:
        return 'Extraction Danger';
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

@immutable
class ArcAdminMapMarker {
  const ArcAdminMapMarker({
    required this.id,
    required this.mapId,
    required this.layer,
    required this.kind,
    required this.name,
    required this.point,
    this.description = '',
    this.blueprintId,
    this.sourceLabel = 'Admin Intel',
    this.confidence = ArcRaidIntelConfidence.confirmed,
    this.state = ArcAdminMapMarkerState.draft,
    this.adminVerified = true,
    this.seedReferenceId,
    this.createdByUid,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String mapId;
  final ArcRaidMapLayer layer;
  final ArcAdminMapMarkerKind kind;
  final String name;
  final String description;
  final ArcNormalizedPoint point;
  final String? blueprintId;
  final String sourceLabel;
  final ArcRaidIntelConfidence confidence;
  final ArcAdminMapMarkerState state;
  final bool adminVerified;
  final String? seedReferenceId;
  final String? createdByUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => state == ArcAdminMapMarkerState.published;

  ArcAdminMapMarker copyWith({
    String? id,
    String? mapId,
    ArcRaidMapLayer? layer,
    ArcAdminMapMarkerKind? kind,
    String? name,
    String? description,
    ArcNormalizedPoint? point,
    String? blueprintId,
    bool clearBlueprintId = false,
    String? sourceLabel,
    ArcRaidIntelConfidence? confidence,
    ArcAdminMapMarkerState? state,
    bool? adminVerified,
    String? seedReferenceId,
    String? createdByUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArcAdminMapMarker(
      id: id ?? this.id,
      mapId: mapId ?? this.mapId,
      layer: layer ?? this.layer,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      description: description ?? this.description,
      point: point ?? this.point,
      blueprintId: clearBlueprintId ? null : (blueprintId ?? this.blueprintId),
      sourceLabel: sourceLabel ?? this.sourceLabel,
      confidence: confidence ?? this.confidence,
      state: state ?? this.state,
      adminVerified: adminVerified ?? this.adminVerified,
      seedReferenceId: seedReferenceId ?? this.seedReferenceId,
      createdByUid: createdByUid ?? this.createdByUid,
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
      'description': description,
      'point': point.toMap(),
      'blueprintId': blueprintId,
      'sourceLabel': sourceLabel,
      'confidence': confidence.name,
      'state': state.name,
      'adminVerified': adminVerified,
      'seedReferenceId': seedReferenceId,
      'createdByUid': createdByUid,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  Map<String, dynamic> toJsonMap() {
    final map = toMap();
    map['createdAt'] = createdAt?.toIso8601String();
    map['updatedAt'] = updatedAt?.toIso8601String();
    return map;
  }

  factory ArcAdminMapMarker.fromMap(Map<String, dynamic> map) {
    return ArcAdminMapMarker(
      id: map['id']?.toString() ?? '',
      mapId: map['mapId']?.toString() ?? '',
      layer: ArcRaidMapLayer.values.firstWhere(
        (value) => value.name == map['layer'],
        orElse: () => ArcRaidMapLayer.surface,
      ),
      kind: ArcAdminMapMarkerKind.values.firstWhere(
        (value) => value.name == map['kind'],
        orElse: () => ArcAdminMapMarkerKind.customIntel,
      ),
      name: map['name']?.toString() ?? 'Unnamed marker',
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
      createdByUid: map['createdByUid']?.toString(),
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
}
