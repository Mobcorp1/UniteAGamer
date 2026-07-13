import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';

class ArcLoadoutWeaponDefinition {
  const ArcLoadoutWeaponDefinition({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.attachmentSlots,
    required this.isBlueprintWeapon,
    required this.requiredWorkshopLevel,
  });

  final String id;
  final String name;
  final String imagePath;
  final List<String> attachmentSlots;
  final bool isBlueprintWeapon;
  final int requiredWorkshopLevel;
}

String _weaponId(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

/// Legacy view retained for callers that still import this file.
/// All slot data now delegates to [ArcLoadoutSeedData.weapons].
final List<ArcLoadoutWeaponDefinition> arcLoadoutWeapons = List.unmodifiable(
  ArcLoadoutSeedData.weapons.map(
    (weapon) => ArcLoadoutWeaponDefinition(
      id: _weaponId(weapon.name),
      name: weapon.name,
      imagePath: 'assets/arc_raiders/items/${_weaponId(weapon.name)}.webp',
      attachmentSlots: List.unmodifiable(weapon.slots),
      isBlueprintWeapon: weapon.blueprintBased,
      requiredWorkshopLevel: weapon.gunsmithLevel ?? 0,
    ),
  ),
);
