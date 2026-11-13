/// Frozen Trail research: 15 distinct projects, not 15 projects per weapon.
/// Community reference checked 20 October 2026. Never infer inventory or game progress.
class ArcAmplificationObjective {
  const ArcAmplificationObjective(this.label, this.target, {this.sameRaid = false});
  final String label;
  final int target;
  final bool sameRaid;
}

class ArcAmplificationProject {
  const ArcAmplificationProject({
    required this.id,
    required this.title,
    required this.perk,
    required this.weapons,
    required this.objectives,
    required this.material,
    required this.materialCount,
    this.targetEnemy,
    this.suggestedMap,
    this.sourceNote,
  });
  final String id;
  final String title;
  final String perk;
  final List<String> weapons;
  final List<ArcAmplificationObjective> objectives;
  final String material;
  final int materialCount;
  final String? targetEnemy;
  final String? suggestedMap;
  final String? sourceNote;
  int get researchCost => 5000;
}

class ArcAmplificationCatalog {
  const ArcAmplificationCatalog._();
  static const int maxActive = 5;
  static const int researchCost = 5000;
  static const Map<String, int> researchItemPoints = <String,int>{
    'Battered Paperback': 50,
    'Raider Logbook': 100,
    'Exodus Technical Handbook': 150,
    'ARC Data Module': 200,
    'Frigate Diagnostic Node': 1000,
  };
  static const Map<String, int> moduleByWeapon = <String, int>{
    'Hairpin': 1, 'Kettle': 1, 'Rattler': 1,
    'Burletta': 2, 'Il Toro': 2,
    'Anvil': 3, 'Canto': 3, 'Osprey': 3, 'Rascal': 3, 'Renegade': 3,
    'Bettina': 4, 'Hullcracker': 4,
    'Aphelion': 5, 'Equalizer': 5, 'Jupiter': 5,
  };
  static const List<ArcAmplificationProject> projects = <ArcAmplificationProject>[
    ArcAmplificationProject(
      id:'action_economy', title:'Action Economy', perk:'Ergonomic Bolt', weapons:['Jupiter','Osprey'],
      objectives:[ArcAmplificationObjective('Damage with a Hairpin in one raid',1000,sameRaid:true)],
      material:'Sentinel Firing Core', materialCount:8,
    ),
    ArcAmplificationProject(
      id:'beam_resonance_tech', title:'Beam Resonance Tech', perk:'Ramping Damage', weapons:['Equalizer'],
      objectives:[ArcAmplificationObjective('Damage Vaporizers with an Equalizer in one raid',1500,sameRaid:true)],
      material:'Queen Reactor', materialCount:2, targetEnemy:'Vaporizer',
    ),
    ArcAmplificationProject(
      id:'burst_assembly_recovery', title:'Burst Assembly Recovery', perk:'Burst Fire', weapons:['Burletta'],
      objectives:[ArcAmplificationObjective('Destroy Shredders with a Raider Tool',3)],
      material:'Pop Trigger', materialCount:20, targetEnemy:'Shredder',
    ),
    ArcAmplificationProject(
      id:'compact_combustion_charges', title:'Compact Combustion Charges', perk:'Incendiary Grenades', weapons:['Hullcracker','Rascal'],
      objectives:[ArcAmplificationObjective('Damage with Blaze Grenades',3000)],
      material:'Bombardier Cell', materialCount:5,
    ),
    ArcAmplificationProject(
      id:'embedded_blast_engineering', title:'Embedded Blast Engineering', perk:'X-Rounds', weapons:['Anvil','Bettina','Kettle'],
      objectives:[
        ArcAmplificationObjective('Damage Fireflies using Light Impact Grenades',1000),
        ArcAmplificationObjective('Damage Hornets using Light Impact Grenades',1000),
        ArcAmplificationObjective('Damage Fireballs using Light Impact Grenades',1000),
        ArcAmplificationObjective('Damage Surveyors using Light Impact Grenades',1000),
      ], material:'Rocketeer Driver',materialCount:5,targetEnemy:'Flying ARC',
    ),
    ArcAmplificationProject(
      id:'extended_burst_cycles', title:'Extended Burst Cycles', perk:'Increased Burst', weapons:['Aphelion','Burletta'],
      objectives:[ArcAmplificationObjective('Damage with Burst Burletta or Charged Burst Aphelion',10000)],
      material:'Comet Igniter',materialCount:10,
    ),
    ArcAmplificationProject(
      id:'high_voltage_exposure', title:'High-Voltage Exposure', perk:'Charged Burst', weapons:['Aphelion'],
      objectives:[ArcAmplificationObjective('Destroy ARC Turbines',5)],
      material:'Leaper Pulse Unit',materialCount:5,targetEnemy:'ARC Turbine',
    ),
    ArcAmplificationProject(
      id:'magazine_geometry_101', title:'Magazine Geometry 101', perk:'Drum Mag', weapons:['Rattler'],
      objectives:[ArcAmplificationObjective('Damage a Bastion with a Rattler',15000),ArcAmplificationObjective('Destroy Bastions with a Rattler',1)],
      material:'Bastion Cell',materialCount:5,targetEnemy:'Bastion',
    ),
    ArcAmplificationProject(
      id:'mobile_fire_grip_fittings', title:'Mobile-Fire Grip Fittings', perk:'Sprint Shooting', weapons:['Burletta','Canto','Hairpin','Rascal'],
      objectives:[
        ArcAmplificationObjective('Visit Electrical Substation in one raid',1,sameRaid:true),
        ArcAmplificationObjective('Visit Truck Stop in one raid',1,sameRaid:true),
        ArcAmplificationObjective('Visit Old Town in one raid',1,sameRaid:true),
        ArcAmplificationObjective('Visit Almatera Station in one raid',1,sameRaid:true),
        ArcAmplificationObjective('Visit Researcher Lodgings in one raid',1,sameRaid:true),
        ArcAmplificationObjective('Visit Deep-Space Telescope in one raid',1,sameRaid:true),
        ArcAmplificationObjective('Visit Commissary Supermarket in one raid',1,sameRaid:true),
      ], material:'Skulker Targeter',materialCount:20,
      sourceNote:'All seven locations must be visited in a single raid. Record completion only after finishing that run.',
    ),
    ArcAmplificationProject(
      id:'shield_stress_testing', title:'Shield Stress Testing', perk:'Anti-Shield', weapons:['Kettle'],
      objectives:[ArcAmplificationObjective('Damage encountered Raiders',700)],
      material:'Matriarch Reactor',materialCount:2,
    ),
    ArcAmplificationProject(
      id:'solid_core_casting_tech', title:'Solid-Core Casting Tech', perk:'Slug Rounds', weapons:['Il Toro'],
      objectives:[ArcAmplificationObjective('Destroy flying ARC using shotguns',50)],
      material:'Tick Pod',materialCount:20,targetEnemy:'Flying ARC',
    ),
    ArcAmplificationProject(
      id:'targeted_component_trial', title:'Targeted Component Trial', perk:'Anti-Weak Point', weapons:['Equalizer','Osprey'],
      objectives:[ArcAmplificationObjective('Destroy thrusters on flying ARC',40)],
      material:'Fireball Burner',materialCount:20,targetEnemy:'Flying ARC',
    ),
    ArcAmplificationProject(
      id:'thermite_tipped_rounds', title:'Thermite-Tipped Rounds', perk:'Incendiary Rounds', weapons:['Aphelion','Canto','Hairpin','Rattler'],
      objectives:[ArcAmplificationObjective('Destroy Fireballs with Explosive Mines',30)],
      material:'Firefly Burner',materialCount:5,targetEnemy:'Fireball',
    ),
    ArcAmplificationProject(
      id:'top_mounted_optics_retrofittings', title:'Top Mounted Optics Retrofittings', perk:'Scoped', weapons:['Jupiter','Renegade'],
      objectives:[ArcAmplificationObjective('Reach Pilgrim\'s Peak (Blue Gate) in one raid',1,sameRaid:true),ArcAmplificationObjective('Damage ARC with an Osprey in the same raid',1000,sameRaid:true)],
      material:'Snitch Scanner',materialCount:14,suggestedMap:'blue_gate',
      sourceNote:'Both objectives must be completed in the same raid.',
    ),
    ArcAmplificationProject(
      id:'trigger_reset_systems', title:'Trigger Reset Systems', perk:'Semi-Auto', weapons:['Bettina','Hairpin'],
      objectives:[ArcAmplificationObjective('Destroy Skulkers with a Raider Tool',5)],
      material:'Vaporizer Regulator',materialCount:4,targetEnemy:'Skulker',
    ),
  ];
  /// Costs are paid when a perk is applied to a specific amplified weapon.
  /// These costs are distinct from research hand-ins. Data: community wiki,
  /// verified against the Oct 2026 amplification tree. Unknown data is omitted.
  static const Map<String, Map<String,int>> nodeCosts = <String,Map<String,int>>{
    'Jupiter|action_economy': {'Fluted Rotor Core':3},
    'Osprey|action_economy': {'Fluted Rotor Core':3},
    'Equalizer|beam_resonance_tech': {'Queen Reactor':3},
    'Burletta|burst_assembly_recovery': {'Queen Reactor':2},
    'Hullcracker|compact_combustion_charges': {'Fossilized Lightning':3},
    'Rascal|compact_combustion_charges': {'Fossilized Lightning':3},
    'Anvil|embedded_blast_engineering': {'Fossilized Lightning':3},
    'Bettina|embedded_blast_engineering': {'Fossilized Lightning':3},
    'Kettle|embedded_blast_engineering': {'Fossilized Lightning':3},
    'Aphelion|extended_burst_cycles': {'Pressure Regulator':2},
    'Burletta|extended_burst_cycles': {'Pressure Regulator':2},
    'Aphelion|high_voltage_exposure': {'Queen Reactor':2},
    'Rattler|magazine_geometry_101': {'Pressure Regulator':4},
    'Burletta|mobile_fire_grip_fittings': {'Fluted Rotor Core':4},
    'Canto|mobile_fire_grip_fittings': {'Fluted Rotor Core':4},
    'Hairpin|mobile_fire_grip_fittings': {'Fluted Rotor Core':3},
    'Rascal|mobile_fire_grip_fittings': {'Fluted Rotor Core':2},
    'Kettle|shield_stress_testing': {'Assessor Matrix':3},
    'Il Toro|solid_core_casting_tech': {'Turbine Compressor':4},
    'Equalizer|targeted_component_trial': {'Assessor Matrix':2},
    'Osprey|targeted_component_trial': {'Assessor Matrix':2},
    'Aphelion|thermite_tipped_rounds': {'Fossilized Lightning':3},
    'Canto|thermite_tipped_rounds': {'Fossilized Lightning':3},
    'Hairpin|thermite_tipped_rounds': {'Fossilized Lightning':3},
    'Rattler|thermite_tipped_rounds': {'Fossilized Lightning':3},
    'Jupiter|top_mounted_optics_retrofittings': {'Fluted Rotor Core':3},
    'Renegade|top_mounted_optics_retrofittings': {'Fluted Rotor Core':4},
    'Bettina|trigger_reset_systems': {'Pneumatic Actuator':3},
    'Hairpin|trigger_reset_systems': {'Pneumatic Actuator':3},
  };
  static const Map<String, String> nodePrerequisites = <String,String>{
    'Rattler|magazine_geometry_101':'Requires More Reload first (2 Propellant Valve Assemblies)',
    'Burletta|extended_burst_cycles':'Requires Burst Fire first',
    'Aphelion|extended_burst_cycles':'Requires Charged Burst first',
    'Hairpin|mobile_fire_grip_fittings':'Requires Semi-Auto first',
    'Bettina|embedded_blast_engineering':'Requires Semi-Auto first',
  };
  /// Only verifiable research-vs-research branch conflicts are enforced here.
  /// Non-research nodes still require user confirmation in the game.
  static const Map<String,List<String>> researchNodeConflicts = <String,List<String>>{
    'Kettle|shield_stress_testing':['embedded_blast_engineering'],
    'Kettle|embedded_blast_engineering':['shield_stress_testing'],
    'Equalizer|beam_resonance_tech':['targeted_component_trial'],
    'Equalizer|targeted_component_trial':['beam_resonance_tech'],
    'Hairpin|thermite_tipped_rounds':['trigger_reset_systems'],
    'Hairpin|trigger_reset_systems':['thermite_tipped_rounds'],
  };
  static const Map<String,String> researchNodePrerequisites = <String,String>{
    'Aphelion|extended_burst_cycles':'high_voltage_exposure',
    'Burletta|extended_burst_cycles':'burst_assembly_recovery',
    'Hairpin|mobile_fire_grip_fittings':'trigger_reset_systems',
    'Bettina|embedded_blast_engineering':'trigger_reset_systems',
  };
  static Map<String,int>? nodeCost(String weapon,String researchId)=>nodeCosts['$weapon|$researchId'];
  static String? nodePrerequisite(String weapon,String researchId)=>nodePrerequisites['$weapon|$researchId'];
  static bool isKnownMaterial(String material) =>
    projects.any((p)=>p.material==material) ||
    nodeCosts.values.any((cost)=>cost.containsKey(material)) ||
    material == 'Propellant Valve Assembly';
  static ArcAmplificationProject project(String id) => projects.firstWhere((p) => p.id == id);
  static List<ArcAmplificationProject> forWeapon(String weapon) => projects.where((p) => p.weapons.contains(weapon)).toList(growable:false);
}
