import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';

void main() {
  group('ArcBlueprintRepository state source of truth', () {
    test('canonical path remains users uid arc_blueprints', () {
      expect(
        ArcBlueprintRepository.canonicalStoragePathFor('abc'),
        'users/abc/arc_blueprints',
      );
    });

    test('runtime legacy recovery only uses user-scoped readable paths', () {
      final paths = ArcBlueprintRepository.legacyStoragePathCandidatesFor(
        'abc',
      );

      expect(
        paths,
        containsAll(<String>[
          'users/abc/arc_blueprint_states',
          'users/abc/blueprints',
        ]),
      );

      expect(paths, isNot(contains('arc_blueprint_states/abc/states')));
      expect(paths, isNot(contains('arc_blueprints/abc/states')));
      expect(paths.every((path) => path.startsWith('users/abc/')), isTrue);
    });

    test('one-shot load uses the same recovery resolver as tracker stream', () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('final states = await _statesFromSnapshot(uid, snapshot);'),
      );
      expect(
        source,
        isNot(
          contains(
            'final snapshot = await _stateCollection(uid).get();\n'
            '    return _statesFromSnapshotDocs(snapshot.docs);',
          ),
        ),
      );
      expect(source, contains('ARC BLUEPRINT STATE: load resolved'));
    });
  });
}
