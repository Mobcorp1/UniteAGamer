import 'package:flutter/foundation.dart';

/// The broad type of source a player can report for a blueprint.
enum ArcDropSourceType { poi, enemy, other }

/// Classification tags shown on the in-game map legend.
enum ArcBuildingType {
  residential,
  oldWorld,
  medical,
  commercial,
  nature,
  technological,
  mechanical,
  industrial,
  security,
  electrical,
  exodus,
  arc,
}

/// Loot ring / visual priority on the map.
enum ArcLootLevel { high, medium, none }

extension ArcBuildingTypeX on ArcBuildingType {
  String get label {
    switch (this) {
      case ArcBuildingType.residential:
        return 'Residential';
      case ArcBuildingType.oldWorld:
        return 'Old World';
      case ArcBuildingType.medical:
        return 'Medical';
      case ArcBuildingType.commercial:
        return 'Commercial';
      case ArcBuildingType.nature:
        return 'Nature';
      case ArcBuildingType.technological:
        return 'Technological';
      case ArcBuildingType.mechanical:
        return 'Mechanical';
      case ArcBuildingType.industrial:
        return 'Industrial';
      case ArcBuildingType.security:
        return 'Security';
      case ArcBuildingType.electrical:
        return 'Electrical';
      case ArcBuildingType.exodus:
        return 'Exodus';
      case ArcBuildingType.arc:
        return 'ARC';
    }
  }
}

extension ArcLootLevelX on ArcLootLevel {
  String get label {
    switch (this) {
      case ArcLootLevel.high:
        return 'High Loot';
      case ArcLootLevel.medium:
        return 'Medium Loot';
      case ArcLootLevel.none:
        return 'POI';
    }
  }
}

extension ArcDropSourceTypeX on ArcDropSourceType {
  String get label {
    switch (this) {
      case ArcDropSourceType.poi:
        return 'POI';
      case ArcDropSourceType.enemy:
        return 'Enemy';
      case ArcDropSourceType.other:
        return 'Other';
    }
  }
}

@immutable
class ArcPoiData {
  const ArcPoiData({
    required this.id,
    required this.mapName,
    required this.name,
    required this.sourceType,
    required this.lootLevel,
    required this.buildingTypes,
    this.includeInBlueprintReports = true,
    this.areaName,
    this.notes,
  });

  final String id;
  final String mapName;
  final String name;
  final ArcDropSourceType sourceType;
  final ArcLootLevel lootLevel;
  final List<ArcBuildingType> buildingTypes;
  final bool includeInBlueprintReports;
  final String? areaName;
  final String? notes;

  bool get isLootableArea => lootLevel != ArcLootLevel.none;

  String get resolvedAreaName {
    final trimmed = areaName?.trim();
    return (trimmed == null || trimmed.isEmpty) ? name : trimmed;
  }

  String get buildingTypeLabel =>
      buildingTypes.map((type) => type.label).join(' / ');
}

@immutable
class ArcEnemySource {
  const ArcEnemySource({
    required this.id,
    required this.name,
    this.includeInBlueprintReports = true,
  });

  final String id;
  final String name;
  final bool includeInBlueprintReports;
}

class ArcPoiDataStore {
  ArcPoiDataStore._();

  static const String buriedCity = 'Buried City';
  static const String damBattlegrounds = 'Dam Battlegrounds';
  static const String stellaMontis = 'Stella Montis';
  static const String blueGate = 'The Blue Gate';
  static const String spaceport = 'Spaceport';

  /// Buried City sources
  static const List<ArcPoiData> buriedCityPois = [
    ArcPoiData(
      id: 'buried_city_library',
      mapName: buriedCity,
      name: 'Library',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_marano_station',
      mapName: buriedCity,
      name: 'Marano Station',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
    ),
    ArcPoiData(
      id: 'buried_city_warehouse',
      mapName: buriedCity,
      name: 'Warehouse',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_piazza_roma',
      mapName: buriedCity,
      name: 'Piazza Roma',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.residential, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_town_hall',
      mapName: buriedCity,
      name: 'Town Hall',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_corso_da_vinci',
      mapName: buriedCity,
      name: 'Corso da Vinci',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_grandioso_apartments',
      mapName: buriedCity,
      name: 'Grandioso Apartments',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_abandoned_highway_camp',
      mapName: buriedCity,
      name: 'Abandoned Highway Camp',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.nature],
    ),
    ArcPoiData(
      id: 'buried_city_maintenance_depot',
      mapName: buriedCity,
      name: 'Maintenance Depot',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'buried_city_plaza_rosa',
      mapName: buriedCity,
      name: 'Plaza Rosa',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_main_street',
      mapName: buriedCity,
      name: 'Main Street',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.residential, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_santa_maria_houses',
      mapName: buriedCity,
      name: 'Santa Maria Houses',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_red_tower',
      mapName: buriedCity,
      name: 'Red Tower',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_church_ruins',
      mapName: buriedCity,
      name: 'Church Ruins',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'buried_city_market_ruins',
      mapName: buriedCity,
      name: 'Market Ruins',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_dunes_end',
      mapName: buriedCity,
      name: "Dune's End",
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature, ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_hospital',
      mapName: buriedCity,
      name: 'Hospital',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.medical],
    ),
    ArcPoiData(
      id: 'buried_city_parking_garage',
      mapName: buriedCity,
      name: 'Parking Garage',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'buried_city_galleria',
      mapName: buriedCity,
      name: 'Galleria',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_space_travel',
      mapName: buriedCity,
      name: 'Space Travel',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [
        ArcBuildingType.commercial,
        ArcBuildingType.technological,
      ],
    ),
    ArcPoiData(
      id: 'buried_city_research',
      mapName: buriedCity,
      name: 'Research',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.medical, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'buried_city_marano_park',
      mapName: buriedCity,
      name: 'Marano Park',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature, ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_buried_properties',
      mapName: buriedCity,
      name: 'Buried Properties',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'buried_city_gas_station',
      mapName: buriedCity,
      name: 'Gas Station',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'buried_city_su_durante_warehouses',
      mapName: buriedCity,
      name: 'Su Durante Warehouses',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'buried_city_metro_station',
      mapName: buriedCity,
      name: 'Metro Station',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
      notes: 'Map marker / access point.',
    ),
    ArcPoiData(
      id: 'buried_city_raider_hatch',
      mapName: buriedCity,
      name: 'Raider Hatch',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
      notes: 'Map marker / access point.',
    ),
    ArcPoiData(
      id: 'buried_city_arc_courier',
      mapName: buriedCity,
      name: 'ARC Courier',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.arc, ArcBuildingType.technological],
      notes: 'Map marker / interaction point.',
    ),
    ArcPoiData(
      id: 'buried_city_field_depot',
      mapName: buriedCity,
      name: 'Field Depot',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
      notes: 'Map marker / interaction point.',
    ),
    ArcPoiData(
      id: 'buried_city_metro_entrance',
      mapName: buriedCity,
      name: 'Metro Entrance',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
      notes: 'Map marker / access point.',
    ),
    ArcPoiData(
      id: 'buried_city_supply_call_station',
      mapName: buriedCity,
      name: 'Supply Call Station',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.exodus, ArcBuildingType.technological],
      notes: 'Map marker / interaction point.',
    ),
  ];

  /// Dam Battlegrounds sources
  static const List<ArcPoiData> damBattlegroundPois = [
    ArcPoiData(
      id: 'dam_hydroponic_dome_complex',
      mapName: damBattlegrounds,
      name: 'Hydroponic Dome Complex',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [
        ArcBuildingType.industrial,
        ArcBuildingType.technological,
      ],
    ),
    ArcPoiData(
      id: 'dam_generator_hall',
      mapName: damBattlegrounds,
      name: 'Generator Hall',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.mechanical, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'dam_power_generation_complex',
      mapName: damBattlegrounds,
      name: 'Power Generation Complex',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'dam_controlled_access_zone',
      mapName: damBattlegrounds,
      name: 'Controlled Access Zone',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'dam_pipeline_tower',
      mapName: damBattlegrounds,
      name: 'Pipeline Tower',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'dam_the_breach',
      mapName: damBattlegrounds,
      name: 'The Breach',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'dam_floodgates',
      mapName: damBattlegrounds,
      name: 'Floodgates',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'dam_primary_facility',
      mapName: damBattlegrounds,
      name: 'Primary Facility',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'dam_control_tower',
      mapName: damBattlegrounds,
      name: 'Control Tower',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'dam_research_administration',
      mapName: damBattlegrounds,
      name: 'Research & Administration',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'dam_testing_annex',
      mapName: damBattlegrounds,
      name: 'Testing Annex',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [
        ArcBuildingType.technological,
        ArcBuildingType.electrical,
      ],
    ),
    ArcPoiData(
      id: 'dam_water_treatment_control',
      mapName: damBattlegrounds,
      name: 'Water Treatment Control',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'dam_electrical_substation',
      mapName: damBattlegrounds,
      name: 'Electrical Substation',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'dam_water_towers',
      mapName: damBattlegrounds,
      name: 'Water Towers',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'dam_scrap_yard',
      mapName: damBattlegrounds,
      name: 'Scrap Yard',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'dam_wreckage',
      mapName: damBattlegrounds,
      name: 'Wreckage',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'dam_small_creek',
      mapName: damBattlegrounds,
      name: 'Small Creek',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature],
    ),
    ArcPoiData(
      id: 'dam_red_lakes_balcony',
      mapName: damBattlegrounds,
      name: 'Red Lakes Balcony',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature],
    ),
    ArcPoiData(
      id: 'dam_ruby_residence',
      mapName: damBattlegrounds,
      name: 'Ruby Residence',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'dam_pale_apartments',
      mapName: damBattlegrounds,
      name: 'Pale Apartments',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.residential],
    ),
    ArcPoiData(
      id: 'dam_ben_welders_sunroof',
      mapName: damBattlegrounds,
      name: "Ben Welder's Sunroof",
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'dam_old_battleground',
      mapName: damBattlegrounds,
      name: 'Old Battleground',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'dam_south_swamp_outpost',
      mapName: damBattlegrounds,
      name: 'South Swamp Outpost',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature, ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'dam_raider_outpost_east',
      mapName: damBattlegrounds,
      name: 'Raider Outpost East',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'dam_west_broken_bridge',
      mapName: damBattlegrounds,
      name: 'West Broken Bridge',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'dam_east_broken_bridge',
      mapName: damBattlegrounds,
      name: 'East Broken Bridge',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'dam_formicai_outpost',
      mapName: damBattlegrounds,
      name: 'Formicai Outpost',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature],
    ),
  ];

  /// Stella Montis sources
  static const List<ArcPoiData> stellaMontisPois = [
    ArcPoiData(
      id: 'stella_assembly_workshops',
      mapName: stellaMontis,
      name: 'Assembly Workshops',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'stella_assembly',
      mapName: stellaMontis,
      name: 'Assembly',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'stella_loading_bay',
      mapName: stellaMontis,
      name: 'Loading Bay',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'stella_lobby',
      mapName: stellaMontis,
      name: 'Lobby',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.exodus, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'stella_business_center',
      mapName: stellaMontis,
      name: 'Business Center',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.exodus],
    ),
    ArcPoiData(
      id: 'stella_cultural_archives',
      mapName: stellaMontis,
      name: 'Cultural Archives',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
    ),
    ArcPoiData(
      id: 'stella_medical_research',
      mapName: stellaMontis,
      name: 'Medical Research',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.medical],
    ),
    ArcPoiData(
      id: 'stella_communications',
      mapName: stellaMontis,
      name: 'Communications',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [
        ArcBuildingType.technological,
        ArcBuildingType.electrical,
      ],
    ),
    ArcPoiData(
      id: 'stella_atrium',
      mapName: stellaMontis,
      name: 'Atrium',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.exodus],
    ),
    ArcPoiData(
      id: 'stella_western_tunnel',
      mapName: stellaMontis,
      name: 'Western Tunnel',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
      notes: 'Access/tunnel area.',
    ),
    ArcPoiData(
      id: 'stella_eastern_tunnel',
      mapName: stellaMontis,
      name: 'Eastern Tunnel',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld],
      notes: 'Access/tunnel area.',
    ),
    ArcPoiData(
      id: 'stella_lobby_metro',
      mapName: stellaMontis,
      name: 'Lobby Metro',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
      notes: 'Metro access area.',
    ),
    ArcPoiData(
      id: 'stella_airshaft',
      mapName: stellaMontis,
      name: 'Airshaft',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.mechanical],
      notes: 'Access area.',
    ),
    ArcPoiData(
      id: 'stella_metro_station',
      mapName: stellaMontis,
      name: 'Metro Station',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
      notes: 'Metro access area.',
    ),
    ArcPoiData(
      id: 'stella_raider_hatch',
      mapName: stellaMontis,
      name: 'Raider Hatch',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
      notes: 'Raider access point.',
    ),
  ];

  /// The Blue Gate sources
  static const List<ArcPoiData> blueGatePois = [
    ArcPoiData(
      id: 'blue_gate_village',
      mapName: blueGate,
      name: 'Village',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.residential, ArcBuildingType.nature],
    ),
    ArcPoiData(
      id: 'blue_gate_pilgrims_peak',
      mapName: blueGate,
      name: "Pilgrim's Peak",
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.nature],
    ),
    ArcPoiData(
      id: 'blue_gate_reinforced_reception',
      mapName: blueGate,
      name: 'Reinforced Reception',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.arc],
    ),
    ArcPoiData(
      id: 'blue_gate_raiders_refuge',
      mapName: blueGate,
      name: "Raider's Refuge",
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature, ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'blue_gate_adorned_wreckage',
      mapName: blueGate,
      name: 'Adorned Wreckage',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'blue_gate_warehouse_complex',
      mapName: blueGate,
      name: 'Warehouse Complex',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
    ),
    ArcPoiData(
      id: 'blue_gate_checkpoint',
      mapName: blueGate,
      name: 'Checkpoint',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'blue_gate_ancient_fort',
      mapName: blueGate,
      name: 'Ancient Fort',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'blue_gate_security_wing',
      mapName: blueGate,
      name: 'Security Wing',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
      notes: 'Detailed in-match sub-location around Checkpoint.',
    ),
    ArcPoiData(
      id: 'blue_gate_traffic_tunnel',
      mapName: blueGate,
      name: 'Traffic Tunnel',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.security],
      notes: 'Detailed in-match sub-location around Checkpoint.',
    ),
    ArcPoiData(
      id: 'blue_gate_maintenance_wing',
      mapName: blueGate,
      name: 'Maintenance Wing',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.mechanical, ArcBuildingType.security],
      notes: 'Detailed in-match sub-location around Checkpoint.',
    ),
    ArcPoiData(
      id: 'blue_gate_airshaft',
      mapName: blueGate,
      name: 'Airshaft',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.mechanical],
      notes: 'Access area / map marker.',
    ),
    ArcPoiData(
      id: 'blue_gate_raider_hatch',
      mapName: blueGate,
      name: 'Raider Hatch',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
      notes: 'Access area / map marker.',
    ),
  ];

  /// Spaceport sources
  static const List<ArcPoiData> spaceportPois = [
    ArcPoiData(
      id: 'spaceport_west_hangar',
      mapName: spaceport,
      name: 'West Hangar',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [
        ArcBuildingType.industrial,
        ArcBuildingType.technological,
      ],
    ),
    ArcPoiData(
      id: 'spaceport_east_hangar',
      mapName: spaceport,
      name: 'East Hangar',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [
        ArcBuildingType.industrial,
        ArcBuildingType.technological,
      ],
    ),
    ArcPoiData(
      id: 'spaceport_little_hangar',
      mapName: spaceport,
      name: 'Little Hangar',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'spaceport_west_container_yard',
      mapName: spaceport,
      name: 'West Container Yard',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_shipping_warehouse',
      mapName: spaceport,
      name: 'Shipping Warehouse',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_north_trench_tower',
      mapName: spaceport,
      name: 'North Trench Tower',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'spaceport_south_trench_tower',
      mapName: spaceport,
      name: 'South Trench Tower',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'spaceport_the_trench',
      mapName: spaceport,
      name: 'The Trench',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.oldWorld],
    ),
    ArcPoiData(
      id: 'spaceport_fuel_control',
      mapName: spaceport,
      name: 'Fuel Control',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.mechanical, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'spaceport_east_container_yard',
      mapName: spaceport,
      name: 'East Container Yard',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_rocket_assembly',
      mapName: spaceport,
      name: 'Rocket Assembly',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [
        ArcBuildingType.industrial,
        ArcBuildingType.technological,
      ],
    ),
    ArcPoiData(
      id: 'spaceport_east_plains_warehouses',
      mapName: spaceport,
      name: 'East Plains Warehouses',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_launch_towers',
      mapName: spaceport,
      name: 'Launch Towers',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'spaceport_arrival_building',
      mapName: spaceport,
      name: 'Arrival Building',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.exodus],
    ),
    ArcPoiData(
      id: 'spaceport_departure_building',
      mapName: spaceport,
      name: 'Departure Building',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.exodus],
    ),
    ArcPoiData(
      id: 'spaceport_car_park',
      mapName: spaceport,
      name: 'Car Park',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_jiangsu_warehouse',
      mapName: spaceport,
      name: 'Jiangsu Warehouse',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_fuel_depot',
      mapName: spaceport,
      name: 'Fuel Depot',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'spaceport_water_towers',
      mapName: spaceport,
      name: 'Water Towers',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'spaceport_vehicle_maintenance',
      mapName: spaceport,
      name: 'Vehicle Maintenance',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.medium,
      buildingTypes: [ArcBuildingType.mechanical, ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'spaceport_container_storage',
      mapName: spaceport,
      name: 'Container Storage',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'spaceport_control_tower_a6',
      mapName: spaceport,
      name: 'Control Tower A6',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.high,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
    ),
    ArcPoiData(
      id: 'spaceport_communications_tower',
      mapName: spaceport,
      name: 'Communications Tower',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [
        ArcBuildingType.technological,
        ArcBuildingType.electrical,
      ],
    ),
    ArcPoiData(
      id: 'spaceport_service_buildings',
      mapName: spaceport,
      name: 'Service Buildings',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_staff_parking',
      mapName: spaceport,
      name: 'Staff Parking',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial],
    ),
    ArcPoiData(
      id: 'spaceport_security_checkpoint',
      mapName: spaceport,
      name: 'Security Checkpoint',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
    ),
    ArcPoiData(
      id: 'spaceport_electrical_substation',
      mapName: spaceport,
      name: 'Electrical Substation',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'spaceport_fuel_processing',
      mapName: spaceport,
      name: 'Fuel Processing',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'spaceport_fuel_lines',
      mapName: spaceport,
      name: 'Fuel Lines',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'spaceport_fuel_storage',
      mapName: spaceport,
      name: 'Fuel Storage',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.electrical],
    ),
    ArcPoiData(
      id: 'spaceport_maintenance_hangar',
      mapName: spaceport,
      name: 'Maintenance Hangar',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.mechanical, ArcBuildingType.industrial],
    ),
    ArcPoiData(
      id: 'spaceport_cargo_elevator',
      mapName: spaceport,
      name: 'Cargo Elevator',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
      notes: 'Map marker / interaction point.',
    ),
    ArcPoiData(
      id: 'spaceport_raider_hatch',
      mapName: spaceport,
      name: 'Raider Hatch',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
      notes: 'Map marker / interaction point.',
    ),
    ArcPoiData(
      id: 'spaceport_baron_husk',
      mapName: spaceport,
      name: 'Baron Husk',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security],
      notes: 'Named encounter / source marker.',
    ),
    ArcPoiData(
      id: 'spaceport_crashed_arc_probe',
      mapName: spaceport,
      name: 'Crashed ARC Probe',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.arc, ArcBuildingType.technological],
      notes: 'Map marker / interaction point.',
    ),
    ArcPoiData(
      id: 'spaceport_field_depot',
      mapName: spaceport,
      name: 'Field Depot',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial],
      notes: 'Map marker / interaction point.',
    ),
    ArcPoiData(
      id: 'spaceport_supply_call_station',
      mapName: spaceport,
      name: 'Supply Call Station',
      sourceType: ArcDropSourceType.other,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.exodus, ArcBuildingType.technological],
      notes: 'Map marker / interaction point.',
    ),
  ];

  static const List<ArcPoiData> buriedCityWeaponCachePois = [
    ArcPoiData(
      id: 'buried_city_weapon_cache_town_hall_broken_bridge',
      mapName: buriedCity,
      name: 'Weapon Cache – Town Hall Broken Bridge',
      areaName: 'Town Hall',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.security],
      notes: 'Player-reported weapon cache spawn on the broken bridge near Town Hall.',
    ),
    ArcPoiData(
      id: 'buried_city_weapon_cache_library_rooftop',
      mapName: buriedCity,
      name: 'Weapon Cache – Library Rooftop',
      areaName: 'Library',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.commercial],
      notes: 'Community guide: rooftop cache spawns on the east and north sides.',
    ),
    ArcPoiData(
      id: 'buried_city_weapon_cache_galleria_sign',
      mapName: buriedCity,
      name: 'Weapon Cache – Galleria Sign',
      areaName: 'Galleria',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.oldWorld],
      notes: 'Community guide: zipline access near the large Galleria sign.',
    ),
    ArcPoiData(
      id: 'buried_city_weapon_cache_marano_station_bus',
      mapName: buriedCity,
      name: 'Weapon Cache – Marano Station Bus',
      areaName: 'Marano Station',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.exodus],
      notes: 'Community guide: broken bus northeast of the barricaded door.',
    ),
    ArcPoiData(
      id: 'buried_city_weapon_cache_parking_garage_raider_camp',
      mapName: buriedCity,
      name: 'Weapon Cache – Parking Garage Raider Camp',
      areaName: 'Parking Garage',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.oldWorld],
      notes: 'Community guide: raider camp reached via the barricaded door and elevator shaft.',
    ),
  ];

  static const List<ArcPoiData> damWeaponCachePois = [
    ArcPoiData(
      id: 'dam_weapon_cache_control_tower_key_room',
      mapName: damBattlegrounds,
      name: 'Weapon Cache – Control Tower Key Room',
      areaName: 'Research & Administration',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
      notes: 'Community guide: near the consoles and left of the stairs by the lockers.',
    ),
    ArcPoiData(
      id: 'dam_weapon_cache_control_tower_lower_floor',
      mapName: damBattlegrounds,
      name: 'Weapon Cache – Control Tower Lower Floor',
      areaName: 'Research & Administration',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
      notes: 'Community guide: under the stairs on the lower floor.',
    ),
    ArcPoiData(
      id: 'dam_weapon_cache_red_lakes_balcony_sewer_entrance',
      mapName: damBattlegrounds,
      name: 'Weapon Cache – Red Lakes Balcony Sewer Entrance',
      areaName: 'Red Lakes',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.nature, ArcBuildingType.industrial],
      notes: 'Community guide: sewer route under the Control Tower back entrance.',
    ),
    ArcPoiData(
      id: 'dam_weapon_cache_hydroponic_southwest',
      mapName: damBattlegrounds,
      name: 'Weapon Cache – Hydroponic Southwest Building',
      areaName: 'Hydroponic Dome Complex',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.technological],
      notes: 'Community guide: westmost part of the building and near the dirty pools.',
    ),
    ArcPoiData(
      id: 'dam_weapon_cache_hydroponic_eastern_building',
      mapName: damBattlegrounds,
      name: 'Weapon Cache – Hydroponic Eastern Building',
      areaName: 'Hydroponic Dome Complex',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.technological],
      notes: 'Community guide: on the scaffolding shelf just inside the south entrance.',
    ),
  ];

  static const List<ArcPoiData> blueGateWeaponCachePois = [
    ArcPoiData(
      id: 'blue_gate_weapon_cache_checkpoint_between_rails',
      mapName: blueGate,
      name: 'Weapon Cache – Checkpoint Between Rails',
      areaName: 'Checkpoint',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.oldWorld],
      notes: 'Community guide: rail between the two broken roads with abandoned cars.',
    ),
    ArcPoiData(
      id: 'blue_gate_weapon_cache_concrete_beams',
      mapName: blueGate,
      name: 'Weapon Cache – Concrete Beams',
      areaName: 'Underground Entrance',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.arc],
      notes: 'Community guide: zipline-access concrete beams above the underground entrance.',
    ),
    ArcPoiData(
      id: 'blue_gate_weapon_cache_pilgrims_peak_top',
      mapName: blueGate,
      name: 'Weapon Cache – Pilgrim\'s Peak Top',
      areaName: 'Pilgrim\'s Peak',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.nature],
      notes: 'Community guide: top of Pilgrim\'s Peak.',
    ),
    ArcPoiData(
      id: 'blue_gate_weapon_cache_data_vault',
      mapName: blueGate,
      name: 'Weapon Cache – Data Vault',
      areaName: 'Data Vault',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.arc, ArcBuildingType.security],
      notes: 'Community guide: below the turret after heading down the stairs and turning right.',
    ),
    ArcPoiData(
      id: 'blue_gate_weapon_cache_traffic_tunnel_right_end',
      mapName: blueGate,
      name: 'Weapon Cache – Traffic Tunnel Right End',
      areaName: 'Traffic Tunnel',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.oldWorld],
      notes: 'Community guide: dead end of the right road in the tunnel.',
    ),
    ArcPoiData(
      id: 'blue_gate_weapon_cache_headhouse_rims',
      mapName: blueGate,
      name: 'Weapon Cache – Headhouse Rims',
      areaName: 'Headhouse',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.arc, ArcBuildingType.security],
      notes: 'Community guide: outer rims above the traffic tunnel, sometimes guarded by turrets.',
    ),
    ArcPoiData(
      id: 'blue_gate_weapon_cache_mantikor_room',
      mapName: blueGate,
      name: 'Weapon Cache – Mantikor Room',
      areaName: 'Mantikor Room',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.arc, ArcBuildingType.security],
      notes: 'Community guide: fuel-cell room accessed from Reinforced Reception.',
    ),
  ];

  static const List<ArcPoiData> spaceportWeaponCachePois = [
    ArcPoiData(
      id: 'spaceport_weapon_cache_departure_building_showers',
      mapName: spaceport,
      name: 'Weapon Cache – Departure Building Showers',
      areaName: 'Departure Building',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.technological],
      notes: 'Community guide: shower area near reception.',
    ),
    ArcPoiData(
      id: 'spaceport_weapon_cache_arrival_building_roof',
      mapName: spaceport,
      name: 'Weapon Cache – Arrival Building Roof',
      areaName: 'Arrival Building',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.commercial, ArcBuildingType.technological],
      notes: 'Community guide: ladder access outside near the Shipping Warehouse side.',
    ),
    ArcPoiData(
      id: 'spaceport_weapon_cache_launch_towers_top',
      mapName: spaceport,
      name: 'Weapon Cache – Launch Towers Top',
      areaName: 'Launch Towers',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.technological, ArcBuildingType.security],
      notes: 'Community guide: top level spawns under the stairs or near the railings facing the rocket shaft.',
    ),
    ArcPoiData(
      id: 'spaceport_weapon_cache_fuel_lines_pipe',
      mapName: spaceport,
      name: 'Weapon Cache – Fuel Lines Pipe',
      areaName: 'Fuel Lines',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.electrical],
      notes: 'Community guide: climb inside the vertical cylindrical pipe east of the nearby Field Depot.',
    ),
    ArcPoiData(
      id: 'spaceport_weapon_cache_east_container_yard',
      mapName: spaceport,
      name: 'Weapon Cache – East Container Yard',
      areaName: 'East Container Yard',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.commercial],
      notes: 'Community guide: lower container yard between the two catwalks east of the raider hatch.',
    ),
    ArcPoiData(
      id: 'spaceport_weapon_cache_tunnels_console_room',
      mapName: spaceport,
      name: 'Weapon Cache – Spaceport Tunnels Console Room',
      areaName: 'Spaceport Tunnels',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.technological],
      notes: 'Community guide: usually in the console rooms or the southeast tunnel camp.',
    ),
  ];

  static const List<ArcPoiData> stellaWeaponCachePois = [
    ArcPoiData(
      id: 'stella_weapon_cache_medical_research_servers',
      mapName: stellaMontis,
      name: 'Weapon Cache – Medical Research Servers',
      areaName: 'Medical Research',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.medical, ArcBuildingType.technological],
      notes: 'Community guide: on top of the server banks in the northern part of the area.',
    ),
    ArcPoiData(
      id: 'stella_weapon_cache_seed_vault_left_hallway',
      mapName: stellaMontis,
      name: 'Weapon Cache – Seed Vault Left Hallway',
      areaName: 'Seed Vault',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.technological, ArcBuildingType.security],
      notes: 'Community guide: inside after opening the fuel-cell door and hugging the left wall.',
    ),
    ArcPoiData(
      id: 'stella_weapon_cache_assembly_hanging_thruster',
      mapName: stellaMontis,
      name: 'Weapon Cache – Assembly Hanging Thruster',
      areaName: 'Assembly Workshops',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.mechanical],
      notes: 'Community guide: inside the hanging thruster.',
    ),
    ArcPoiData(
      id: 'stella_weapon_cache_lobby_security_bridge',
      mapName: stellaMontis,
      name: 'Weapon Cache – Lobby Security Bridge',
      areaName: 'Lobby',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.security, ArcBuildingType.exodus],
      notes: 'Community guide: right side of the Security Bridge.',
    ),
    ArcPoiData(
      id: 'stella_weapon_cache_auditorium_teacher_desk',
      mapName: stellaMontis,
      name: 'Weapon Cache – Auditorium Teacher Desk',
      areaName: 'Auditorium',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.oldWorld, ArcBuildingType.commercial],
      notes: 'Community guide: behind or in front of the teacher\'s desk.',
    ),
    ArcPoiData(
      id: 'stella_weapon_cache_cargo_docks_railcar',
      mapName: stellaMontis,
      name: 'Weapon Cache – Cargo Docks Railcar',
      areaName: 'Cargo Docks',
      sourceType: ArcDropSourceType.poi,
      lootLevel: ArcLootLevel.none,
      buildingTypes: [ArcBuildingType.industrial, ArcBuildingType.exodus],
      notes: 'Community guide: lying on the railcar between Cargo Dock A and B.',
    ),
  ];


  static const List<ArcEnemySource> commonEnemySources = [
    ArcEnemySource(id: 'enemy_surveyor', name: 'Surveyor'),
    ArcEnemySource(id: 'enemy_raider', name: 'Raider'),
    ArcEnemySource(id: 'enemy_turret', name: 'Turret'),
    ArcEnemySource(id: 'enemy_drone', name: 'Drone'),
    ArcEnemySource(id: 'enemy_assessor', name: 'Assessor'),
  ];

  static const Map<String, List<ArcPoiData>> poisByMap = {
    buriedCity: [...buriedCityPois, ...buriedCityWeaponCachePois],
    damBattlegrounds: [...damBattlegroundPois, ...damWeaponCachePois],
    stellaMontis: [...stellaMontisPois, ...stellaWeaponCachePois],
    blueGate: [...blueGatePois, ...blueGateWeaponCachePois],
    spaceport: [...spaceportPois, ...spaceportWeaponCachePois],
  };

  static List<String> get availableMaps =>
      poisByMap.keys.toList(growable: false);

  static List<ArcPoiData> blueprintReportPoisForMap(String mapName) {
    return (poisByMap[mapName] ?? const <ArcPoiData>[])
        .where((poi) => poi.includeInBlueprintReports)
        .toList(growable: false);
  }

  static List<String> blueprintReportAreasForMap(String mapName) {
    final areas = blueprintReportPoisForMap(mapName)
        .map((poi) => poi.resolvedAreaName)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return areas;
  }

  static List<ArcPoiData> blueprintReportPoisForArea(
    String mapName,
    String areaName,
  ) {
    final normalizedArea = areaName.trim().toLowerCase();
    return blueprintReportPoisForMap(mapName)
        .where((poi) => poi.resolvedAreaName.toLowerCase() == normalizedArea)
        .toList(growable: false);
  }

  static ArcPoiData? findPoiById(String mapName, String poiId) {
    for (final poi in poisByMap[mapName] ?? const <ArcPoiData>[]) {
      if (poi.id == poiId) return poi;
    }
    return null;
  }
}
