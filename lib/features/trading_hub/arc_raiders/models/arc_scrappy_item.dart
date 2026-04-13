import 'package:flutter/foundation.dart';

enum ArcScrappyTier { tier1, tier2, tier3, tier4 }

@immutable
class ArcScrappyItem {
  final String id;
  final String name;
  final String category;
  final String group;
  final int sortOrder;
  final ArcScrappyTier tier;
  final int neededCount;
  final String imageAsset;
  final String helperText;
  final String? locationHint;

  const ArcScrappyItem({
    required this.id,
    required this.name,
    required this.category,
    required this.group,
    required this.sortOrder,
    required this.tier,
    required this.neededCount,
    required this.imageAsset,
    this.helperText = '',
    this.locationHint,
  });

  String get tierLabel {
    switch (tier) {
      case ArcScrappyTier.tier1:
        return 'Tier 1';
      case ArcScrappyTier.tier2:
        return 'Tier 2';
      case ArcScrappyTier.tier3:
        return 'Tier 3';
      case ArcScrappyTier.tier4:
        return 'Tier 4';
    }
  }
}
