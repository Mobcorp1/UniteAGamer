import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_quest_reward_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';

class ArcBlueprintUnlockPlan {
  const ArcBlueprintUnlockPlan({
    required this.reward,
    required this.quest,
    required this.pathNodes,
    required this.containsUnverifiedDependency,
  });

  final ArcBlueprintQuestReward reward;
  final ArcQuestCatalogueNode quest;
  final List<ArcQuestCatalogueNode> pathNodes;
  final bool containsUnverifiedDependency;

  List<ArcQuestCatalogueNode> get prerequisiteNodes =>
      pathNodes.where((node) => node.id != quest.id).toList(growable: false);

  int get prerequisiteCount => prerequisiteNodes.length;

  String get shortSummary {
    final uncertainty = containsUnverifiedDependency
        ? ' • route contains an unverified junction'
        : '';
    final bonus = reward.bonusUnlocks.isEmpty
        ? ''
        : ' • + ${reward.bonusUnlocks.join(', ')}';
    return '${quest.displayName} • ${quest.trader} • '
        '$prerequisiteCount prerequisite${prerequisiteCount == 1 ? '' : 's'}'
        '$bonus$uncertainty';
  }
}

class ArcBlueprintUnlockEngine {
  const ArcBlueprintUnlockEngine._();

  static ArcBlueprintUnlockPlan? planForBlueprint(String blueprintName) {
    final reward = ArcBlueprintQuestRewardCatalog.forBlueprint(blueprintName);
    final quest = reward?.quest;
    if (reward == null || quest == null) return null;

    final visited = <String>{};
    final ordered = <ArcQuestCatalogueNode>[];
    var containsUnverified = false;

    void visit(ArcQuestCatalogueNode node) {
      if (!visited.add(node.id)) return;
      if (node.prerequisitePolicy == ArcQuestPrerequisitePolicy.unverified ||
          node.dependencyConfidence ==
              ArcQuestDependencyConfidence.provisional) {
        containsUnverified = true;
      }
      for (final parentId in node.prerequisiteQuestIds) {
        final parent = ArcQuestCatalogue.byId[parentId];
        if (parent != null) visit(parent);
      }
      ordered.add(node);
    }

    visit(quest);

    return ArcBlueprintUnlockPlan(
      reward: reward,
      quest: quest,
      pathNodes: List<ArcQuestCatalogueNode>.unmodifiable(ordered),
      containsUnverifiedDependency: containsUnverified,
    );
  }
}
