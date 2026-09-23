import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_food_queue_item.dart';

class ArcScrappyFoodQueueData {
  static const String _assetRoot = 'assets/arc_raiders/scrappy_resources';

  static const List<ArcScrappyFoodQueueItem> items = [
    ArcScrappyFoodQueueItem(
      id: 'fruit-mix',
      name: 'Fruit Mix',
      imageAsset: '$_assetRoot/fruit_mix.webp',
      resourceBonus: '+5 ALL BASE RESOURCES',
      rewardPool: 'Broad mixed reward pool',
      intelRank: 100,
      goals: ['Overall'],
      highlights: [
        'All six base resources',
        'Mixed crafting materials',
        'Broad reward pool',
      ],
      hint: 'Craft Topside: 1 Lemon + 1 Apricot + 1 Prickly Pear.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'agave',
      name: 'Agave',
      imageAsset: '$_assetRoot/agave.webp',
      resourceBonus: '+5 ASSORTED SEEDS',
      rewardPool: 'Mods / mod crafting materials',
      intelRank: 90,
      goals: ['Mods'],
      highlights: ['Mods', 'Mod crafting materials'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'mushrooms',
      name: 'Mushrooms',
      imageAsset: '$_assetRoot/mushrooms.webp',
      resourceBonus: '+5 PLASTIC PARTS',
      rewardPool: 'Gear Bench materials / equipment',
      intelRank: 85,
      goals: ['Gear'],
      highlights: ['Gear Bench materials', 'Gear Bench equipment'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'lemons',
      name: 'Lemons',
      imageAsset: '$_assetRoot/lemons.webp',
      resourceBonus: '+5 CHEMICALS',
      rewardPool: 'Explosives Station materials / equipment',
      intelRank: 80,
      goals: ['Explosives'],
      highlights: ['Explosives Station materials', 'Explosives equipment'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'prickly-pears',
      name: 'Prickly Pears',
      imageAsset: '$_assetRoot/prickly_pears.webp',
      resourceBonus: '+5 RUBBER PARTS',
      rewardPool: 'Utility Station materials / equipment',
      intelRank: 78,
      goals: ['Utility'],
      highlights: ['Utility Station materials', 'Utility equipment'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'apricots',
      name: 'Apricots',
      imageAsset: '$_assetRoot/apricots.webp',
      resourceBonus: '+5 METAL PARTS',
      rewardPool: 'Gunsmith materials / equipment',
      intelRank: 72,
      goals: ['Gunsmith'],
      highlights: ['Gunsmith materials', 'Gunsmith equipment'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'olives',
      name: 'Olives',
      imageAsset: '$_assetRoot/olives.webp',
      resourceBonus: '+5 FABRIC',
      rewardPool: 'Medical Lab materials / equipment',
      intelRank: 65,
      goals: ['Medical'],
      highlights: ['Medical Lab materials', 'Medical equipment'],
    ),
  ];
}
