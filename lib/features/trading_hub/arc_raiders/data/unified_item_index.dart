import 'package:flutter/foundation.dart';

@immutable
class UnifiedItemEntry {
  const UnifiedItemEntry({
    required this.id,
    required this.name,
    required this.usedIn,
    this.aliases = const <String>[],
  });
  final String id;
  final String name;
  final List<String> usedIn;
  final List<String> aliases;
  bool get neededForBench => usedIn.contains('Bench Tracker');
  bool get neededForQuest => usedIn.contains('Quest Tracker');
  bool get neededForScrappy => usedIn.contains('Scrappy Tracker');
  bool get tradeRelevant => usedIn.contains('Trading Hub');
}

class UnifiedItemIndex {
  const UnifiedItemIndex._();
  static const List<UnifiedItemEntry> items = <UnifiedItemEntry>[
    UnifiedItemEntry(
      id: 'acoustic-guitar',
      name: 'Acoustic Guitar',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'adrenaline-shot',
      name: 'Adrenaline Shot',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'advanced-arc-powercell',
      name: 'Advanced ARC Powercell',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'advanced-electrical-components',
      name: 'Advanced Electrical Components',
      usedIn: <String>['Bench Tracker', 'Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'advanced-mechanical-components',
      name: 'Advanced Mechanical Components',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'agave',
      name: 'Agave',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'agave-juice',
      name: 'Agave Juice',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'alien-duck',
      name: 'Alien Duck',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'ancient-fort-security-code',
      name: 'Ancient Fort Security Code',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'angled-grip-i',
      name: 'Angled Grip I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'angled-grip-ii',
      name: 'Angled Grip II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'angled-grip-iii',
      name: 'Angled Grip III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'antiseptic',
      name: 'Antiseptic',
      usedIn: <String>['Bench Tracker', 'Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'anvil',
      name: 'Anvil',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'anvil-splitter',
      name: 'Anvil Splitter',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'aphelion',
      name: 'Aphelion',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'apricot',
      name: 'Apricot',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'apricots-tier-2',
      name: 'Apricots',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>['apricots tier 2', 'apricots tier 4'],
    ),
    UnifiedItemEntry(
      id: 'arc-alloy',
      name: 'ARC Alloy',
      usedIn: <String>['Bench Tracker', 'Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-circuitry',
      name: 'ARC Circuitry',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-coolant',
      name: 'ARC Coolant',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-flex-rubber',
      name: 'ARC Flex Rubber',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-motion-core',
      name: 'ARC Motion Core',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-motion-cores',
      name: 'ARC Motion Cores',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-performance-steel',
      name: 'ARC Performance Steel',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-powercell',
      name: 'ARC Powercell',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-powercells',
      name: 'ARC Powercells',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-synthetic-resin',
      name: 'ARC Synthetic Resin',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arc-thermo-lining',
      name: 'ARC Thermo Lining',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'arpeggio',
      name: 'Arpeggio',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'assessor-matrix',
      name: 'Assessor Matrix',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'assorted-seeds',
      name: 'Assorted Seeds',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bandage',
      name: 'Bandage',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bastion-cell',
      name: 'Bastion Cell',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bastion-cells',
      name: 'Bastion Cells',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'battery',
      name: 'Battery',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'beachcombing-cache',
      name: 'Beachcombing Cache',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bettina',
      name: 'Bettina',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bicycle-pump',
      name: 'Bicycle Pump',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'blue-gate-cellar-key',
      name: 'Blue Gate Cellar Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'blue-gate-communication-tower-key',
      name: 'Blue Gate Communication Tower Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'blue-gate-confiscation-room-key',
      name: 'Blue Gate Confiscation Room Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'blue-gate-village-key',
      name: 'Blue Gate Village Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bobcat',
      name: 'Bobcat',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bombardier-cell',
      name: 'Bombardier Cell',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'bombardier-cells',
      name: 'Bombardier Cells',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'breach-room',
      name: 'Breach Room',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'breach-room-key',
      name: 'Breach Room Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'buried-city-hospital-key',
      name: 'Buried City Hospital Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'buried-city-jkv-employee-access-card',
      name: 'Buried City JKV Employee Access Card',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'buried-city-residential-master-key',
      name: 'Buried City Residential Master Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'buried-city-town-hall-key',
      name: 'Buried City Town Hall Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'burletta',
      name: 'Burletta',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'camera-lens',
      name: 'Camera Lens',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'canister',
      name: 'Canister',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'canto',
      name: 'Canto',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'cat-bed',
      name: 'Cat Bed',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'chemicals',
      name: 'Chemicals',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'chip-pods',
      name: 'Chip Pods',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'coffee-pot',
      name: 'Coffee Pot',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'comet-igniter',
      name: 'Comet Igniter',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'compensator-i',
      name: 'Compensator I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'compensator-ii',
      name: 'Compensator II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'compensator-iii',
      name: 'Compensator III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'complex-gun-parts',
      name: 'Complex Gun Parts',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'cool-box-on-wheels',
      name: 'Cool Box on Wheels',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'cracked-bioscanners',
      name: 'Cracked Bioscanners',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'crude-explosives',
      name: 'Crude Explosives',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dam-control-tower-key',
      name: 'Dam Control Tower Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dam-controlled-access-zone-key',
      name: 'Dam Controlled Access Zone Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dam-staff-room-key',
      name: 'Dam Staff Room Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dam-surveillance-key',
      name: 'Dam Surveillance Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dam-testing-annex-key',
      name: 'Dam Testing Annex Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dam-utility-key',
      name: 'Dam Utility Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'damaged-heat-sink',
      name: 'Damaged Heat Sink',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'damaged-heat-sinks',
      name: 'Damaged Heat Sinks',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'deflated-football',
      name: 'Deflated Football',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dog-collar',
      name: 'Dog Collar',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'dolabra',
      name: 'Dolabra',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'duct-tape',
      name: 'Duct Tape',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'durable-cloth',
      name: 'Durable Cloth',
      usedIn: <String>['Bench Tracker', 'Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'electrical-components',
      name: 'Electrical Components',
      usedIn: <String>['Bench Tracker', 'Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'empty-wine-bottle',
      name: 'Empty Wine Bottle',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'energy-ammo',
      name: 'Energy Ammo',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'equalizer',
      name: 'Equalizer',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'espresso-machine-parts',
      name: 'Espresso Machine Parts',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'exodus-module',
      name: 'Exodus Module',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'explosive-compound',
      name: 'Explosive Compound',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'explosive-compounds',
      name: 'Explosive Compounds',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-barrel',
      name: 'Extended Barrel',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-light-mag-i',
      name: 'Extended Light Mag I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-light-mag-ii',
      name: 'Extended Light Mag II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-light-mag-iii',
      name: 'Extended Light Mag III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-medium-mag-i',
      name: 'Extended Medium Mag I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-medium-mag-ii',
      name: 'Extended Medium Mag II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-medium-mag-iii',
      name: 'Extended Medium Mag III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-shotgun-mag-i',
      name: 'Extended Shotgun Mag I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-shotgun-mag-ii',
      name: 'Extended Shotgun Mag II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'extended-shotgun-mag-iii',
      name: 'Extended Shotgun Mag III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fabric',
      name: 'Fabric',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'faded-photograph',
      name: 'Faded Photograph',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'ferro',
      name: 'Ferro',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fertiliser',
      name: 'Fertiliser',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fertilizer',
      name: 'Fertilizer',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'film-reel',
      name: 'Film Reel',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fine-wristwatch',
      name: 'Fine Wristwatch',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fireball-burner',
      name: 'Fireball Burner',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fireball-burners',
      name: 'Fireball Burners',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'firefly-burner',
      name: 'Firefly Burner',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fireworks-box',
      name: 'Fireworks Box',
      usedIn: <String>['Quest Tracker'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'flow-controller',
      name: 'Flow Controller',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'frequency-modulation-box',
      name: 'Frequency Modulation Box',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fried-motherboard',
      name: 'Fried Motherboard',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'fried-motherboards',
      name: 'Fried Motherboards',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'great-mullein',
      name: 'Great Mullein',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'hairpin',
      name: 'Hairpin',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'harvester-components',
      name: 'Harvester Components',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'heavy-gun-parts',
      name: 'Heavy Gun Parts',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'high-durability-weapon',
      name: 'High Durability Weapon',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'high-security-key',
      name: 'High Security Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'horizontal-grip',
      name: 'Horizontal Grip',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'hornet-driver',
      name: 'Hornet Driver',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'hornet-drivers',
      name: 'Hornet Drivers',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'hullcracker',
      name: 'Hullcracker',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'il-toro',
      name: 'Il Toro',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'industrial-batteries',
      name: 'Industrial Batteries',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'industrial-battery',
      name: 'Industrial Battery',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'jupiter',
      name: 'Jupiter',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'kettle',
      name: 'Kettle',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'kinetic-converter',
      name: 'Kinetic Converter',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'l4-weapon',
      name: 'L4 Weapon',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'laboratory-reagents',
      name: 'Laboratory Reagents',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'leaper-pulse-unit',
      name: 'Leaper Pulse Unit',
      usedIn: <String>['Quest Tracker'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'leaper-pulse-units',
      name: 'Leaper Pulse Units',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'lemon',
      name: 'Lemon',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'lemons',
      name: 'Lemons',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'leviathans-crown-ship-model',
      name: 'Leviathan’s Crown Ship Model',
      usedIn: <String>['Trading Hub'],
      aliases: <String>['leviathans crown ship model'],
    ),
    UnifiedItemEntry(
      id: 'light-gun-parts',
      name: 'Light Gun Parts',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'light-impact-grenade',
      name: 'Light Impact Grenade',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'lightweight-stock',
      name: 'Lightweight Stock',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'locked-room',
      name: 'Locked Room',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'locked-room-key',
      name: 'Locked Room Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'magnet',
      name: 'Magnet',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'magnetic-accelerator',
      name: 'Magnetic Accelerator',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'matriarch-components',
      name: 'Matriarch Components',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'matriarch-reactor',
      name: 'Matriarch Reactor',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'mechanical-components',
      name: 'Mechanical Components',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'medical-kit',
      name: 'Medical Kit',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'medium-gun-parts',
      name: 'Medium Gun Parts',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'metal-parts',
      name: 'Metal Parts',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'micro-arc-reactor',
      name: 'Micro ARC Reactor',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'mod-components',
      name: 'Mod Components',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'modded-weapon',
      name: 'Modded Weapon',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'moss',
      name: 'Moss',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'motor',
      name: 'Motor',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'motors',
      name: 'Motors',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'mushroom',
      name: 'Mushroom',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'mushrooms',
      name: 'Mushrooms',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'music-box',
      name: 'Music Box',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'muzzle-brake-i',
      name: 'Muzzle Brake I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'muzzle-brake-ii',
      name: 'Muzzle Brake II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'muzzle-brake-iii',
      name: 'Muzzle Brake III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'oil',
      name: 'Oil',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'olives',
      name: 'Olives',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'osprey',
      name: 'Osprey',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'padded-stock',
      name: 'Padded Stock',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'patrol-car-key',
      name: 'Patrol Car Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'plastic-parts',
      name: 'Plastic Parts',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'pop-trigger',
      name: 'Pop Trigger',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'pop-triggers',
      name: 'Pop Triggers',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'portable-tv',
      name: 'Portable TV',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'power-cable',
      name: 'Power Cable',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'power-cables',
      name: 'Power Cables',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'power-clips',
      name: 'Power Clips',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'power-rod',
      name: 'Power Rod',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'prickly-pear',
      name: 'Prickly Pear',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'prickly-pears',
      name: 'Prickly Pears',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'processor',
      name: 'Processor',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'queen-reactor',
      name: 'Queen Reactor',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'raider-cache',
      name: 'Raider Cache',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'pilgrims-peak-security-code',
      name: 'Raider Hatch Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>['pilgrims peak security code'],
    ),
    UnifiedItemEntry(
      id: 'rattler',
      name: 'Rattler',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'recorder',
      name: 'Recorder',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'red-coral-jewelry',
      name: 'Red Coral Jewelry',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'raiders-refuge-security-code',
      name: 'Reinforced Reception Security Code',
      usedIn: <String>['Trading Hub'],
      aliases: <String>['raiders refuge security code'],
    ),
    UnifiedItemEntry(
      id: 'renegade',
      name: 'Renegade',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rocketeer-driver',
      name: 'Rocketeer Driver',
      usedIn: <String>['Quest Tracker'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rocketeer-drivers',
      name: 'Rocketeer Drivers',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'roots',
      name: 'Roots',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rubber-duck',
      name: 'Rubber Duck',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rubber-parts',
      name: 'Rubber Parts',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rusted-gears',
      name: 'Rusted Gears',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rusted-shut-medical-kit',
      name: 'Rusted Shut Medical Kit',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rusted-shut-medical-kits',
      name: 'Rusted Shut Medical Kits',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rusted-tools',
      name: 'Rusted Tools',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'rusty-arc-steel',
      name: 'Rusty ARC Steel',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'sample-cleaner',
      name: 'Sample Cleaner',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'sensors',
      name: 'Sensors',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'sentinel-firing-core',
      name: 'Sentinel Firing Core',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'sentinel-firing-cores',
      name: 'Sentinel Firing Cores',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'shotgun-choke-i',
      name: 'Shotgun Choke I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'shotgun-choke-ii',
      name: 'Shotgun Choke II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'shotgun-choke-iii',
      name: 'Shotgun Choke III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'shotgun-silencer',
      name: 'Shotgun Silencer',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'shredder-gyro',
      name: 'Shredder Gyro',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'silencer-i',
      name: 'Silencer I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'silencer-ii',
      name: 'Silencer II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'silencer-iii',
      name: 'Silencer III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'simple-gun-parts',
      name: 'Simple Gun Parts',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'snitch-scanner',
      name: 'Snitch Scanner',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'snitch-scanners',
      name: 'Snitch Scanners',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'sorena-dorata-ship-model',
      name: 'Sorena Dorata Ship Model',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'spaceport-container-storage-key',
      name: 'Spaceport Container Storage Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'spaceport-control-tower-key',
      name: 'Spaceport Control Tower Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'spaceport-trench-tower-key',
      name: 'Spaceport Trench Tower Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'spaceport-warehouse-key',
      name: 'Spaceport Warehouse Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stable-stock-i',
      name: 'Stable Stock I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stable-stock-ii',
      name: 'Stable Stock II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stable-stock-iii',
      name: 'Stable Stock III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stack-of-movie-tapes',
      name: 'Stack Of Movie Tapes',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'standard-ammo',
      name: 'Standard Ammo',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'statuette',
      name: 'Statuette',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'steel-spring',
      name: 'Steel Spring',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'steel-springs',
      name: 'Steel Springs',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stella-montis-archives-key',
      name: 'Stella Montis Archives Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stella-montis-assembly-admin-key',
      name: 'Stella Montis Assembly Admin Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stella-montis-medical-storage-key',
      name: 'Stella Montis Medical Storage Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stella-montis-security-checkpoint-key',
      name: 'Stella Montis Security Checkpoint Key',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'stitcher',
      name: 'Stitcher',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'suitcase',
      name: 'Suitcase',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'surveyor-vault',
      name: 'Surveyor Vault',
      usedIn: <String>['Quest Tracker'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'surveyor-vaults',
      name: 'Surveyor Vaults',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'synthesized-fuel',
      name: 'Synthesized Fuel',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'syringe',
      name: 'Syringe',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'tempest',
      name: 'Tempest',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'tick-pod',
      name: 'Tick Pod',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'tick-pod-canister',
      name: 'Tick Pod Canister',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'tick-pods',
      name: 'Tick Pods',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'toasters',
      name: 'Toasters',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'torrente',
      name: 'Torrente',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'turbine-compressor',
      name: 'Turbine Compressor',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'twilight-compass-ship-model',
      name: 'Twilight Compass Ship Model',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vaporizer-regulator',
      name: 'Vaporizer Regulator',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vase',
      name: 'Vase',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'velocity-ship-model',
      name: 'Velocity Ship Model',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'venator',
      name: 'Venator',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vertical-grip-i',
      name: 'Vertical Grip I',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vertical-grip-ii',
      name: 'Vertical Grip II',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vertical-grip-iii',
      name: 'Vertical Grip III',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'very-comfortable-pillows',
      name: 'Very Comfortable Pillows',
      usedIn: <String>['Bench Tracker', 'Scrappy Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vita-shot',
      name: 'Vita Shot',
      usedIn: <String>['Quest Tracker'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'voltage-converter',
      name: 'Voltage Converter',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vortex-components',
      name: 'Vortex Components',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'vulcano',
      name: 'Vulcano',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'wasp-driver',
      name: 'Wasp Driver',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'wasp-drivers',
      name: 'Wasp Drivers',
      usedIn: <String>['Bench Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'water-filter',
      name: 'Water Filter',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'weapon-case',
      name: 'Weapon Case',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'wind-sprite-ship-model',
      name: 'Wind Sprite Ship Model',
      usedIn: <String>['Trading Hub'],
      aliases: <String>[],
    ),
    UnifiedItemEntry(
      id: 'wires',
      name: 'Wires',
      usedIn: <String>['Quest Tracker', 'Trading Hub'],
      aliases: <String>[],
    ),
  ];

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static UnifiedItemEntry? findBest(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return null;
    for (final item in items) {
      if (normalize(item.name) == normalized ||
          normalize(item.id) == normalized)
        return item;
      for (final alias in item.aliases) {
        if (normalize(alias) == normalized) return item;
      }
    }
    for (final item in items) {
      final name = normalize(item.name);
      if (name.contains(normalized) || normalized.contains(name)) return item;
      for (final alias in item.aliases) {
        final normalizedAlias = normalize(alias);
        if (normalizedAlias.contains(normalized) ||
            normalized.contains(normalizedAlias))
          return item;
      }
    }
    return null;
  }

  static List<UnifiedItemEntry> search(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return const <UnifiedItemEntry>[];
    return items
        .where((item) {
          final name = normalize(item.name);
          if (name.contains(normalized) || normalized.contains(name))
            return true;
          return item.aliases.any(
            (alias) => normalize(alias).contains(normalized),
          );
        })
        .take(20)
        .toList(growable: false);
  }
}
