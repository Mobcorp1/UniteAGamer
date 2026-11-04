import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_universal_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_route_candidate_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

const engine = ArcUniversalIntelligenceEngine();
const point = ArcNormalizedPoint(x: 0.4, y: 0.5);

ArcRaidMapMarker pin(String id, String map, ArcRaidMapMarkerCategory category,
    String label, {List<String> tags = const []}) => ArcRaidMapMarker(
  id: id, mapId: map, category: category, label: label, point: point, tags: tags);

ArcRaidObjective goal(String id, String item, {String system = 'Bench',
    bool location = false, String? questId, double weight = 1}) => ArcRaidObjective(
  id: id, label: item, reason: 'Needed',
  category: ArcRaidMapMarkerCategory.operationObjective,
  system: system, itemName: item, missingCount: location ? 0 : 1,
  weight: weight, questLocationOnly: location, questId: questId);

void main() {
  test('future resource pins resolve automatically from item metadata', () {
    final results = engine.matchesForMarker(
      marker: pin('great-mullein-pin', 'blue_gate', ArcRaidMapMarkerCategory.upgrade,
        'Great Mullein', tags: ['uag:item:great-mullein']),
      objectives: [goal('bench', 'Great Mullein')],
    );
    expect(results, hasLength(1));
    expect(results.single.evidence, ArcUniversalEvidence.explicitMarker);
  });

  test('Bastion and Bombardier names match own components but not another unit', () {
    final bastion = pin('b', 'blue_gate', ArcRaidMapMarkerCategory.arcThreat, 'Bastion',
      tags: ['uag:subtype:bastion']);
    final results = engine.matchesForMarker(marker: bastion,
      objectives: [goal('cell', 'Bastion Cell'), goal('other', 'Bombardier Cell')]);
    expect(results.map((r) => r.objective.id), contains('cell'));
    expect(results.map((r) => r.objective.id), isNot(contains('other')));
    expect(results.single.evidence, ArcUniversalEvidence.inferredSource);
  });

  test('named canonical POI contributes only to its map', () {
    final marker = pin('olive-poi', 'blue_gate', ArcRaidMapMarkerCategory.poi,
      'Olive Grove', tags: const []);
    final linked = ArcRaidMapMarker(
      id: marker.id, mapId: marker.mapId, category: marker.category,
      label: marker.label, point: marker.point,
      payloadId: 'blue_gate_olive_grove');
    final matches = engine.matchesForMarker(marker: linked,
      objectives: [goal('nature', 'Great Mullein')]);
    expect(matches.map((m) => m.objective.id), contains('nature'));
    expect(matches.first.evidence, ArcUniversalEvidence.researchedPool);
  });

  test('quest markers require exact bound quest ID', () {
    final quest = goal('questloc', 'Quest location', location: true,
      questId: 'quest-alpha', system: 'Quest');
    expect(engine.matchesForMarker(marker: pin('q', 'blue_gate',
      ArcRaidMapMarkerCategory.questObjective, 'Quest area',
      tags: ['uag:quest:quest-alpha']), objectives: [quest]), hasLength(1));
    expect(engine.matchesForMarker(marker: pin('q2', 'blue_gate',
      ArcRaidMapMarkerCategory.questObjective, 'Quest area',
      tags: ['uag:quest:quest-beta']), objectives: [quest]), isEmpty);
  });

  test('map scores reward unique quest and resources over duplicate ARC pins', () {
    final markers = [
      pin('b1', 'blue_gate', ArcRaidMapMarkerCategory.arcThreat, 'Bastion',
        tags: ['uag:subtype:bastion']),
      pin('quest', 'blue_gate', ArcRaidMapMarkerCategory.questObjective, 'Quest area',
        tags: ['uag:quest:quest-alpha']),
      pin('m', 'blue_gate', ArcRaidMapMarkerCategory.upgrade, 'Great Mullein',
        tags: ['uag:item:great-mullein']),
      pin('b2', 'buried_city', ArcRaidMapMarkerCategory.arcThreat, 'Bastion',
        tags: ['uag:subtype:bastion']),
      pin('b3', 'buried_city', ArcRaidMapMarkerCategory.arcThreat, 'Bastion',
        tags: ['uag:subtype:bastion']),
    ];
    final scores = engine.rankMaps(publishedMarkers: markers, objectives: [
      goal('cell', 'Bastion Cell'),
      goal('mullein', 'Great Mullein'),
      goal('quest', 'Quest location', system: 'Quest', location: true, questId: 'quest-alpha'),
    ]);
    expect(scores.first.mapId, 'blue_gate');
    expect(scores.first.objectiveCount, 3);
    expect(scores.last.objectiveCount, 1);
  });

  test('no needs creates no map recommendation; no fictitious location', () {
    expect(engine.rankMaps(publishedMarkers: [
      pin('b', 'blue_gate', ArcRaidMapMarkerCategory.arcThreat, 'Bastion'),
    ], objectives: const []), isEmpty);
  });

  test('smart run limits duplicate single-item ARC source stops', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final markers = List.generate(7, (i) => pin('b$i', 'blue_gate',
      ArcRaidMapMarkerCategory.arcThreat, 'Bastion', tags: ['uag:subtype:bastion']));
    final candidates = const ArcPersonalRouteCandidateEngine().build(
      map: map, layer: ArcRaidMapLayer.surface,
      markers: markers, personalMatches: const {},
      trackedObjectives: [goal('cell', 'Bastion Cell')]);
    expect(candidates, hasLength(1));
  });

  test('research expansion uses exact catalogue recipes only', () {
    final unknown = engine.expandObjectives([goal('x', 'Uncatalogued Craft')]);
    expect(unknown, hasLength(1));
    final research = engine.expandObjectives([goal('r', 'Magazine Geometry 101')]);
    expect(research.any((r) => r.itemName == 'Bastion Cell'), isTrue);
  });
}
