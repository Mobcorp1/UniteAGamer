import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_preview_frame_gate.dart';

void main() {
  test('accepts first frame and throttles frames inside interval', () {
    final gate = ArcBlueprintPreviewFrameGate(
      minimumInterval: const Duration(milliseconds: 250),
    );

    expect(gate.shouldProcess(1_000_000), isTrue);
    expect(gate.shouldProcess(1_100_000), isFalse);
    expect(gate.shouldProcess(1_249_999), isFalse);
    expect(gate.shouldProcess(1_250_000), isTrue);
  });

  test('reset allows the next frame immediately', () {
    final gate = ArcBlueprintPreviewFrameGate(
      minimumInterval: const Duration(milliseconds: 250),
    );

    expect(gate.shouldProcess(2_000_000), isTrue);
    expect(gate.shouldProcess(2_010_000), isFalse);

    gate.reset();

    expect(gate.shouldProcess(2_010_000), isTrue);
  });
}
