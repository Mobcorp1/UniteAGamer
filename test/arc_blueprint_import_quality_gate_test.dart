import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_import_quality_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

List<ArcBlueprintPhotoCellDecision> decisions(int count) {
  return List<ArcBlueprintPhotoCellDecision>.generate(
    count,
    (index) => ArcBlueprintPhotoCellDecision(
      blueprintId: 'bp_$index',
      blueprintIndex: index,
      state: index.isEven
          ? ArcBlueprintPhotoCellState.owned
          : ArcBlueprintPhotoCellState.missing,
      confidence: 0.90,
      sourceCaptureId: index < 50 ? 'top' : 'bottom',
      rowIndex: index ~/ 10,
      columnIndex: index % 10,
    ),
  );
}

void main() {
  test('accepts exactly 83 canonical positions', () {
    final result = const ArcBlueprintImportQualityGate().evaluate(
      decisions: decisions(83),
      topCaptureConfidence: 0.90,
      bottomCaptureConfidence: 0.90,
    );

    expect(result.accepted, isTrue);
  });

  test('rejects an incomplete 82-position result', () {
    final result = const ArcBlueprintImportQualityGate().evaluate(
      decisions: decisions(82),
      topCaptureConfidence: 0.90,
      bottomCaptureConfidence: 0.90,
    );

    expect(result.accepted, isFalse);
    expect(result.message, contains('82 of 83 positions'));
  });
}
