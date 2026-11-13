/// In-game 14-position Stencil ordering, 13 October 2026.
/// Lowercase-hyphen WebP names follow UAG's established Blueprint convention.
/// Player-confirmed assets: positions 2, 3, 5, 6, 7, 9.
class ArcStencilCatalogue {
  const ArcStencilCatalogue._();

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
  ];
  // Hand-defined for punctuation and user's exact file spelling.
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
  ];

  static String nameAt(int slot) => names[slot - 1];
  static String assetAt(int slot) =>
      'assets/arc_raiders/blueprints/${fileNames[slot - 1]}';
}
