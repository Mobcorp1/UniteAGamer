class ArcAdminMarkerVisualRegistry {
  const ArcAdminMarkerVisualRegistry._();

  static const String _mapBase = 'assets/arc_raiders/map_filter_icons/';
  static const String _scrappyBase = 'assets/arc_raiders/scrappy_resources/';

  static const Map<String, String> _exactAssets = <String, String>{
    'ammo_case': '${_mapBase}ammo_case.webp',
    'weapon_case': '${_mapBase}weapon_case.webp',
    'weapon_cache': '${_mapBase}weapon_case.webp',
    'locker': '${_mapBase}security_locker.webp',
    'security_locker': '${_mapBase}security_locker.webp',
    'medical_bag': '${_mapBase}medical_bag.webp',
    'medical_container': '${_mapBase}medical_bag.webp',
    'combat_supply': '${_mapBase}combat_supply.webp',
    'field_crate': '${_mapBase}field_crate.webp',
    'field_depot': '${_mapBase}field_depot.webp',
    'button': '${_mapBase}button.webp',
    'fuel_cell': '${_mapBase}fuel_cell.webp',
    'supply_station': '${_mapBase}supply_call_station.webp',
    'supply_call_station': '${_mapBase}supply_call_station.webp',
    'player_spawn': '${_mapBase}player_spawn.webp',
    'raider_camp': '${_mapBase}raider_camp.webp',
    'raider_cache': '${_mapBase}raider_cache.webp',
    'hidden_cache': '${_mapBase}raider_cache.webp',
    'locked_room': '${_mapBase}locked_room.webp',
    'key_room': '${_mapBase}key_room.webp',
    'breach_room': '${_mapBase}breach_room.webp',
    'breachable_door': '${_mapBase}breachable_container.webp',
    'raider_hatch': '${_mapBase}raider_hatch.webp',
    'extraction': '${_mapBase}extraction_point.webp',
    'zipline': '${_mapBase}zipline.webp',
    'arc_assessor': '${_mapBase}arc_assessor.webp',
    'baron_husk': '${_mapBase}arc_baron_husk.webp',
    'bastion': '${_mapBase}arc_bastion.webp',
    'bombardier': '${_mapBase}arc_bombardier.webp',
    'comet': '${_mapBase}arc_comet.webp',
    'arc_courier': '${_mapBase}arc_courier.webp',
    'courier': '${_mapBase}arc_courier.webp',
    'fireball': '${_mapBase}arc_fireball.webp',
    'firefly': '${_mapBase}arc_firefly.webp',
    'harvester': '${_mapBase}arc_harvester.webp',
    'arc_harvester': '${_mapBase}arc_harvester.webp',
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
    'turbine': '${_mapBase}arc_turbine.webp',
    'tick': '${_mapBase}arc_tick.webp',
    'turret': '${_mapBase}arc_turret.webp',
    'vaporizer': '${_mapBase}arc_vaporizer.webp',
    'community_report_rat': '${_mapBase}rat.webp',
    'reported_rat': '${_mapBase}rat.webp',
    'community_hunt_rat': '${_mapBase}hunt_a_rat.webp',
    'hunt_a_rat': '${_mapBase}hunt_a_rat.webp',
    'wasp': '${_mapBase}arc_wasp.webp',
    'agave': '${_scrappyBase}agave.webp',
    'apricot': '${_scrappyBase}apricots.webp',
    'fertilizer': '${_scrappyBase}fertilizer.webp',
    'great_mullein': '${_scrappyBase}great_mullein.webp',
    'lemon': '${_scrappyBase}lemons.webp',
    'moss': '${_scrappyBase}moss.webp',
    'mushroom': '${_scrappyBase}mushrooms.webp',
    'olives': '${_scrappyBase}olives.webp',
    'prickly_pear': '${_scrappyBase}prickly_pears.webp',
    'roots': '${_scrappyBase}roots.webp',
  };

  static String? assetPathForSubtype(String? subtypeId) {
    final id = (subtypeId ?? '').trim().toLowerCase();
    if (id.isEmpty) return null;
    return _exactAssets[id];
  }

  static bool hasDedicatedAsset(String? subtypeId) =>
      assetPathForSubtype(subtypeId) != null;
}
