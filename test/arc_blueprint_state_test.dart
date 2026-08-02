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

    test('empty placeholder records do not become owned blueprints', () {
      final state = ArcBlueprintState.fromMap(const {'blueprintId': 'anvil'});

      expect(state.blueprintId, 'anvil');
      expect(state.owned, isFalse);
      expect(state.wanted, isTrue);
      expect(state.availableToTrade, isFalse);
    });

    test('available-to-trade legacy records still imply ownership', () {
      final state = ArcBlueprintState.fromMap(const {
        'blueprintId': 'tempest',
        'availableToTrade': true,
      });

      expect(state.owned, isTrue);
    });

    test('copyWith clamps invalid duplicate and priority counts', () {
      final state = ArcBlueprintState.empty(
        'bobcat',
      ).copyWith(dupesOwned: -4, priorityRank: -1);

      expect(state.owned, isFalse);
      expect(state.dupesOwned, 0);
      expect(state.priorityRank, 0);
    });

    test('hydration snapshot distinguishes loading from confirmed empty', () {
      final loading = ArcBlueprintStateSnapshot.loading(userId: 'raider');
      final loadedEmpty = ArcBlueprintStateSnapshot.loaded(
        userId: 'raider',
        states: const <String, ArcBlueprintState>{},
      );
      final cachedRefresh = ArcBlueprintStateSnapshot.loading(
        userId: 'raider',
        states: <String, ArcBlueprintState>{
          'hairpin': ArcBlueprintState.empty(
            'hairpin',
          ).copyWith(owned: true, dupesOwned: 3),
        },
      );

      expect(loading.isLoading, isTrue);
      expect(loading.isConfirmedEmpty, isFalse);
      expect(loading.hasUsableState, isFalse);
      expect(loadedEmpty.isConfirmedEmpty, isTrue);
      expect(cachedRefresh.isLoading, isTrue);
      expect(cachedRefresh.hasUsableState, isTrue);
      expect(cachedRefresh.states['hairpin']?.dupesOwned, 3);
    });
  });
}
