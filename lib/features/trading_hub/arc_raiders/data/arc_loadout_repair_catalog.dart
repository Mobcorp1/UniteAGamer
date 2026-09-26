class ArcVerifiedRepairRecipe {
  const ArcVerifiedRepairRecipe({
    required this.itemName,
    required this.tier,
    required this.materials,
    required this.durabilityRestored,
    required this.sourceUrl,
  });

  final String itemName;
  final int tier;
  final Map<String, int> materials;
  final int durabilityRestored;
  final String sourceUrl;
}

class ArcShieldIntelligence {
  const ArcShieldIntelligence({
    required this.name,
    required this.charge,
    required this.damageReductionPercent,
    required this.movementPenaltyPercent,
    required this.craftRecipe,
    required this.repairRecipe,
    required this.repairDurability,
    required this.sourceUrl,
  });

  final String name;
  final int charge;
  final double damageReductionPercent;
  final double movementPenaltyPercent;
  final Map<String, int> craftRecipe;
  final Map<String, int> repairRecipe;
  final int repairDurability;
  final String sourceUrl;
}

class ArcLoadoutRepairCatalog {
  const ArcLoadoutRepairCatalog._();

  static const String verifiedSnapshot = '2026-09-26';

  static const List<ArcShieldIntelligence> shields = <ArcShieldIntelligence>[
    ArcShieldIntelligence(
      name: 'Light Shield',
      charge: 40,
      damageReductionPercent: 40,
      movementPenaltyPercent: 0,
      craftRecipe: <String, int>{'arc_alloy': 2, 'plastic_parts': 4},
      repairRecipe: <String, int>{'plastic_parts': 4},
      repairDurability: 50,
      sourceUrl: 'https://arcraiders.wiki/wiki/Light_Shield',
    ),
    ArcShieldIntelligence(
      name: 'Medium Shield',
      charge: 70,
      damageReductionPercent: 42.5,
      movementPenaltyPercent: 5,
      craftRecipe: <String, int>{'battery': 4, 'arc_circuitry': 1},
      repairRecipe: <String, int>{'arc_circuitry': 1, 'battery': 1},
      repairDurability: 50,
      sourceUrl: 'https://arcraiders.wiki/wiki/Medium_Shield',
    ),
    ArcShieldIntelligence(
      name: 'Heavy Shield',
      charge: 80,
      damageReductionPercent: 52.5,
      movementPenaltyPercent: 15,
      craftRecipe: <String, int>{'power_rod': 1, 'voltage_converter': 2},
      repairRecipe: <String, int>{'arc_circuitry': 2, 'voltage_converter': 1},
      repairDurability: 50,
      sourceUrl: 'https://arcraiders.wiki/wiki/Heavy_Shield',
    ),
  ];

  static const Map<String, List<ArcVerifiedRepairRecipe>> weaponRepairs =
      <String, List<ArcVerifiedRepairRecipe>>{
        'anvil': <ArcVerifiedRepairRecipe>[
          ArcVerifiedRepairRecipe(
            itemName: 'Anvil',
            tier: 1,
            materials: <String, int>{
              'mechanical_components': 2,
              'simple_gun_parts': 2,
            },
            durabilityRestored: 50,
            sourceUrl: 'https://arcraiders.wiki/wiki/Anvil',
          ),
          ArcVerifiedRepairRecipe(
            itemName: 'Anvil',
            tier: 2,
            materials: <String, int>{
              'mechanical_components': 3,
              'simple_gun_parts': 3,
            },
            durabilityRestored: 55,
            sourceUrl: 'https://arcraiders.wiki/wiki/Anvil',
          ),
          ArcVerifiedRepairRecipe(
            itemName: 'Anvil',
            tier: 3,
            materials: <String, int>{
              'mechanical_components': 4,
              'simple_gun_parts': 4,
            },
            durabilityRestored: 60,
            sourceUrl: 'https://arcraiders.wiki/wiki/Anvil',
          ),
          ArcVerifiedRepairRecipe(
            itemName: 'Anvil',
            tier: 4,
            materials: <String, int>{
              'mechanical_components': 5,
              'simple_gun_parts': 5,
            },
            durabilityRestored: 65,
            sourceUrl: 'https://arcraiders.wiki/wiki/Anvil',
          ),
        ],
        'stitcher': <ArcVerifiedRepairRecipe>[
          ArcVerifiedRepairRecipe(
            itemName: 'Stitcher',
            tier: 1,
            materials: <String, int>{'metal_parts': 3, 'rubber_parts': 2},
            durabilityRestored: 50,
            sourceUrl: 'https://arcraiders.wiki/wiki/Stitcher',
          ),
          ArcVerifiedRepairRecipe(
            itemName: 'Stitcher',
            tier: 2,
            materials: <String, int>{'metal_parts': 6, 'rubber_parts': 6},
            durabilityRestored: 55,
            sourceUrl: 'https://arcraiders.wiki/wiki/Stitcher',
          ),
          ArcVerifiedRepairRecipe(
            itemName: 'Stitcher',
            tier: 3,
            materials: <String, int>{'metal_parts': 12, 'simple_gun_parts': 1},
            durabilityRestored: 60,
            sourceUrl: 'https://arcraiders.wiki/wiki/Stitcher',
          ),
          ArcVerifiedRepairRecipe(
            itemName: 'Stitcher',
            tier: 4,
            materials: <String, int>{
              'mechanical_components': 2,
              'simple_gun_parts': 2,
            },
            durabilityRestored: 65,
            sourceUrl: 'https://arcraiders.wiki/wiki/Stitcher',
          ),
        ],
      };

  static String normalise(String value) => value.trim().toLowerCase();

  static ArcShieldIntelligence? shieldFor(String name) {
    final target = normalise(migrateLegacyShield(name));
    for (final shield in shields) {
      if (normalise(shield.name) == target) return shield;
    }
    return null;
  }

  static ArcVerifiedRepairRecipe? repairForWeapon(
    String weaponName, {
    int tier = 4,
  }) {
    final recipes = weaponRepairs[normalise(weaponName)];
    if (recipes == null) return null;
    for (final recipe in recipes) {
      if (recipe.tier == tier) return recipe;
    }
    return null;
  }

  static String migrateLegacyShield(String? value) {
    final raw = (value ?? '').trim();
    switch (normalise(raw)) {
      case '':
      case 'shield level 2':
        return 'Medium Shield';
      case 'shield level 1':
        return 'Light Shield';
      case 'shield level 3':
        return 'Heavy Shield';
      default:
        return raw;
    }
  }
}
