import 'package:flutter/foundation.dart';
@immutable
class UagResearchRequirement {
  const UagResearchRequirement(this.name, this.quantity);
  final String name;
  final int quantity;
}
@immutable
class UagResearchRecipe {
  const UagResearchRecipe({required this.id, required this.title, required this.kind,
    required this.stationLevel, required this.researchPoints,
    required this.stepOne, required this.materials, required this.sourceUrl,
    this.unlocks = '', this.crafting = const <UagResearchRequirement>[]});
  final String id;
  final String title;
  final String kind;
  final int stationLevel;
  final int researchPoints;
  final String stepOne;
  final String unlocks;
  final List<UagResearchRequirement> materials;
  final List<UagResearchRequirement> crafting;
  final String sourceUrl;
}
class UagResearchCatalogue {
  UagResearchCatalogue._();
  static const recipes = <UagResearchRecipe>[
    UagResearchRecipe(id: 'blueprint-bantam', title: 'Bantam Blueprint', kind: 'blueprint', stationLevel: 1, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Bantam', materials: [UagResearchRequirement('Hornet Driver', 8)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-barricade-kit', title: 'Barricade Kit Blueprint', kind: 'blueprint', stationLevel: 1, researchPoints: 1000, stepOne: 'Gather research materials', unlocks: 'Barricade Kit', materials: [UagResearchRequirement('Rusty ARC Steel', 3)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-burletta', title: 'Burletta Blueprint', kind: 'blueprint', stationLevel: 1, researchPoints: 2000, stepOne: 'Gather research materials', unlocks: 'Burletta', materials: [UagResearchRequirement('Simple Gun Parts', 8)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-crash-mat', title: 'Crash Mat Blueprint', kind: 'blueprint', stationLevel: 1, researchPoints: 1000, stepOne: 'Gather research materials', unlocks: 'Crash Mat', materials: [UagResearchRequirement('Durable Cloth', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-gas-mine', title: 'Gas Mine Blueprint', kind: 'blueprint', stationLevel: 1, researchPoints: 1000, stepOne: 'Gather research materials', unlocks: 'Gas Mine', materials: [UagResearchRequirement('Household Cleaner', 3)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-grappling-hook', title: 'Grappling Hook Blueprint', kind: 'blueprint', stationLevel: 1, researchPoints: 2000, stepOne: 'Gather research materials', unlocks: 'Grappling Hook', materials: [UagResearchRequirement('Rope', 10)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-anvil', title: 'Anvil Blueprint', kind: 'blueprint', stationLevel: 2, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Anvil', materials: [UagResearchRequirement('Bully Fragmenter', 5), UagResearchRequirement('Rusted Tools', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-canto', title: 'Canto Blueprint', kind: 'blueprint', stationLevel: 2, researchPoints: 2000, stepOne: 'Gather research materials', unlocks: 'Canto', materials: [UagResearchRequirement('Skulker Targeter', 10), UagResearchRequirement('Steel Spring', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-bettina', title: 'Bettina Blueprint', kind: 'blueprint', stationLevel: 3, researchPoints: 4500, stepOne: 'Gather research materials', unlocks: 'Bettina', materials: [UagResearchRequirement('Rocketeer Driver', 5), UagResearchRequirement('Complex Gun Parts', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-deadline', title: 'Deadline Blueprint', kind: 'blueprint', stationLevel: 3, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Deadline', materials: [UagResearchRequirement('Comet Igniter', 5), UagResearchRequirement('Fossilized Lightning', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-hullcracker', title: 'Hullcracker Blueprint', kind: 'blueprint', stationLevel: 3, researchPoints: 4500, stepOne: 'Gather research materials', unlocks: 'Hullcracker', materials: [UagResearchRequirement('Bombardier Cell', 5), UagResearchRequirement('Complex Gun Parts', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-venator', title: 'Venator Blueprint', kind: 'blueprint', stationLevel: 2, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Venator', materials: [UagResearchRequirement('Leaper Pulse Unit', 3), UagResearchRequirement('Mechanical Components', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-osprey', title: 'Osprey Blueprint', kind: 'blueprint', stationLevel: 2, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Osprey', materials: [UagResearchRequirement('Sentinel Firing Core', 3), UagResearchRequirement('Camera Lens', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-rascal', title: 'Rascal Blueprint', kind: 'blueprint', stationLevel: 2, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Rascal', materials: [UagResearchRequirement('Bombardier Cell', 2), UagResearchRequirement('ARC Alloy', 15)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
    UagResearchRecipe(id: 'blueprint-torrente', title: 'Torrente Blueprint', kind: 'blueprint', stationLevel: 2, researchPoints: 3000, stepOne: 'Gather research materials', unlocks: 'Torrente', materials: [UagResearchRequirement('Bastion Cell', 3), UagResearchRequirement('Cooling Fan', 1)], sourceUrl: 'https://arcraiders.wiki/wiki/Research_Points'),
UagResearchRecipe(id: 'action-economy', title: 'Action Economy', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 1,000 damage with a Hairpin in one round', unlocks: 'Ergonomic Bolt', materials: [UagResearchRequirement('Sentinel Firing Core', 8)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'beam-resonance-tech', title: 'Beam Resonance Tech', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 1,500 damage to Vaporizers with an Equalizer in one round', unlocks: 'Ramping Damage', materials: [UagResearchRequirement('Queen Reactor', 2)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'compact-combustion-charges', title: 'Compact Combustion Charges', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 3,000 damage with Blaze Grenades', unlocks: 'Incendiary Grenades', materials: [UagResearchRequirement('Bombardier Cell', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'embedded-blast-engineering', title: 'Embedded Blast Engineering', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 1,000 damage to Fireflies, Hornets, Fireballs, and Surveyors using Light Impact Grenades (each)', unlocks: 'X-Rounds', materials: [UagResearchRequirement('Rocketeer Driver', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'extended-burst-cycles', title: 'Extended Burst Cycles', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 10,000 damage with a Burst Burletta or Charged Burst Aphelion', unlocks: 'Increased Burst', materials: [UagResearchRequirement('Comet Igniter', 10)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'high-voltage-exposure', title: 'High-Voltage Exposure', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Destroy 5 ARC Turbines', unlocks: 'Charged Burst', materials: [UagResearchRequirement('Leaper Pulse Unit', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'magazine-geometry-101', title: 'Magazine Geometry 101', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 15,000 damage to a Bastion and destroy one Bastion with a Rattler', unlocks: 'Drum Mag', materials: [UagResearchRequirement('Bastion Cell', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'mobile-fire-grip-fittings', title: 'Mobile-Fire Grip Fittings', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Visit Electrical Substation, Truck Stop, Old Town, Almatera Station, Researcher Lodgings, Deep-Space Telescope and Commissary Supermarket in one round', unlocks: 'Sprint Shooting', materials: [UagResearchRequirement('Skulker Targeter', 20)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'shield-stress-testing', title: 'Shield Stress Testing', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Deal 700 damage to encountered Raiders', unlocks: 'Anti-Shield', materials: [UagResearchRequirement('Matriarch Reactor', 2)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'solid-core-casting-tech', title: 'Solid-Core Casting Tech', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Destroy 50 Flying ARC using shotguns', unlocks: 'Slug Rounds', materials: [UagResearchRequirement('Tick Pod', 20)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'targeted-component-trial', title: 'Targeted Component Trial', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Destroy 40 thrusters on flying ARC enemies', unlocks: 'Anti-Weak Point', materials: [UagResearchRequirement('Fireball Burner', 20)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'thermite-tipped-rounds', title: 'Thermite-Tipped Rounds', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Destroy 30 Fireballs with Explosive Mines', unlocks: 'Incendiary Rounds', materials: [UagResearchRequirement('Firefly Burner', 5)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'top-mounted-optics-retrofittings', title: 'Top Mounted Optics Retrofittings', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'On Blue Gate at Pilgrim’s Peak deal 1,000 damage to ARC enemies using the Osprey in one round', unlocks: 'Scoped', materials: [UagResearchRequirement('Snitch Scanner', 14)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'trigger-reset-systems', title: 'Trigger Reset Systems', kind: 'amplification', stationLevel: 4, researchPoints: 5000, stepOne: 'Destroy 5 Skulkers with a Raider Tool', unlocks: 'Semi-Auto', materials: [UagResearchRequirement('Vaporizer Regulator', 4)], sourceUrl: 'https://arcraiders.wiki/wiki/Amplified_Research'),
UagResearchRecipe(id: 'bureau-ceiling-lamp', title: 'Bureau Ceiling Lamp Design', kind: 'design', stationLevel: 2, researchPoints: 1000, stepOne: 'Gather research materials', unlocks: 'Bureau Ceiling Lamp', materials: [UagResearchRequirement('Broken Flashlight', 1)], crafting: [UagResearchRequirement('Sheet Metal', 10), UagResearchRequirement('Light Bulb', 1)], sourceUrl: 'https://arctracker.io/items/bureau_ceiling_lamp_design'),
UagResearchRecipe(id: 'tufted-sofa', title: 'Tufted Sofa Design', kind: 'design', stationLevel: 3, researchPoints: 2000, stepOne: 'Gather research materials', unlocks: 'Tufted Sofa', materials: [UagResearchRequirement('Very Comfortable Pillow', 3)], crafting: [UagResearchRequirement('Spring Cushion', 3), UagResearchRequirement('Planks', 20)], sourceUrl: 'https://arcraiders.wiki/wiki/Furniture'),
 ];
static final researchableBlueprints = <String, UagResearchRecipe>{
    for (final recipe in recipes.where((recipe) => recipe.kind == 'blueprint'))
      recipe.id.substring('blueprint-'.length): recipe,
  };
  static final byId = {for (final recipe in recipes) recipe.id: recipe};
}
