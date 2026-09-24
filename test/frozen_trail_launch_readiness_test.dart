import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_subtype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_preview_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_network_liquidity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_control_config.dart';

void main() {
  test('Frozen Trail and Research Workstation are prewired', () {
    expect(ArcFrozenTrailPreviewData.updateName, 'Frozen Trail');
    expect(ArcFrozenTrailPreviewData.mapName, 'Pendola Pass');
    expect(
      ArcFrozenTrailPreviewData.researchWorkstation.name,
      'Research Workstation',
    );
    expect(
      ArcFrozenTrailPreviewData.items.map((item) => item.name),
      containsAll(<String>[
        'Frigate',
        'Bully',
        'Skulker',
        'Hydra',
        'Stiletto',
        'Bantam',
        'Grappling Hook',
        'Tether Launcher',
        'Yank Grenade',
        'Camera',
        'Outpost',
        'Amplified Weapons',
      ]),
    );
  });

  test(
    'Pendola Pass is prewired but not promoted to live Raid Intelligence',
    () {
      expect(
        ArcMapAssetRegistry.canonicalMapIdFor('Pendola Pass'),
        ArcMapAssetRegistry.pendolaPassMapId,
      );
      expect(
        ArcMapAssetRegistry.registeredMapIds,
        contains(ArcMapAssetRegistry.pendolaPassMapId),
      );
      expect(
        ArcRaidIntelligenceSeedData.supportedMapIds,
        isNot(contains(ArcMapAssetRegistry.pendolaPassMapId)),
      );
    },
  );

  test('new ARC marker types exist', () {
    final ids = ArcAdminMapMarkerSubtypeCatalog.arc.map((item) => item.id);
    expect(ids, containsAll(<String>['bully', 'skulker', 'hydra']));
  });

  test('Blueprint expansion is bounded and canonical list stays unchanged', () {
    final canonical = ArcBlueprintSeedData.blueprints.length;
    expect(ArcBlueprintSeedData.withExpansionSlots(7).length, canonical + 7);
    expect(ArcBlueprintSeedData.withExpansionSlots(100).length, canonical + 30);
    expect(ArcBlueprintSeedData.blueprints.length, canonical);
    expect(
      ArcAdminControlConfig.fromDocument(<String, dynamic>{
        'blueprintExpansionSlots': 11,
      }).blueprintExpansionSlots,
      11,
    );
  });

  test('network liquidity finds reciprocal trade pair', () {
    final result = const ArcNetworkLiquidityEngine().calculate(
      listings: <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'open',
          'userId': 'a',
          'offeredBlueprintId': 'anvil',
          'wantedBlueprintId': 'bobcat',
        },
        <String, dynamic>{
          'status': 'open',
          'userId': 'b',
          'offeredBlueprintId': 'bobcat',
          'wantedBlueprintId': 'anvil',
        },
      ],
      profiles: <Map<String, dynamic>>[
        <String, dynamic>{
          'visibleInSearch': true,
          'region': 'EU',
          'platform': 'PS5',
          'crossplayEnabled': true,
        },
        <String, dynamic>{
          'visibleInSearch': true,
          'region': 'EU',
          'platform': 'PC',
          'crossplayEnabled': true,
        },
      ],
    );
    expect(result.activeTraders, 2);
    expect(result.alignedListingPairs, 1);
    expect(result.reciprocalTradePairs, 1);
    expect(result.potentialCandidatePairs, 1);
  });
}
