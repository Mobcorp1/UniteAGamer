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
}
