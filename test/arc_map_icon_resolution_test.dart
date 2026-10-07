import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_visual_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';

void main() {
  group('ARC map icon resolution', () {
    test('known working map icons keep their canonical artwork', () {
      expect(
        ArcMapFilterIconRegistry.assetPathForSubtype('player_spawn'),
        'assets/arc_raiders/map_filter_icons/player_spawn.webp',
      );
      expect(
        ArcMapFilterIconRegistry.assetPathForSubtype('great_mullein'),
        'assets/arc_raiders/map_filter_icons/nature_great_mullein.webp',
      );
    });

    test(
      'weapon cache resolves through its dedicated shared artwork alias',
      () {
        expect(
          ArcMapFilterIconRegistry.assetPathForSubtype('weapon_cache'),
          'assets/arc_raiders/map_filter_icons/weapon_case.webp',
        );
        expect(
          ArcMapFilterIconRegistry.tryAssetPathFor('loot_weapon_cache'),
          'assets/arc_raiders/map_filter_icons/weapon_case.webp',
        );
      },
    );

    test('taxonomy icon keys inherit dedicated subtype artwork when needed', () {
      for (final entry in ArcMapFilterTaxonomy.all) {
        final dedicated = ArcAdminMarkerVisualRegistry.assetPathForSubtype(
          entry.id,
        );
        if (dedicated == null) continue;

        final resolved = ArcMapFilterIconRegistry.tryAssetPathFor(
          entry.iconKey,
        );
        expect(
          resolved,
          isNotNull,
          reason:
              '${entry.id} has dedicated artwork ($dedicated), but its taxonomy icon key ${entry.iconKey} does not resolve.',
        );
      }
    });

    test('every dedicated subtype can resolve through the main registry', () {
      for (final subtypeId
          in ArcAdminMarkerVisualRegistry.dedicatedSubtypeIds) {
        final path = ArcMapFilterIconRegistry.assetPathForSubtype(subtypeId);
        expect(
          path,
          isNotEmpty,
          reason:
              'Dedicated subtype $subtypeId is not reachable through the main map icon registry.',
        );
        expect(
          File(path).existsSync(),
          isTrue,
          reason:
              'Dedicated subtype $subtypeId resolves to a missing asset: $path',
        );
      }
    });

    test('every dedicated subtype artwork path exists on disk', () {
      for (final path in ArcAdminMarkerVisualRegistry.dedicatedAssetPaths) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Dedicated ARC map marker artwork is missing: $path',
        );
      }
    });

    test('every resolved canonical taxonomy artwork path exists on disk', () {
      for (final entry in ArcMapFilterTaxonomy.all) {
        final path = ArcMapFilterIconRegistry.tryAssetPathFor(entry.iconKey);
        if (path == null || path.isEmpty) continue;
        expect(
          File(path).existsSync(),
          isTrue,
          reason:
              '${entry.id} resolves ${entry.iconKey} to a missing asset: $path',
        );
      }
    });
  });
}
