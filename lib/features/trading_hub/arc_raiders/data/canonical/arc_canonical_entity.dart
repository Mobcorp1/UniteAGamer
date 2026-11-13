class ArcCanonicalEntity {
  final String id;
  final String name;
  final String category;
  final List<String> aliases;
  final List<String> searchTerms;
  final String? imageAsset;
  final String? iconKey;

  const ArcCanonicalEntity({
    required this.id,
    required this.name,
    required this.category,
    this.aliases = const [],
    this.searchTerms = const [],
    this.imageAsset,
    this.iconKey,
  });

  bool matchesQuery(String query) {
    final normalisedQuery = query.trim().toLowerCase();

    if (normalisedQuery.isEmpty) {
      return false;
    }

    if (id.toLowerCase() == normalisedQuery ||
        name.toLowerCase() == normalisedQuery) {
      return true;
    }

    return aliases.any((alias) => alias.toLowerCase() == normalisedQuery) ||
        searchTerms.any((term) => term.toLowerCase().contains(normalisedQuery));
  }
}
