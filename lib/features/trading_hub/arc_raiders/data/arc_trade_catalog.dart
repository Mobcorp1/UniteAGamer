class ArcTradeCatalogItem {
  final String id;
  final String name;
  final String category;
  final String group;
  final List<String> tags;
  final bool highDemand;

  const ArcTradeCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.group,
    this.tags = const <String>[],
    this.highDemand = false,
  });
}

class ArcTradeCatalog {
  static const List<ArcTradeCatalogItem> items = <ArcTradeCatalogItem>[
    // Seeds / currency
    ArcTradeCatalogItem(id: 'assorted-seeds', name: 'Assorted Seeds', category: 'Currency', group: 'Seeds', tags: ['seeds', 'currency'], highDemand: true),

    // Legendary / premium trade materials
    ArcTradeCatalogItem(id: 'queen-reactor', name: 'Queen Reactor', category: 'Legendary Material', group: 'Reactors', tags: ['reactor', 'legendary', 'queen'], highDemand: true),
    ArcTradeCatalogItem(id: 'matriarch-reactor', name: 'Matriarch Reactor', category: 'Legendary Material', group: 'Reactors', tags: ['reactor', 'legendary', 'matriarch'], highDemand: true),
    ArcTradeCatalogItem(id: 'assessor-matrix', name: 'Assessor Matrix', category: 'Rare Material', group: 'Core Components', tags: ['assessor', 'matrix'], highDemand: true),
    ArcTradeCatalogItem(id: 'bastion-cell', name: 'Bastion Cell', category: 'Epic Material', group: 'Cells', tags: ['cell', 'bastion']),
    ArcTradeCatalogItem(id: 'bombardier-cell', name: 'Bombardier Cell', category: 'Epic Material', group: 'Cells', tags: ['cell', 'bombardier']),
    ArcTradeCatalogItem(id: 'sentinel-firing-core', name: 'Sentinel Firing Core', category: 'Rare Material', group: 'Core Components', tags: ['core', 'sentinel']),
    ArcTradeCatalogItem(id: 'shredder-gyro', name: 'Shredder Gyro', category: 'Rare Material', group: 'Core Components', tags: ['gyro', 'shredder']),
    ArcTradeCatalogItem(id: 'flow-controller', name: 'Flow Controller', category: 'Rare Material', group: 'Core Components', tags: ['flow', 'controller']),

    // Keys
    ArcTradeCatalogItem(id: 'ancient-fort-security-code', name: 'Ancient Fort Security Code', category: 'Key', group: 'Security Codes', tags: ['key', 'code']),
    ArcTradeCatalogItem(id: 'blue-gate-cellar-key', name: 'Blue Gate Cellar Key', category: 'Key', group: 'Blue Gate Keys', tags: ['key', 'blue gate']),
    ArcTradeCatalogItem(id: 'blue-gate-communication-tower-key', name: 'Blue Gate Communication Tower Key', category: 'Key', group: 'Blue Gate Keys', tags: ['key', 'blue gate']),
    ArcTradeCatalogItem(id: 'blue-gate-confiscation-room-key', name: 'Blue Gate Confiscation Room Key', category: 'Key', group: 'Blue Gate Keys', tags: ['key', 'blue gate']),
    ArcTradeCatalogItem(id: 'blue-gate-village-key', name: 'Blue Gate Village Key', category: 'Key', group: 'Blue Gate Keys', tags: ['key', 'blue gate']),
    ArcTradeCatalogItem(id: 'buried-city-hospital-key', name: 'Buried City Hospital Key', category: 'Key', group: 'Buried City Keys', tags: ['key', 'buried city']),
    ArcTradeCatalogItem(id: 'buried-city-jkv-employee-access-card', name: 'Buried City JKV Employee Access Card', category: 'Key', group: 'Buried City Keys', tags: ['key', 'buried city', 'access card']),
    ArcTradeCatalogItem(id: 'buried-city-residential-master-key', name: 'Buried City Residential Master Key', category: 'Key', group: 'Buried City Keys', tags: ['key', 'buried city']),
    ArcTradeCatalogItem(id: 'buried-city-town-hall-key', name: 'Buried City Town Hall Key', category: 'Key', group: 'Buried City Keys', tags: ['key', 'buried city']),
    ArcTradeCatalogItem(id: 'dam-control-tower-key', name: 'Dam Control Tower Key', category: 'Key', group: 'Dam Keys', tags: ['key', 'dam']),
    ArcTradeCatalogItem(id: 'dam-controlled-access-zone-key', name: 'Dam Controlled Access Zone Key', category: 'Key', group: 'Dam Keys', tags: ['key', 'dam']),
    ArcTradeCatalogItem(id: 'dam-staff-room-key', name: 'Dam Staff Room Key', category: 'Key', group: 'Dam Keys', tags: ['key', 'dam']),
    ArcTradeCatalogItem(id: 'dam-surveillance-key', name: 'Dam Surveillance Key', category: 'Key', group: 'Dam Keys', tags: ['key', 'dam']),
    ArcTradeCatalogItem(id: 'dam-testing-annex-key', name: 'Dam Testing Annex Key', category: 'Key', group: 'Dam Keys', tags: ['key', 'dam']),
    ArcTradeCatalogItem(id: 'dam-utility-key', name: 'Dam Utility Key', category: 'Key', group: 'Dam Keys', tags: ['key', 'dam']),
    ArcTradeCatalogItem(id: 'patrol-car-key', name: 'Patrol Car Key', category: 'Key', group: 'Utility Keys', tags: ['key', 'vehicle']),
    ArcTradeCatalogItem(id: 'pilgrims-peak-security-code', name: "Pilgrim's Peak Security Code", category: 'Key', group: 'Security Codes', tags: ['key', 'code']),
    ArcTradeCatalogItem(id: 'raider-hatch-key', name: 'Raider Hatch Key', category: 'Key', group: 'Utility Keys', tags: ['key', 'hatch'], highDemand: true),
    ArcTradeCatalogItem(id: 'raiders-refuge-security-code', name: "Raider's Refuge Security Code", category: 'Key', group: 'Security Codes', tags: ['key', 'code']),
    ArcTradeCatalogItem(id: 'reinforced-reception-security-code', name: 'Reinforced Reception Security Code', category: 'Key', group: 'Security Codes', tags: ['key', 'code']),
    ArcTradeCatalogItem(id: 'spaceport-container-storage-key', name: 'Spaceport Container Storage Key', category: 'Key', group: 'Spaceport Keys', tags: ['key', 'spaceport']),
    ArcTradeCatalogItem(id: 'spaceport-control-tower-key', name: 'Spaceport Control Tower Key', category: 'Key', group: 'Spaceport Keys', tags: ['key', 'spaceport']),
    ArcTradeCatalogItem(id: 'spaceport-trench-tower-key', name: 'Spaceport Trench Tower Key', category: 'Key', group: 'Spaceport Keys', tags: ['key', 'spaceport']),
    ArcTradeCatalogItem(id: 'spaceport-warehouse-key', name: 'Spaceport Warehouse Key', category: 'Key', group: 'Spaceport Keys', tags: ['key', 'spaceport']),
    ArcTradeCatalogItem(id: 'stella-montis-archives-key', name: 'Stella Montis Archives Key', category: 'Key', group: 'Stella Montis Keys', tags: ['key', 'stella montis']),
    ArcTradeCatalogItem(id: 'stella-montis-assembly-admin-key', name: 'Stella Montis Assembly Admin Key', category: 'Key', group: 'Stella Montis Keys', tags: ['key', 'stella montis']),
    ArcTradeCatalogItem(id: 'stella-montis-medical-storage-key', name: 'Stella Montis Medical Storage Key', category: 'Key', group: 'Stella Montis Keys', tags: ['key', 'stella montis']),
    ArcTradeCatalogItem(id: 'stella-montis-security-checkpoint-key', name: 'Stella Montis Security Checkpoint Key', category: 'Key', group: 'Stella Montis Keys', tags: ['key', 'stella montis']),

    // Weapon mods
    ArcTradeCatalogItem(id: 'angled-grip-i', name: 'Angled Grip I', category: 'Weapon Mod', group: 'Grip'),
    ArcTradeCatalogItem(id: 'angled-grip-ii', name: 'Angled Grip II', category: 'Weapon Mod', group: 'Grip'),
    ArcTradeCatalogItem(id: 'angled-grip-iii', name: 'Angled Grip III', category: 'Weapon Mod', group: 'Grip'),
    ArcTradeCatalogItem(id: 'anvil-splitter', name: 'Anvil Splitter', category: 'Weapon Mod', group: 'Legendary Mod', highDemand: true),
    ArcTradeCatalogItem(id: 'compensator-i', name: 'Compensator I', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'compensator-ii', name: 'Compensator II', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'compensator-iii', name: 'Compensator III', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'extended-barrel', name: 'Extended Barrel', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'extended-light-mag-i', name: 'Extended Light Mag I', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-light-mag-ii', name: 'Extended Light Mag II', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-light-mag-iii', name: 'Extended Light Mag III', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-medium-mag-i', name: 'Extended Medium Mag I', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-medium-mag-ii', name: 'Extended Medium Mag II', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-medium-mag-iii', name: 'Extended Medium Mag III', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-shotgun-mag-i', name: 'Extended Shotgun Mag I', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-shotgun-mag-ii', name: 'Extended Shotgun Mag II', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'extended-shotgun-mag-iii', name: 'Extended Shotgun Mag III', category: 'Weapon Mod', group: 'Magazine'),
    ArcTradeCatalogItem(id: 'horizontal-grip', name: 'Horizontal Grip', category: 'Weapon Mod', group: 'Grip', highDemand: true),
    ArcTradeCatalogItem(id: 'kinetic-converter', name: 'Kinetic Converter', category: 'Weapon Mod', group: 'Legendary Mod', highDemand: true),
    ArcTradeCatalogItem(id: 'lightweight-stock', name: 'Lightweight Stock', category: 'Weapon Mod', group: 'Stock'),
    ArcTradeCatalogItem(id: 'muzzle-brake-i', name: 'Muzzle Brake I', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'muzzle-brake-ii', name: 'Muzzle Brake II', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'muzzle-brake-iii', name: 'Muzzle Brake III', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'padded-stock', name: 'Padded Stock', category: 'Weapon Mod', group: 'Stock'),
    ArcTradeCatalogItem(id: 'shotgun-choke-i', name: 'Shotgun Choke I', category: 'Weapon Mod', group: 'Shotgun Muzzle'),
    ArcTradeCatalogItem(id: 'shotgun-choke-ii', name: 'Shotgun Choke II', category: 'Weapon Mod', group: 'Shotgun Muzzle'),
    ArcTradeCatalogItem(id: 'shotgun-choke-iii', name: 'Shotgun Choke III', category: 'Weapon Mod', group: 'Shotgun Muzzle'),
    ArcTradeCatalogItem(id: 'shotgun-silencer', name: 'Shotgun Silencer', category: 'Weapon Mod', group: 'Shotgun Muzzle'),
    ArcTradeCatalogItem(id: 'silencer-i', name: 'Silencer I', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'silencer-ii', name: 'Silencer II', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'silencer-iii', name: 'Silencer III', category: 'Weapon Mod', group: 'Muzzle'),
    ArcTradeCatalogItem(id: 'stable-stock-i', name: 'Stable Stock I', category: 'Weapon Mod', group: 'Stock'),
    ArcTradeCatalogItem(id: 'stable-stock-ii', name: 'Stable Stock II', category: 'Weapon Mod', group: 'Stock'),
    ArcTradeCatalogItem(id: 'stable-stock-iii', name: 'Stable Stock III', category: 'Weapon Mod', group: 'Stock'),
    ArcTradeCatalogItem(id: 'vertical-grip-i', name: 'Vertical Grip I', category: 'Weapon Mod', group: 'Grip'),
    ArcTradeCatalogItem(id: 'vertical-grip-ii', name: 'Vertical Grip II', category: 'Weapon Mod', group: 'Grip'),
    ArcTradeCatalogItem(id: 'vertical-grip-iii', name: 'Vertical Grip III', category: 'Weapon Mod', group: 'Grip'),

    // Weapons
    ArcTradeCatalogItem(id: 'kettle', name: 'Kettle', category: 'Weapon', group: 'Assault Rifle'),
    ArcTradeCatalogItem(id: 'rattler', name: 'Rattler', category: 'Weapon', group: 'Assault Rifle'),
    ArcTradeCatalogItem(id: 'arpeggio', name: 'Arpeggio', category: 'Weapon', group: 'Assault Rifle'),
    ArcTradeCatalogItem(id: 'tempest', name: 'Tempest', category: 'Weapon', group: 'Assault Rifle'),
    ArcTradeCatalogItem(id: 'bettina', name: 'Bettina', category: 'Weapon', group: 'Assault Rifle', highDemand: true),
    ArcTradeCatalogItem(id: 'ferro', name: 'Ferro', category: 'Weapon', group: 'Battle Rifle'),
    ArcTradeCatalogItem(id: 'renegade', name: 'Renegade', category: 'Weapon', group: 'Battle Rifle'),
    ArcTradeCatalogItem(id: 'aphelion', name: 'Aphelion', category: 'Weapon', group: 'Legendary Weapon', highDemand: true),
    ArcTradeCatalogItem(id: 'stitcher', name: 'Stitcher', category: 'Weapon', group: 'SMG'),
    ArcTradeCatalogItem(id: 'canto', name: 'Canto', category: 'Weapon', group: 'SMG', highDemand: true),
    ArcTradeCatalogItem(id: 'bobcat', name: 'Bobcat', category: 'Weapon', group: 'SMG'),
    ArcTradeCatalogItem(id: 'il-toro', name: 'Il Toro', category: 'Weapon', group: 'Shotgun'),
    ArcTradeCatalogItem(id: 'vulcano', name: 'Vulcano', category: 'Weapon', group: 'Shotgun'),
    ArcTradeCatalogItem(id: 'dolabra', name: 'Dolabra', category: 'Weapon', group: 'Legendary Weapon', highDemand: true),
    ArcTradeCatalogItem(id: 'hairpin', name: 'Hairpin', category: 'Weapon', group: 'Pistol'),
    ArcTradeCatalogItem(id: 'burletta', name: 'Burletta', category: 'Weapon', group: 'Pistol'),
    ArcTradeCatalogItem(id: 'venator', name: 'Venator', category: 'Weapon', group: 'Pistol'),
    ArcTradeCatalogItem(id: 'anvil', name: 'Anvil', category: 'Weapon', group: 'Hand Cannon'),
    ArcTradeCatalogItem(id: 'torrente', name: 'Torrente', category: 'Weapon', group: 'LMG'),
    ArcTradeCatalogItem(id: 'osprey', name: 'Osprey', category: 'Weapon', group: 'Sniper Rifle'),
    ArcTradeCatalogItem(id: 'jupiter', name: 'Jupiter', category: 'Weapon', group: 'Legendary Weapon', highDemand: true),
    ArcTradeCatalogItem(id: 'hullcracker', name: 'Hullcracker', category: 'Weapon', group: 'Special Weapon'),
    ArcTradeCatalogItem(id: 'equalizer', name: 'Equalizer', category: 'Weapon', group: 'Legendary Weapon', highDemand: true),

    // Core materials / crafted components
    ArcTradeCatalogItem(id: 'arc-alloy', name: 'ARC Alloy', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'arc-circuitry', name: 'ARC Circuitry', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'arc-coolant', name: 'ARC Coolant', category: 'Material', group: 'Recyclable'),
    ArcTradeCatalogItem(id: 'arc-flex-rubber', name: 'ARC Flex Rubber', category: 'Material', group: 'Recyclable'),
    ArcTradeCatalogItem(id: 'arc-motion-core', name: 'ARC Motion Core', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'arc-performance-steel', name: 'ARC Performance Steel', category: 'Material', group: 'Recyclable'),
    ArcTradeCatalogItem(id: 'arc-powercell', name: 'ARC Powercell', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'advanced-arc-powercell', name: 'Advanced ARC Powercell', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'arc-synthetic-resin', name: 'ARC Synthetic Resin', category: 'Material', group: 'Recyclable'),
    ArcTradeCatalogItem(id: 'arc-thermo-lining', name: 'ARC Thermo Lining', category: 'Material', group: 'Recyclable'),
    ArcTradeCatalogItem(id: 'advanced-electrical-components', name: 'Advanced Electrical Components', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'advanced-mechanical-components', name: 'Advanced Mechanical Components', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'electrical-components', name: 'Electrical Components', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'mechanical-components', name: 'Mechanical Components', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'mod-components', name: 'Mod Components', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'metal-parts', name: 'Metal Parts', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'plastic-parts', name: 'Plastic Parts', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'rubber-parts', name: 'Rubber Parts', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'fabric', name: 'Fabric', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'chemicals', name: 'Chemicals', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'wires', name: 'Wires', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'duct-tape', name: 'Duct Tape', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'processor', name: 'Processor', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'steel-spring', name: 'Steel Spring', category: 'Material', group: 'Refined Material'),
    ArcTradeCatalogItem(id: 'canister', name: 'Canister', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'crude-explosives', name: 'Crude Explosives', category: 'Material', group: 'Explosive Material'),
    ArcTradeCatalogItem(id: 'explosive-compound', name: 'Explosive Compound', category: 'Material', group: 'Explosive Material'),
    ArcTradeCatalogItem(id: 'sensors', name: 'Sensors', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'oil', name: 'Oil', category: 'Material', group: 'Basic Material'),
    ArcTradeCatalogItem(id: 'antiseptic', name: 'Antiseptic', category: 'Material', group: 'Medical Material'),
    ArcTradeCatalogItem(id: 'syringe', name: 'Syringe', category: 'Material', group: 'Medical Material'),
    ArcTradeCatalogItem(id: 'bandage', name: 'Bandage', category: 'Material', group: 'Medical Material'),
    ArcTradeCatalogItem(id: 'voltage-converter', name: 'Voltage Converter', category: 'Material', group: 'Core Components'),
    ArcTradeCatalogItem(id: 'frequency-modulation-box', name: 'Frequency Modulation Box', category: 'Material', group: 'Core Components'),
    ArcTradeCatalogItem(id: 'fried-motherboard', name: 'Fried Motherboard', category: 'Material', group: 'Core Components'),
    ArcTradeCatalogItem(id: 'sample-cleaner', name: 'Sample Cleaner', category: 'Material', group: 'Nature / Lab'),
    ArcTradeCatalogItem(id: 'rusted-shut-medical-kit', name: 'Rusted Shut Medical Kit', category: 'Material', group: 'Medical Material'),
    ArcTradeCatalogItem(id: 'rusted-tools', name: 'Rusted Tools', category: 'Material', group: 'Mechanical'),
    ArcTradeCatalogItem(id: 'rusty-arc-steel', name: 'Rusty ARC Steel', category: 'Material', group: 'Mechanical'),
    ArcTradeCatalogItem(id: 'battery', name: 'Battery', category: 'Material', group: 'Topside Material'),
    ArcTradeCatalogItem(id: 'fireball-burner', name: 'Fireball Burner', category: 'Material', group: 'Explosive Material'),
    ArcTradeCatalogItem(id: 'firefly-burner', name: 'Firefly Burner', category: 'Material', group: 'Explosive Material'),
    ArcTradeCatalogItem(id: 'fertilizer', name: 'Fertilizer', category: 'Material', group: 'Nature / Lab'),
    ArcTradeCatalogItem(id: 'agave', name: 'Agave', category: 'Material', group: 'Nature / Lab'),
    ArcTradeCatalogItem(id: 'apricot', name: 'Apricot', category: 'Material', group: 'Nature / Lab'),
  ];

  static List<ArcTradeCatalogItem> get sortedItems {
    final copy = List<ArcTradeCatalogItem>.from(items);
    copy.sort((a, b) {
      final highDemandCompare = b.highDemand ? 1 : 0;
      final otherHighDemandCompare = a.highDemand ? 1 : 0;
      if (highDemandCompare != otherHighDemandCompare) {
        return highDemandCompare.compareTo(otherHighDemandCompare);
      }
      final categoryCompare = a.category.toLowerCase().compareTo(b.category.toLowerCase());
      if (categoryCompare != 0) return categoryCompare;
      final groupCompare = a.group.toLowerCase().compareTo(b.group.toLowerCase());
      if (groupCompare != 0) return groupCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }
}
