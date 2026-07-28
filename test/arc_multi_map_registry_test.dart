import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('registers Blue Gate and Buried City in one shared registry', () {
    expect(
      ArcMapAssetRegistry.registeredMaps.map((item) => item.mapId),
      containsAll(<String>[
        'blue_gate',
        'buried_city',
        'dam_battlegrounds',
        'stella_montis',
        'riven_tides',
        'spaceport',
      ]),
    );
    expect(ArcMapAssetRegistry.hasRegisteredAsset('blue_gate'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('buried_city'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('dam_battlegrounds'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('stella_montis'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('riven_tides'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('spaceport'), isTrue);
  });

  test('Buried City renders its master image but remains provisional', () {
    final map = ArcRaidIntelligenceSeedData.mapById('buried_city');
    final asset = map.assetForLayer(ArcRaidMapLayer.surface);

    expect(
      asset?.localAssetPath,
      'assets/arc_raiders/maps/buried_city/buried_city_master.webp',
    );
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(
      ArcMapAssetRegistry.statusFor('buried_city'),
      'Provisional map image',
    );
  });

  test('Stella Montis exposes both provisional map layers', () {
    final map = ArcRaidIntelligenceSeedData.mapById('stella_montis');
    final surface = map.assetForLayer(ArcRaidMapLayer.surface);
    final underground = map.assetForLayer(ArcRaidMapLayer.underground);

    expect(
      surface?.localAssetPath,
      'assets/arc_raiders/maps/stella_montis/stella_montis_master.webp',
    );
    expect(
      underground?.localAssetPath,
      'assets/arc_raiders/maps/stella_montis/stella_montis_level_2.webp',
    );
    expect(
      map.availableLayers,
      containsAll(<ArcRaidMapLayer>[
        ArcRaidMapLayer.surface,
        ArcRaidMapLayer.underground,
      ]),
    );
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasRenderableLayer(ArcRaidMapLayer.underground), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.underground), isFalse);
    expect(
      ArcMapAssetRegistry.statusFor('stella_montis'),
      'Provisional map image',
    );
  });

  test('Dam Battlegrounds renders its master image but remains provisional', () {
    final map = ArcRaidIntelligenceSeedData.mapById('dam_battlegrounds');
    final asset = map.assetForLayer(ArcRaidMapLayer.surface);

    expect(
      asset?.localAssetPath,
      'assets/arc_raiders/maps/dam_battlegrounds/dam_battlegrounds_master.webp',
    );
    expect(map.availableLayers, [ArcRaidMapLayer.surface]);
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(
      ArcMapAssetRegistry.statusFor('dam_battlegrounds'),
      'Provisional Alignment',
    );
  });

  test('Spaceport exposes provisional surface and Level 2 map layers', () {
    final map = ArcRaidIntelligenceSeedData.mapById('spaceport');
    final surface = map.assetForLayer(ArcRaidMapLayer.surface);
    final underground = map.assetForLayer(ArcRaidMapLayer.underground);

    expect(
      surface?.localAssetPath,
      'assets/arc_raiders/maps/spaceport/spaceport_master.webp',
    );
    expect(
      underground?.localAssetPath,
      'assets/arc_raiders/maps/spaceport/spaceport_level_2.webp',
    );
    expect(
      map.availableLayers,
      containsAll(<ArcRaidMapLayer>[
        ArcRaidMapLayer.surface,
        ArcRaidMapLayer.underground,
      ]),
    );
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasRenderableLayer(ArcRaidMapLayer.underground), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.underground), isFalse);
    expect(ArcMapAssetRegistry.statusFor('spaceport'), 'Provisional Alignment');
  });

  test('Riven Tides renders its master image but remains provisional', () {
    final map = ArcRaidIntelligenceSeedData.mapById('riven_tides');
    final asset = map.assetForLayer(ArcRaidMapLayer.surface);

    expect(
      asset?.localAssetPath,
      'assets/arc_raiders/maps/riven_tides/riven_tides_master.webp',
    );
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(
      ArcMapAssetRegistry.statusFor('riven_tides'),
      'Provisional map image',
    );
  });

  test('Blue Gate remains fully calibrated', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');

    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isTrue);
    expect(ArcMapAssetRegistry.statusFor('blue_gate'), 'Calibrated');
  });
}
