import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_loot_intel_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_personal_need_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  const resolver = ArcPoiPersonalNeedResolver();
  test('no active needs means no recommendations', () {
    expect(resolver.matchVisibleMarkers(markers: const [], trackedObjectives: const [], blueprintStates: const {}), isEmpty);
  });
  test('only exact, active quest needs match a canonical marker', () {
    final entry = ArcPoiLootIntelCatalog.entries.first;
    final poiMarker = ArcRaidMapMarker(
      id: 'example', mapId: entry.poiId.startsWith('blue_gate') ? 'blue_gate' : 'buried_city',
      category: ArcRaidMapMarkerCategory.poi,
      label: 'Not A Canonical POI', point: const ArcNormalizedPoint(x: 0.5, y: 0.5),
    );
    final matched = resolver.matchVisibleMarkers(
      markers: [poiMarker],
      trackedObjectives: [ArcRaidObjective(id: 'need', label: entry.itemName, reason: 'Quest', category: ArcRaidMapMarkerCategory.questObjective, itemName: entry.itemName, missingCount: 1, system: 'Quest')],
      blueprintStates: const {},
    );
    expect(matched, isEmpty);
  });
  test('active quest need highlights a real canonical POI marker', () {
    final entry = ArcPoiLootIntelCatalog.entries.first;
    final poi = ArcPoiDataStore.poisByMap.values
        .expand((items) => items)
        .firstWhere((candidate) => candidate.id == entry.poiId);
    final mapId = poi.mapName.toLowerCase().replaceAll('the ', '').replaceAll(' ', '_');
    final marker = ArcRaidMapMarker(
      id: 'canonical', mapId: mapId,
      category: ArcRaidMapMarkerCategory.poi,
      label: poi.name, payloadId: poi.id,
      point: const ArcNormalizedPoint(x: 0.5, y: 0.5),
    );
    final matches = resolver.matchVisibleMarkers(
      markers: [marker],
      trackedObjectives: [ArcRaidObjective(
        id: 'quest-need', label: entry.itemName, reason: 'Quest material',
        category: ArcRaidMapMarkerCategory.questObjective,
        itemName: entry.itemName, missingCount: 2, system: 'Quest',
      )],
      blueprintStates: const {},
    );
    expect(matches['canonical'], isNotEmpty);
    expect(matches['canonical']!.first.itemName, entry.itemName);
  });
  test('owned or unprioritised blueprints are excluded', () {
    final blueprint = ArcBlueprintSeedData.blueprints.first;
    final states = {
      blueprint.id: ArcBlueprintState.empty(blueprint.id),
    };
    expect(resolver.matchVisibleMarkers(markers: const [], trackedObjectives: const [], blueprintStates: states), isEmpty);
  });
  test('loot catalogue only contains known canonical POI ids', () {
    expect(ArcPoiLootIntelCatalog.entries, isNotEmpty);
  });
}
