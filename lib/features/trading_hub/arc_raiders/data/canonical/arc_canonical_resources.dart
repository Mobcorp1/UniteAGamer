import 'arc_canonical_entity.dart';

class ArcCanonicalResources {
  const ArcCanonicalResources._();

  static const List<ArcCanonicalEntity> items = [
    ArcCanonicalEntity(
      id: 'mechanical-components',
      name: 'Mechanical Components',
      category: 'resource',
      aliases: ['mechanical component', 'mechanicals'],
      searchTerms: ['mechanical', 'bench', 'upgrade', 'scrappy'],
    ),
    ArcCanonicalEntity(
      id: 'electrical-components',
      name: 'Electrical Components',
      category: 'resource',
      aliases: ['electrical component', 'electricals'],
      searchTerms: ['electrical', 'bench', 'upgrade', 'scrappy'],
    ),
    ArcCanonicalEntity(
      id: 'industrial-components',
      name: 'Industrial Components',
      category: 'resource',
      aliases: ['industrial component', 'industrials'],
      searchTerms: ['industrial', 'bench', 'upgrade', 'scrappy'],
    ),
    ArcCanonicalEntity(
      id: 'fabric',
      name: 'Fabric',
      category: 'resource',
      aliases: ['cloth'],
      searchTerms: ['fabric', 'scrappy', 'upgrade'],
    ),
    ArcCanonicalEntity(
      id: 'chemicals',
      name: 'Chemicals',
      category: 'resource',
      aliases: ['chemical'],
      searchTerms: ['chemical', 'bench', 'upgrade'],
    ),
  ];

  static ArcCanonicalEntity? findById(String id) {
    for (final item in items) {
      if (item.id.toLowerCase() == id.toLowerCase()) {
        return item;
      }
    }

    return null;
  }

  static ArcCanonicalEntity? findByQuery(String query) {
    for (final item in items) {
      if (item.matchesQuery(query)) {
        return item;
      }
    }

    return null;
  }
}
