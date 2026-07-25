import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcRaidIntelligenceSeedData {
  const ArcRaidIntelligenceSeedData._();

  static const String providerId = 'uag_local_seed_provider';
  static const String attribution =
      'UAG local seed data and Community Intel. Schematic positions are approximate.';

  static const Map<String, String> canonicalMapIds = {
    ArcPoiDataStore.buriedCity: 'buried_city',
    ArcPoiDataStore.damBattlegrounds: 'dam_battlegrounds',
    ArcPoiDataStore.rivenTides: 'riven_tides',
    ArcPoiDataStore.spaceport: 'spaceport',
    ArcPoiDataStore.stellaMontis: 'stella_montis',
    ArcPoiDataStore.blueGate: 'blue_gate',
  };

  static const Map<String, String> _aliases = {
    'buried city': 'buried_city',
    'buried_city': 'buried_city',
    'dam battlegrounds': 'dam_battlegrounds',
    'dam': 'dam_battlegrounds',
    'dam_battlegrounds': 'dam_battlegrounds',
    'riven tides': 'riven_tides',
    'riven_tides': 'riven_tides',
    'spaceport': 'spaceport',
    'stella montis': 'stella_montis',
    'stella_montis': 'stella_montis',
    'blue gate': 'blue_gate',
    'the blue gate': 'blue_gate',
    'blue_gate': 'blue_gate',
  };

  static const List<String> supportedMapIds = [
    'buried_city',
    'dam_battlegrounds',
    'riven_tides',
    'spaceport',
    'stella_montis',
    'blue_gate',
  ];

  static final List<ArcRaidMapMarkerDefinition> markerDefinitions =
      ArcRaidMapMarkerCategory.values
          .map(
            (category) => ArcRaidMapMarkerDefinition(
              category: category,
              shape: category.clustersByDefault ? 'cluster' : 'pin',
              semanticDescription:
                  '${category.label} marker in ${category.filteringGroup}.',
              disabledByDefault: category.filteringGroup == 'Loot Sources',
            ),
          )
          .toList(growable: false);

  static String normalizeMapId(String value) {
    final key = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return _aliases[key] ?? value.trim().toLowerCase().replaceAll(' ', '_');
  }

  static String displayNameForMapId(String mapId) {
    return switch (normalizeMapId(mapId)) {
      'buried_city' => ArcPoiDataStore.buriedCity,
      'dam_battlegrounds' => ArcPoiDataStore.damBattlegrounds,
      'riven_tides' => ArcPoiDataStore.rivenTides,
      'spaceport' => ArcPoiDataStore.spaceport,
      'stella_montis' => ArcPoiDataStore.stellaMontis,
      'blue_gate' => ArcPoiDataStore.blueGate,
      _ => mapId,
    };
  }

  static ArcRaidMap mapById(String mapId) {
    final normalized = normalizeMapId(mapId);
    return maps.firstWhere(
      (map) => map.id == normalized,
      orElse: () => maps.first,
    );
  }

  static List<ArcRaidMap> get maps {
    return supportedMapIds.map(_buildMap).toList(growable: false);
  }

  static ArcRaidMap _buildMap(String mapId) {
    final displayName = displayNameForMapId(mapId);
    final pois = _pois(displayName, mapId);
    final regions = _regions(mapId);
    final spawnRegions = _spawnRegions(mapId);
    final extractions = _extractions(mapId);
    final hatches = _hatches(mapId);
    final routeNodes = _routeNodes(mapId, pois, spawnRegions, extractions);
    final routeEdges = _routeEdges(mapId, routeNodes);
    final markers = <ArcRaidMapMarker>[
      for (final region in regions)
        ArcRaidMapMarker(
          id: '${region.id}_marker',
          mapId: mapId,
          category: ArcRaidMapMarkerCategory.region,
          label: region.name,
          point: region.center,
          radius: 0.12,
          payloadId: region.id,
          confidence: ArcRaidIntelConfidence.moderate,
        ),
      for (final poi in pois)
        ArcRaidMapMarker(
          id: '${poi.id}_marker',
          mapId: mapId,
          category: ArcRaidMapMarkerCategory.poi,
          label: poi.name,
          point: poi.point,
          payloadId: poi.id,
          confidence: ArcRaidIntelConfidence.moderate,
          approximate: poi.approximate,
        ),
      for (final spawn in spawnRegions)
        ArcRaidMapMarker(
          id: '${spawn.id}_marker',
          mapId: mapId,
          category: ArcRaidMapMarkerCategory.spawnRegion,
          label: spawn.name,
          point: spawn.center,
          radius: spawn.radius,
          payloadId: spawn.id,
          confidence: ArcRaidIntelConfidence.moderate,
        ),
      for (final extraction in extractions)
        ArcRaidMapMarker(
          id: '${extraction.id}_marker',
          mapId: mapId,
          category: ArcRaidMapMarkerCategory.standardExtraction,
          label: extraction.name,
          point: extraction.point,
          payloadId: extraction.id,
          confidence: ArcRaidIntelConfidence.moderate,
        ),
      for (final hatch in hatches)
        ArcRaidMapMarker(
          id: '${hatch.id}_marker',
          mapId: mapId,
          category: ArcRaidMapMarkerCategory.raiderHatch,
          label: hatch.name,
          point: hatch.point,
          payloadId: hatch.id,
          confidence: ArcRaidIntelConfidence.moderate,
        ),
      ..._genericLootMarkers(mapId),
      if (mapId == ArcMapAssetRegistry.blueGateMapId) ...[
        ..._blueGateProductionMarkers(),
        ..._blueGateProductionPoiMarkers(),
      ],
    ];
    final layerAssets = ArcMapAssetRegistry.assetsFor(mapId);
    final layerCalibrations = ArcMapAssetRegistry.calibrationsFor(mapId);
    return ArcRaidMap(
      id: mapId,
      displayName: displayName,
      aliases: _aliases.entries
          .where((entry) => entry.value == mapId)
          .map((entry) => entry.key)
          .toList(growable: false),
      bounds: const ArcNormalizedPoint(x: 1, y: 1),
      regions: regions,
      pois: pois,
      spawnRegions: spawnRegions,
      extractions: extractions,
      hatches: hatches,
      routeNodes: routeNodes,
      routeEdges: routeEdges,
      markers: markers,
      asset: layerAssets[ArcRaidMapLayer.surface],
      calibration: layerCalibrations[ArcRaidMapLayer.surface],
      layerAssets: layerAssets,
      layerCalibrations: layerCalibrations,
      dataVersion: mapId == ArcMapAssetRegistry.blueGateMapId
          ? 'pass-282-raid-intelligence-core-v1'
          : 'pass-275-local-schematic-v1',
      lastReviewed: DateTime.utc(2026, 7, 23),
    );
  }

  static List<ArcRaidMapPoi> _pois(String displayName, String mapId) {
    final sourcePois = ArcPoiDataStore.blueprintReportPoisForMap(displayName);
    final count = math.max(sourcePois.length, 1);
    return [
      for (var index = 0; index < sourcePois.length; index++)
        ArcRaidMapPoi(
          id: sourcePois[index].id,
          mapId: mapId,
          name: sourcePois[index].name,
          point: _schematicPoint(index, count, mapId),
          regionId: _regionIdForPoint(
            mapId,
            _schematicPoint(index, count, mapId),
          ),
          approximate: true,
          lootTags: [
            sourcePois[index].lootLevel.label,
            for (final type in sourcePois[index].buildingTypes) type.label,
          ],
        ),
    ];
  }

  static List<ArcRaidMapRegion> _regions(String mapId) {
    const names = [
      ('northwest', 'Northwest Sector', 0.22, 0.22, 0.30),
      ('northeast', 'Northeast Sector', 0.78, 0.24, 0.38),
      ('central', 'Central Route Web', 0.50, 0.50, 0.48),
      ('southwest', 'Southwest Approach', 0.24, 0.78, 0.28),
      ('southeast', 'Southeast Extraction Band', 0.76, 0.76, 0.34),
    ];
    return [
      for (final item in names)
        ArcRaidMapRegion(
          id: '${mapId}_${item.$1}',
          mapId: mapId,
          name: item.$2,
          center: ArcNormalizedPoint(x: item.$3, y: item.$4),
          risk: item.$5,
          notes: 'Schematic sector; not an exact in-game boundary.',
        ),
    ];
  }

  static List<ArcRaidSpawnRegion> _spawnRegions(String mapId) {
    return const [
          ('north_spawn', 'North Spawn Band', 0.50, 0.08),
          ('west_spawn', 'West Spawn Band', 0.08, 0.50),
          ('south_spawn', 'South Spawn Band', 0.50, 0.92),
        ]
        .map(
          (item) => ArcRaidSpawnRegion(
            id: '${mapId}_${item.$1}',
            mapId: mapId,
            name: item.$2,
            center: ArcNormalizedPoint(x: item.$3, y: item.$4),
          ),
        )
        .toList(growable: false);
  }

  static List<ArcRaidExtraction> _extractions(String mapId) {
    return const [
          ('north_extraction', 'North Standard Extraction', 0.86, 0.12),
          ('southwest_extraction', 'Southwest Standard Extraction', 0.12, 0.86),
          ('southeast_extraction', 'Southeast Standard Extraction', 0.86, 0.86),
        ]
        .map(
          (item) => ArcRaidExtraction(
            id: '${mapId}_${item.$1}',
            mapId: mapId,
            name: item.$2,
            point: ArcNormalizedPoint(x: item.$3, y: item.$4),
            notes:
                'Configured schematic extraction. Live extraction timers must be chosen by the player.',
          ),
        )
        .toList(growable: false);
  }

  static List<ArcRaiderHatch> _hatches(String mapId) {
    return const [
          ('hatch_west', 'West Raider Hatch', 0.20, 0.55),
          ('hatch_east', 'East Raider Hatch', 0.80, 0.46),
        ]
        .map(
          (item) => ArcRaiderHatch(
            id: '${mapId}_${item.$1}',
            mapId: mapId,
            name: item.$2,
            point: ArcNormalizedPoint(x: item.$3, y: item.$4),
          ),
        )
        .toList(growable: false);
  }

  static List<ArcRaidRouteNode> _routeNodes(
    String mapId,
    List<ArcRaidMapPoi> pois,
    List<ArcRaidSpawnRegion> spawns,
    List<ArcRaidExtraction> extractions,
  ) {
    final selectedPois = pois.take(12).toList(growable: false);
    return [
      for (final spawn in spawns)
        ArcRaidRouteNode(
          id: spawn.id,
          mapId: mapId,
          name: spawn.name,
          point: spawn.center,
        ),
      for (final poi in selectedPois)
        ArcRaidRouteNode(
          id: poi.id,
          mapId: mapId,
          name: poi.name,
          point: poi.point,
        ),
      for (final extraction in extractions)
        ArcRaidRouteNode(
          id: extraction.id,
          mapId: mapId,
          name: extraction.name,
          point: extraction.point,
        ),
    ];
  }

  static List<ArcRaidRouteEdge> _routeEdges(
    String mapId,
    List<ArcRaidRouteNode> nodes,
  ) {
    if (nodes.length < 2) return const <ArcRaidRouteEdge>[];
    final edges = <ArcRaidRouteEdge>[];
    for (var index = 0; index < nodes.length - 1; index++) {
      final from = nodes[index];
      final to = nodes[index + 1];
      final distance = from.point.distanceTo(to.point);
      edges.add(
        ArcRaidRouteEdge(
          id: '${mapId}_edge_${from.id}_${to.id}',
          fromNodeId: from.id,
          toNodeId: to.id,
          travelCost: 1 + (distance * 10),
          riskCost: distance * 2,
          geometry: [from.point, to.point],
        ),
      );
    }
    return edges;
  }

  static List<ArcRaidMapMarker> _blueGateProductionPoiMarkers() {
    const mapId = ArcMapAssetRegistry.blueGateMapId;
    return const <ArcRaidMapMarker>[
      ArcRaidMapMarker(
        id: 'blue_gate_poi_raider_refuge',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Raider Refuge',
        point: ArcNormalizedPoint(x: 0.305, y: 0.085),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        detail: 'Northern fortified POI.',
        tags: <String>['POI', 'North'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_trapper_glade',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: "Trapper's Glade",
        point: ArcNormalizedPoint(x: 0.381, y: 0.215),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        detail: 'Northern woodland POI.',
        tags: <String>['POI', 'North'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_adorned_wreckage',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Adorned Wreckage',
        point: ArcNormalizedPoint(x: 0.596, y: 0.190),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'North'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_checkpoint',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Checkpoint',
        point: ArcNormalizedPoint(x: 0.702, y: 0.215),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'Northeast'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_reinforced_reception',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Reinforced Reception',
        point: ArcNormalizedPoint(x: 0.545, y: 0.306),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'Central'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_white_valley',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'White Valley',
        point: ArcNormalizedPoint(x: 0.635, y: 0.393),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'East'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_village',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Village',
        point: ArcNormalizedPoint(x: 0.387, y: 0.381),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'West'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_warehouse_complex',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Warehouse Complex',
        point: ArcNormalizedPoint(x: 0.313, y: 0.476),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'West'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_highway_collapse',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Highway Collapse',
        point: ArcNormalizedPoint(x: 0.535, y: 0.474),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'Central'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_confiscation_room',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Confiscation Room',
        point: ArcNormalizedPoint(x: 0.664, y: 0.510),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'East'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_ancient_fort',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Ancient Fort',
        point: ArcNormalizedPoint(x: 0.481, y: 0.704),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        tags: <String>['POI', 'South'],
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_poi_underground',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Blue Gate Underground',
        point: ArcNormalizedPoint(x: 0.500, y: 0.510),
        layer: ArcRaidMapLayer.underground,
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
        detail: 'Level 2 underground map layer.',
        tags: <String>['POI', 'Level 2'],
      ),
    ];
  }

  static List<ArcRaidMapMarker> _blueGateProductionMarkers() {
    const mapId = ArcMapAssetRegistry.blueGateMapId;
    return const <ArcRaidMapMarker>[
      ArcRaidMapMarker(
        id: 'blue_gate_airshaft_raider_hatch_northwest',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.surfaceTransition,
        label: 'Airshaft / Raider Hatch',
        point: ArcNormalizedPoint(x: 0.244, y: 0.121),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_airshaft_ridgeline',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.surfaceTransition,
        label: 'Airshaft',
        point: ArcNormalizedPoint(x: 0.507, y: 0.113),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_airshaft_white_valley',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.surfaceTransition,
        label: 'Airshaft',
        point: ArcNormalizedPoint(x: 0.585, y: 0.394),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_raider_hatch_ancient_fort',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.raiderHatch,
        label: 'Raider Hatch',
        point: ArcNormalizedPoint(x: 0.490, y: 0.794),
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
      ),
      ArcRaidMapMarker(
        id: 'blue_gate_level2_transition',
        mapId: mapId,
        category: ArcRaidMapMarkerCategory.undergroundTransition,
        label: 'Level 2 Access',
        point: ArcNormalizedPoint(x: 0.503, y: 0.502),
        layer: ArcRaidMapLayer.underground,
        confidence: ArcRaidIntelConfidence.confirmed,
        approximate: false,
      ),
    ];
  }

  static List<ArcRaidMapMarker> _genericLootMarkers(String mapId) {
    return const [
          (
            ArcRaidMapMarkerCategory.weaponCase,
            'Weapon Case Cluster',
            0.35,
            0.38,
          ),
          (
            ArcRaidMapMarkerCategory.securityLocker,
            'Security Locker Route',
            0.66,
            0.34,
          ),
          (
            ArcRaidMapMarkerCategory.firstWaveCache,
            'First Wave Cache Area',
            0.45,
            0.62,
          ),
          (
            ArcRaidMapMarkerCategory.raiderCache,
            'Raider Cache Area',
            0.58,
            0.58,
          ),
          (
            ArcRaidMapMarkerCategory.fieldCrate,
            'Field Crate Sweep',
            0.30,
            0.70,
          ),
          (
            ArcRaidMapMarkerCategory.containerCluster,
            'Container Cluster',
            0.70,
            0.70,
          ),
        ]
        .map(
          (item) => ArcRaidMapMarker(
            id: '${mapId}_${item.$1.name}',
            mapId: mapId,
            category: item.$1,
            label: item.$2,
            point: ArcNormalizedPoint(x: item.$3, y: item.$4),
            confidence: ArcRaidIntelConfidence.limited,
            approximate: true,
          ),
        )
        .toList(growable: false);
  }

  static ArcNormalizedPoint _schematicPoint(
    int index,
    int count,
    String mapId,
  ) {
    final columns = math.max(4, math.sqrt(count).ceil());
    final row = index ~/ columns;
    final col = index % columns;
    final rows = math.max(1, (count / columns).ceil());
    final mapOffset = supportedMapIds.indexOf(mapId).clamp(0, 5) * 0.017;
    final xBase = columns <= 1 ? 0.5 : 0.14 + (col / (columns - 1)) * 0.72;
    final yBase = rows <= 1 ? 0.5 : 0.16 + (row / math.max(1, rows - 1)) * 0.68;
    final wave = math.sin((index + 1) * 1.7) * 0.035;
    return ArcNormalizedPoint(
      x: (xBase + wave + mapOffset).clamp(0.08, 0.92),
      y: (yBase - wave + (mapOffset / 2)).clamp(0.08, 0.92),
    );
  }

  static String _regionIdForPoint(String mapId, ArcNormalizedPoint point) {
    final horizontal = point.x < 0.4
        ? 'west'
        : point.x > 0.6
        ? 'east'
        : 'central';
    final vertical = point.y < 0.4
        ? 'north'
        : point.y > 0.6
        ? 'south'
        : 'central';
    if (horizontal == 'central' || vertical == 'central') {
      return '${mapId}_central';
    }
    return '${mapId}_$vertical$horizontal';
  }
}
