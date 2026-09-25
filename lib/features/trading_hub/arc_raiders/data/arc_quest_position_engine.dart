import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';

class ArcQuestPositionEngine {
  const ArcQuestPositionEngine();

  Set<String> inferCompletedAncestors(Iterable<String> selectedQuestIds) {
    final inferred = <String>{};

    void walk(String questId) {
      final node = ArcQuestCatalogue.byId[questId];
      if (node == null ||
          node.prerequisiteQuestIds.isEmpty ||
          node.prerequisitePolicy != ArcQuestPrerequisitePolicy.all ||
          node.dependencyConfidence ==
              ArcQuestDependencyConfidence.provisional) {
        return;
      }

      for (final parentId in node.prerequisiteQuestIds) {
        if (!inferred.add(parentId)) continue;
        walk(parentId);
      }
    }

    for (final questId in selectedQuestIds) {
      walk(questId);
    }

    return inferred;
  }

  Set<String> availableQuestIds(Set<String> completedQuestIds) {
    final available = <String>{};

    for (final node in ArcQuestCatalogue.nodes) {
      if (completedQuestIds.contains(node.id)) continue;
      if (node.prerequisiteQuestIds.isEmpty) {
        available.add(node.id);
        continue;
      }

      final parents = node.prerequisiteQuestIds;
      final unlocked = switch (node.prerequisitePolicy) {
        ArcQuestPrerequisitePolicy.all => parents.every(
          completedQuestIds.contains,
        ),
        ArcQuestPrerequisitePolicy.any => parents.any(
          completedQuestIds.contains,
        ),
        ArcQuestPrerequisitePolicy.unverified => parents.every(
          completedQuestIds.contains,
        ),
      };

      if (unlocked) available.add(node.id);
    }

    return available;
  }

  Set<String> comingNextQuestIds({
    required Set<String> trackedQuestIds,
    required Set<String> completedQuestIds,
  }) {
    final result = <String>{};
    for (final trackedId in trackedQuestIds) {
      for (final child in ArcQuestCatalogue.childrenOf(trackedId)) {
        if (!completedQuestIds.contains(child.id) &&
            !trackedQuestIds.contains(child.id)) {
          result.add(child.id);
        }
      }
    }
    return result;
  }

  List<ArcQuestCatalogueNode> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return _sorted(ArcQuestCatalogue.nodes);
    }

    final exactTraderMatches = ArcQuestCatalogue.nodes.where(
      (node) => _normalize(node.trader) == normalized,
    );
    if (exactTraderMatches.isNotEmpty) {
      return _sorted(exactTraderMatches);
    }

    final exactMapMatches = ArcQuestCatalogue.nodes.where(
      (node) =>
          node.mapNames.any((mapName) => _normalize(mapName) == normalized),
    );
    if (exactMapMatches.isNotEmpty) {
      return _sorted(exactMapMatches);
    }

    return _sorted(
      ArcQuestCatalogue.nodes.where((node) {
        final haystack = <String>[
          node.displayName,
          node.trader,
          node.contentUpdate,
          ...node.mapNames,
        ].map(_normalize).join(' ');
        return haystack.contains(normalized);
      }),
    );
  }

  List<ArcQuestCatalogueNode> _sorted(Iterable<ArcQuestCatalogueNode> nodes) {
    final values = nodes.toList(growable: false)
      ..sort(
        (left, right) => left.canonicalOrder.compareTo(right.canonicalOrder),
      );
    return values;
  }

  List<ArcQuestCatalogueNode> ordered(Iterable<String> questIds) {
    final output = <ArcQuestCatalogueNode>[];
    for (final questId in questIds) {
      final node = ArcQuestCatalogue.byId[questId];
      if (node != null) output.add(node);
    }
    output.sort(
      (left, right) => left.canonicalOrder.compareTo(right.canonicalOrder),
    );
    return output;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
