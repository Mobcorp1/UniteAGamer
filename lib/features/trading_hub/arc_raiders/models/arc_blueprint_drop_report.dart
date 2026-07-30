import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

@immutable
class ArcBlueprintDropReport {
  const ArcBlueprintDropReport({
    required this.id,
    required this.blueprintId,
    required this.userId,
    required this.mapName,
    required this.sourceType,
    required this.mode,
    required this.raidType,
    required this.entryTime,
    required this.timeOfDay,
    required this.createdAt,
    required this.confirmationCount,
    required this.confirmedByUserIds,
    this.poiId,
    this.markerId,
    this.poiName,
    this.historicalPoint,
    this.enemySourceId,
    this.enemySourceName,
    this.containerTypeId,
    this.containerTypeLabel,
    this.weatherConditionId,
    this.weatherConditionLabel,
    this.mapEventId,
    this.mapEventLabel,
    this.acquisitionSource = ArcBlueprintAcquisitionSource.lootDrop,
    this.giftRelationship = ArcGiftedBlueprintRelationship.unknown,
    this.originalFindMapName,
    this.originalFindLayer,
    this.originalFindPoiId,
    this.originalFindPoiName,
    this.handoverMapName,
    this.handoverLayer,
    this.handoverPoiId,
    this.handoverPoiName,
    this.recipientWitnessedOriginalPickup = false,
    this.originalFinderUid,
    this.originalFinderEmbarkId,
    this.acquisitionEvidence = '',
    this.acquisitionConfidence = ArcBlueprintReportConfidence.standard,
    this.withdrawn = false,
    this.disputed = false,
    this.foundAt,
    this.localTimeLabel,
    this.timezoneOffsetMinutes,
    this.lastConfirmedAt,
    this.notes = '',
    this.signature = '',
  });

  final String id;
  final String blueprintId;
  final String userId;
  final String mapName;
  final ArcDropSourceType sourceType;
  final String? poiId;
  final String? markerId;
  final String? poiName;
  final ArcNormalizedPoint? historicalPoint;
  final String? enemySourceId;
  final String? enemySourceName;
  final String? containerTypeId;
  final String? containerTypeLabel;
  final String? weatherConditionId;
  final String? weatherConditionLabel;
  final String? mapEventId;
  final String? mapEventLabel;
  final ArcBlueprintAcquisitionSource acquisitionSource;
  final ArcGiftedBlueprintRelationship giftRelationship;
  final String? originalFindMapName;
  final ArcRaidMapLayer? originalFindLayer;
  final String? originalFindPoiId;
  final String? originalFindPoiName;
  final String? handoverMapName;
  final ArcRaidMapLayer? handoverLayer;
  final String? handoverPoiId;
  final String? handoverPoiName;
  final bool recipientWitnessedOriginalPickup;
  final String? originalFinderUid;
  final String? originalFinderEmbarkId;
  final String acquisitionEvidence;
  final ArcBlueprintReportConfidence acquisitionConfidence;
  final bool withdrawn;
  final bool disputed;
  final ArcRaidMode mode;
  final ArcRaidType raidType;
  final ArcEntryTime entryTime;
  final ArcTimeOfDay timeOfDay;
  final DateTime? foundAt;
  final String? localTimeLabel;
  final int? timezoneOffsetMinutes;
  final DateTime? lastConfirmedAt;
  final String notes;
  final DateTime? createdAt;
  final int confirmationCount;
  final List<String> confirmedByUserIds;
  final String signature;

  static String buildSignature({
    required String blueprintId,
    required String mapName,
    required ArcDropSourceType sourceType,
    required ArcRaidMode mode,
    required ArcRaidType raidType,
    required ArcEntryTime entryTime,
    required ArcTimeOfDay timeOfDay,
    ArcBlueprintAcquisitionSource acquisitionSource =
        ArcBlueprintAcquisitionSource.lootDrop,
    String? poiId,
    String? enemySourceId,
    String? containerTypeId,
    String? weatherConditionId,
    String? mapEventId,
    ArcGiftedBlueprintRelationship giftRelationship =
        ArcGiftedBlueprintRelationship.unknown,
    String? originalFindMapName,
    String? originalFindPoiId,
    String? handoverMapName,
    String? handoverPoiId,
  }) {
    String normalize(String? value, {String fallback = 'none'}) {
      final trimmed = value?.trim().toLowerCase();
      return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
    }

    return [
      normalize(blueprintId),
      normalize(mapName),
      sourceType.name.toLowerCase(),
      normalize(poiId),
      normalize(enemySourceId),
      normalize(containerTypeId),
      normalize(weatherConditionId),
      normalize(mapEventId),
      mode.name.toLowerCase(),
      raidType.name.toLowerCase(),
      entryTime.name.toLowerCase(),
      timeOfDay.name.toLowerCase(),
      acquisitionSource.name.toLowerCase(),
      giftRelationship.name.toLowerCase(),
      normalize(originalFindMapName),
      normalize(originalFindPoiId),
      normalize(handoverMapName),
      normalize(handoverPoiId),
    ].join('|');
  }

  String get areaLabel {
    switch (sourceType) {
      case ArcDropSourceType.poi:
        return poiName?.trim().isNotEmpty == true
            ? poiName!.trim()
            : 'Unknown POI';
      case ArcDropSourceType.enemy:
        return enemySourceName?.trim().isNotEmpty == true
            ? enemySourceName!.trim()
            : 'Unknown Enemy';
      case ArcDropSourceType.other:
        return poiName?.trim().isNotEmpty == true
            ? poiName!.trim()
            : enemySourceName?.trim().isNotEmpty == true
            ? enemySourceName!.trim()
            : 'Other Source';
    }
  }

  String get locationName => areaLabel;

  String get resolvedContainerLabel {
    final label = containerTypeLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return ArcContainerTypes.byId(containerTypeId).label;
  }

  String get weatherLabel {
    final label = weatherConditionLabel?.trim();
    return (label != null && label.isNotEmpty) ? label : 'No Special Weather';
  }

  String get eventLabel {
    final label = mapEventLabel?.trim();
    return (label != null && label.isNotEmpty) ? label : 'No Map Event';
  }

  String? get conditionId {
    final weatherId = weatherConditionId?.trim();
    if (weatherId != null && weatherId.isNotEmpty) return weatherId;

    final eventId = mapEventId?.trim();
    if (eventId != null && eventId.isNotEmpty) return eventId;

    return null;
  }

  String? get conditionLabel {
    final weather = weatherConditionLabel?.trim();
    if (weather != null && weather.isNotEmpty) return weather;

    final event = mapEventLabel?.trim();
    if (event != null && event.isNotEmpty) return event;

    return null;
  }

  bool get isGiftedOrIndirect => acquisitionSource.isGiftedOrIndirect;

  bool get hasOriginalFindLocation {
    final map = originalFindMapName?.trim();
    final poi = originalFindPoiId?.trim() ?? originalFindPoiName?.trim();
    return map != null && map.isNotEmpty && poi != null && poi.isNotEmpty;
  }

  bool get countsForMapIntelligence =>
      !withdrawn &&
      !disputed &&
      (!isGiftedOrIndirect ||
          recipientWitnessedOriginalPickup ||
          hasOriginalFindLocation);

  String get intelligenceMapName =>
      hasOriginalFindLocation ? originalFindMapName!.trim() : mapName;

  String? get intelligencePoiId =>
      hasOriginalFindLocation ? originalFindPoiId?.trim() : poiId;

  String? get intelligencePoiName =>
      hasOriginalFindLocation ? originalFindPoiName?.trim() : poiName;

  ArcRaidMapLayer get intelligenceLayer => hasOriginalFindLocation
      ? (originalFindLayer ?? ArcRaidMapLayer.surface)
      : ArcRaidMapLayer.surface;

  String get areaKey {
    final sourceKey = switch (sourceType) {
      ArcDropSourceType.poi => poiId ?? poiName ?? 'poi_unknown',
      ArcDropSourceType.enemy =>
        enemySourceId ?? enemySourceName ?? 'enemy_unknown',
      ArcDropSourceType.other => poiId ?? enemySourceId ?? 'other_unknown',
    };

    return '$mapName|${sourceType.name}|$sourceKey';
  }

  ArcBlueprintDropReport copyWith({
    String? id,
    String? blueprintId,
    String? userId,
    String? mapName,
    ArcDropSourceType? sourceType,
    String? poiId,
    String? markerId,
    String? poiName,
    ArcNormalizedPoint? historicalPoint,
    String? enemySourceId,
    String? enemySourceName,
    String? containerTypeId,
    String? containerTypeLabel,
    String? weatherConditionId,
    String? weatherConditionLabel,
    String? mapEventId,
    String? mapEventLabel,
    ArcBlueprintAcquisitionSource? acquisitionSource,
    ArcGiftedBlueprintRelationship? giftRelationship,
    String? originalFindMapName,
    ArcRaidMapLayer? originalFindLayer,
    String? originalFindPoiId,
    String? originalFindPoiName,
    String? handoverMapName,
    ArcRaidMapLayer? handoverLayer,
    String? handoverPoiId,
    String? handoverPoiName,
    bool? recipientWitnessedOriginalPickup,
    String? originalFinderUid,
    String? originalFinderEmbarkId,
    String? acquisitionEvidence,
    ArcBlueprintReportConfidence? acquisitionConfidence,
    bool? withdrawn,
    bool? disputed,
    ArcRaidMode? mode,
    ArcRaidType? raidType,
    ArcEntryTime? entryTime,
    ArcTimeOfDay? timeOfDay,
    DateTime? foundAt,
    String? localTimeLabel,
    int? timezoneOffsetMinutes,
    DateTime? lastConfirmedAt,
    String? notes,
    DateTime? createdAt,
    int? confirmationCount,
    List<String>? confirmedByUserIds,
    String? signature,
  }) {
    return ArcBlueprintDropReport(
      id: id ?? this.id,
      blueprintId: blueprintId ?? this.blueprintId,
      userId: userId ?? this.userId,
      mapName: mapName ?? this.mapName,
      sourceType: sourceType ?? this.sourceType,
      poiId: poiId ?? this.poiId,
      markerId: markerId ?? this.markerId,
      poiName: poiName ?? this.poiName,
      historicalPoint: historicalPoint ?? this.historicalPoint,
      enemySourceId: enemySourceId ?? this.enemySourceId,
      enemySourceName: enemySourceName ?? this.enemySourceName,
      containerTypeId: containerTypeId ?? this.containerTypeId,
      containerTypeLabel: containerTypeLabel ?? this.containerTypeLabel,
      weatherConditionId: weatherConditionId ?? this.weatherConditionId,
      weatherConditionLabel:
          weatherConditionLabel ?? this.weatherConditionLabel,
      mapEventId: mapEventId ?? this.mapEventId,
      mapEventLabel: mapEventLabel ?? this.mapEventLabel,
      acquisitionSource: acquisitionSource ?? this.acquisitionSource,
      giftRelationship: giftRelationship ?? this.giftRelationship,
      originalFindMapName: originalFindMapName ?? this.originalFindMapName,
      originalFindLayer: originalFindLayer ?? this.originalFindLayer,
      originalFindPoiId: originalFindPoiId ?? this.originalFindPoiId,
      originalFindPoiName: originalFindPoiName ?? this.originalFindPoiName,
      handoverMapName: handoverMapName ?? this.handoverMapName,
      handoverLayer: handoverLayer ?? this.handoverLayer,
      handoverPoiId: handoverPoiId ?? this.handoverPoiId,
      handoverPoiName: handoverPoiName ?? this.handoverPoiName,
      recipientWitnessedOriginalPickup:
          recipientWitnessedOriginalPickup ??
          this.recipientWitnessedOriginalPickup,
      originalFinderUid: originalFinderUid ?? this.originalFinderUid,
      originalFinderEmbarkId:
          originalFinderEmbarkId ?? this.originalFinderEmbarkId,
      acquisitionEvidence: acquisitionEvidence ?? this.acquisitionEvidence,
      acquisitionConfidence:
          acquisitionConfidence ?? this.acquisitionConfidence,
      withdrawn: withdrawn ?? this.withdrawn,
      disputed: disputed ?? this.disputed,
      mode: mode ?? this.mode,
      raidType: raidType ?? this.raidType,
      entryTime: entryTime ?? this.entryTime,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      foundAt: foundAt ?? this.foundAt,
      localTimeLabel: localTimeLabel ?? this.localTimeLabel,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      confirmationCount: confirmationCount ?? this.confirmationCount,
      confirmedByUserIds: confirmedByUserIds ?? this.confirmedByUserIds,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blueprintId': blueprintId,
      'userId': userId,
      'mapName': mapName,
      'sourceType': sourceType.name,
      'poiId': poiId,
      'markerId': markerId,
      'poiName': poiName,
      'historicalPoint': historicalPoint?.toMap(),
      'enemySourceId': enemySourceId,
      'enemySourceName': enemySourceName,
      'containerTypeId': containerTypeId,
      'containerTypeLabel': containerTypeLabel,
      'weatherConditionId': weatherConditionId,
      'weatherConditionLabel': weatherConditionLabel,
      'mapEventId': mapEventId,
      'mapEventLabel': mapEventLabel,
      'conditionId': conditionId,
      'conditionLabel': conditionLabel,
      'locationName': areaLabel,
      'acquisitionSource': acquisitionSource.name,
      'acquisitionSourceLabel': acquisitionSource.label,
      'giftRelationship': giftRelationship.name,
      'giftRelationshipLabel': giftRelationship.label,
      'originalFindMapName': originalFindMapName,
      'originalFindLayer': originalFindLayer?.storageValue,
      'originalFindPoiId': originalFindPoiId,
      'originalFindPoiName': originalFindPoiName,
      'handoverMapName': handoverMapName,
      'handoverLayer': handoverLayer?.storageValue,
      'handoverPoiId': handoverPoiId,
      'handoverPoiName': handoverPoiName,
      'recipientWitnessedOriginalPickup': recipientWitnessedOriginalPickup,
      'originalFinderUid': originalFinderUid,
      'originalFinderEmbarkId': originalFinderEmbarkId,
      'acquisitionEvidence': acquisitionEvidence,
      'acquisitionConfidence': acquisitionConfidence.name,
      'withdrawn': withdrawn,
      'disputed': disputed,
      'mode': mode.name,
      'raidType': raidType.name,
      'entryTime': entryTime.name,
      'timeOfDay': timeOfDay.name,
      'foundAt': foundAt == null ? null : Timestamp.fromDate(foundAt!),
      'localTimeLabel': localTimeLabel,
      'timezoneOffsetMinutes': timezoneOffsetMinutes,
      'lastConfirmedAt': lastConfirmedAt == null
          ? null
          : Timestamp.fromDate(lastConfirmedAt!),
      'notes': notes,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'confirmationCount': confirmationCount,
      'confirmedByUserIds': confirmedByUserIds,
      'signature': signature,
    };
  }

  factory ArcBlueprintDropReport.fromMap(Map<String, dynamic> map) {
    final sourceType =
        _enumByName(ArcDropSourceType.values, map['sourceType'] as String?) ??
        ArcDropSourceType.poi;

    final locationFields = _locationFieldsFrom(map);
    final legacyLocation = locationFields.namedLocation;
    final poiName = locationFields.poiName;
    final poiId = _firstTrimmedString(map, const <String>[
      'poiId',
      'canonicalPoiId',
      'poiID',
    ]);
    final markerId = _firstTrimmedString(map, const <String>[
      'markerId',
      'mapMarkerId',
      'publishedMarkerId',
      'canonicalMarkerId',
      'adminMarkerId',
    ]);
    final enemySourceName = (map['enemySourceName'] as String?)?.trim();
    final weatherConditionId = (map['weatherConditionId'] as String?)?.trim();
    final weatherConditionLabel = (map['weatherConditionLabel'] as String?)
        ?.trim();
    final mapEventId = (map['mapEventId'] as String?)?.trim();
    final mapEventLabel = (map['mapEventLabel'] as String?)?.trim();
    final legacyConditionId = (map['conditionId'] as String?)?.trim();
    final legacyConditionLabel = (map['conditionLabel'] as String?)?.trim();

    final confirmedBy = ((map['confirmedByUserIds'] as List?) ?? const [])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final mapName = _canonicalMapName(
      _firstTrimmedString(map, const <String>[
            'mapName',
            'map',
            'mapId',
            'mapID',
            'mapLabel',
            'mapDisplayName',
          ]) ??
          'Unknown Map',
    );
    final rawPoiName = sourceType == ArcDropSourceType.poi
        ? (poiName ?? legacyLocation)
        : poiName;
    final canonicalPoiName = ArcPoiDataStore.canonicalPoiNameForMap(
      mapName,
      rawPoiName,
    );

    final report = ArcBlueprintDropReport(
      id: (map['id'] as String?) ?? '',
      blueprintId: (map['blueprintId'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      mapName: mapName,
      sourceType: sourceType,
      poiId: poiId,
      markerId: markerId,
      poiName:
          canonicalPoiName ??
          poiName ??
          (sourceType == ArcDropSourceType.poi ? legacyLocation : null),
      historicalPoint: _historicalPointFrom(map),
      enemySourceId: (map['enemySourceId'] as String?)?.trim(),
      enemySourceName:
          enemySourceName ??
          (sourceType == ArcDropSourceType.enemy ? legacyLocation : null),
      containerTypeId: (map['containerTypeId'] as String?)?.trim(),
      containerTypeLabel: (map['containerTypeLabel'] as String?)?.trim(),
      weatherConditionId: weatherConditionId,
      weatherConditionLabel: weatherConditionLabel,
      mapEventId:
          mapEventId ??
          ((weatherConditionId == null || weatherConditionId.isEmpty)
              ? legacyConditionId
              : null),
      mapEventLabel:
          mapEventLabel ??
          ((weatherConditionLabel == null || weatherConditionLabel.isEmpty)
              ? legacyConditionLabel
              : null),
      acquisitionSource:
          ArcBlueprintAcquisitionSourceX.fromStorage(
            map['acquisitionSource'] as String?,
          ) ??
          ArcBlueprintAcquisitionSource.lootDrop,
      giftRelationship:
          ArcGiftedBlueprintRelationshipX.fromStorage(
            map['giftRelationship'] as String?,
          ) ??
          ArcGiftedBlueprintRelationship.unknown,
      originalFindMapName: (map['originalFindMapName'] as String?)?.trim(),
      originalFindLayer: _layerFromStorage(map['originalFindLayer'] as String?),
      originalFindPoiId: (map['originalFindPoiId'] as String?)?.trim(),
      originalFindPoiName: (map['originalFindPoiName'] as String?)?.trim(),
      handoverMapName: (map['handoverMapName'] as String?)?.trim(),
      handoverLayer: _layerFromStorage(map['handoverLayer'] as String?),
      handoverPoiId: (map['handoverPoiId'] as String?)?.trim(),
      handoverPoiName: (map['handoverPoiName'] as String?)?.trim(),
      recipientWitnessedOriginalPickup:
          map['recipientWitnessedOriginalPickup'] == true,
      originalFinderUid: (map['originalFinderUid'] as String?)?.trim(),
      originalFinderEmbarkId: (map['originalFinderEmbarkId'] as String?)
          ?.trim(),
      acquisitionEvidence:
          (map['acquisitionEvidence'] as String?)?.trim() ?? '',
      acquisitionConfidence:
          ArcBlueprintReportConfidenceX.fromStorage(
            map['acquisitionConfidence'] as String?,
          ) ??
          ArcBlueprintReportConfidence.standard,
      withdrawn: map['withdrawn'] == true,
      disputed: map['disputed'] == true,
      mode:
          _enumByName(ArcRaidMode.values, map['mode'] as String?) ??
          ArcRaidMode.dayRaid,
      raidType:
          ArcRaidTypeX.fromStorage(map['raidType'] as String?) ??
          ArcRaidType.fullRaid,
      entryTime:
          _enumByName(ArcEntryTime.values, map['entryTime'] as String?) ??
          ArcEntryTime.unknown,
      timeOfDay:
          _enumByName(ArcTimeOfDay.values, map['timeOfDay'] as String?) ??
          ArcTimeOfDay.unknown,
      foundAt: (map['foundAt'] as Timestamp?)?.toDate(),
      localTimeLabel: (map['localTimeLabel'] as String?)?.trim(),
      timezoneOffsetMinutes: (map['timezoneOffsetMinutes'] as num?)?.toInt(),
      lastConfirmedAt: (map['lastConfirmedAt'] as Timestamp?)?.toDate(),
      notes: (map['notes'] as String?)?.trim() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      confirmationCount: (map['confirmationCount'] as num?)?.toInt() ?? 1,
      confirmedByUserIds: confirmedBy,
      signature: (map['signature'] as String?)?.trim() ?? '',
    );

    if (report.signature.isNotEmpty) return report;

    return report.copyWith(
      signature: ArcBlueprintDropReport.buildSignature(
        blueprintId: report.blueprintId,
        mapName: report.mapName,
        sourceType: report.sourceType,
        poiId: report.poiId,
        enemySourceId: report.enemySourceId,
        containerTypeId: report.containerTypeId,
        weatherConditionId: report.weatherConditionId,
        mapEventId: report.mapEventId,
        mode: report.mode,
        raidType: report.raidType,
        entryTime: report.entryTime,
        timeOfDay: report.timeOfDay,
        acquisitionSource: report.acquisitionSource,
        giftRelationship: report.giftRelationship,
        originalFindMapName: report.originalFindMapName,
        originalFindPoiId: report.originalFindPoiId,
        handoverMapName: report.handoverMapName,
        handoverPoiId: report.handoverPoiId,
      ),
    );
  }

  static _ReportLocationFields _locationFieldsFrom(Map<String, dynamic> map) {
    final poiName = _firstTrimmedString(map, const <String>[
      'poiName',
      'poi_name',
    ]);
    final namedLocation = _firstTrimmedString(map, const <String>[
      'locationName',
      'locationLabel',
      'reportedLocation',
      'dropLocation',
      'sourceLocation',
      'landmark',
    ]);
    final nestedPoiName = _nestedLabelFrom(map['poi']);
    final nestedMarkerName = _nestedLabelFrom(map['marker']);
    final areaFallback = _firstTrimmedString(map, const <String>[
      'areaName',
      'area',
      'zone',
    ]);

    return _ReportLocationFields(
      poiName: poiName ?? nestedPoiName,
      namedLocation: namedLocation ?? nestedMarkerName ?? areaFallback,
    );
  }

  static String? _firstTrimmedString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _trimmedString(map[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String? _nestedLabelFrom(dynamic value) {
    if (value is String) return _trimmedString(value);
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    return _firstTrimmedString(data, const <String>[
      'name',
      'label',
      'poiName',
      'locationName',
    ]);
  }

  static String? _trimmedString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _canonicalMapName(String rawName) {
    final normalized = rawName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    return switch (normalized) {
      'buried city' => ArcPoiDataStore.buriedCity,
      'dam battlegrounds' || 'dam' => ArcPoiDataStore.damBattlegrounds,
      'stella montis' => ArcPoiDataStore.stellaMontis,
      'blue gate' || 'the blue gate' => 'Blue Gate',
      'spaceport' => ArcPoiDataStore.spaceport,
      'riven tides' => ArcPoiDataStore.rivenTides,
      _ => rawName.trim(),
    };
  }

  static ArcNormalizedPoint? _historicalPointFrom(Map<String, dynamic> map) {
    final nestedPoint =
        _pointFromDynamic(map['historicalPoint']) ??
        _pointFromDynamic(map['normalizedPoint']) ??
        _pointFromDynamic(map['coordinates']) ??
        _pointFromDynamic(map['coordinate']) ??
        _pointFromDynamic(map['position']) ??
        _pointFromDynamic(map['point']);
    if (nestedPoint != null) return nestedPoint;

    final x =
        _doubleFrom(map['normalizedX']) ??
        _doubleFrom(map['x']) ??
        _doubleFrom(map['dx']);
    final y =
        _doubleFrom(map['normalizedY']) ??
        _doubleFrom(map['y']) ??
        _doubleFrom(map['dy']);
    return _normalizedPointOrNull(x, y);
  }

  static ArcNormalizedPoint? _pointFromDynamic(dynamic value) {
    if (value is Map) {
      final data = Map<String, dynamic>.from(value);
      final x =
          _doubleFrom(data['normalizedX']) ??
          _doubleFrom(data['x']) ??
          _doubleFrom(data['dx']);
      final y =
          _doubleFrom(data['normalizedY']) ??
          _doubleFrom(data['y']) ??
          _doubleFrom(data['dy']);
      return _normalizedPointOrNull(x, y);
    }
    if (value is List && value.length >= 2) {
      return _normalizedPointOrNull(
        _doubleFrom(value[0]),
        _doubleFrom(value[1]),
      );
    }
    return null;
  }

  static ArcNormalizedPoint? _normalizedPointOrNull(double? x, double? y) {
    if (x == null || y == null) return null;
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    return ArcNormalizedPoint(x: x, y: y);
  }

  static double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static ArcRaidMapLayer? _layerFromStorage(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;
    final normalized = rawName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    for (final layer in ArcRaidMapLayer.values) {
      final storageValue = layer.storageValue.toLowerCase().replaceAll(
        RegExp(r'[\s_-]+'),
        '',
      );
      if (layer.name.toLowerCase() == normalized ||
          storageValue == normalized) {
        return layer;
      }
    }
    if (normalized == 'level2') return ArcRaidMapLayer.underground;
    return null;
  }

  static T? _enumByName<T>(List<T> values, String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;

    final normalized = rawName.trim().toLowerCase();

    for (final value in values) {
      if (value is Enum && value.name.toLowerCase() == normalized) {
        return value;
      }
    }

    return null;
  }
}

class _ReportLocationFields {
  const _ReportLocationFields({this.poiName, this.namedLocation});

  final String? poiName;
  final String? namedLocation;
}

enum ArcRaidMode { dayRaid, nightRaid }

enum ArcRaidType { fullRaid, midRaid, lateRaid }

enum ArcEntryTime { early, mid, late, unknown }

enum ArcTimeOfDay {
  earlyMorning,
  midMorning,
  midday,
  midAfternoon,
  night,
  lateNight,
  unknown,
}

enum ArcBlueprintAcquisitionSource {
  lootDrop,
  questReward,
  trade,
  gifted,
  giftedBySquadmate,
  giftedByAnotherRaider,
  tradedDuringRaid,
  recoveredFromAnotherRaider,
  unknown,
  trialReward,
}

enum ArcGiftedBlueprintRelationship { squadmate, otherRaider, unknown }

enum ArcBlueprintReportConfidence { low, standard, high, verified }

extension ArcRaidModeX on ArcRaidMode {
  String get label {
    switch (this) {
      case ArcRaidMode.dayRaid:
        return 'Day Raid';
      case ArcRaidMode.nightRaid:
        return 'Night Raid';
    }
  }
}

extension ArcRaidTypeX on ArcRaidType {
  String get label {
    switch (this) {
      case ArcRaidType.fullRaid:
        return 'Full';
      case ArcRaidType.midRaid:
        return 'Mid';
      case ArcRaidType.lateRaid:
        return 'Late';
    }
  }

  static ArcRaidType? fromStorage(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;
    final normalized = rawName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );

    switch (normalized) {
      case 'full':
      case 'fullraid':
      case 'early':
      case 'earlyraid':
        return ArcRaidType.fullRaid;
      case 'mid':
      case 'midraid':
        return ArcRaidType.midRaid;
      case 'late':
      case 'lateraid':
        return ArcRaidType.lateRaid;
    }

    return null;
  }
}

extension ArcEntryTimeX on ArcEntryTime {
  String get label {
    switch (this) {
      case ArcEntryTime.early:
        return 'Early Entry';
      case ArcEntryTime.mid:
        return 'Mid Entry';
      case ArcEntryTime.late:
        return 'Late Entry';
      case ArcEntryTime.unknown:
        return 'Unknown Entry';
    }
  }
}

extension ArcTimeOfDayX on ArcTimeOfDay {
  String get label {
    switch (this) {
      case ArcTimeOfDay.earlyMorning:
        return 'Early Morning';
      case ArcTimeOfDay.midMorning:
        return 'Mid-Morning';
      case ArcTimeOfDay.midday:
        return 'Midday';
      case ArcTimeOfDay.midAfternoon:
        return 'Mid-Afternoon';
      case ArcTimeOfDay.night:
        return 'Night';
      case ArcTimeOfDay.lateNight:
        return 'Late Night';
      case ArcTimeOfDay.unknown:
        return 'Unknown';
    }
  }
}

extension ArcBlueprintAcquisitionSourceX on ArcBlueprintAcquisitionSource {
  String get label {
    switch (this) {
      case ArcBlueprintAcquisitionSource.lootDrop:
        return 'Found Personally';
      case ArcBlueprintAcquisitionSource.questReward:
        return 'Quest Reward';
      case ArcBlueprintAcquisitionSource.trade:
        return 'Trade';
      case ArcBlueprintAcquisitionSource.gifted:
        return 'Gifted';
      case ArcBlueprintAcquisitionSource.giftedBySquadmate:
        return 'Gifted by Squadmate';
      case ArcBlueprintAcquisitionSource.giftedByAnotherRaider:
        return 'Gifted by Another Raider';
      case ArcBlueprintAcquisitionSource.tradedDuringRaid:
        return 'Traded During Raid';
      case ArcBlueprintAcquisitionSource.recoveredFromAnotherRaider:
        return 'Recovered from Another Raider';
      case ArcBlueprintAcquisitionSource.unknown:
        return 'Unknown / Not Sure';
      case ArcBlueprintAcquisitionSource.trialReward:
        return 'Trial';
    }
  }

  bool get isGiftedOrIndirect {
    switch (this) {
      case ArcBlueprintAcquisitionSource.gifted:
      case ArcBlueprintAcquisitionSource.trade:
      case ArcBlueprintAcquisitionSource.giftedBySquadmate:
      case ArcBlueprintAcquisitionSource.giftedByAnotherRaider:
      case ArcBlueprintAcquisitionSource.tradedDuringRaid:
      case ArcBlueprintAcquisitionSource.recoveredFromAnotherRaider:
      case ArcBlueprintAcquisitionSource.unknown:
        return true;
      case ArcBlueprintAcquisitionSource.lootDrop:
      case ArcBlueprintAcquisitionSource.questReward:
      case ArcBlueprintAcquisitionSource.trialReward:
        return false;
    }
  }

  static ArcBlueprintAcquisitionSource? fromStorage(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;
    final normalized = rawName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );

    switch (normalized) {
      case 'lootdrop':
      case 'normaldrop':
      case 'foundpersonally':
      case 'found':
      case 'drop':
        return ArcBlueprintAcquisitionSource.lootDrop;
      case 'questreward':
      case 'quest':
        return ArcBlueprintAcquisitionSource.questReward;
      case 'trade':
        return ArcBlueprintAcquisitionSource.trade;
      case 'gifted':
      case 'gift':
        return ArcBlueprintAcquisitionSource.gifted;
      case 'giftedbysquadmate':
      case 'squadmate':
      case 'squadmategift':
        return ArcBlueprintAcquisitionSource.giftedBySquadmate;
      case 'giftedbyanotherraider':
      case 'otherraider':
      case 'anotherraider':
        return ArcBlueprintAcquisitionSource.giftedByAnotherRaider;
      case 'tradedduringraid':
      case 'raidtrade':
      case 'traded':
        return ArcBlueprintAcquisitionSource.tradedDuringRaid;
      case 'recoveredfromanotherraider':
      case 'recovered':
      case 'pickedupfromraider':
        return ArcBlueprintAcquisitionSource.recoveredFromAnotherRaider;
      case 'unknown':
      case 'notsure':
      case 'unsure':
        return ArcBlueprintAcquisitionSource.unknown;
      case 'trialreward':
      case 'trial':
        return ArcBlueprintAcquisitionSource.trialReward;
    }

    return null;
  }
}

extension ArcGiftedBlueprintRelationshipX on ArcGiftedBlueprintRelationship {
  String get label {
    switch (this) {
      case ArcGiftedBlueprintRelationship.squadmate:
        return 'Squadmate';
      case ArcGiftedBlueprintRelationship.otherRaider:
        return 'Other Raider';
      case ArcGiftedBlueprintRelationship.unknown:
        return 'Unknown';
    }
  }

  static ArcGiftedBlueprintRelationship? fromStorage(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;
    final normalized = rawName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    switch (normalized) {
      case 'squadmate':
      case 'squad':
      case 'friend':
        return ArcGiftedBlueprintRelationship.squadmate;
      case 'otherraider':
      case 'anotherraider':
      case 'raider':
        return ArcGiftedBlueprintRelationship.otherRaider;
      case 'unknown':
      case 'unsure':
      case 'notsure':
        return ArcGiftedBlueprintRelationship.unknown;
    }
    return null;
  }
}

extension ArcBlueprintReportConfidenceX on ArcBlueprintReportConfidence {
  String get label {
    switch (this) {
      case ArcBlueprintReportConfidence.low:
        return 'Low';
      case ArcBlueprintReportConfidence.standard:
        return 'Standard';
      case ArcBlueprintReportConfidence.high:
        return 'High';
      case ArcBlueprintReportConfidence.verified:
        return 'Verified';
    }
  }

  static ArcBlueprintReportConfidence? fromStorage(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;
    final normalized = rawName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    switch (normalized) {
      case 'low':
      case 'limited':
        return ArcBlueprintReportConfidence.low;
      case 'standard':
      case 'normal':
        return ArcBlueprintReportConfidence.standard;
      case 'high':
      case 'strong':
        return ArcBlueprintReportConfidence.high;
      case 'verified':
      case 'confirmed':
        return ArcBlueprintReportConfidence.verified;
    }
    return null;
  }
}
