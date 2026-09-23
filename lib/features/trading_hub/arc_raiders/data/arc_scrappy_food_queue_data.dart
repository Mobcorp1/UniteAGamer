import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_food_queue_item.dart';

class ArcScrappyFoodQueueData {
  static const String _assetRoot = 'assets/arc_raiders/scrappy_resources';

  static const List<ArcScrappyFoodQueueItem> items = [
    ArcScrappyFoodQueueItem(
      id: 'fruit-mix',
      name: 'Fruit Mix',
      imageAsset: '$_assetRoot/fruit_mix.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 100,
      goals: ['Feed'],
      highlights: ['Craftable feed option'],
      hint: 'Craft: 1 Apricot + 1 Lemon + 1 Prickly Pear.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'agave',
      name: 'Agave',
      imageAsset: '$_assetRoot/agave.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 90,
      goals: ['Feed'],
      highlights: ['Feed Scrappy'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'mushrooms',
      name: 'Mushrooms',
      imageAsset: '$_assetRoot/mushrooms.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 85,
      goals: ['Feed'],
      highlights: ['Feed Scrappy'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'lemons',
      name: 'Lemons',
      imageAsset: '$_assetRoot/lemons.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 80,
      goals: ['Feed'],
      highlights: ['Feed Scrappy'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'prickly-pears',
      name: 'Prickly Pears',
      imageAsset: '$_assetRoot/prickly_pears.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 78,
      goals: ['Feed'],
      highlights: ['Feed Scrappy'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'apricots',
      name: 'Apricots',
      imageAsset: '$_assetRoot/apricots.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 72,
      goals: ['Feed'],
      highlights: ['Feed Scrappy'],
    ),
    ArcScrappyFoodQueueItem(
      id: 'olives',
      name: 'Olives',
      imageAsset: '$_assetRoot/olives.webp',
      resourceBonus: 'FEED ITEM',
      rewardPool: 'Scrappy',
      intelRank: 65,
      goals: ['Feed'],
      highlights: ['Feed Scrappy'],
    ),
  ];
}
