import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('registers Blue Gate and Buried City in one shared registry', () {
    expect(
      ArcMapAssetRegistry.registeredMaps.map((item) => item.mapId),
      containsAll(<String>['blue_gate', 'buried_city', 'stella_montis']),
    );
    expect(ArcMapAssetRegistry.hasRegisteredAsset('blue_gate'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('buried_city'), isTrue);
    expect(ArcMapAssetRegistry.hasRegisteredAsset('stella_montis'), isTrue);
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

  test('Stella Montis renders its master image but remains provisional', () {
    final map = ArcRaidIntelligenceSeedData.mapById('stella_montis');
    final asset = map.assetForLayer(ArcRaidMapLayer.surface);

    expect(
      asset?.localAssetPath,
      'assets/arc_raiders/maps/stella_montis/stella_montis_master.webp',
    );
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(
      ArcMapAssetRegistry.statusFor('stella_montis'),
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
