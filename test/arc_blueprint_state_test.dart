import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

void main() {
  group('ArcBlueprintState mapping', () {
    test('legacy ownedCount becomes owned state with duplicates', () {
      final state = ArcBlueprintState.fromMap(const {
        'blueprintId': 'tempest',
        'ownedCount': 3,
      });

      expect(state.blueprintId, 'tempest');
      expect(state.owned, isTrue);
      expect(state.dupesOwned, 2);
      expect(state.availableToTrade, isTrue);
    });

    test('wanted legacy state remains missing and prioritized', () {
      final state = ArcBlueprintState.fromMap(const {
        'blueprintId': 'wolfpack',
        'wanted': true,
        'priorityRank': 2,
      });

      expect(state.owned, isFalse);
      expect(state.wanted, isTrue);
      expect(state.priorityRank, 2);
      expect(state.isPrioritized, isTrue);
    });

    test('copyWith clamps invalid duplicate and priority counts', () {
      final state = ArcBlueprintState.empty(
        'bobcat',
      ).copyWith(dupesOwned: -4, priorityRank: -1);

      expect(state.owned, isFalse);
      expect(state.dupesOwned, 0);
      expect(state.priorityRank, 0);
    });
  });
}
