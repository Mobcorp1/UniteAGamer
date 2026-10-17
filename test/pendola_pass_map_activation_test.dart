import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_preview_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_pendola_pass_verified_map_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('Pendola Pass master is registered and live', () {
    final registration = ArcMapAssetRegistry.registrationFor('Pendola Pass');

    expect(registration, isNotNull);
    expect(registration!.mapId, ArcMapAssetRegistry.pendolaPassMapId);
    expect(registration.hasRenderableAsset, isTrue);
    expect(registration.hasPublishedCalibration, isTrue);
    expect(
      registration.layerAssets[ArcRaidMapLayer.surface]?.localAssetPath,
      ArcPendolaPassVerifiedMapData.masterAssetPath,
    );
    expect(
      File(ArcPendolaPassVerifiedMapData.masterAssetPath).existsSync(),
      isTrue,
    );
  });

  test('Pendola Pass is a live Raid Intelligence map without fake markers', () {
    expect(
      ArcRaidIntelligenceSeedData.supportedMapIds,
      contains(ArcMapAssetRegistry.pendolaPassMapId),
    );

    final map = ArcRaidIntelligenceSeedData.mapById('Pendola Pass');
    expect(map.id, ArcMapAssetRegistry.pendolaPassMapId);
    expect(map.displayName, 'Pendola Pass');
    expect(map.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
    expect(map.hasCalibratedLayer(ArcRaidMapLayer.surface), isTrue);

    expect(map.pois, isEmpty);
    expect(map.regions, isEmpty);
    expect(map.spawnRegions, isEmpty);
    expect(map.hatches, isEmpty);
    expect(map.dataVersion, 'frozen-trail-2.0-pendola-master-2026-10-08-v1');
  });

  test('launch-day Pendola condition knowledge is captured', () {
    expect(
      ArcPendolaPassVerifiedMapData.observedConditions,
      containsAll(<String>['Redirection', 'Frigate']),
    );
    expect(
      ArcFrozenTrailPreviewData.items.map((item) => item.name),
      contains('Redirection'),
    );
    expect(
      ArcPendolaPassVerifiedMapData.verifiedPoiLabelsPendingCoordinates,
      containsAll(<String>[
        'City Hall',
        'Metro Shopping Mall',
        'Castle',
        'Monastery',
        'Train Station',
        'Research Administration',
      ]),
    );
  });

  test('Pendola metadata and identity calibration are valid JSON', () {
    final metadata =
        jsonDecode(
              File(
                'assets/arc_raiders/maps/pendola_pass/metadata.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final calibration =
        jsonDecode(
              File(
                'assets/arc_raiders/maps/pendola_pass/calibration.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(metadata['mapId'], 'pendola_pass');
    expect(metadata['masterAsset'], 'pendola_pass_master.webp');
    expect(metadata['markerStatus'], 'verified coordinates pending');

    expect(calibration['id'], 'pendola_pass_surface_identity_v1');
    expect(calibration['published'], isTrue);
    expect((calibration['anchors'] as List<dynamic>), hasLength(4));
  });
}
