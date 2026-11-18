/// In-game 18-position Stencil ordering, updated 17 November 2026.
///
/// Slots 1-14 preserve the established UAG ordering exactly.
/// Player-confirmed November additions:
/// 15 Sundog, 16 Malocchio, 17 Taurus.
/// Slot 18 exists in-game but its identity is not yet confirmed.
///
/// Lowercase-hyphen WebP names follow UAG's established convention.
class ArcStencilCatalogue {
  const ArcStencilCatalogue._();

  static const int slotCount = 18;
  static const int columns = 9;
  static const String assetDirectory = 'assets/arc_raiders/blueprints';

  static const List<String> names = <String>[
    'Verdigris',
    'Slipstream',
    'Tortoise',
    'Sacrifice',
    'Milky Terracotta',
    'Curulean',
    'Dusty Camo',
    'Bulwark',
    "Dragon's Breath",
    'Empyrean',
    'Fortuna',
    'Serac',
    'Garnet',
    'Ochre',
    'Sundog',
    'Malocchio',
    'Taurus',
    'Unknown Stencil',
  ];

  static const List<String> fileNames = <String>[
    'verdigris.webp',
    'slipstream.webp',
    'tortoise.webp',
    'sacrifice.webp',
    'milky-terracotta.webp',
    'curulean.webp',
    'dusty-camo.webp',
    'bulwark.webp',
    'dragons-breath.webp',
    'empyrean.webp',
    'fortuna.webp',
    'serac.webp',
    'garnet.webp',
    'ochre.webp',
    'sundog.webp',
    'malocchio.webp',
    'taurus.webp',
    'unknown-stencil.webp',
  ];

  static String nameAt(int slot) => names[_indexFor(slot)];

  static String assetAt(int slot) =>
      '$assetDirectory/${fileNames[_indexFor(slot)]}';

  static int _indexFor(int slot) {
    if (slot < 1 || slot > slotCount) {
      throw RangeError.range(slot, 1, slotCount, 'slot');
    }
    return slot - 1;
  }
}
