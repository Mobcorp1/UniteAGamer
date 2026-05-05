import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';

class ArcQuestRequirement {
  final String questName;
  final String trader;
  final int order;
  final String itemId;
  final String itemName;
  final int quantity;
  final String sourceHint;

  const ArcQuestRequirement({
    required this.questName,
    required this.trader,
    required this.order,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.sourceHint,
  });

  String get questLabel => '$trader • $questName';
}

class ArcQuestRequirementSeedData {
  static const int columns = 3;

  static const List<ArcQuestRequirement> requirements = [
    ArcQuestRequirement(questName: 'Clearer Skies', trader: 'Shani', order: 1, itemId: 'arc-alloy', itemName: 'ARC Alloy', quantity: 3, sourceHint: 'Found on defeated ARC enemies.'),
    ArcQuestRequirement(questName: "Doctor's Orders", trader: 'Lance', order: 2, itemId: 'syringe', itemName: 'Syringe', quantity: 1, sourceHint: 'Found inside Med Crates and Medical locations.'),
    ArcQuestRequirement(questName: "Doctor's Orders", trader: 'Lance', order: 3, itemId: 'antiseptic', itemName: 'Antiseptic', quantity: 2, sourceHint: 'Found inside Med Crates and Medical locations.'),
    ArcQuestRequirement(questName: "Doctor's Orders", trader: 'Lance', order: 4, itemId: 'durable-cloth', itemName: 'Durable Cloth', quantity: 1, sourceHint: 'Found inside Commercial and Medical locations.'),
    ArcQuestRequirement(questName: "Doctor's Orders", trader: 'Lance', order: 5, itemId: 'great-mullein', itemName: 'Great Mullein', quantity: 1, sourceHint: 'Found in submerged and swampy areas.'),
    ArcQuestRequirement(questName: 'Eyes on the Prize', trader: 'Tian Wen', order: 6, itemId: 'wires', itemName: 'Wires', quantity: 3, sourceHint: 'Found inside Electrical and Technological locations.'),
    ArcQuestRequirement(questName: 'Lance’s Tea Party', trader: 'Lance', order: 7, itemId: 'rubber-duck', itemName: 'Rubber Duck', quantity: 2, sourceHint: 'Trinket found in Residential, Commercial, and Old World locations.'),
    ArcQuestRequirement(questName: 'Lance’s Tea Party', trader: 'Lance', order: 8, itemId: 'faded-photograph', itemName: 'Faded Photograph', quantity: 2, sourceHint: 'Trinket found in Residential locations.'),
    ArcQuestRequirement(questName: 'Into the Fray', trader: 'Shani', order: 9, itemId: 'leaper-pulse-unit', itemName: 'Leaper Pulse Unit', quantity: 1, sourceHint: 'Found on destroyed Leaper ARCs.'),
    ArcQuestRequirement(questName: 'Mixed Signals', trader: 'Tian Wen', order: 10, itemId: 'surveyor-vault', itemName: 'Surveyor Vault', quantity: 1, sourceHint: 'Found on destroyed Surveyor ARCs.'),
    ArcQuestRequirement(questName: 'Movie Night', trader: 'Apollo', order: 11, itemId: 'camera-lens', itemName: 'Camera Lens', quantity: 1, sourceHint: 'Found inside Security locations.'),
    ArcQuestRequirement(questName: 'Movie Night', trader: 'Apollo', order: 12, itemId: 'film-reel', itemName: 'Film Reel', quantity: 1, sourceHint: 'Trinket found in Residential and Old World locations.'),
    ArcQuestRequirement(questName: 'Movie Night', trader: 'Apollo', order: 13, itemId: 'electrical-components', itemName: 'Electrical Components', quantity: 3, sourceHint: 'Found in Electrical locations.'),
    ArcQuestRequirement(questName: 'Out of the Shadows', trader: 'Shani', order: 14, itemId: 'rocketeer-driver', itemName: 'Rocketeer Driver', quantity: 1, sourceHint: 'Found on destroyed Rocketeer ARCs.'),
    ArcQuestRequirement(questName: 'Pied Piper', trader: 'Apollo', order: 15, itemId: 'recorder', itemName: 'Recorder', quantity: 1, sourceHint: 'Trinket found in Residential locations.'),
    ArcQuestRequirement(questName: 'Pied Piper', trader: 'Apollo', order: 16, itemId: 'apricot', itemName: 'Apricot', quantity: 1, sourceHint: 'Found in Nature areas.'),
    ArcQuestRequirement(questName: 'Pied Piper', trader: 'Apollo', order: 17, itemId: 'empty-wine-bottle', itemName: 'Empty Wine Bottle', quantity: 1, sourceHint: 'Trinket found in Residential and Commercial locations.'),
    ArcQuestRequirement(questName: 'Pied Piper', trader: 'Apollo', order: 18, itemId: 'light-impact-grenade', itemName: 'Light Impact Grenade', quantity: 3, sourceHint: 'Found in Weapon Caches.'),
    ArcQuestRequirement(questName: 'Pied Piper', trader: 'Apollo', order: 19, itemId: 'oil', itemName: 'Oil', quantity: 1, sourceHint: 'Found in Mechanical locations.'),
    ArcQuestRequirement(questName: 'Powering Up the Greenhouse', trader: 'Tian Wen', order: 20, itemId: 'advanced-electrical-components', itemName: 'Advanced Electrical Components', quantity: 1, sourceHint: 'Found in Electrical locations.'),
    ArcQuestRequirement(questName: 'Powering Up the Greenhouse', trader: 'Tian Wen', order: 21, itemId: 'sensors', itemName: 'Sensors', quantity: 3, sourceHint: 'Found in Security and Technological locations.'),
    ArcQuestRequirement(questName: 'Small But Sinister', trader: 'Shani', order: 22, itemId: 'tick-pod', itemName: 'Tick Pod', quantity: 1, sourceHint: 'Found on destroyed Tick ARCs.'),
    ArcQuestRequirement(questName: 'The Trifecta', trader: 'Shani', order: 23, itemId: 'wasp-driver', itemName: 'Wasp Driver', quantity: 1, sourceHint: 'Found on destroyed Wasp ARCs.'),
    ArcQuestRequirement(questName: 'The Trifecta', trader: 'Shani', order: 24, itemId: 'hornet-driver', itemName: 'Hornet Driver', quantity: 1, sourceHint: 'Found on destroyed Hornet ARCs.'),
    ArcQuestRequirement(questName: 'The Trifecta', trader: 'Shani', order: 25, itemId: 'snitch-scanner', itemName: 'Snitch Scanner', quantity: 1, sourceHint: 'Found on destroyed Snitch ARCs.'),
    ArcQuestRequirement(questName: 'Trash Into Treasure', trader: 'Shani', order: 26, itemId: 'wires', itemName: 'Wires', quantity: 6, sourceHint: 'Found inside Electrical and Technological locations.'),
    ArcQuestRequirement(questName: 'Trash Into Treasure', trader: 'Shani', order: 27, itemId: 'battery', itemName: 'Battery', quantity: 1, sourceHint: 'Found inside Electrical and Technological locations.'),
    ArcQuestRequirement(questName: 'Tribute to Toledo', trader: 'Celeste', order: 28, itemId: 'power-rod', itemName: 'Power Rod', quantity: 1, sourceHint: 'Found inside Exodus locations.'),
    ArcQuestRequirement(questName: 'Wasps and Hornets', trader: 'Shani', order: 29, itemId: 'wasp-driver', itemName: 'Wasp Driver', quantity: 1, sourceHint: 'Found on destroyed Wasp ARCs.'),
    ArcQuestRequirement(questName: 'Wasps and Hornets', trader: 'Shani', order: 30, itemId: 'hornet-driver', itemName: 'Hornet Driver', quantity: 1, sourceHint: 'Found on destroyed Hornet ARCs.'),
    ArcQuestRequirement(questName: 'What Goes Around', trader: 'Apollo', order: 31, itemId: 'fireball-burner', itemName: 'Fireball Burner', quantity: 1, sourceHint: 'Found on destroyed ARCs.'),
    ArcQuestRequirement(questName: 'The League', trader: 'Apollo', order: 32, itemId: 'bicycle-pump', itemName: 'Bicycle Pump', quantity: 1, sourceHint: 'Found as residential/civilian world loot.'),
    ArcQuestRequirement(questName: 'The League', trader: 'Apollo', order: 33, itemId: 'deflated-football', itemName: 'Deflated Football', quantity: 1, sourceHint: 'Found inside Residential locations.'),
    ArcQuestRequirement(questName: 'Movie Night', trader: 'Apollo', order: 34, itemId: 'portable-tv', itemName: 'Portable TV', quantity: 1, sourceHint: 'Found as civilian/household world loot.'),
    ArcQuestRequirement(questName: 'Movie Night', trader: 'Apollo', order: 35, itemId: 'stack-of-movie-tapes', itemName: 'Stack Of Movie Tapes', quantity: 1, sourceHint: 'Found as residential/old-world world loot.'),
    ArcQuestRequirement(questName: 'Movie Night', trader: 'Apollo', order: 36, itemId: 'fireworks-box', itemName: 'Fireworks Box', quantity: 1, sourceHint: 'Found as world/event loot and blueprint-related item.'),
    ArcQuestRequirement(questName: 'Espresso', trader: 'Apollo', order: 37, itemId: 'espresso-machine-parts', itemName: 'Espresso Machine Parts', quantity: 1, sourceHint: 'Quest collection item.'),
    ArcQuestRequirement(questName: 'Espresso', trader: 'Apollo', order: 38, itemId: 'coffee-pot', itemName: 'Coffee Pot', quantity: 1, sourceHint: 'Found as residential/commercial world loot.'),
    ArcQuestRequirement(questName: 'A New Type Of Plant', trader: 'Lance', order: 39, itemId: 'vita-shot', itemName: 'Vita Shot', quantity: 1, sourceHint: 'Found in Medical containers and loot.'),
    ArcQuestRequirement(questName: 'A New Type Of Plant', trader: 'Lance', order: 40, itemId: 'antiseptic', itemName: 'Antiseptic', quantity: 5, sourceHint: 'Found inside Med Crates and Medical locations.'),
    ArcQuestRequirement(questName: 'Clamoring for Attention', trader: 'Shani', order: 41, itemId: 'battery', itemName: 'Battery', quantity: 1, sourceHint: 'Found inside Electrical and Technological locations.'),
    ArcQuestRequirement(questName: 'Clamoring for Attention', trader: 'Shani', order: 42, itemId: 'wires', itemName: 'Wires', quantity: 3, sourceHint: 'Found inside Electrical and Technological locations.'),
    ArcQuestRequirement(questName: 'Settled in Full', trader: 'Tian Wen', order: 43, itemId: 'bastion-cell', itemName: 'Bastion Cell', quantity: 1, sourceHint: 'Found on destroyed Bastion ARCs.'),
    ArcQuestRequirement(questName: 'Test Case', trader: 'Apollo', order: 44, itemId: 'fireball-burner', itemName: 'Fireball Burner', quantity: 1, sourceHint: 'Found on destroyed Fireball ARCs.'),
    ArcQuestRequirement(questName: 'Test Case', trader: 'Apollo', order: 45, itemId: 'firefly-burner', itemName: 'Firefly Burner', quantity: 1, sourceHint: 'Found on destroyed Firefly ARCs.'),
    ArcQuestRequirement(questName: 'Test Case', trader: 'Apollo', order: 46, itemId: 'hornet-driver', itemName: 'Hornet Driver', quantity: 1, sourceHint: 'Found on destroyed Hornet ARCs.'),
  ];

  static List<ArcScrappyItem> get items {
    return [
      for (var index = 0; index < requirements.length; index++)
        ArcScrappyItem(
          id: 'quest-${requirements[index].trader.toLowerCase().replaceAll(' ', '-')}-${requirements[index].questName.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), '-')}-${requirements[index].itemId}',
          name: requirements[index].itemName,
          category: requirements[index].trader,
          group: requirements[index].questName,
          sortOrder: requirements[index].order,
          tier: _tierForTrader(requirements[index].trader),
          neededCount: requirements[index].quantity,
          imageAsset: _imageAssetForItemId(requirements[index].itemId),
          helperText: '${requirements[index].itemName} x${requirements[index].quantity} is required for ${requirements[index].trader} quest: ${requirements[index].questName}.',
          locationHint: requirements[index].sourceHint,
        ),
    ];
  }

  static List<ArcScrappyItem> itemsForTrader(String trader) {
    return items.where((item) => item.category == trader).toList(growable: false);
  }

  static List<ArcScrappyItem> itemsForQuest(String trader, String questName) {
    return items.where((item) => item.category == trader && item.group == questName).toList(growable: false);
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

  static ArcScrappyTier _tierForTrader(String trader) {
    switch (trader) {
      case 'Celeste':
        return ArcScrappyTier.tier1;
      case 'Shani':
        return ArcScrappyTier.tier2;
      case 'Tian Wen':
        return ArcScrappyTier.tier3;
      case 'Lance':
      case 'Apollo':
      default:
        return ArcScrappyTier.tier4;
    }
  }
}
