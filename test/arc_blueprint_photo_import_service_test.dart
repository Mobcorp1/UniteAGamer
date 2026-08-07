import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

void main() {
  test('ownership import preserves duplicates and priority', () {
    final existing = {
      'a': ArcBlueprintState(
        blueprintId: 'a',
        owned: true,
        dupesOwned: 3,
        priorityRank: 88,
        updatedAt: DateTime(2026),
      ),
      'b': ArcBlueprintState(
        blueprintId: 'b',
        owned: false,
        dupesOwned: 0,
        priorityRank: 42,
        updatedAt: DateTime(2026),
      ),
    };
    const decisions = [
      ArcBlueprintPhotoCellDecision(
        blueprintId: 'a',
        blueprintIndex: 0,
        state: ArcBlueprintPhotoCellState.missing,
        confidence: 1,
        sourceCaptureId: 'top',
        rowIndex: 0,
        columnIndex: 0,
        manuallyConfirmed: true,
      ),
      ArcBlueprintPhotoCellDecision(
        blueprintId: 'b',
        blueprintIndex: 1,
        state: ArcBlueprintPhotoCellState.owned,
        confidence: 1,
        sourceCaptureId: 'top',
        rowIndex: 0,
        columnIndex: 1,
        manuallyConfirmed: true,
      ),
    ];

    final updates = ArcBlueprintPhotoImportService.buildUpdates(
      decisions: decisions,
      existing: existing,
    );

    final a = updates.firstWhere((state) => state.blueprintId == 'a');
    final b = updates.firstWhere((state) => state.blueprintId == 'b');
    expect(a.owned, isTrue, reason: 'Duplicate ownership must remain owned.');
    expect(a.dupesOwned, 3);
    expect(a.priorityRank, 88);
    expect(b.owned, isTrue);
    expect(b.dupesOwned, 0);
    expect(b.priorityRank, 42);
  });

  test('uncertain import decisions preserve previous ownership state', () {
    final existing = {
      'owned': ArcBlueprintState(
        blueprintId: 'owned',
        owned: true,
        dupesOwned: 0,
        priorityRank: 7,
        updatedAt: DateTime(2026),
      ),
      'missing': ArcBlueprintState(
        blueprintId: 'missing',
        owned: false,
        dupesOwned: 0,
        priorityRank: 4,
        updatedAt: DateTime(2026),
      ),
    };
    const decisions = [
      ArcBlueprintPhotoCellDecision(
        blueprintId: 'owned',
        blueprintIndex: 0,
        state: ArcBlueprintPhotoCellState.uncertain,
        confidence: 0.5,
        sourceCaptureId: 'top',
        rowIndex: 0,
        columnIndex: 0,
      ),
      ArcBlueprintPhotoCellDecision(
        blueprintId: 'missing',
        blueprintIndex: 1,
        state: ArcBlueprintPhotoCellState.uncertain,
        confidence: 0.5,
        sourceCaptureId: 'top',
        rowIndex: 0,
        columnIndex: 1,
      ),
    ];

    final updates = ArcBlueprintPhotoImportService.buildUpdates(
      decisions: decisions,
      existing: existing,
    );

    expect(
      updates.firstWhere((state) => state.blueprintId == 'owned').owned,
      isTrue,
    );
    expect(
      updates.firstWhere((state) => state.blueprintId == 'missing').owned,
      isFalse,
    );
  });
}
