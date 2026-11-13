import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';

void main() {
  group('ArcQuestCatalogue Riven Tides graph', () {
    test('contains the complete 100-node catalogue with one root', () {
      expect(ArcQuestCatalogue.version, 'riven-tides-2026-09-25');
      expect(ArcQuestCatalogue.nodes, hasLength(100));
      expect(
        ArcQuestCatalogue.nodes.where((node) => node.isRoot),
        hasLength(1),
      );
      expect(
        ArcQuestCatalogue.nodes.where((node) => node.isRoot).single.id,
        ArcQuestCatalogue.rootQuestId,
      );
    });

    test('matches authoritative trader counts', () {
      int count(String trader) =>
          ArcQuestCatalogue.nodes.where((node) => node.trader == trader).length;

      expect(count('Shani'), 33);
      expect(count('Celeste'), 25);
      expect(count('Tian Wen'), 18);
      expect(count('Apollo'), 15);
      expect(count('Lance'), 9);
    });

    test('every prerequisite resolves and graph is acyclic', () {
      final ids = ArcQuestCatalogue.byId.keys.toSet();
      for (final node in ArcQuestCatalogue.nodes) {
        for (final parent in node.prerequisiteQuestIds) {
          expect(ids, contains(parent), reason: '${node.displayName}: $parent');
        }
      }

      final visiting = <String>{};
      final visited = <String>{};

      void visit(String id) {
        if (visited.contains(id)) return;
        expect(
          visiting.add(id),
          isTrue,
          reason: 'Cycle detected while visiting $id',
        );
        final node = ArcQuestCatalogue.byId[id]!;
        for (final parent in node.prerequisiteQuestIds) {
          visit(parent);
        }
        visiting.remove(id);
        visited.add(id);
      }

      for (final node in ArcQuestCatalogue.nodes) {
        visit(node.id);
      }
      expect(visited, hasLength(100));
    });

    test('known multi-parent relationships are preserved', () {
      final dormant = ArcQuestCatalogue.findByName('Dormant Barons')!;
      expect(dormant.prerequisiteQuestIds.toSet(), <String>{
        ArcQuestCatalogue.findByName('Greasing Her Palms')!.id,
        ArcQuestCatalogue.findByName('The Trifecta')!.id,
      });

      final water = ArcQuestCatalogue.findByName('Water Troubles')!;
      expect(water.prerequisiteQuestIds, hasLength(2));

      final backOnTop = ArcQuestCatalogue.findByName('Back on Top')!;
      expect(backOnTop.prerequisiteQuestIds, hasLength(3));
    });

    test('Combat Recon remains a conservative unverified junction', () {
      final combatRecon = ArcQuestCatalogue.findByName('Combat Recon')!;
      expect(
        combatRecon.prerequisitePolicy,
        ArcQuestPrerequisitePolicy.unverified,
      );
      expect(
        combatRecon.dependencyConfidence,
        ArcQuestDependencyConfidence.provisional,
      );
      expect(combatRecon.prerequisiteQuestIds, hasLength(2));
    });
  });
}
