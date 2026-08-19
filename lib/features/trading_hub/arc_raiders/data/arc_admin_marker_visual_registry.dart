class ArcAdminMarkerVisualRegistry {
  const ArcAdminMarkerVisualRegistry._();

  static const String _mapBase = 'assets/arc_raiders/map_filter_icons/';
  static const String _itemBase = 'assets/arc_raiders/items/';

  static const Map<String, String> _exactAssets = <String, String>{
    'ammo_case': '${_mapBase}ammo_case.webp',
    'weapon_case': '${_mapBase}weapon_case.webp',
    'weapon_cache': '${_mapBase}weapon_case.webp',
    'locker': '${_mapBase}security_locker.webp',
    'security_locker': '${_mapBase}security_locker.webp',
    'medical_bag': '${_mapBase}medical_bag.webp',
    'field_crate': '${_mapBase}field_crate.webp',
    'field_depot': '${_mapBase}field_depot.webp',
    'raider_cache': '${_mapBase}raider_cache.webp',
    'hidden_cache': '${_mapBase}raider_cache.webp',
    'locked_room': '${_mapBase}locked_room.webp',
    'breachable_door': '${_mapBase}breachable_container.webp',
    'raider_hatch': '${_mapBase}raider_hatch.webp',
    'extraction': '${_mapBase}extraction_point.webp',
    'zipline': '${_mapBase}zipline.webp',
    'arc_assessor': '${_mapBase}arc_assessor.webp',
    'baron_husk': '${_mapBase}arc_baron_husk.webp',
    'bastion': '${_mapBase}arc_bastion.webp',
    'bombardier': '${_mapBase}arc_bombardier.webp',
    'fireball': '${_mapBase}arc_fireball.webp',
    'firefly': '${_mapBase}arc_firefly.webp',
    'harvester': '${_mapBase}arc_harvester.webp',
    'hornet': '${_mapBase}arc_hornet.webp',
    'leaper': '${_mapBase}arc_leaper.webp',
    'matriarch': '${_mapBase}arc_matriarch.webp',
    'pop': '${_mapBase}arc_pop.webp',
    'arc_probe': '${_mapBase}arc_probe.webp',
    'queen': '${_mapBase}arc_queen.webp',
    'rocketeer': '${_mapBase}arc_rocketeer.webp',
    'sentinel': '${_mapBase}arc_sentinel.webp',
    'shredder': '${_mapBase}arc_shredder.webp',
    'snitch': '${_mapBase}arc_snitch.webp',
    'spotter': '${_mapBase}arc_spotter.webp',
    'surveyor': '${_mapBase}arc_surveyor.webp',
    'tick': '${_mapBase}arc_tick.webp',
    'turret': '${_mapBase}arc_turret.webp',
    'vaporizer': '${_mapBase}arc_vaporizer.webp',
    'wasp': '${_mapBase}arc_wasp.webp',
    'agave': '${_itemBase}agave.webp',
    'apricot': '${_itemBase}apricots.webp',
    'fertilizer': '${_itemBase}fertilizer.webp',
    'great_mullein': '${_itemBase}great_mullein.webp',
    'lemon': '${_itemBase}lemons.webp',
    'moss': '${_itemBase}moss.webp',
    'mushroom': '${_itemBase}mushroom.webp',
    'olives': '${_itemBase}olives.webp',
    'prickly_pear': '${_itemBase}prickly_pears.webp',
    'roots': '${_itemBase}roots.webp',
  };

  static String? assetPathForSubtype(String? subtypeId) {
    final id = (subtypeId ?? '').trim().toLowerCase();
    if (id.isEmpty) return null;
    return _exactAssets[id];
  }

  static bool hasDedicatedAsset(String? subtypeId) =>
      assetPathForSubtype(subtypeId) != null;
}
