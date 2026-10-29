import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_two_content.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_asset_registry.dart';

void main() {
  const expectedItems = <String, String>{
    'planks': 'planks',
    'battered-paperbacks': 'battered_paperbacks',
    'calculators': 'calculators',
    'skulker-targeters': 'skulker_targeters',
    'differential-microphones': 'differential_microphones',
    'bully-fragmenters': 'bully_fragmenters',
  };

  group('Research Station resource art', () {
    for (final entry in expectedItems.entries) {
      test('${entry.key} uses canonical item artwork', () {
        final expectedPath = 'assets/arc_raiders/items/${entry.value}.webp';
        expect(ArcItemAssetRegistry.assetPathForId(entry.key), expectedPath);
        expect(
          ArcItemAssetRegistry.assetPathForId(entry.key.replaceAll('-', '_')),
          expectedPath,
        );
        expect(
          ArcItemAssetRegistry.targetItemAssetPathForId(entry.key),
          expectedPath,
        );

        final catalogItem = ArcFrozenTrailTwoContent.items.firstWhere(
          (item) => item.id == entry.value,
        );
        expect(catalogItem.imageAsset, expectedPath);
      });
    }

    test('singular names resolve to the same assets', () {
      const aliases = <String, String>{
        'plank': 'planks',
        'battered-paperback': 'battered_paperbacks',
        'calculator': 'calculators',
        'skulker-targeter': 'skulker_targeters',
        'differential-microphone': 'differential_microphones',
        'bully-fragmenter': 'bully_fragmenters',
      };
      for (final entry in aliases.entries) {
        expect(
          ArcItemAssetRegistry.assetPathForId(entry.key),
          'assets/arc_raiders/items/${entry.value}.webp',
        );
      }
    });

    test('unillustrated research resources retain neutral pending art', () {
      for (final id in <String>[
        'mini_pumps',
        'raider_logbooks',
        'exodus_technical_handbooks',
        'thermal_shakers',
        'arc_data_modules',
        'frigate_inductors',
      ]) {
        expect(
          ArcItemAssetRegistry.assetPathForId(id),
          ArcItemAssetRegistry.upgradeArtworkPending,
        );
      }
    });

    test('existing Scrappy and bench artwork paths are unchanged', () {
      expect(
        ArcItemAssetRegistry.assetPathForId('metal_parts'),
        'assets/arc_raiders/scrappy_resources/metal_parts.webp',
      );
      expect(
        ArcItemAssetRegistry.dogCollar,
        'assets/arc_raiders/scrappy_resources/dog_collar.webp',
      );
      expect(
        ArcItemAssetRegistry.assetPathForId('magnetic_accelerators'),
        'assets/arc_raiders/scrappy_resources/magnetic_accelerator.webp',
      );
    });
  });
}
