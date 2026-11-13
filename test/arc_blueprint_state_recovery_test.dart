import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state_recovery.dart';

void main() {
  test(
    'Blueprint recovery preserves current state while adding legacy gaps',
    () {
      final current = <String, ArcBlueprintState>{
        'hairpin': ArcBlueprintState.empty(
          'hairpin',
        ).copyWith(owned: true, dupesOwned: 0, priorityRank: 2),
      };
      final legacy = ArcBlueprintStateRecoverySource(
        path: 'arc_blueprints/user_a/states',
        states: <String, ArcBlueprintState>{
          'hairpin': ArcBlueprintState.empty(
            'hairpin',
          ).copyWith(owned: true, dupesOwned: 3, priorityRank: 5),
          'anvil-splitter': ArcBlueprintState.empty(
            'anvil-splitter',
          ).copyWith(owned: true),
        },
      );

      final merged = ArcBlueprintStateRecovery.merge(
        currentStates: current,
        legacySources: [legacy],
      );

      expect(merged.keys, containsAll(<String>['hairpin', 'anvil-splitter']));
      expect(merged['hairpin']?.owned, isTrue);
      expect(merged['hairpin']?.dupesOwned, 3);
      expect(merged['hairpin']?.priorityRank, 2);
      expect(merged['anvil-splitter']?.owned, isTrue);
    },
  );

  test('Blueprint recovery preview flags populated legacy sources', () {
    final preview = ArcBlueprintStateRecoveryPreview(
      canonicalPath: 'users/user_a/arc_blueprints',
      currentStates: const <String, ArcBlueprintState>{},
      legacySources: [
        ArcBlueprintStateRecoverySource(
          path: 'users/user_a/blueprints',
          states: <String, ArcBlueprintState>{
            'kinetic-converter': ArcBlueprintState.empty(
              'kinetic-converter',
            ).copyWith(owned: true),
          },
        ),
      ],
      mergedStates: <String, ArcBlueprintState>{
        'kinetic-converter': ArcBlueprintState.empty(
          'kinetic-converter',
        ).copyWith(owned: true),
      },
    );

    expect(preview.requiresMigration, isTrue);
    expect(preview.legacyPathsWithData, ['users/user_a/blueprints']);
    expect(preview.recoveredStateCount, 1);
  });
}
