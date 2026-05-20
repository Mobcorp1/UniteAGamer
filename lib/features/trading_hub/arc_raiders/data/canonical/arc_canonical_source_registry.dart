import 'arc_canonical_blueprints.dart';

class ArcCanonicalRegistry {
  static final blueprints = ArcCanonicalBlueprints.items;

  static ArcCanonicalBlueprint? findBlueprintById(String id) {
    return ArcCanonicalBlueprints.findById(id);
  }

  static ArcCanonicalBlueprint? findBlueprintByName(String name) {
    return ArcCanonicalBlueprints.findByName(name);
  }
}
