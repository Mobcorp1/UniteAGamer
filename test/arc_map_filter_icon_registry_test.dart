import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';

void main() {
  test('new in-game map marker artwork resolves to WebP assets', () {
    expect(ArcMapFilterIconRegistry.rasterIconKeys, isNotEmpty);
    for (final iconKey in ArcMapFilterIconRegistry.rasterIconKeys) {
      final path = ArcMapFilterIconRegistry.tryAssetPathFor(iconKey);
      expect(path, isNotNull, reason: iconKey);
      expect(path, endsWith('.webp'), reason: iconKey);
      expect(File(path!).existsSync(), isTrue, reason: path);
    }
  });

  test('taxonomy keys remain stable while unfinished artwork falls back safely', () {
    for (final entry in ArcMapFilterTaxonomy.all) {
      expect(entry.iconKey.trim(), isNotEmpty, reason: entry.id);
      final path = ArcMapFilterIconRegistry.tryAssetPathFor(entry.iconKey);
      if (path != null) expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('core completed marker replacements are wired', () {
    const expected = <String, String>{
      'extract_standard': 'extraction_point.webp',
      'extract_raider_hatch': 'raider_hatch.webp',
      'infra_field_depot': 'field_depot.webp',
      'infra_zipline': 'zipline.webp',
      'loot_weapon_case': 'weapon_case.webp',
      'loot_security_locker': 'security_locker.webp',
      'loot_raider_cache': 'raider_cache.webp',
      'loot_field_crate': 'field_crate.webp',
      'loot_ammo_case': 'ammo_case.webp',
      'loot_medical_container': 'medical_bag.webp',
      'access_locked_room': 'locked_room.webp',
      'access_breachable_door': 'breachable_container.webp',
    };
    for (final entry in expected.entries) {
      expect(
        ArcMapFilterIconRegistry.tryAssetPathFor(entry.key),
        '${ArcMapFilterIconRegistry.assetDirectory}/${entry.value}',
      );
    }
  });

  test('all completed ARC enemy artwork is wired without renaming taxonomy', () {
    for (final key in ArcMapFilterIconRegistry.rasterIconKeys
        .where((key) => key.startsWith('arc_'))) {
      expect(ArcMapFilterIconRegistry.canonicalIconKeys, contains(key));
    }
  });

  test('unknown icon keys use widget fallback rather than a missing asset', () {
    expect(ArcMapFilterIconRegistry.tryAssetPathFor('custom_signal'), isNull);
    expect(ArcMapFilterIconRegistry.assetPathFor('custom_signal'), isEmpty);
  });
}
