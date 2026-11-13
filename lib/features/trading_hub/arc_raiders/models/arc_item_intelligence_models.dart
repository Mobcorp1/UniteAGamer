class ArcItemIntelligenceItem {
  const ArcItemIntelligenceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.imageAsset,
    required this.primaryStation,
    required this.stationIds,
    required this.stationLevel,
    required this.aliases,
    required this.recipe,
    required this.recyclesInto,
    required this.salvagesInto,
  });

  final String id;
  final String name;
  final String type;
  final String rarity;
  final String imageAsset;
  final String primaryStation;
  final List<String> stationIds;
  final int? stationLevel;
  final List<String> aliases;
  final Map<String, int> recipe;
  final Map<String, int> recyclesInto;
  final Map<String, int> salvagesInto;

  bool get craftable => recipe.isNotEmpty;
  bool get recyclable => recyclesInto.isNotEmpty;
  bool get salvageable => salvagesInto.isNotEmpty;
}

class ArcCraftStep {
  const ArcCraftStep({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;
}

class ArcCraftingPlan {
  const ArcCraftingPlan({
    required this.targetId,
    required this.targetName,
    required this.targetQuantity,
    required this.immediateRecipe,
    required this.rawMaterials,
    required this.craftSteps,
    required this.unresolvedTargets,
  });

  final String targetId;
  final String targetName;
  final int targetQuantity;
  final Map<String, int> immediateRecipe;
  final Map<String, int> rawMaterials;
  final List<ArcCraftStep> craftSteps;
  final List<String> unresolvedTargets;

  bool get complete => unresolvedTargets.isEmpty;
}

class ArcLoadoutCraftingPlan {
  const ArcLoadoutCraftingPlan({
    required this.loadoutName,
    required this.resolvedTargets,
    required this.rawMaterials,
    required this.craftSteps,
    required this.unresolvedTargets,
  });

  final String loadoutName;
  final Map<String, int> resolvedTargets;
  final Map<String, int> rawMaterials;
  final List<ArcCraftStep> craftSteps;
  final List<String> unresolvedTargets;

  bool get complete => unresolvedTargets.isEmpty;
}

class ArcRecycleSource {
  const ArcRecycleSource({
    required this.item,
    required this.resourceId,
    required this.yield,
  });

  final ArcItemIntelligenceItem item;
  final String resourceId;
  final int yield;
}
