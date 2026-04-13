import 'package:flutter/foundation.dart';

@immutable
class ArcScrappyFoodQueueItem {
  const ArcScrappyFoodQueueItem({
    required this.id,
    required this.name,
    required this.imageAsset,
    this.hint,
  });

  final String id;
  final String name;
  final String imageAsset;
  final String? hint;
}
