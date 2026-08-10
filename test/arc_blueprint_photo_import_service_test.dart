import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

ArcBlueprintState state(String id, {required bool owned}) => ArcBlueprintState(
  blueprintId: id,
  owned: owned,
  dupesOwned: owned ? 2 : 0,
  priorityRank: 7,
  updatedAt: DateTime(2026),
);

ArcBlueprintPhotoCellDecision decision(
  String id,
  int index,
  ArcBlueprintPhotoCellState cellState,
) => ArcBlueprintPhotoCellDecision(
  blueprintId: id,
  blueprintIndex: index,
  state: cellState,
  confidence: 0.95,
  sourceCaptureId: index < 50 ? 'top' : 'bottom',
  rowIndex: index ~/ 10,
  columnIndex: index % 10,
);

void main() {
  test('rescan is additive and never clears previous ownership', () {
    final existing = <String, ArcBlueprintState>{
      'old': state('old', owned: true),
      'new': state('new', owned: false),
    };

    final updates = ArcBlueprintPhotoImportService.buildUpdates(
      decisions: <ArcBlueprintPhotoCellDecision>[
        decision('old', 0, ArcBlueprintPhotoCellState.missing),
        decision('new', 1, ArcBlueprintPhotoCellState.owned),
      ],
      existing: existing,
    );

    final old = updates.firstWhere((item) => item.blueprintId == 'old');
    final newlyOwned = updates.firstWhere((item) => item.blueprintId == 'new');

    expect(old.owned, isTrue);
    expect(old.dupesOwned, 2);
    expect(old.priorityRank, 7);
    expect(newlyOwned.owned, isTrue);
  });

  test('blocks catastrophic 83 of 83 false-positive update', () {
    final existing = <String, ArcBlueprintState>{
      for (var i = 0; i < 38; i++) 'bp_$i': state('bp_$i', owned: true),
    };
    final decisions = <ArcBlueprintPhotoCellDecision>[
      for (var i = 0; i < 83; i++)
        decision('bp_$i', i, ArcBlueprintPhotoCellState.owned),
    ];

    final reason = ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
      decisions: decisions,
      existing: existing,
    );

    expect(reason, isNotNull);
    expect(reason, contains('almost every Blueprint'));
  });

  test('allows a normal small rescan update', () {
    final existing = <String, ArcBlueprintState>{
      for (var i = 0; i < 38; i++) 'bp_$i': state('bp_$i', owned: true),
    };
    final decisions = <ArcBlueprintPhotoCellDecision>[
      for (var i = 0; i < 43; i++)
        decision('bp_$i', i, ArcBlueprintPhotoCellState.owned),
      for (var i = 43; i < 83; i++)
        decision('bp_$i', i, ArcBlueprintPhotoCellState.missing),
    ];

    final reason = ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
      decisions: decisions,
      existing: existing,
    );

    expect(reason, isNull);
  });
}
