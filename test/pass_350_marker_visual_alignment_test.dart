import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_visual_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';

void main() {
  test('PASS 350 confirmed marker assets resolve to matching runtime artwork', () {
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('weapon_case'),
      'assets/arc_raiders/map_filter_icons/weapon_case.webp',
    );
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('security_locker'),
      'assets/arc_raiders/map_filter_icons/security_locker.webp',
    );
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('ammo_case'),
      'assets/arc_raiders/map_filter_icons/ammo_case.webp',
    );
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('lemon'),
      'assets/arc_raiders/scrappy_resources/lemons.webp',
    );
    expect(
      ArcAdminMarkerVisualRegistry.assetPathForSubtype('mushroom'),
      'assets/arc_raiders/scrappy_resources/mushrooms.webp',
    );
  });

  test('PASS 350 weapon tube is canonical but does not invent a fake image asset', () {
    expect(ArcMapFilterTaxonomy.byId('weapon_tube'), isNotNull);
    expect(ArcMapFilterTaxonomy.byId('weapon_tube')!.label, 'Weapon Tube');
    expect(ArcAdminMarkerVisualRegistry.assetPathForSubtype('weapon_tube'), isNull);
  });
}
