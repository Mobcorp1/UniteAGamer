class ArcCanonicalBlueprint {
  final String id;
  final String name;
  final List<String> aliases;
  final List<String> searchTerms;
  final String imagePath;
  final String category;

  const ArcCanonicalBlueprint({
    required this.id,
    required this.name,
    required this.aliases,
    required this.searchTerms,
    required this.imagePath,
    required this.category,
  });
}

class ArcCanonicalBlueprints {
  static const List<ArcCanonicalBlueprint> items = [
    ArcCanonicalBlueprint(
      id: 'extended-barrel-ii',
      name: 'Extended Barrel II',
      aliases: ['extended barrel 2', 'barrel 2'],
      searchTerms: ['extended', 'barrel', 'weapon'],
      imagePath: 'assets/images/arc_raiders/blueprints/extended-barrel-ii.webp',
      category: 'weapon_mod',
    ),

    ArcCanonicalBlueprint(
      id: 'rascal',
      name: 'Rascal',
      aliases: ['rascal weapon'],
      searchTerms: ['rascal', 'smg'],
      imagePath: 'assets/images/arc_raiders/blueprints/rascal.webp',
      category: 'weapon',
    ),
  ];

  static ArcCanonicalBlueprint? findById(String id) {
    try {
      return items.firstWhere(
        (item) => item.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static ArcCanonicalBlueprint? findByName(String name) {
    final query = name.toLowerCase();

    try {
      return items.firstWhere(
        (item) =>
            item.name.toLowerCase() == query ||
            item.aliases.any((alias) => alias.toLowerCase() == query),
      );
    } catch (_) {
      return null;
    }
  }
}
