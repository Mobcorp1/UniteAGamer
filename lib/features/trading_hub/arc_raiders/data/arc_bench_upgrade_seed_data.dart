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

  static const List<String> stationOrder = <String>[
    'Gunsmith',
    'Explosives Station',
    'Gear Bench',
    'Medical Lab',
    'Utility Station',
    'Refiner',
  ];


  static const List<ArcBenchUpgradeRequirement> requirements = [
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

  static List<ArcScrappyItem> get items {
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
      grouped[item.category]!.putIfAbsent(level, () => <ArcScrappyItem>[]);
      grouped[item.category]![level]!.add(item);
    }

    for (final stationLevels in grouped.values) {
      for (final levelItems in stationLevels.values) {
        levelItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    }

    return grouped;
  }

  static List<int> levelsForStation(String station) {
    final levels = requirements
        .where((requirement) => requirement.station == station)
        .map((requirement) => requirement.level)
        .toSet()
        .toList()
      ..sort();
    return levels;
  }

  static List<ArcScrappyItem> itemsForStation(String station) {
    return items
        .where((item) => item.category == station)
        .toList(growable: false);
  }

  static List<ArcScrappyItem> itemsForStationLevel(String station, int level) {
    return items
        .where(
          (item) =>
              item.category == station && item.group == _groupLabel(station, level),
        )
        .toList(growable: false);
  }

  static List<String> usedFor(String benchItemId) {
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
    );
  }


  static String _imageAssetForItemId(String itemId) {
    final canonicalId = switch (itemId) {
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

    return 'assets/arc_raiders/scrappy_resources/${canonicalId.replaceAll('-', '_')}.webp';
  }

  static String _stationId(String station) {
    return station
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _groupLabel(String station, int level) => '$station Tier $level';

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
