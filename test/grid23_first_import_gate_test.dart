import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  List<ArcBlueprintPhotoCellDecision> occupied(int count) => [
    for (var i = 0; i < count; i++)
      ArcBlueprintPhotoCellDecision(
        blueprintId: 'bp_$i',
        blueprintIndex: i,
        sourceCaptureId: 'full-grid',
        rowIndex: i ~/ 17,
        columnIndex: i % 17,
        state: ArcBlueprintPhotoCellState.owned,
        confidence: .96,
      ),
  ];
  test('ordinary near-complete first import is blocked until reviewed', () {
    expect(
      ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
        decisions: occupied(80),
        existing: const {},
      ),
      isNotNull,
    );
  });
  test('explicitly confirmed first import passes the automatic-only cap', () {
    expect(
      ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
        decisions: occupied(80),
        existing: const {},
        confirmedInitialImport: true,
      ),
      isNull,
    );
  });
}
