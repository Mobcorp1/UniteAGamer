import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('Blue Gate publishes calibrated surface and Level 2 assets', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');

    expect(map.availableLayers, [
      ArcRaidMapLayer.surface,
      ArcRaidMapLayer.underground,
    ]);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.underground), isTrue);
    expect(
      map.assetForLayer(ArcRaidMapLayer.surface)?.localAssetPath,
      'assets/arc_raiders/maps/blue_gate/bluegate_master.webp',
    );
    expect(
      map.assetForLayer(ArcRaidMapLayer.underground)?.localAssetPath,
      'assets/arc_raiders/maps/blue_gate/bluegate_level_2.webp',
    );
    expect(ArcMapAssetRegistry.blueGateAssets.length, 2);
  });

  test('Dam and Spaceport publish provisional renderable map assets', () {
    final dam = ArcRaidIntelligenceSeedData.mapById('dam_battlegrounds');
    final spaceport = ArcRaidIntelligenceSeedData.mapById('spaceport');

    expect(dam.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(dam.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(
      dam.assetForLayer(ArcRaidMapLayer.surface)?.localAssetPath,
      'assets/arc_raiders/maps/dam_battlegrounds/dam_battlegrounds_master.webp',
    );

    expect(spaceport.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(spaceport.hasRenderableLayer(ArcRaidMapLayer.underground), isTrue);
    expect(spaceport.hasCalibratedLayer(ArcRaidMapLayer.surface), isFalse);
    expect(spaceport.hasCalibratedLayer(ArcRaidMapLayer.underground), isFalse);
    expect(
      spaceport.assetForLayer(ArcRaidMapLayer.surface)?.localAssetPath,
      'assets/arc_raiders/maps/spaceport/spaceport_master.webp',
    );
    expect(
      spaceport.assetForLayer(ArcRaidMapLayer.underground)?.localAssetPath,
      'assets/arc_raiders/maps/spaceport/spaceport_level_2.webp',
    );
  });
}
