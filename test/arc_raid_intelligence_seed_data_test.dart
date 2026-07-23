import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  group('ArcRaidIntelligenceSeedData', () {
    test('loads every official map with schematic fallback data', () {
      final maps = ArcRaidIntelligenceSeedData.maps;

      expect(
        maps.map((map) => map.id),
        containsAll(ArcRaidIntelligenceSeedData.supportedMapIds),
      );
      expect(maps, hasLength(6));

      for (final map in maps) {
        expect(map.publicationState, ArcRaidMapPublicationState.published);
        expect(map.hasCalibratedMap, isFalse);
        expect(map.schematicLabel, contains('Tactical schematic'));
        expect(map.regions, isNotEmpty);
        expect(map.spawnRegions, isNotEmpty);
        expect(map.extractions, isNotEmpty);
        expect(map.hatches, isNotEmpty);
        expect(map.routeNodes, isNotEmpty);
        expect(map.routeEdges, isNotEmpty);
        expect(map.markers, isNotEmpty);

        for (final marker in map.markers) {
          expect(marker.point.x, inInclusiveRange(0, 1));
          expect(marker.point.y, inInclusiveRange(0, 1));
        }
      }
    });

    test('normalises Blue Gate aliases without duplicate map records', () {
      expect(
        ArcRaidIntelligenceSeedData.normalizeMapId('Blue Gate'),
        'blue_gate',
      );
      expect(
        ArcRaidIntelligenceSeedData.normalizeMapId('The Blue Gate'),
        'blue_gate',
      );
      expect(
        ArcRaidIntelligenceSeedData.mapById('The Blue Gate').id,
        ArcRaidIntelligenceSeedData.mapById('blue_gate').id,
      );
    });

    test('provides marker definitions for every supported category', () {
      final categories = ArcRaidIntelligenceSeedData.markerDefinitions
          .map((definition) => definition.category)
          .toSet();

      expect(categories, containsAll(ArcRaidMapMarkerCategory.values));
      expect(
        ArcRaidIntelligenceSeedData.markerDefinitions
            .where((definition) => definition.disabledByDefault)
            .map((definition) => definition.category.filteringGroup)
            .toSet(),
        {'Loot Sources'},
      );
    });
  });
}
