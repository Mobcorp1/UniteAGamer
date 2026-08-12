import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';

void main() {
  test('canonical taxonomy exposes stable unique IDs and icon keys', () {
    expect(ArcMapFilterTaxonomy.all, isNotEmpty);
    final ids = ArcMapFilterTaxonomy.all.map((entry) => entry.id).toList();
    final iconKeys = ArcMapFilterTaxonomy.all
        .map((entry) => entry.iconKey)
        .toList();

    expect(ids.toSet().length, ids.length);
    expect(iconKeys.every((value) => value.trim().isNotEmpty), isTrue);
  });

  test('taxonomy includes core extraction types', () {
    expect(
      ArcMapFilterTaxonomy.byId('cargo_elevator')?.kind,
      ArcAdminMapMarkerKind.extraction,
    );
    expect(
      ArcMapFilterTaxonomy.byId('metro_station')?.kind,
      ArcAdminMapMarkerKind.extraction,
    );
    expect(
      ArcMapFilterTaxonomy.byId('airshaft')?.kind,
      ArcAdminMapMarkerKind.extraction,
    );
    expect(
      ArcMapFilterTaxonomy.byId('raider_hatch')?.kind,
      ArcAdminMapMarkerKind.raiderHatch,
    );
  });

  test('taxonomy includes requested filter foundations', () {
    for (final id in [
      'weapon_case',
      'weapon_cache',
      'security_locker',
      'raider_cache',
      'field_crate',
      'bastion',
      'bombardier',
      'rocketeer',
      'leaper',
      'arc_probe',
      'field_depot',
      'supply_station',
      'locked_room',
      'key_room',
      'great_mullein',
    ]) {
      expect(ArcMapFilterTaxonomy.byId(id), isNotNull, reason: id);
    }
  });
}
