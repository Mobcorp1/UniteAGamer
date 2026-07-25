import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcCommunityIntelCategory {
  blueprintFound,
  lockedRoom,
  lootContainer,
  highValueLoot,
  arcThreat,
  raiderActivity,
  extractionActivity,
  extractionDanger,
  clearedArea,
}

extension ArcCommunityIntelCategoryX on ArcCommunityIntelCategory {
  String get label {
    switch (this) {
      case ArcCommunityIntelCategory.blueprintFound:
        return 'Blueprint Found';
      case ArcCommunityIntelCategory.lockedRoom:
        return 'Locked Room';
      case ArcCommunityIntelCategory.lootContainer:
        return 'Loot Container';
      case ArcCommunityIntelCategory.highValueLoot:
        return 'High-Value Loot';
      case ArcCommunityIntelCategory.arcThreat:
        return 'ARC Threat';
      case ArcCommunityIntelCategory.raiderActivity:
        return 'Raider Activity';
      case ArcCommunityIntelCategory.extractionActivity:
        return 'Active Extraction';
      case ArcCommunityIntelCategory.extractionDanger:
        return 'Extraction Danger';
      case ArcCommunityIntelCategory.clearedArea:
        return 'Cleared / Empty Area';
    }
  }

  String get shortLabel {
    switch (this) {
      case ArcCommunityIntelCategory.blueprintFound:
        return 'Blueprint';
      case ArcCommunityIntelCategory.lockedRoom:
        return 'Locked Room';
      case ArcCommunityIntelCategory.lootContainer:
        return 'Container';
      case ArcCommunityIntelCategory.highValueLoot:
        return 'High Value';
      case ArcCommunityIntelCategory.arcThreat:
        return 'ARC';
      case ArcCommunityIntelCategory.raiderActivity:
        return 'Raiders';
      case ArcCommunityIntelCategory.extractionActivity:
        return 'Extraction';
      case ArcCommunityIntelCategory.extractionDanger:
        return 'Danger';
      case ArcCommunityIntelCategory.clearedArea:
        return 'Cleared';
    }
  }

  String get markerTag => name;
}

@immutable
class ArcCommunityIntelReport {
  const ArcCommunityIntelReport({
    required this.id,
    required this.reporterUid,
    required this.mapId,
    required this.layer,
    required this.category,
    required this.point,
    required this.createdAt,
    required this.updatedAt,
    required this.confirmationCount,
    required this.confirmedByUserIds,
    required this.signature,
    this.poiId,
    this.poiName,
    this.blueprintId,
    this.blueprintName,
    this.notes = '',
    this.lastConfirmedAt,
    this.active = true,
  });

  final String id;
  final String reporterUid;
  final String mapId;
  final ArcRaidMapLayer layer;
  final ArcCommunityIntelCategory category;
  final ArcNormalizedPoint point;
  final String? poiId;
  final String? poiName;
  final String? blueprintId;
  final String? blueprintName;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConfirmedAt;
  final int confirmationCount;
  final List<String> confirmedByUserIds;
  final String signature;
  final bool active;

  String get displayLabel {
    final blueprint = blueprintName?.trim();
    if (category == ArcCommunityIntelCategory.blueprintFound &&
        blueprint != null &&
        blueprint.isNotEmpty) {
      return '$blueprint found';
    }
    final poi = poiName?.trim();
    if (poi != null && poi.isNotEmpty) {
      return '${category.label} at $poi';
    }
    return category.label;
  }

  ArcRaidIntelConfidence get confidence {
    if (confirmationCount >= 5) return ArcRaidIntelConfidence.confirmed;
    if (confirmationCount >= 3) return ArcRaidIntelConfidence.strong;
    if (confirmationCount >= 2) return ArcRaidIntelConfidence.moderate;
    return ArcRaidIntelConfidence.limited;
  }

  bool get isStale {
    final reference = lastConfirmedAt ?? updatedAt;
    return DateTime.now().difference(reference).inHours >= 72;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'reporterUid': reporterUid,
      'mapId': mapId,
      'layer': layer.storageValue,
      'category': category.name,
      'point': <String, double>{'x': point.x, 'y': point.y},
      'poiId': poiId,
      'poiName': poiName,
      'blueprintId': blueprintId,
      'blueprintName': blueprintName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastConfirmedAt': lastConfirmedAt == null
          ? null
          : Timestamp.fromDate(lastConfirmedAt!),
      'confirmationCount': confirmationCount,
      'confirmedByUserIds': confirmedByUserIds,
      'signature': signature,
      'active': active,
    };
  }

  factory ArcCommunityIntelReport.fromMap(Map<String, dynamic> map) {
    final rawPoint = map['point'];
    final pointMap = rawPoint is Map
        ? rawPoint.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final layerName = map['layer']?.toString();
    final categoryName = map['category']?.toString();

    return ArcCommunityIntelReport(
      id: map['id']?.toString() ?? '',
      reporterUid: map['reporterUid']?.toString() ?? '',
      mapId: map['mapId']?.toString() ?? '',
      layer: ArcRaidMapLayer.values.firstWhere(
        (value) => value.storageValue == layerName,
        orElse: () => ArcRaidMapLayer.surface,
      ),
      category: ArcCommunityIntelCategory.values.firstWhere(
        (value) => value.name == categoryName,
        orElse: () => ArcCommunityIntelCategory.highValueLoot,
      ),
      point: ArcNormalizedPoint(
        x: (pointMap['x'] as num?)?.toDouble() ?? 0.5,
        y: (pointMap['y'] as num?)?.toDouble() ?? 0.5,
      ).clamp(),
      poiId: map['poiId']?.toString(),
      poiName: map['poiName']?.toString(),
      blueprintId: map['blueprintId']?.toString(),
      blueprintName: map['blueprintName']?.toString(),
      notes: map['notes']?.toString() ?? '',
      createdAt: _dateFrom(map['createdAt']) ?? DateTime.now(),
      updatedAt:
          _dateFrom(map['updatedAt']) ??
          _dateFrom(map['createdAt']) ??
          DateTime.now(),
      lastConfirmedAt: _dateFrom(map['lastConfirmedAt']),
      confirmationCount: (map['confirmationCount'] as num?)?.toInt() ?? 1,
      confirmedByUserIds:
          (map['confirmedByUserIds'] as Iterable?)
              ?.map((value) => value.toString())
              .toList(growable: false) ??
          const <String>[],
      signature: map['signature']?.toString() ?? '',
      active: map['active'] is bool ? map['active'] as bool : true,
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String buildSignature({
    required String mapId,
    required ArcRaidMapLayer layer,
    required ArcCommunityIntelCategory category,
    required ArcNormalizedPoint point,
    String? blueprintId,
  }) {
    const bucketScale = 50;
    final xBucket = (point.x.clamp(0.0, 1.0) * bucketScale).round();
    final yBucket = (point.y.clamp(0.0, 1.0) * bucketScale).round();
    final blueprint = blueprintId?.trim().toLowerCase() ?? 'none';
    return [
      mapId.trim().toLowerCase(),
      layer.storageValue,
      category.name,
      xBucket,
      yBucket,
      blueprint,
    ].join('|');
  }
}
