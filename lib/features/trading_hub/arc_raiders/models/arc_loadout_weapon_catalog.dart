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

const arcLoadoutWeapons = [
  ArcLoadoutWeaponDefinition(
    id: 'stitcher',
    name: 'Stitcher',
    imagePath: 'assets/images/arc_raiders/loadouts/weapons/stitcher.webp',
    attachmentSlots: ['Muzzle', 'Magazine', 'Grip', 'Stock'],
    isBlueprintWeapon: false,
    requiredWorkshopLevel: 1,
  ),
  ArcLoadoutWeaponDefinition(
    id: 'ferro',
    name: 'Ferro',
    imagePath: 'assets/images/arc_raiders/loadouts/weapons/ferro.webp',
    attachmentSlots: ['Muzzle', 'Magazine', 'Stock'],
    isBlueprintWeapon: false,
    requiredWorkshopLevel: 1,
  ),
  ArcLoadoutWeaponDefinition(
    id: 'harpin',
    name: 'Hairpin',
    imagePath: 'assets/images/arc_raiders/loadouts/weapons/harpin.webp',
    attachmentSlots: ['Magazine', 'Grip', 'Stock'],
    isBlueprintWeapon: false,
    requiredWorkshopLevel: 1,
  ),
  ArcLoadoutWeaponDefinition(
    id: 'kettle',
    name: 'Kettle',
    imagePath: 'assets/images/arc_raiders/loadouts/weapons/kettle.webp',
    attachmentSlots: ['Muzzle', 'Magazine'],
    isBlueprintWeapon: false,
    requiredWorkshopLevel: 1,
  ),
];
