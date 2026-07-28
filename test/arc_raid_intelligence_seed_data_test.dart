import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  group('ArcRaidIntelligenceSeedData', () {
    test(
      'loads Blue Gate as calibrated production data and keeps schematic fallbacks',
      () {
        final maps = ArcRaidIntelligenceSeedData.maps;

        expect(
          maps.map((map) => map.id),
          containsAll(ArcRaidIntelligenceSeedData.supportedMapIds),
        );
        expect(maps, hasLength(6));

        for (final map in maps) {
          expect(map.publicationState, ArcRaidMapPublicationState.published);

          if (map.id == 'blue_gate') {
            expect(map.hasCalibratedMap, isTrue);
            expect(
              map.availableLayers,
              containsAll(const [
                ArcRaidMapLayer.surface,
                ArcRaidMapLayer.underground,
              ]),
            );
            expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isTrue);
            expect(map.hasCalibratedLayer(ArcRaidMapLayer.underground), isTrue);
          } else {
            expect(map.hasCalibratedMap, isFalse);
            expect(map.schematicLabel, contains('Tactical schematic'));
          }

          if (map.id == 'riven_tides') {
            expect(map.hasRenderableMap, isTrue);
            expect(
              map.assetForLayer(ArcRaidMapLayer.surface)?.localAssetPath,
              'assets/arc_raiders/maps/riven_tides/riven_tides_master.webp',
            );
            expect(map.dataVersion, 'pass-294-riven-tides-provisional-v1');
          }

          if (map.id == 'dam_battlegrounds') {
            expect(map.hasRenderableMap, isTrue);
            expect(
              map.assetForLayer(ArcRaidMapLayer.surface)?.localAssetPath,
              'assets/arc_raiders/maps/dam_battlegrounds/dam_battlegrounds_master.webp',
            );
            expect(
              map.dataVersion,
              'pass-294-dam-battlegrounds-provisional-v1',
            );
          }

          if (map.id == 'spaceport') {
            expect(map.hasRenderableMap, isTrue);
            expect(
              map.availableLayers,
              containsAll(const [
                ArcRaidMapLayer.surface,
                ArcRaidMapLayer.underground,
              ]),
            );
            expect(
              map.assetForLayer(ArcRaidMapLayer.surface)?.localAssetPath,
              'assets/arc_raiders/maps/spaceport/spaceport_master.webp',
            );
            expect(
              map.assetForLayer(ArcRaidMapLayer.underground)?.localAssetPath,
              'assets/arc_raiders/maps/spaceport/spaceport_level_2.webp',
            );
            expect(
              map.dataVersion,
              'pass-294-spaceport-two-layer-provisional-v1',
            );
          }

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
      },
    );

    test('Blue Gate includes calibrated production POI markers', () {
      final blueGate = ArcRaidIntelligenceSeedData.mapById('blue_gate');
      final productionPois = blueGate.markers.where(
        (marker) =>
            marker.category == ArcRaidMapMarkerCategory.poi &&
            marker.approximate == false,
      );

      expect(productionPois.length, greaterThanOrEqualTo(10));
      expect(
        productionPois.map((marker) => marker.label),
        containsAll(<String>[
          'Raider Refuge',
          "Trapper's Glade",
          'Ancient Fort',
          'Warehouse Complex',
        ]),
      );
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
