import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';

class ArcBenchUpgradeRequirement {
  final String station;
  final int level;
  final String itemId;
  final String itemName;
  final int quantity;

  const ArcBenchUpgradeRequirement({
    required this.station,
    required this.level,
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  String get upgradeLabel => '$station Lv.$level';
}

class ArcBenchUpgradeSeedData {
  static const int columns = 3;

  static const List stationOrder = [
    'Gunsmith',
    'Explosives Station',
    'Gear Bench',
    'Medical Lab',
    'Utility Station',
    'Refiner',
  ];

  static const List requirements = [
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 1,
      itemId: 'metal-parts',
      itemName: 'Metal Parts',
      quantity: 20,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 1,
      itemId: 'rubber-parts',
      itemName: 'Rubber Parts',
      quantity: 30,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 2,
      itemId: 'rusted-tools',
      itemName: 'Rusted Tools',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 2,
      itemId: 'mechanical-components',
      itemName: 'Mechanical Components',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 2,
      itemId: 'wasp-drivers',
      itemName: 'Wasp Drivers',
      quantity: 8,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 3,
      itemId: 'rusted-gears',
      itemName: 'Rusted Gears',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 3,
      itemId: 'advanced-mechanical-components',
      itemName: 'Advanced Mechanical Components',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gunsmith',
      level: 3,
      itemId: 'sentinel-firing-cores',
      itemName: 'Sentinel Firing Cores',
      quantity: 4,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 1,
      itemId: 'chemicals',
      itemName: 'Chemicals',
      quantity: 50,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 1,
      itemId: 'arc-alloy',
      itemName: 'ARC Alloy',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 2,
      itemId: 'synthesized-fuel',
      itemName: 'Synthesized Fuel',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 2,
      itemId: 'crude-explosives',
      itemName: 'Crude Explosives',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 2,
      itemId: 'pop-triggers',
      itemName: 'Pop Triggers',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 3,
      itemId: 'laboratory-reagents',
      itemName: 'Laboratory Reagents',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 3,
      itemId: 'explosive-compounds',
      itemName: 'Explosive Compounds',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Explosives Station',
      level: 3,
      itemId: 'rocketeer-drivers',
      itemName: 'Rocketeer Drivers',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 1,
      itemId: 'plastic-parts',
      itemName: 'Plastic Parts',
      quantity: 25,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 1,
      itemId: 'fabric',
      itemName: 'Fabric',
      quantity: 30,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 2,
      itemId: 'power-cables',
      itemName: 'Power Cables',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 2,
      itemId: 'electrical-components',
      itemName: 'Electrical Components',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 2,
      itemId: 'hornet-drivers',
      itemName: 'Hornet Drivers',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 3,
      itemId: 'industrial-batteries',
      itemName: 'Industrial Batteries',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 3,
      itemId: 'advanced-electrical-components',
      itemName: 'Advanced Electrical Components',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Gear Bench',
      level: 3,
      itemId: 'bastion-cells',
      itemName: 'Bastion Cells',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 1,
      itemId: 'fabric',
      itemName: 'Fabric',
      quantity: 50,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 1,
      itemId: 'arc-alloy',
      itemName: 'ARC Alloy',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 2,
      itemId: 'cracked-bioscanners',
      itemName: 'Cracked Bioscanners',
      quantity: 2,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 2,
      itemId: 'durable-cloth',
      itemName: 'Durable Cloth',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 2,
      itemId: 'tick-pods',
      itemName: 'Tick Pods',
      quantity: 8,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 3,
      itemId: 'rusted-shut-medical-kits',
      itemName: 'Rusted Shut Medical Kits',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 3,
      itemId: 'antiseptic',
      itemName: 'Antiseptic',
      quantity: 8,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Medical Lab',
      level: 3,
      itemId: 'surveyor-vaults',
      itemName: 'Surveyor Vaults',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 1,
      itemId: 'plastic-parts',
      itemName: 'Plastic Parts',
      quantity: 50,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 1,
      itemId: 'arc-alloy',
      itemName: 'ARC Alloy',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 2,
      itemId: 'damaged-heat-sinks',
      itemName: 'Damaged Heat Sinks',
      quantity: 2,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 2,
      itemId: 'electrical-components',
      itemName: 'Electrical Components',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 2,
      itemId: 'snitch-scanners',
      itemName: 'Snitch Scanners',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 3,
      itemId: 'fried-motherboards',
      itemName: 'Fried Motherboards',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 3,
      itemId: 'advanced-electrical-components',
      itemName: 'Advanced Electrical Components',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Utility Station',
      level: 3,
      itemId: 'leaper-pulse-units',
      itemName: 'Leaper Pulse Units',
      quantity: 4,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 1,
      itemId: 'metal-parts',
      itemName: 'Metal Parts',
      quantity: 60,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 1,
      itemId: 'arc-powercells',
      itemName: 'ARC Powercells',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 2,
      itemId: 'toasters',
      itemName: 'Toasters',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 2,
      itemId: 'arc-motion-cores',
      itemName: 'ARC Motion Cores',
      quantity: 5,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 2,
      itemId: 'fireball-burners',
      itemName: 'Fireball Burners',
      quantity: 8,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 3,
      itemId: 'motors',
      itemName: 'Motors',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 3,
      itemId: 'arc-circuitry',
      itemName: 'ARC Circuitry',
      quantity: 10,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Refiner',
      level: 3,
      itemId: 'bombardier-cells',
      itemName: 'Bombardier Cells',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 2,
      itemId: 'dog-collar',
      itemName: 'Dog Collar',
      quantity: 1,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 3,
      itemId: 'lemons',
      itemName: 'Lemons',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 3,
      itemId: 'apricots',
      itemName: 'Apricots',
      quantity: 3,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 4,
      itemId: 'prickly-pears',
      itemName: 'Prickly Pears',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 4,
      itemId: 'olives',
      itemName: 'Olives',
      quantity: 6,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 4,
      itemId: 'cat-bed',
      itemName: 'Cat Bed',
      quantity: 1,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 5,
      itemId: 'mushrooms',
      itemName: 'Mushrooms',
      quantity: 12,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 5,
      itemId: 'apricots',
      itemName: 'Apricots',
      quantity: 12,
    ),
    ArcBenchUpgradeRequirement(
      station: 'Scrappy',
      level: 5,
      itemId: 'very-comfortable-pillows',
      itemName: 'Very Comfortable Pillows',
      quantity: 3,
    ),
  ];

  static List get items {
    final benchRequirements = requirements
        .where((requirement) => requirement.station != 'Scrappy')
        .toList(growable: false);

    return [
      for (var index = 0; index < benchRequirements.length; index++)
        _toScrappyItem(benchRequirements[index], index),
    ];
  }

  static Map<String, Map<int, List<ArcScrappyItem>>> get groupedItems {
    final grouped = <String, Map<int, List<ArcScrappyItem>>>{};
    for (final item in items) {
      final level = _levelFromGroup(item.group);
      grouped.putIfAbsent(item.category, () => <int, List<ArcScrappyItem>>{});
      grouped[item.category]!.putIfAbsent(level, () => []);
      grouped[item.category]![level]!.add(item);
    }
    for (final stationLevels in grouped.values) {
      for (final levelItems in stationLevels.values) {
        levelItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    }
    return grouped;
  }

  static List levelsForStation(String station) {
    final levels =
        requirements
            .where((requirement) => requirement.station == station)
            .map((requirement) => requirement.level)
            .toSet()
            .toList()
          ..sort();
    return levels;
  }

  static List itemsForStation(String station) {
    return items
        .where((item) => item.category == station)
        .toList(growable: false);
  }

  static List itemsForStationLevel(String station, int level) {
    return items
        .where(
          (item) =>
              item.category == station &&
              item.group == _groupLabel(station, level),
        )
        .toList(growable: false);
  }

  static List usedFor(String benchItemId) {
    final cleanId = benchItemId.startsWith('bench-')
        ? benchItemId.substring('bench-'.length)
        : benchItemId;

    return requirements
        .where(
          (requirement) =>
              cleanId.endsWith(requirement.itemId) ||
              cleanId == requirement.itemId,
        )
        .map(
          (requirement) =>
              '${requirement.upgradeLabel} x${requirement.quantity}',
        )
        .toList(growable: false);
  }

  static ArcScrappyItem _toScrappyItem(
    ArcBenchUpgradeRequirement requirement,
    int index,
  ) {
    return ArcScrappyItem(
      id: 'bench-${_stationId(requirement.station)}-tier${requirement.level}-${requirement.itemId}',
      name: requirement.itemName,
      category: requirement.station,
      group: _groupLabel(requirement.station, requirement.level),
      sortOrder: index + 1,
      tier: _tierForLevel(requirement.level),
      neededCount: requirement.quantity,
      imageAsset: _imageAssetForItemId(requirement.itemId),
      helperText:
          '${requirement.itemName} x${requirement.quantity} is required for ${requirement.station} Tier ${requirement.level}.',
      locationHint: _intelForItemId(requirement.itemId),
    );
  }

  static String _intelForItemId(String itemId) {
    final canonicalId = _canonicalResourceId(itemId);
    switch (canonicalId) {
      case 'metal-parts':
        return 'Best intel: common industrial/mechanical scrap. Loot field crates, industrial shelves, workshops, garages and mechanical POIs. Recycle metal junk if short.';
      case 'rubber-parts':
        return 'Best intel: common industrial/mechanical material. Search garages, workshops, vehicle/service areas, tool crates and industrial containers. Recycle rubber-heavy junk.';
      case 'plastic-parts':
        return 'Best intel: common civilian/industrial material. Search cabinets, shelves, field crates, commercial interiors and general containers. Recycle plastic junk.';
      case 'fabric':
        return 'Best intel: residential/medical/civilian interiors. Search wardrobes, beds, shelves, medical areas and civilian rooms. Recycle clothing/soft goods.';
      case 'chemicals':
        return 'Best intel: medical, laboratory, industrial and chemical storage areas. Search med crates, lab shelves, utility rooms and industrial containers.';
      case 'arc-alloy':
        return 'Best intel: defeated ARC enemies and ARC-heavy zones. Farm small/medium ARC patrols safely; salvage ARC wreckage after fights.';
      case 'arc-powercells':
        return 'Best intel: defeated ARC enemies and electrical/ARC tech containers. Prioritise ARC patrol routes and electrical POIs.';
      case 'arc-motion-cores':
        return 'Best intel: ARC enemy drops and ARC tech salvage. Run ARC-heavy areas and loot wreckage after engagements.';
      case 'arc-circuitry':
        return 'Best intel: ARC enemies, electrical tech rooms and advanced electronic containers. Strong in security/electrical POIs and ARC-heavy routes.';
      case 'rusted-tools':
        return 'Best intel: red lockers, square rusted metal boxes, workshops and industrial crates. Strong reported route: Dam Battlegrounds Controlled Access Zone / facility loading areas.';
      case 'rusted-gears':
        return 'Best intel: mechanical/industrial loot. Search workshops, garages, machinery rooms, toolboxes, rusted metal boxes and industrial shelves.';
      case 'mechanical-components':
        return 'Best intel: mechanical POIs, workshops, garages, machinery rooms and mechanical crates. Scrappy can also return mechanical materials.';
      case 'advanced-mechanical-components':
        return 'Best intel: high-value mechanical/industrial areas and advanced crates. Prioritise locked rooms, breach rooms, high-loot industrial zones and advanced machinery areas.';
      case 'wasp-drivers':
        return 'Best intel: destroyed Wasp ARCs. Farm Wasp patrols and loot the ARC wreck before moving on.';
      case 'hornet-drivers':
        return 'Best intel: destroyed Hornet ARCs. Farm Hornet patrols and recover the driver from wreckage.';
      case 'snitch-scanners':
        return 'Best intel: destroyed Snitch ARCs. Target Snitch patrols early before they alert or move away.';
      case 'leaper-pulse-units':
        return 'Best intel: destroyed Leaper ARCs. Higher risk target; bring burst damage, safe angle and extract after recovery.';
      case 'sentinel-firing-cores':
        return 'Best intel: destroyed Sentinel ARCs. Farm Sentinel-heavy routes and loot wreckage after clearing nearby threats.';
      case 'bastion-cells':
        return 'Best intel: destroyed Bastion ARCs. High-risk ARC component; squad farming and safe extraction recommended.';
      case 'tick-pods':
        return 'Best intel: destroyed Tick ARCs. Common around ARC activity routes; clear and loot quickly.';
      case 'surveyor-vaults':
        return 'Best intel: destroyed Surveyor ARCs. Search ARC-heavy open areas and recover from Surveyor wreckage.';
      case 'fireball-burners':
        return 'Best intel: destroyed Fireball ARCs. Farm Fireball routes, loot wreckage, then reset before more ARCs stack up.';
      case 'rocketeer-drivers':
        return 'Best intel: destroyed Rocketeer ARCs. High-risk ARC target; prioritise cover, line-of-sight breaks and quick extraction.';
      case 'bombardier-cells':
        return 'Best intel: destroyed Bombardier ARCs. High-risk component; safest with prepared weapons and squad support.';
      case 'power-cables':
        return 'Best intel: electrical/technological POIs, red lockers, power rooms, server/electrical cabinets and industrial tech crates. Controlled Access Zone can be strong.';
      case 'electrical-components':
        return 'Best intel: electrical rooms, tech/server areas, cabinets, control rooms and electronic containers. Recycle electronic junk if short.';
      case 'advanced-electrical-components':
        return 'Best intel: high-value electrical/tech zones, locked rooms, server rooms, control rooms and advanced electronic containers.';
      case 'industrial-batteries':
        return 'Best intel: electrical/industrial storage, power generation areas, utility rooms and battery/electrical crates.';
      case 'cracked-bioscanners':
        return 'Best intel: medical/laboratory loot. Search med crates, clinics, labs, medical shelves and treatment rooms.';
      case 'durable-cloth':
        return 'Best intel: medical/commercial/residential interiors. Search med rooms, clothing/soft-good shelves, wardrobes and commercial storage.';
      case 'rusted-shut-medical-kits':
        return 'Best intel: medical POIs and med crates. Prioritise clinics, medical rooms, ambulance/first-aid areas and locked medical storage.';
      case 'antiseptic':
        return 'Best intel: medical areas, med crates, clinics, labs and treatment-room shelves.';
      case 'damaged-heat-sinks':
        return 'Best intel: electrical/technological POIs, server rooms, control cabinets, power generation areas and electronic crates.';
      case 'fried-motherboards':
        return 'Best intel: tech/server/electrical areas. Search computer rooms, server racks, control rooms, offices with electronics and high-value tech containers.';
      case 'synthesized-fuel':
        return 'Best intel: industrial/chemical/mechanical zones. Search fuel storage, utility rooms, industrial shelves and chemical containers.';
      case 'crude-explosives':
        return 'Best intel: industrial/explosive storage and security/weapon-adjacent containers. Search industrial crates, breach rooms and high-risk utility areas.';
      case 'pop-triggers':
        return 'Best intel: weapon/explosive/security loot. Search weapon caches, security rooms, crates and explosive station-style industrial areas.';
      case 'laboratory-reagents':
        return 'Best intel: labs, medical rooms, research shelves and chemical storage. Medical/lab POIs are the strongest route.';
      case 'explosive-compounds':
        return 'Best intel: explosive/industrial/chemical containers. Search locked rooms, industrial crates, utility rooms and security-adjacent loot.';
      case 'toasters':
        return 'Best intel: residential/commercial kitchens and civilian interiors. Check counters, shelves, cupboards and apartments.';
      case 'motors':
        return 'Best intel: mechanical/industrial loot. Search workshops, garages, machinery rooms, loading areas and mechanical containers.';
      default:
        return 'Best intel: check the item type in-game, then target matching POIs and containers. Prioritise high-loot rooms, locked rooms and breach rooms for rare variants.';
    }
  }

  static String _imageAssetForItemId(String itemId) {
    final canonicalId = _canonicalResourceId(itemId);
    return 'assets/arc_raiders/scrappy_resources/${canonicalId.replaceAll('-', '_')}.webp';
  }

  static String _canonicalResourceId(String itemId) {
    return switch (itemId) {
      'apricot' => 'apricots',
      'lemon' => 'lemons',
      'prickly-pear' => 'prickly-pears',
      'very-comfortable-pillow' => 'very-comfortable-pillows',
      'wasp-driver' => 'wasp-drivers',
      'hornet-driver' => 'hornet-drivers',
      'snitch-scanner' => 'snitch-scanners',
      'leaper-pulse-unit' => 'leaper-pulse-units',
      'surveyor-vault' => 'surveyor-vaults',
      'fireball-burner' => 'fireball-burners',
      'rocketeer-driver' => 'rocketeer-drivers',
      'bastion-cell' => 'bastion-cells',
      'electrical-component' => 'electrical-components',
      'mechanical-component' => 'mechanical-components',
      'advanced-electrical-component' => 'advanced-electrical-components',
      'advanced-mechanical-component' => 'advanced-mechanical-components',
      'wire' => 'wires',
      _ => itemId,
    };
  }

  static String _stationId(String station) {
    return station
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _groupLabel(String station, int level) =>
      '$station Tier $level';

  static int _levelFromGroup(String group) {
    final match = RegExp(r'Tier\s+(\d+)').firstMatch(group);
    if (match == null) return 1;
    return int.tryParse(match.group(1) ?? '1') ?? 1;
  }

  static ArcScrappyTier _tierForLevel(int level) {
    switch (level) {
      case 1:
        return ArcScrappyTier.tier1;
      case 2:
        return ArcScrappyTier.tier2;
      case 3:
        return ArcScrappyTier.tier3;
      case 4:
      case 5:
      default:
        return ArcScrappyTier.tier4;
    }
  }
}
