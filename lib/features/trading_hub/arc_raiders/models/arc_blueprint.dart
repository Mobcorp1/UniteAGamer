import 'package:flutter/material.dart';

enum ArcBlueprintRarity { common, uncommon, rare, epic, legendary }

class ArcBlueprint {
  final String id;
  final String name;
  final String category;
  final String group;
  final int sortOrder;
  final ArcBlueprintRarity rarity;
  final IconData icon;
  final String? imageAssetPath;
  final String intelHint;

  const ArcBlueprint({
    required this.id,
    required this.name,
    required this.category,
    required this.group,
    required this.sortOrder,
    required this.rarity,
    required this.icon,
    this.imageAssetPath,
    this.intelHint = '',
  });

  String get rarityLabel {
    switch (rarity) {
      case ArcBlueprintRarity.common:
        return 'Common';
      case ArcBlueprintRarity.uncommon:
        return 'Uncommon';
      case ArcBlueprintRarity.rare:
        return 'Rare';
      case ArcBlueprintRarity.epic:
        return 'Epic';
      case ArcBlueprintRarity.legendary:
        return 'Legendary';
    }
  }
}
