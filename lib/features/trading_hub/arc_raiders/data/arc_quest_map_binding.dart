import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';

/// Canonical bridge between Quest catalogue metadata and UAG map IDs.
///
/// Quest catalogue map names are broad map relevance only. Precise route
/// coordinates still require a published quest-location marker.
class ArcQuestMapBinding {
  const ArcQuestMapBinding._();

  static List<ArcQuestCatalogueNode> questsForMap(String? map) {
    final mapId = ArcMapAssetRegistry.canonicalMapIdFor(map);
    if (mapId == null) return const <ArcQuestCatalogueNode>[];

    final quests =
        ArcQuestCatalogue.nodes
            .where(
              (quest) => quest.mapNames.any(
                (name) => ArcMapAssetRegistry.canonicalMapIdFor(name) == mapId,
              ),
            )
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.canonicalOrder.compareTo(right.canonicalOrder),
          );
    return List<ArcQuestCatalogueNode>.unmodifiable(quests);
  }

  static bool questSupportsMap(String questId, String? map) {
    final quest = ArcQuestCatalogue.byId[questId];
    final mapId = ArcMapAssetRegistry.canonicalMapIdFor(map);
    if (quest == null || mapId == null) return false;
    return quest.mapNames.any(
      (name) => ArcMapAssetRegistry.canonicalMapIdFor(name) == mapId,
    );
  }

  static Set<String> mapIdsForQuest(String questId) {
    final quest = ArcQuestCatalogue.byId[questId];
    if (quest == null) return const <String>{};
    return Set<String>.unmodifiable(
      quest.mapNames
          .map(ArcMapAssetRegistry.canonicalMapIdFor)
          .whereType<String>(),
    );
  }

  static String labelFor(ArcQuestCatalogueNode quest) =>
      '${quest.trader} — ${quest.displayName}';
}
