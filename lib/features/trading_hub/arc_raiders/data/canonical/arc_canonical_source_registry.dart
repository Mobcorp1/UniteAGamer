import 'arc_canonical_blueprints.dart';
import 'arc_canonical_containers.dart';
import 'arc_canonical_entity.dart';
import 'arc_canonical_resources.dart';

class ArcCanonicalRegistry {
  static final blueprints = ArcCanonicalBlueprints.items;
  static const List<ArcCanonicalEntity> resources = ArcCanonicalResources.items;
  static const List<ArcCanonicalEntity> containers =
      ArcCanonicalContainers.items;

  static ArcCanonicalBlueprint? findBlueprintById(String id) {
    return ArcCanonicalBlueprints.findById(id);
  }

  static ArcCanonicalBlueprint? findBlueprintByName(String name) {
    return ArcCanonicalBlueprints.findByName(name);
  }

  static ArcCanonicalEntity? findResourceById(String id) {
    return ArcCanonicalResources.findById(id);
  }

  static ArcCanonicalEntity? findResourceByQuery(String query) {
    return ArcCanonicalResources.findByQuery(query);
  }

  static ArcCanonicalEntity? findContainerById(String id) {
    return ArcCanonicalContainers.findById(id);
  }

  static ArcCanonicalEntity? findContainerByQuery(String query) {
    return ArcCanonicalContainers.findByQuery(query);
  }
}
