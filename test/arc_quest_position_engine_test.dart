import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_position_engine.dart';

void main() {
  const engine = ArcQuestPositionEngine();

  group('ArcQuestPositionEngine', () {
    test('starting state exposes only the root quest', () {
      final available = engine.availableQuestIds(<String>{});
      expect(available, <String>{ArcQuestCatalogue.rootQuestId});
    });

    test('verified ALL child safely infers both prerequisite branches', () {
      final dormant = ArcQuestCatalogue.findByName('Dormant Barons')!;
      final inferred = engine.inferCompletedAncestors(<String>{dormant.id});

      expect(
        inferred,
        contains(ArcQuestCatalogue.findByName('Greasing Her Palms')!.id),
      );
      expect(
        inferred,
        contains(ArcQuestCatalogue.findByName('The Trifecta')!.id),
      );
      expect(
        inferred,
        isNot(contains(ArcQuestCatalogue.findByName('Dust On The Wires')!.id)),
      );
    });

    test('Combat Recon blocks backwards inference at ambiguity', () {
      final combatRecon = ArcQuestCatalogue.findByName('Combat Recon')!;
      final inferred = engine.inferCompletedAncestors(<String>{combatRecon.id});

      expect(inferred, isEmpty);
      expect(
        inferred,
        isNot(contains(ArcQuestCatalogue.findByName('Into The Fray')!.id)),
      );
      expect(
        inferred,
        isNot(contains(ArcQuestCatalogue.findByName('Out Of The Shadows')!.id)),
      );
    });

    test('search supports quest, trader and map', () {
      expect(
        engine.search('Dormant Barons').map((node) => node.displayName),
        contains('Dormant Barons'),
      );
      final lanceResults = engine.search('Lance');
      expect(lanceResults, isNotEmpty);
      expect(lanceResults.every((node) => node.trader == 'Lance'), isTrue);
      expect(
        lanceResults.map((node) => node.displayName),
        isNot(contains('A Balanced Harvest')),
      );
      expect(
        engine
            .search('Stella Montis')
            .every((node) => node.mapNames.contains('Stella Montis')),
        isTrue,
      );
    });
  });
}
