import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';

class ArcScrappySeedData {
  static const int columns = 3;

  static const List items = [
    ArcScrappyItem(
      id: 'dog-collar',
      name: 'Dog Collar',
      category: 'Materials',
      group: 'Tier 1',
      sortOrder: 1,
      tier: ArcScrappyTier.tier1,
      neededCount: 1,
      imageAsset: ArcItemAssetRegistry.dogCollar,
      helperText: 'Need 1 total to finish this tracker entry.',
      locationHint:
          'Best intel: residential/civilian interiors, wardrobes, drawers, shelves, apartments and house POIs. Prioritise Buried City residential blocks and Blue Gate Village-style homes.',
    ),
    ArcScrappyItem(
      id: 'lemons',
      name: 'Lemons',
      category: 'Materials',
      group: 'Tier 2',
      sortOrder: 2,
      tier: ArcScrappyTier.tier2,
      neededCount: 3,
      imageAsset: ArcItemAssetRegistry.lemons,
      helperText: 'Need 3 total for this tracker entry.',
      locationHint:
          'Best intel: nature/fruit spawns. Check Blue Gate Olive Grove, Marano Park, gardens, orchards, greenhouse areas and wicker baskets during Lush Blooms. Safe-pocket immediately.',
    ),
    ArcScrappyItem(
      id: 'apricots-tier-2',
      name: 'Apricots',
      category: 'Materials',
      group: 'Tier 2',
      sortOrder: 3,
      tier: ArcScrappyTier.tier2,
      neededCount: 3,
      imageAsset: ArcItemAssetRegistry.apricots,
      helperText: 'Tier 2 apricot target is 3 total.',
      locationHint:
          'Best intel: nature/fruit spawns. Check Blue Gate Olive Grove, Marano Park, gardens, orchards, greenhouse areas and wicker baskets during Lush Blooms. Safe-pocket immediately.',
    ),
    ArcScrappyItem(
      id: 'prickly-pears',
      name: 'Prickly Pears',
      category: 'Materials',
      group: 'Tier 3',
      sortOrder: 4,
      tier: ArcScrappyTier.tier3,
      neededCount: 6,
      imageAsset: ArcItemAssetRegistry.pricklyPears,
      helperText: 'Need 6 total for this tracker entry.',
      locationHint:
          'Best intel: nature/desert plant spawns. Run Blue Gate outdoor plant routes, Village outskirts, Olive Grove/park edges and nature containers. Check wicker baskets when Lush Blooms is active.',
    ),
    ArcScrappyItem(
      id: 'olives',
      name: 'Olives',
      category: 'Materials',
      group: 'Tier 3',
      sortOrder: 5,
      tier: ArcScrappyTier.tier3,
      neededCount: 6,
      imageAsset: ArcItemAssetRegistry.olives,
      helperText: 'Need 6 total for this tracker entry.',
      locationHint:
          'Best intel: Blue Gate - Olive Grove / Olive Garden routes. Also check nature food spawns, gardens and wicker baskets during Lush Blooms.',
    ),
    ArcScrappyItem(
      id: 'cat-bed',
      name: 'Cat Bed',
      category: 'Materials',
      group: 'Tier 3',
      sortOrder: 6,
      tier: ArcScrappyTier.tier3,
      neededCount: 1,
      imageAsset: ArcItemAssetRegistry.catBed,
      helperText: 'Single Tier 3 furniture item.',
      locationHint:
          'Best intel: residential/furniture loot. Search bedrooms, apartments, houses, shelves and civilian interiors. Buried City residential blocks and Blue Gate houses are the safest target routes.',
    ),
    ArcScrappyItem(
      id: 'mushrooms',
      name: 'Mushrooms',
      category: 'Materials',
      group: 'Tier 4',
      sortOrder: 7,
      tier: ArcScrappyTier.tier4,
      neededCount: 12,
      imageAsset: ArcItemAssetRegistry.mushrooms,
      helperText:
          'Need 12 total. Any amount above 12 becomes tradeable surplus.',
      locationHint:
          'Best intel: nature/organic spawns. Prioritise Blue Gate nature POIs, damp/greenhouse routes, wooded edges, planters and wicker baskets during Lush Blooms.',
    ),
    ArcScrappyItem(
      id: 'apricots-tier-4',
      name: 'Apricots',
      category: 'Materials',
      group: 'Tier 4',
      sortOrder: 8,
      tier: ArcScrappyTier.tier4,
      neededCount: 12,
      imageAsset: ArcItemAssetRegistry.apricots,
      helperText: 'Tier 4 apricot target is 12 total.',
      locationHint:
          'Best intel: nature/fruit spawns. Check Blue Gate Olive Grove, Marano Park, gardens, orchards, greenhouse areas and wicker baskets during Lush Blooms. Safe-pocket immediately.',
    ),
    ArcScrappyItem(
      id: 'very-comfortable-pillows',
      name: 'Very Comfortable Pillows',
      category: 'Materials',
      group: 'Tier 4',
      sortOrder: 9,
      tier: ArcScrappyTier.tier4,
      neededCount: 3,
      imageAsset: ArcItemAssetRegistry.veryComfortablePillows,
      helperText: 'Need 3 total. Extra pillows become tradeable surplus.',
      locationHint:
          'Best intel: residential bedroom loot. Search apartments, houses, hotels, beds, wardrobes, shelves and drawers. Buried City apartments are the strongest route.',
    ),
  ];
}
