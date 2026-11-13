import 'package:flutter/foundation.dart';

@immutable
class ArcScrappyFoodQueueItem {
  const ArcScrappyFoodQueueItem({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.resourceBonus,
    required this.rewardPool,
    required this.intelRank,
    required this.goals,
    required this.highlights,
    this.hint,
  });

  final String id;
  final String name;
  final String imageAsset;
  final String resourceBonus;
  final String rewardPool;
  final int intelRank;
  final List<String> goals;
  final List<String> highlights;
  final String? hint;
}
