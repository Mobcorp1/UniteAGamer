/// Player-confirmed 18-position Stencil ordering (9 columns × 2 rows).
/// First 14 slots retain their original IDs, names and save positions.
/// The last four were added in November 2026.
/// WebP files use lowercase-hyphen names within assets/arc_raiders/blueprints/.
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
    'Sundog',
    'Malocchio',
    'Taurus',
    'Golden Olive',
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
    'sundog.webp',
    'malocchio.webp',
    'taurus.webp',
    'golden-olive.webp',
  ];

  static String nameAt(int slot) => names[slot - 1];

  /// Canonical asset path. Existing assets and historical slot numbering are
  /// intentionally unchanged. All four new assets remain real player artwork.
  static String assetAt(int slot) =>
      'assets/arc_raiders/blueprints/${fileNames[slot - 1]}';

  static String _stem(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\\.[^.]+
), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Resolve compressed images that were imported with different separators,
  /// filename casing or the original "Malcio"/"Unknown Stencil" labels.
  /// Returns only assets actually listed in the Flutter bundle manifest.
  /// Never substitutes another stencil's artwork.
  static String? bundledAssetAt(int slot, Iterable<String> bundledAssets) {
    final canonical = assetAt(slot);
    final namesForSlot = <String>{
      _stem(fileNames[slot - 1]),
      if (slot == 16) ...<String>{'malcio', 'maloccio'},
      if (slot == 18) 'unknownstencil',
    };
    String? best;
    var bestRank = 1000;
    for (final path in bundledAssets) {
      if (!path.toLowerCase().startsWith('assets/arc_raiders/blueprints/')) {
        continue;
      }
      final file = path.split('/').last;
      final ext = file.contains('.')
          ? file.substring(file.lastIndexOf('.')).toLowerCase()
          : '';
      if (!const <String>{'.webp', '.png', '.jpg', '.jpeg'}.contains(ext) ||
          !namesForSlot.contains(_stem(file))) {
        continue;
      }
      final rank = path == canonical
          ? 0
          : ext == '.webp'
              ? 1
              : ext == '.png'
                  ? 2
                  : 3;
      if (rank < bestRank || (rank == bestRank && path.compareTo(best ?? '') < 0)) {
        best = path;
        bestRank = rank;
      }
    }
    return best;
  }
}
