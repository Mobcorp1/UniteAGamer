import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_subtype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_visual_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';

void main() {
  test('PASS 355 wires newly supplied map marker artwork', () {
    const expected = <String, String>{
      'infra_button': 'button.webp',
      'infra_fuel_cell': 'fuel_cell.webp',
      'infra_supply_station': 'supply_call_station.webp',
      'infra_raider_camp': 'raider_camp.webp',
      'infra_player_spawn': 'player_spawn.webp',
      'loot_combat_supply': 'combat_supply.webp',
      'access_key_room': 'key_room.webp',
      'access_breach_room': 'breach_room.webp',
      'community_report_rat': 'rat.webp',
      'community_hunt_rat': 'hunt_a_rat.webp',
    };

    for (final entry in expected.entries) {
      expect(
        ArcMapFilterIconRegistry.tryAssetPathFor(entry.key),
        '${ArcMapFilterIconRegistry.assetDirectory}/${entry.value}',
        reason: entry.key,
      );
    }
  });

  test('PASS 355 exposes Rat report and active contract separately', () {
    final reported = ArcMapFilterTaxonomy.byId('reported_rat');
    final contract = ArcMapFilterTaxonomy.byId('hunt_a_rat');

    expect(reported, isNotNull);
    expect(reported!.iconKey, 'community_report_rat');
    expect(reported.kind, ArcAdminMapMarkerKind.customIntel);

    expect(contract, isNotNull);
    expect(contract!.iconKey, 'community_hunt_rat');
    expect(contract.kind, ArcAdminMapMarkerKind.customIntel);

    final adminOptions = ArcAdminMapMarkerSubtypeCatalog.forKind(
      ArcAdminMapMarkerKind.customIntel,
    );
    expect(adminOptions.map((item) => item.id), contains('reported_rat'));
    expect(adminOptions.map((item) => item.id), contains('hunt_a_rat'));
  });

  test('PASS 355 admin visual registry resolves new marker subtypes', () {
    const expected = <String, String>{
      'button': 'button.webp',
      'fuel_cell': 'fuel_cell.webp',
      'supply_station': 'supply_call_station.webp',
      'raider_camp': 'raider_camp.webp',
      'player_spawn': 'player_spawn.webp',
      'combat_supply': 'combat_supply.webp',
      'key_room': 'key_room.webp',
      'breach_room': 'breach_room.webp',
      'reported_rat': 'rat.webp',
      'hunt_a_rat': 'hunt_a_rat.webp',
      'comet': 'arc_comet.webp',
      'arc_courier': 'arc_courier.webp',
      'turbine': 'arc_turbine.webp',
    };

    for (final entry in expected.entries) {
      expect(
        ArcAdminMarkerVisualRegistry.assetPathForSubtype(entry.key),
        'assets/arc_raiders/map_filter_icons/${entry.value}',
        reason: entry.key,
      );
    }
  });

  test('PASS 355 every map-filter WebP is runtime referenced', () {
    final directory = Directory(ArcMapFilterIconRegistry.assetDirectory);
    expect(directory.existsSync(), isTrue);

    final assets = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.webp'))
        .toList();
    expect(assets, isNotEmpty);

    final runtimePaths = <String>{
      for (final key in ArcMapFilterIconRegistry.rasterIconKeys)
        ?ArcMapFilterIconRegistry.tryAssetPathFor(key),
    };

    for (final file in assets) {
      final normalized = file.path.replaceAll('\\', '/');
      expect(runtimePaths, contains(normalized), reason: normalized);
    }
  });

  test('PASS 355 nature admin markers reuse scrappy resource artwork', () {
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('great_mullein'),
      'assets/arc_raiders/scrappy_resources/great_mullein.webp',
    );
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('mushroom'),
      'assets/arc_raiders/scrappy_resources/mushrooms.webp',
    );
  });
}
