import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';

class ArcBlueprintQuestReward {
  const ArcBlueprintQuestReward({
    required this.blueprintName,
    required this.questName,
    this.bonusUnlocks = const <String>[],
    this.note = '',
  });

  final String blueprintName;
  final String questName;
  final List<String> bonusUnlocks;
  final String note;

  ArcQuestCatalogueNode? get quest => ArcQuestCatalogue.findByName(questName);
  String? get questId => quest?.id;
}

class ArcBlueprintQuestRewardCatalog {
  const ArcBlueprintQuestRewardCatalog._();

  static const String version = 'riven-tides-2026-09-25';

  static const List<ArcBlueprintQuestReward> rewards =
      <ArcBlueprintQuestReward>[
        ArcBlueprintQuestReward(
          blueprintName: 'Burletta',
          questName: 'Industrial Espionage',
        ),
        ArcBlueprintQuestReward(
          blueprintName: 'Hullcracker',
          questName: "The Major's Footlocker",
          bonusUnlocks: <String>['Launcher Ammo recipe'],
          note:
              'Learning the Hullcracker Blueprint also unlocks Launcher Ammo.',
        ),
        ArcBlueprintQuestReward(
          blueprintName: 'Lure Grenade',
          questName: 'Greasing Her Palms',
        ),
        ArcBlueprintQuestReward(
          blueprintName: "Trigger 'Nade",
          questName: 'Sparks Fly',
        ),
        ArcBlueprintQuestReward(
          blueprintName: 'Vita Spray',
          questName: 'Worth Your Salt',
        ),
      ];

  static String _normalise(String value) {
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r"['’`]"), '');
    result = result.replaceAll(RegExp(r'\bblueprint\b'), '');
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static ArcBlueprintQuestReward? forBlueprint(String blueprintName) {
    final target = _normalise(blueprintName);
    for (final reward in rewards) {
      if (_normalise(reward.blueprintName) == target) return reward;
    }
    return null;
  }

  static List<ArcBlueprintQuestReward> forQuest(String questName) {
    final target = _normalise(questName);
    return rewards
        .where((reward) => _normalise(reward.questName) == target)
        .toList(growable: false);
  }
}
