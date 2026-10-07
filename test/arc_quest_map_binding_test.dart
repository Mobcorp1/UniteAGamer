import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_map_binding.dart';

void main() {
  group('ArcQuestMapBinding', () {
    test('Blue Gate aliases resolve to the same canonical quest list', () {
      final canonical = ArcQuestMapBinding.questsForMap(
        'Blue Gate',
      ).map((quest) => quest.id).toList();
      final article = ArcQuestMapBinding.questsForMap(
        'The Blue Gate',
      ).map((quest) => quest.id).toList();
      final storage = ArcQuestMapBinding.questsForMap(
        'blue_gate',
      ).map((quest) => quest.id).toList();

      expect(article, canonical);
      expect(storage, canonical);
      expect(canonical, isNotEmpty);
    });

    test(
      'quests are filtered by verified map metadata and canonical order',
      () {
        final quests = ArcQuestMapBinding.questsForMap('Dam Battlegrounds');
        expect(quests, isNotEmpty);

        for (var i = 1; i < quests.length; i++) {
          expect(
            quests[i - 1].canonicalOrder <= quests[i].canonicalOrder,
            isTrue,
          );
        }

        final paving = ArcQuestCatalogue.findByName('Paving The Way')!;
        expect(
          ArcQuestMapBinding.questSupportsMap(paving.id, 'The Blue Gate'),
          isTrue,
        );
        expect(
          ArcQuestMapBinding.questSupportsMap(paving.id, 'Buried City'),
          isTrue,
        );
        expect(
          ArcQuestMapBinding.questSupportsMap(paving.id, 'Dam Battlegrounds'),
          isTrue,
        );
        expect(
          ArcQuestMapBinding.questSupportsMap(paving.id, 'Spaceport'),
          isFalse,
        );
      },
    );

    test('mapless quests are not invented onto a map', () {
      final root = ArcQuestCatalogue.byId[ArcQuestCatalogue.rootQuestId]!;
      expect(root.mapNames, isEmpty);
      expect(
        ArcQuestMapBinding.questSupportsMap(root.id, 'Blue Gate'),
        isFalse,
      );
      expect(
        ArcQuestMapBinding.questsForMap('Blue Gate').map((quest) => quest.id),
        isNot(contains(root.id)),
      );
    });
  });
}
