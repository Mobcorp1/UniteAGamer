import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_route_candidate_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_loot_intel_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_personal_need_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  const engine = ArcPersonalRouteCandidateEngine();
  final map = ArcRaidIntelligenceSeedData.mapById('buried_city');
  final marker = ArcRaidMapMarker(
    id: 'published-bastion', mapId: 'buried_city',
    category: ArcRaidMapMarkerCategory.arcThreat,
    label: 'Bastion',
    point: const ArcNormalizedPoint(x: 0.4, y: 0.6),
  );
  final need = ArcRaidObjective(
    id: 'quest:bastion-cell', label: 'Bastion Cell',
    reason: 'Needed for crafting',
    category: ArcRaidMapMarkerCategory.questObjective,
    system: 'Bench', itemName: 'Bastion Cell', missingCount: 2,
  );
  test('not tracked means no autonomous route candidate', () {
    expect(engine.build(map: map, layer: ArcRaidMapLayer.surface,
      markers: [marker], personalMatches: const {}, trackedObjectives: const []), isEmpty);
  });
  test('published Bastion spawn routes to needed Bastion Cells', () {
    final route = engine.build(map: map, layer: ArcRaidMapLayer.surface,
      markers: [marker], personalMatches: const {}, trackedObjectives: [need]);
    expect(route, hasLength(1));
    expect(route.single.objectives.single.id, 'quest:bastion-cell');
    expect(route.single.point.x, 0.4);
  });
  test('non-Bastion ARC spawn does not produce Bastion Cell suggestion', () {
    final other = ArcRaidMapMarker(id: 'other', mapId: 'buried_city',
      category: ArcRaidMapMarkerCategory.arcThreat, label: 'Hornet',
      point: const ArcNormalizedPoint(x: 0.4, y: 0.6));
    expect(engine.build(map: map, layer: ArcRaidMapLayer.surface,
      markers: [other], personalMatches: const {}, trackedObjectives: [need]), isEmpty);
  });
  test('wrong map or layer cannot produce a stop', () {
    expect(engine.build(map: ArcRaidIntelligenceSeedData.mapById('blue_gate'),
      layer: ArcRaidMapLayer.surface, markers: [marker],
      personalMatches: const {}, trackedObjectives: [need]), isEmpty);
  });
  test('POI chance only used for actual tracked need', () {
    final poiMarker = map.markers.where((m) =>
      m.category == ArcRaidMapMarkerCategory.poi &&
      ArcPoiLootIntelCatalog.forMarker(m).isNotEmpty).first;
    final entry = ArcPoiLootIntelCatalog.forMarker(poiMarker).first;
    final matchedNeed = ArcRaidObjective(id: 'quest:item', label: entry.itemName,
      reason: 'Quest', category: ArcRaidMapMarkerCategory.questObjective,
      system: 'Quest', itemName: entry.itemName, missingCount: 1);
    final matches = const ArcPoiPersonalNeedResolver().matchVisibleMarkers(
      markers: [poiMarker], trackedObjectives: [matchedNeed], blueprintStates: const {});
    final candidates = engine.build(map: map, layer: poiMarker.layer,
      markers: [poiMarker], personalMatches: matches, trackedObjectives: [matchedNeed]);
    expect(candidates, hasLength(1));
    expect(candidates.single.point.x, poiMarker.point.x);
  });
}
