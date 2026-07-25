import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum ArcRaidMapPublicationState { draft, published, archived }

enum ArcRaidMapRenderMode { tacticalSchematic, calibratedGameMap }

enum ArcRaidMapLayer { surface, underground, transition }

enum ArcRaidMapMarkerCategory {
  blueprintOpportunity,
  topWanted,
  favouriteLoadoutRequirement,
  tradePreparationRequirement,
  operationObjective,
  questObjective,
  teammateObjective,
  spawn,
  spawnRegion,
  standardExtraction,
  raiderHatch,
  routeWaypoint,
  currentPosition,
  poi,
  region,
  weaponCase,
  securityLocker,
  firstWaveCache,
  raiderCache,
  fieldCrate,
  lockedRoom,
  keyRoom,
  containerCluster,
  generalLoot,
  communityIntel,
  researchedIntel,
  confirmedIntel,
  disputedIntel,
  staleIntel,
  mapEvent,
  arcThreat,
  surfaceTransition,
  undergroundTransition,
  configuredHazard,
}

enum ArcRaidIntelConfidence { unverified, limited, moderate, strong, confirmed }

enum ArcRaidRouteStyle { fast, balanced, thorough, safer }

enum ArcRaidSquadMode { solo, duo, trio }

enum ArcRaidObjectivePriority { myNeedsFirst, balancedSquad, helpTeammate }

enum ArcRaidObjectiveSharing {
  keepPrivate,
  broadGoals,
  selectedBlueprintGoals,
  allChosenRaidPlanObjectives,
}

enum ArcRaidRouteStopState { planned, searched, completed, skipped }

extension ArcRaidMapPublicationStateX on ArcRaidMapPublicationState {
  String get storageValue => name;

  static ArcRaidMapPublicationState fromStorage(String? value) {
    return ArcRaidMapPublicationState.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ArcRaidMapPublicationState.draft,
    );
  }
}

extension ArcRaidMapRenderModeX on ArcRaidMapRenderMode {
  String get label {
    switch (this) {
      case ArcRaidMapRenderMode.tacticalSchematic:
        return 'Tactical schematic';
      case ArcRaidMapRenderMode.calibratedGameMap:
        return 'Calibrated game map';
    }
  }

  String get storageValue => name;

  static ArcRaidMapRenderMode fromStorage(String? value) {
    return ArcRaidMapRenderMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ArcRaidMapRenderMode.tacticalSchematic,
    );
  }
}

extension ArcRaidMapLayerX on ArcRaidMapLayer {
  String get label {
    switch (this) {
      case ArcRaidMapLayer.surface:
        return 'Surface';
      case ArcRaidMapLayer.underground:
        return 'Level 2';
      case ArcRaidMapLayer.transition:
        return 'Transition';
    }
  }

  String get storageValue => name;
}

extension ArcRaidMapMarkerCategoryX on ArcRaidMapMarkerCategory {
  String get id => name;

  String get label {
    switch (this) {
      case ArcRaidMapMarkerCategory.blueprintOpportunity:
        return 'Blueprint Opportunity';
      case ArcRaidMapMarkerCategory.topWanted:
        return 'Top 5 Wanted';
      case ArcRaidMapMarkerCategory.favouriteLoadoutRequirement:
        return 'Favourite Loadout Requirement';
      case ArcRaidMapMarkerCategory.tradePreparationRequirement:
        return 'Trade Preparation Requirement';
      case ArcRaidMapMarkerCategory.operationObjective:
        return 'Operation Objective';
      case ArcRaidMapMarkerCategory.questObjective:
        return 'Quest Objective';
      case ArcRaidMapMarkerCategory.teammateObjective:
        return 'Teammate Objective';
      case ArcRaidMapMarkerCategory.spawn:
        return 'Spawn';
      case ArcRaidMapMarkerCategory.spawnRegion:
        return 'Spawn Region';
      case ArcRaidMapMarkerCategory.standardExtraction:
        return 'Standard Extraction';
      case ArcRaidMapMarkerCategory.raiderHatch:
        return 'Raider Hatch';
      case ArcRaidMapMarkerCategory.routeWaypoint:
        return 'Route Waypoint';
      case ArcRaidMapMarkerCategory.currentPosition:
        return 'Current Approximate Position';
      case ArcRaidMapMarkerCategory.poi:
        return 'POI';
      case ArcRaidMapMarkerCategory.region:
        return 'Region';
      case ArcRaidMapMarkerCategory.weaponCase:
        return 'Weapon Case';
      case ArcRaidMapMarkerCategory.securityLocker:
        return 'Security Locker';
      case ArcRaidMapMarkerCategory.firstWaveCache:
        return 'First Wave Cache';
      case ArcRaidMapMarkerCategory.raiderCache:
        return 'Raider Cache';
      case ArcRaidMapMarkerCategory.fieldCrate:
        return 'Field Crate';
      case ArcRaidMapMarkerCategory.lockedRoom:
        return 'Locked Room';
      case ArcRaidMapMarkerCategory.keyRoom:
        return 'Key Room';
      case ArcRaidMapMarkerCategory.containerCluster:
        return 'Container Cluster';
      case ArcRaidMapMarkerCategory.generalLoot:
        return 'General Loot';
      case ArcRaidMapMarkerCategory.communityIntel:
        return 'Community Intel';
      case ArcRaidMapMarkerCategory.researchedIntel:
        return 'Researched Intel';
      case ArcRaidMapMarkerCategory.confirmedIntel:
        return 'Confirmed Intel';
      case ArcRaidMapMarkerCategory.disputedIntel:
        return 'Disputed Intel';
      case ArcRaidMapMarkerCategory.staleIntel:
        return 'Stale Intel';
      case ArcRaidMapMarkerCategory.mapEvent:
        return 'Map Event';
      case ArcRaidMapMarkerCategory.arcThreat:
        return 'ARC Threat';
      case ArcRaidMapMarkerCategory.surfaceTransition:
        return 'Surface Transition';
      case ArcRaidMapMarkerCategory.undergroundTransition:
        return 'Underground Transition';
      case ArcRaidMapMarkerCategory.configuredHazard:
        return 'Configured Hazard';
    }
  }

  String get filteringGroup {
    switch (this) {
      case ArcRaidMapMarkerCategory.blueprintOpportunity:
      case ArcRaidMapMarkerCategory.topWanted:
      case ArcRaidMapMarkerCategory.favouriteLoadoutRequirement:
      case ArcRaidMapMarkerCategory.tradePreparationRequirement:
      case ArcRaidMapMarkerCategory.operationObjective:
      case ArcRaidMapMarkerCategory.questObjective:
      case ArcRaidMapMarkerCategory.teammateObjective:
        return 'My Objectives';
      case ArcRaidMapMarkerCategory.weaponCase:
      case ArcRaidMapMarkerCategory.securityLocker:
      case ArcRaidMapMarkerCategory.firstWaveCache:
      case ArcRaidMapMarkerCategory.raiderCache:
      case ArcRaidMapMarkerCategory.fieldCrate:
      case ArcRaidMapMarkerCategory.lockedRoom:
      case ArcRaidMapMarkerCategory.keyRoom:
      case ArcRaidMapMarkerCategory.containerCluster:
      case ArcRaidMapMarkerCategory.generalLoot:
        return 'Loot Sources';
      case ArcRaidMapMarkerCategory.communityIntel:
      case ArcRaidMapMarkerCategory.researchedIntel:
      case ArcRaidMapMarkerCategory.confirmedIntel:
      case ArcRaidMapMarkerCategory.disputedIntel:
      case ArcRaidMapMarkerCategory.staleIntel:
        return 'Intel Quality';
      default:
        return 'Map';
    }
  }

  bool get clustersByDefault {
    switch (this) {
      case ArcRaidMapMarkerCategory.blueprintOpportunity:
      case ArcRaidMapMarkerCategory.communityIntel:
      case ArcRaidMapMarkerCategory.researchedIntel:
      case ArcRaidMapMarkerCategory.confirmedIntel:
      case ArcRaidMapMarkerCategory.containerCluster:
        return true;
      default:
        return false;
    }
  }
}

extension ArcRaidIntelConfidenceX on ArcRaidIntelConfidence {
  String get label {
    switch (this) {
      case ArcRaidIntelConfidence.unverified:
        return 'Unverified';
      case ArcRaidIntelConfidence.limited:
        return 'Limited';
      case ArcRaidIntelConfidence.moderate:
        return 'Moderate';
      case ArcRaidIntelConfidence.strong:
        return 'Strong';
      case ArcRaidIntelConfidence.confirmed:
        return 'Confirmed';
    }
  }

  int get score {
    switch (this) {
      case ArcRaidIntelConfidence.unverified:
        return 12;
      case ArcRaidIntelConfidence.limited:
        return 32;
      case ArcRaidIntelConfidence.moderate:
        return 56;
      case ArcRaidIntelConfidence.strong:
        return 78;
      case ArcRaidIntelConfidence.confirmed:
        return 96;
    }
  }

  static ArcRaidIntelConfidence fromStorage(String? value) {
    return ArcRaidIntelConfidence.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ArcRaidIntelConfidence.unverified,
    );
  }
}

extension ArcRaidRouteStyleX on ArcRaidRouteStyle {
  String get label {
    switch (this) {
      case ArcRaidRouteStyle.fast:
        return 'Fast';
      case ArcRaidRouteStyle.balanced:
        return 'Balanced';
      case ArcRaidRouteStyle.thorough:
        return 'Thorough';
      case ArcRaidRouteStyle.safer:
        return 'Safer';
    }
  }

  int stopLimitForStage(String raidStage) {
    final stage = raidStage.trim().toLowerCase();
    final base = stage == 'late'
        ? 1
        : stage == 'mid'
        ? 2
        : 4;
    switch (this) {
      case ArcRaidRouteStyle.fast:
        return math.max(1, base - 1);
      case ArcRaidRouteStyle.balanced:
        return base;
      case ArcRaidRouteStyle.thorough:
        return math.min(5, base + 1);
      case ArcRaidRouteStyle.safer:
        return base;
    }
  }
}

extension ArcRaidSquadModeX on ArcRaidSquadMode {
  String get label {
    switch (this) {
      case ArcRaidSquadMode.solo:
        return 'Solo';
      case ArcRaidSquadMode.duo:
        return 'Duo';
      case ArcRaidSquadMode.trio:
        return 'Trio';
    }
  }

  int get size {
    switch (this) {
      case ArcRaidSquadMode.solo:
        return 1;
      case ArcRaidSquadMode.duo:
        return 2;
      case ArcRaidSquadMode.trio:
        return 3;
    }
  }
}

@immutable
class ArcNormalizedPoint {
  const ArcNormalizedPoint({required this.x, required this.y});

  final double x;
  final double y;

  ArcNormalizedPoint clamp() {
    return ArcNormalizedPoint(
      x: x.clamp(0.0, 1.0).toDouble(),
      y: y.clamp(0.0, 1.0).toDouble(),
    );
  }

  double distanceTo(ArcNormalizedPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  factory ArcNormalizedPoint.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return ArcNormalizedPoint(
      x: ((data['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      y: ((data['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
    );
  }
}

@immutable
class ArcRaidMapAsset {
  const ArcRaidMapAsset({
    required this.id,
    required this.mapId,
    required this.renderMode,
    this.layer = ArcRaidMapLayer.surface,
    this.localAssetPath,
    this.remoteUrl,
    this.width,
    this.height,
    this.published = false,
  });

  final String id;
  final String mapId;
  final ArcRaidMapRenderMode renderMode;
  final ArcRaidMapLayer layer;
  final String? localAssetPath;
  final String? remoteUrl;
  final int? width;
  final int? height;
  final bool published;

  bool get hasRenderableImage =>
      renderMode == ArcRaidMapRenderMode.calibratedGameMap &&
      ((localAssetPath?.trim().isNotEmpty ?? false) ||
          (remoteUrl?.trim().isNotEmpty ?? false));
}

@immutable
class ArcRaidMapAnchor {
  const ArcRaidMapAnchor({
    required this.id,
    required this.label,
    required this.canonicalPoint,
    required this.imagePoint,
    this.linkedPoiId,
  });

  final String id;
  final String label;
  final ArcNormalizedPoint canonicalPoint;
  final ArcNormalizedPoint imagePoint;
  final String? linkedPoiId;
}

@immutable
class ArcRaidMapCalibration {
  const ArcRaidMapCalibration({
    required this.id,
    required this.mapId,
    this.cropOrigin = const ArcNormalizedPoint(x: 0, y: 0),
    this.cropSize = const ArcNormalizedPoint(x: 1, y: 1),
    this.rotationDegrees = 0,
    this.anchors = const <ArcRaidMapAnchor>[],
    this.residualError = 0,
    this.published = false,
  });

  final String id;
  final String mapId;
  final ArcNormalizedPoint cropOrigin;
  final ArcNormalizedPoint cropSize;
  final double rotationDegrees;
  final List<ArcRaidMapAnchor> anchors;
  final double residualError;
  final bool published;

  bool get valid => anchors.length >= 3 && residualError <= 0.08;

  ArcNormalizedPoint canonicalToImage(ArcNormalizedPoint point) {
    final cropped = ArcNormalizedPoint(
      x: cropOrigin.x + (point.x * cropSize.x),
      y: cropOrigin.y + (point.y * cropSize.y),
    );
    if (rotationDegrees == 0) return cropped.clamp();
    final radians = rotationDegrees * math.pi / 180;
    final centeredX = cropped.x - 0.5;
    final centeredY = cropped.y - 0.5;
    return ArcNormalizedPoint(
      x:
          0.5 +
          (centeredX * math.cos(radians)) -
          (centeredY * math.sin(radians)),
      y:
          0.5 +
          (centeredX * math.sin(radians)) +
          (centeredY * math.cos(radians)),
    ).clamp();
  }

  ArcNormalizedPoint imageToCanonical(ArcNormalizedPoint point) {
    final uncropped = ArcNormalizedPoint(
      x: cropSize.x == 0 ? point.x : (point.x - cropOrigin.x) / cropSize.x,
      y: cropSize.y == 0 ? point.y : (point.y - cropOrigin.y) / cropSize.y,
    );
    return uncropped.clamp();
  }
}

@immutable
class ArcRaidMapRegion {
  const ArcRaidMapRegion({
    required this.id,
    required this.mapId,
    required this.name,
    required this.center,
    this.polygon = const <ArcNormalizedPoint>[],
    this.risk = 0,
    this.notes = '',
  });

  final String id;
  final String mapId;
  final String name;
  final ArcNormalizedPoint center;
  final List<ArcNormalizedPoint> polygon;
  final double risk;
  final String notes;
}

@immutable
class ArcRaidMapPoi {
  const ArcRaidMapPoi({
    required this.id,
    required this.mapId,
    required this.name,
    required this.point,
    this.regionId,
    this.approximate = true,
    this.lootTags = const <String>[],
  });

  final String id;
  final String mapId;
  final String name;
  final ArcNormalizedPoint point;
  final String? regionId;
  final bool approximate;
  final List<String> lootTags;
}

@immutable
class ArcRaidSpawnRegion {
  const ArcRaidSpawnRegion({
    required this.id,
    required this.mapId,
    required this.name,
    required this.center,
    this.radius = 0.08,
  });

  final String id;
  final String mapId;
  final String name;
  final ArcNormalizedPoint center;
  final double radius;
}

@immutable
class ArcRaidExtraction {
  const ArcRaidExtraction({
    required this.id,
    required this.mapId,
    required this.name,
    required this.point,
    this.visibleByDefault = true,
    this.notes = '',
  });

  final String id;
  final String mapId;
  final String name;
  final ArcNormalizedPoint point;
  final bool visibleByDefault;
  final String notes;
}

@immutable
class ArcRaiderHatch {
  const ArcRaiderHatch({
    required this.id,
    required this.mapId,
    required this.name,
    required this.point,
    this.requiresKey = true,
  });

  final String id;
  final String mapId;
  final String name;
  final ArcNormalizedPoint point;
  final bool requiresKey;
}

@immutable
class ArcRaidRouteNode {
  const ArcRaidRouteNode({
    required this.id,
    required this.mapId,
    required this.name,
    required this.point,
    this.layer = ArcRaidMapLayer.surface,
  });

  final String id;
  final String mapId;
  final String name;
  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
}

@immutable
class ArcRaidRouteEdge {
  const ArcRaidRouteEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.travelCost,
    this.riskCost = 0,
    this.layer = ArcRaidMapLayer.surface,
    this.oneWay = false,
    this.accessRequirement,
    this.conditionRequirement,
    this.geometry = const <ArcNormalizedPoint>[],
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final double travelCost;
  final double riskCost;
  final ArcRaidMapLayer layer;
  final bool oneWay;
  final String? accessRequirement;
  final String? conditionRequirement;
  final List<ArcNormalizedPoint> geometry;
}

@immutable
class ArcRaidMapMarkerDefinition {
  const ArcRaidMapMarkerDefinition({
    required this.category,
    required this.semanticDescription,
    required this.shape,
    this.disabledByDefault = false,
  });

  final ArcRaidMapMarkerCategory category;
  final String semanticDescription;
  final String shape;
  final bool disabledByDefault;
}

@immutable
class ArcRaidMapMarker {
  const ArcRaidMapMarker({
    required this.id,
    required this.mapId,
    required this.category,
    required this.label,
    required this.point,
    this.layer = ArcRaidMapLayer.surface,
    this.radius,
    this.payloadId,
    this.confidence = ArcRaidIntelConfidence.limited,
    this.approximate = true,
    this.enabled = true,
    this.count = 1,
  });

  final String id;
  final String mapId;
  final ArcRaidMapMarkerCategory category;
  final String label;
  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
  final double? radius;
  final String? payloadId;
  final ArcRaidIntelConfidence confidence;
  final bool approximate;
  final bool enabled;
  final int count;

  String get semanticLabel =>
      '${category.label}: $label${approximate ? ', approximate' : ''}';
}

@immutable
class ArcRaidMapCondition {
  const ArcRaidMapCondition({
    required this.id,
    required this.displayName,
    this.aliases = const <String>[],
    this.routeRiskModifier = 0,
    this.markerWeightModifiers = const <ArcRaidMapMarkerCategory, double>{},
  });

  final String id;
  final String displayName;
  final List<String> aliases;
  final double routeRiskModifier;
  final Map<ArcRaidMapMarkerCategory, double> markerWeightModifiers;
}

@immutable
class ArcRaidMapConditionWindow {
  const ArcRaidMapConditionWindow({
    required this.conditionId,
    required this.displayName,
    required this.mapId,
    required this.startsAtUtc,
    required this.endsAtUtc,
    this.officialReference,
  });

  final String conditionId;
  final String displayName;
  final String mapId;
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;
  final String? officialReference;

  bool isActiveAt(DateTime utcNow) =>
      !utcNow.isBefore(startsAtUtc) && utcNow.isBefore(endsAtUtc);

  bool isUpcomingAt(DateTime utcNow) => startsAtUtc.isAfter(utcNow);
}

@immutable
class ArcRaidMapFilterState {
  const ArcRaidMapFilterState({
    this.missingBlueprints = true,
    this.topWanted = true,
    this.favouriteLoadout = true,
    this.tradePreparation = true,
    this.operations = true,
    this.quests = true,
    this.squadObjectives = false,
    this.lootSources = false,
    this.mapBasics = true,
    this.communityIntel = true,
    this.researchedIntel = true,
    this.confirmedIntel = true,
    this.recentReports = true,
    this.highConfidence = false,
    this.includeLimitedEvidence = true,
    this.hideDisputed = true,
    this.hideStale = true,
    this.routeOnly = false,
    this.searchQuery = '',
  });

  final bool missingBlueprints;
  final bool topWanted;
  final bool favouriteLoadout;
  final bool tradePreparation;
  final bool operations;
  final bool quests;
  final bool squadObjectives;
  final bool lootSources;
  final bool mapBasics;
  final bool communityIntel;
  final bool researchedIntel;
  final bool confirmedIntel;
  final bool recentReports;
  final bool highConfidence;
  final bool includeLimitedEvidence;
  final bool hideDisputed;
  final bool hideStale;
  final bool routeOnly;
  final String searchQuery;

  static const defaults = ArcRaidMapFilterState();

  int get activeCount {
    final defaults = ArcRaidMapFilterState.defaults;
    final values = <bool>[
      missingBlueprints != defaults.missingBlueprints,
      topWanted != defaults.topWanted,
      favouriteLoadout != defaults.favouriteLoadout,
      tradePreparation != defaults.tradePreparation,
      operations != defaults.operations,
      quests != defaults.quests,
      squadObjectives != defaults.squadObjectives,
      lootSources != defaults.lootSources,
      mapBasics != defaults.mapBasics,
      communityIntel != defaults.communityIntel,
      researchedIntel != defaults.researchedIntel,
      confirmedIntel != defaults.confirmedIntel,
      recentReports != defaults.recentReports,
      highConfidence != defaults.highConfidence,
      includeLimitedEvidence != defaults.includeLimitedEvidence,
      hideDisputed != defaults.hideDisputed,
      hideStale != defaults.hideStale,
      routeOnly != defaults.routeOnly,
      searchQuery.trim().isNotEmpty,
    ];
    return values.where((changed) => changed).length;
  }

  bool allows(ArcRaidMapMarker marker) {
    if (routeOnly &&
        marker.category != ArcRaidMapMarkerCategory.routeWaypoint &&
        marker.category != ArcRaidMapMarkerCategory.standardExtraction &&
        marker.category != ArcRaidMapMarkerCategory.raiderHatch &&
        marker.category != ArcRaidMapMarkerCategory.spawn) {
      return false;
    }
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty && !marker.label.toLowerCase().contains(query)) {
      return false;
    }
    if (highConfidence && marker.confidence.score < 70) return false;
    if (!includeLimitedEvidence &&
        marker.confidence == ArcRaidIntelConfidence.limited) {
      return false;
    }
    switch (marker.category) {
      case ArcRaidMapMarkerCategory.blueprintOpportunity:
        return missingBlueprints;
      case ArcRaidMapMarkerCategory.topWanted:
        return topWanted;
      case ArcRaidMapMarkerCategory.favouriteLoadoutRequirement:
        return favouriteLoadout;
      case ArcRaidMapMarkerCategory.tradePreparationRequirement:
        return tradePreparation;
      case ArcRaidMapMarkerCategory.operationObjective:
        return operations;
      case ArcRaidMapMarkerCategory.questObjective:
        return quests;
      case ArcRaidMapMarkerCategory.teammateObjective:
        return squadObjectives;
      case ArcRaidMapMarkerCategory.communityIntel:
        return communityIntel;
      case ArcRaidMapMarkerCategory.researchedIntel:
        return researchedIntel;
      case ArcRaidMapMarkerCategory.confirmedIntel:
        return confirmedIntel;
      case ArcRaidMapMarkerCategory.disputedIntel:
        return !hideDisputed;
      case ArcRaidMapMarkerCategory.staleIntel:
        return !hideStale;
      case ArcRaidMapMarkerCategory.weaponCase:
      case ArcRaidMapMarkerCategory.securityLocker:
      case ArcRaidMapMarkerCategory.firstWaveCache:
      case ArcRaidMapMarkerCategory.raiderCache:
      case ArcRaidMapMarkerCategory.fieldCrate:
      case ArcRaidMapMarkerCategory.lockedRoom:
      case ArcRaidMapMarkerCategory.keyRoom:
      case ArcRaidMapMarkerCategory.containerCluster:
      case ArcRaidMapMarkerCategory.generalLoot:
        return lootSources;
      default:
        return mapBasics;
    }
  }

  ArcRaidMapFilterState copyWith({
    bool? missingBlueprints,
    bool? topWanted,
    bool? favouriteLoadout,
    bool? tradePreparation,
    bool? operations,
    bool? quests,
    bool? squadObjectives,
    bool? lootSources,
    bool? mapBasics,
    bool? communityIntel,
    bool? researchedIntel,
    bool? confirmedIntel,
    bool? recentReports,
    bool? highConfidence,
    bool? includeLimitedEvidence,
    bool? hideDisputed,
    bool? hideStale,
    bool? routeOnly,
    String? searchQuery,
  }) {
    return ArcRaidMapFilterState(
      missingBlueprints: missingBlueprints ?? this.missingBlueprints,
      topWanted: topWanted ?? this.topWanted,
      favouriteLoadout: favouriteLoadout ?? this.favouriteLoadout,
      tradePreparation: tradePreparation ?? this.tradePreparation,
      operations: operations ?? this.operations,
      quests: quests ?? this.quests,
      squadObjectives: squadObjectives ?? this.squadObjectives,
      lootSources: lootSources ?? this.lootSources,
      mapBasics: mapBasics ?? this.mapBasics,
      communityIntel: communityIntel ?? this.communityIntel,
      researchedIntel: researchedIntel ?? this.researchedIntel,
      confirmedIntel: confirmedIntel ?? this.confirmedIntel,
      recentReports: recentReports ?? this.recentReports,
      highConfidence: highConfidence ?? this.highConfidence,
      includeLimitedEvidence:
          includeLimitedEvidence ?? this.includeLimitedEvidence,
      hideDisputed: hideDisputed ?? this.hideDisputed,
      hideStale: hideStale ?? this.hideStale,
      routeOnly: routeOnly ?? this.routeOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

@immutable
class ArcRaidIntelEvidence {
  const ArcRaidIntelEvidence({
    required this.id,
    required this.blueprintId,
    required this.mapId,
    this.poiId,
    this.approximateArea,
    this.point,
    this.containerSource,
    this.conditionId,
    this.raidStage,
    this.acquisitionSource,
    this.claimSummary = '',
    this.sourceCategory = 'uag_seed',
    this.sourceReference = 'UAG local seed',
    this.publishedAt,
    this.reviewedAt,
    this.gameVersion,
    this.direct = false,
    this.confidence = ArcRaidIntelConfidence.limited,
    this.notes = '',
  });

  final String id;
  final String blueprintId;
  final String mapId;
  final String? poiId;
  final String? approximateArea;
  final ArcNormalizedPoint? point;
  final String? containerSource;
  final String? conditionId;
  final String? raidStage;
  final String? acquisitionSource;
  final String claimSummary;
  final String sourceCategory;
  final String sourceReference;
  final DateTime? publishedAt;
  final DateTime? reviewedAt;
  final String? gameVersion;
  final bool direct;
  final ArcRaidIntelConfidence confidence;
  final String notes;
}

@immutable
class ArcRaidIntelCluster {
  const ArcRaidIntelCluster({
    required this.id,
    required this.mapId,
    required this.label,
    required this.point,
    required this.blueprintIds,
    required this.evidence,
    this.poiId,
    this.confidence = ArcRaidIntelConfidence.limited,
    this.reportCount = 0,
    this.independentReporterCount = 0,
    this.freshnessLabel = 'Seeded',
    this.commonSource = 'Area-level report',
    this.conditionCorrelation = 'Any condition',
  });

  final String id;
  final String mapId;
  final String label;
  final ArcNormalizedPoint point;
  final List<String> blueprintIds;
  final List<ArcRaidIntelEvidence> evidence;
  final String? poiId;
  final ArcRaidIntelConfidence confidence;
  final int reportCount;
  final int independentReporterCount;
  final String freshnessLabel;
  final String commonSource;
  final String conditionCorrelation;

  String get cautiousSummary {
    if (confidence == ArcRaidIntelConfidence.confirmed) {
      return 'Confirmed Intel';
    }
    if (confidence == ArcRaidIntelConfidence.strong) {
      return 'Strong community confidence';
    }
    if (confidence == ArcRaidIntelConfidence.moderate) {
      return 'Several recent reports';
    }
    if (confidence == ArcRaidIntelConfidence.limited) {
      return 'Limited evidence';
    }
    return 'Possible opportunity';
  }
}

@immutable
class ArcRaidObjective {
  const ArcRaidObjective({
    required this.id,
    required this.label,
    required this.reason,
    required this.category,
    this.blueprintId,
    this.weight = 1,
    this.private = true,
  });

  final String id;
  final String label;
  final String reason;
  final ArcRaidMapMarkerCategory category;
  final String? blueprintId;
  final double weight;
  final bool private;
}

@immutable
class ArcRaidRouteParticipant {
  const ArcRaidRouteParticipant({
    required this.uid,
    required this.displayName,
    this.objectiveSharing = ArcRaidObjectiveSharing.keepPrivate,
  });

  final String uid;
  final String displayName;
  final ArcRaidObjectiveSharing objectiveSharing;

  bool get sharesSpecificObjectives =>
      objectiveSharing == ArcRaidObjectiveSharing.selectedBlueprintGoals ||
      objectiveSharing == ArcRaidObjectiveSharing.allChosenRaidPlanObjectives;
}

@immutable
class ArcRaidRouteStop {
  const ArcRaidRouteStop({
    required this.id,
    required this.label,
    required this.point,
    required this.order,
    this.clusterId,
    this.markerId,
    this.blueprintIds = const <String>[],
    this.state = ArcRaidRouteStopState.planned,
    this.reason = '',
  });

  final String id;
  final String label;
  final ArcNormalizedPoint point;
  final int order;
  final String? clusterId;
  final String? markerId;
  final List<String> blueprintIds;
  final ArcRaidRouteStopState state;
  final String reason;

  ArcRaidRouteStop copyWith({int? order, ArcRaidRouteStopState? state}) {
    return ArcRaidRouteStop(
      id: id,
      label: label,
      point: point,
      order: order ?? this.order,
      clusterId: clusterId,
      markerId: markerId,
      blueprintIds: blueprintIds,
      state: state ?? this.state,
      reason: reason,
    );
  }
}

@immutable
class ArcRaidRoutePlan {
  const ArcRaidRoutePlan({
    required this.id,
    required this.mapId,
    required this.mapName,
    required this.squadMode,
    required this.routeStyle,
    required this.raidStage,
    required this.objectivePriority,
    required this.spawn,
    required this.extraction,
    required this.stops,
    this.usesRaiderHatch = false,
    this.hatchKeyConfirmed = false,
    this.participants = const <ArcRaidRouteParticipant>[],
    this.score = 0,
    this.summary = '',
    this.approximate = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String mapId;
  final String mapName;
  final ArcRaidSquadMode squadMode;
  final ArcRaidRouteStyle routeStyle;
  final String raidStage;
  final ArcRaidObjectivePriority objectivePriority;
  final ArcRaidRouteStop spawn;
  final ArcRaidRouteStop extraction;
  final List<ArcRaidRouteStop> stops;
  final bool usesRaiderHatch;
  final bool hatchKeyConfirmed;
  final List<ArcRaidRouteParticipant> participants;
  final int score;
  final String summary;
  final bool approximate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<ArcRaidRouteStop> get orderedStops {
    final out = <ArcRaidRouteStop>[spawn, ...stops, extraction]
      ..sort((a, b) => a.order.compareTo(b.order));
    return out;
  }

  bool get routeReady =>
      spawn.label.trim().isNotEmpty &&
      extraction.label.trim().isNotEmpty &&
      (!usesRaiderHatch || hatchKeyConfirmed);

  ArcRaidRoutePlan copyWith({
    List<ArcRaidRouteStop>? stops,
    ArcRaidRouteStop? spawn,
    ArcRaidRouteStop? extraction,
    bool? usesRaiderHatch,
    bool? hatchKeyConfirmed,
    int? score,
    String? summary,
  }) {
    return ArcRaidRoutePlan(
      id: id,
      mapId: mapId,
      mapName: mapName,
      squadMode: squadMode,
      routeStyle: routeStyle,
      raidStage: raidStage,
      objectivePriority: objectivePriority,
      spawn: spawn ?? this.spawn,
      extraction: extraction ?? this.extraction,
      stops: stops ?? this.stops,
      usesRaiderHatch: usesRaiderHatch ?? this.usesRaiderHatch,
      hatchKeyConfirmed: hatchKeyConfirmed ?? this.hatchKeyConfirmed,
      participants: participants,
      score: score ?? this.score,
      summary: summary ?? this.summary,
      approximate: approximate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

@immutable
class ArcRaidMap {
  const ArcRaidMap({
    required this.id,
    required this.displayName,
    required this.bounds,
    required this.regions,
    required this.pois,
    required this.spawnRegions,
    required this.extractions,
    required this.hatches,
    required this.routeNodes,
    required this.routeEdges,
    required this.markers,
    this.aliases = const <String>[],
    this.asset,
    this.calibration,
    this.layerAssets = const <ArcRaidMapLayer, ArcRaidMapAsset>{},
    this.layerCalibrations = const <ArcRaidMapLayer, ArcRaidMapCalibration>{},
    this.publicationState = ArcRaidMapPublicationState.published,
    this.dataVersion = 'local-seed-v1',
    this.lastReviewed,
    this.schematicLabel = 'Tactical schematic — positions are approximate',
  });

  final String id;
  final String displayName;
  final List<String> aliases;
  final ArcNormalizedPoint bounds;
  final List<ArcRaidMapRegion> regions;
  final List<ArcRaidMapPoi> pois;
  final List<ArcRaidSpawnRegion> spawnRegions;
  final List<ArcRaidExtraction> extractions;
  final List<ArcRaiderHatch> hatches;
  final List<ArcRaidRouteNode> routeNodes;
  final List<ArcRaidRouteEdge> routeEdges;
  final List<ArcRaidMapMarker> markers;
  final ArcRaidMapAsset? asset;
  final ArcRaidMapCalibration? calibration;
  final Map<ArcRaidMapLayer, ArcRaidMapAsset> layerAssets;
  final Map<ArcRaidMapLayer, ArcRaidMapCalibration> layerCalibrations;
  final ArcRaidMapPublicationState publicationState;
  final String dataVersion;
  final DateTime? lastReviewed;
  final String schematicLabel;

  ArcRaidMapAsset? assetForLayer(ArcRaidMapLayer layer) {
    if (layerAssets.containsKey(layer)) return layerAssets[layer];
    if (layer == ArcRaidMapLayer.surface) return asset;
    return null;
  }

  ArcRaidMapCalibration? calibrationForLayer(ArcRaidMapLayer layer) {
    if (layerCalibrations.containsKey(layer)) {
      return layerCalibrations[layer];
    }
    if (layer == ArcRaidMapLayer.surface) return calibration;
    return null;
  }

  List<ArcRaidMapLayer> get availableLayers {
    final layers = <ArcRaidMapLayer>{
      ...layerAssets.keys,
      if (asset != null) ArcRaidMapLayer.surface,
    }.toList(growable: false)..sort((a, b) => a.index.compareTo(b.index));
    return layers;
  }

  bool hasCalibratedLayer(ArcRaidMapLayer layer) {
    return assetForLayer(layer)?.hasRenderableImage == true &&
        calibrationForLayer(layer)?.valid == true;
  }

  bool get hasCalibratedMap => availableLayers.any(hasCalibratedLayer);
}

@immutable
class ArcRaidIntelligenceState {
  const ArcRaidIntelligenceState({
    required this.map,
    required this.activeLayer,
    required this.filters,
    required this.visibleMarkers,
    required this.opportunityClusters,
    required this.routePlan,
    required this.activeConditionLabel,
    required this.statusLabel,
    required this.recommendation,
  });

  final ArcRaidMap map;
  final ArcRaidMapLayer activeLayer;
  final ArcRaidMapFilterState filters;
  final List<ArcRaidMapMarker> visibleMarkers;
  final List<ArcRaidIntelCluster> opportunityClusters;
  final ArcRaidRoutePlan? routePlan;
  final String activeConditionLabel;
  final String statusLabel;
  final String recommendation;
}
