import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_food_queue_item.dart';

class ArcScrappyFoodQueueData {
  static const String _assetRoot = 'assets/arc_raiders/scrappy_resources';

  static const List<ArcScrappyFoodQueueItem> items = [
    ArcScrappyFoodQueueItem(
      id: 'lemons',
      name: 'Lemons',
      imageAsset: '$_assetRoot/lemons.webp',
      hint: 'Blue Gate • Village. Keep for Scrappy Level 3.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'apricots',
      name: 'Apricots',
      imageAsset: '$_assetRoot/apricots.webp',
      hint: 'Blue Gate • Village. Used for Scrappy Level 3 and Level 5.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'prickly-pears',
      name: 'Prickly Pears',
      imageAsset: '$_assetRoot/prickly_pears.webp',
      hint: 'Dam Battlegrounds • Pattern House. Keep for Scrappy Level 4.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'olives',
      name: 'Olives',
      imageAsset: '$_assetRoot/olives.webp',
      hint: 'Blue Gate • Olive Garden. Keep for Scrappy Level 4.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'mushrooms',
      name: 'Mushrooms',
      imageAsset: '$_assetRoot/mushrooms.webp',
      hint: 'Rivern Tides • Dried Riverbed. Keep for Scrappy Level 5.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'fruit-mix',
      name: 'Fruit Mix',
      imageAsset: '$_assetRoot/fruit_mix.webp',
      hint:
          'Craft Topside 1 x Lemon, 1 x Apricot + 1 x Prickly Pear. Queue for feeding when made.',
    ),
    ArcScrappyFoodQueueItem(
      id: 'agave',
      name: 'Agave',
      imageAsset: '$_assetRoot/agave.webp',
      hint: 'Dam Battlegrounds • Pattern House. Queue for feeding when found.',
    ),
  ];
}
