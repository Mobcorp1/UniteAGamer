import 'arc_canonical_entity.dart';

class ArcCanonicalContainers {
  const ArcCanonicalContainers._();

  static const List<ArcCanonicalEntity> items = [
    ArcCanonicalEntity(
      id: 'raider-cache',
      name: 'Raider Cache',
      category: 'container',
      aliases: ['raiders cache', 'raider crate'],
      searchTerms: ['cache', 'raider', 'blueprint'],
    ),
    ArcCanonicalEntity(
      id: 'weapon-cache',
      name: 'Weapon Cache',
      category: 'container',
      aliases: ['weapon crate', 'gun cache'],
      searchTerms: ['weapon', 'cache', 'blueprint'],
    ),
    ArcCanonicalEntity(
      id: 'locked-room',
      name: 'Locked Room',
      category: 'container',
      aliases: ['key room', 'locked room cache'],
      searchTerms: ['locked', 'key', 'room', 'blueprint'],
    ),
    ArcCanonicalEntity(
      id: 'breach-room',
      name: 'Breach Room',
      category: 'container',
      aliases: ['breached room', 'breachable room'],
      searchTerms: ['breach', 'room', 'blueprint'],
    ),
    ArcCanonicalEntity(
      id: 'security-container',
      name: 'Security Container',
      category: 'container',
      aliases: ['security crate', 'security box'],
      searchTerms: ['security', 'container', 'blueprint'],
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
