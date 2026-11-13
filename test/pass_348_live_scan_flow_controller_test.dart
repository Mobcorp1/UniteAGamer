import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_scan_flow_controller.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  ArcBlueprintLiveOccupancySnapshot stableSnapshot({
    required int rowOffset,
    required int rows,
  }) {
    return ArcBlueprintLiveOccupancySnapshot(
      frameCount: 4,
      cells: <ArcBlueprintLiveCellEstimate>[
        for (var row = 0; row < rows; row++)
          for (var column = 0; column < 10; column++)
            if (rowOffset + row < 8 || column < 3)
              ArcBlueprintLiveCellEstimate(
                rowIndex: rowOffset + row,
                columnIndex: column,
                state: ArcBlueprintPhotoCellState.missing,
                occupancyScore: 0.08,
                confidence: 0.92,
                observationCount: 4,
                stable: true,
              ),
      ],
    );
  }

  test('PASS 348 top section auto-completes without a photo action', () {
    final controller = ArcBlueprintLiveScanFlowController();

    final transition = controller.acceptStableFrame(
      snapshot: stableSnapshot(rowOffset: 0, rows: 5),
      frameBytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(transition.accepted, isTrue);
    expect(controller.phase, ArcBlueprintLiveScanPhase.awaitingBottomScroll);
    expect(controller.result, isNull);
  });

  test(
    'PASS 348 lower scan starts only after explicit scroll confirmation',
    () {
      final controller = ArcBlueprintLiveScanFlowController();
      controller.acceptStableFrame(
        snapshot: stableSnapshot(rowOffset: 0, rows: 5),
        frameBytes: Uint8List.fromList(<int>[1]),
      );

      expect(controller.beginBottomSection(), isTrue);
      expect(controller.phase, ArcBlueprintLiveScanPhase.bottomScanning);
      expect(controller.beginBottomSection(), isFalse);
    },
  );

  test('PASS 348 stable lower section completes frame pair', () {
    final controller = ArcBlueprintLiveScanFlowController();
    controller.acceptStableFrame(
      snapshot: stableSnapshot(rowOffset: 0, rows: 5),
      frameBytes: Uint8List.fromList(<int>[11, 12]),
    );
    controller.beginBottomSection();

    final transition = controller.acceptStableFrame(
      snapshot: stableSnapshot(rowOffset: 5, rows: 4),
      frameBytes: Uint8List.fromList(<int>[21, 22]),
    );

    expect(transition.accepted, isTrue);
    expect(controller.phase, ArcBlueprintLiveScanPhase.complete);
    expect(controller.result, isNotNull);
    expect(controller.result!.topFrameBytes, <int>[11, 12]);
    expect(controller.result!.bottomFrameBytes, <int>[21, 22]);
  });

  test('PASS 348 unstable sections never auto-complete', () {
    final controller = ArcBlueprintLiveScanFlowController();
    const snapshot = ArcBlueprintLiveOccupancySnapshot(
      frameCount: 2,
      cells: <ArcBlueprintLiveCellEstimate>[
        ArcBlueprintLiveCellEstimate(
          rowIndex: 0,
          columnIndex: 0,
          state: ArcBlueprintPhotoCellState.uncertain,
          occupancyScore: 0.5,
          confidence: 0.2,
          observationCount: 2,
          stable: false,
        ),
      ],
    );

    final transition = controller.acceptStableFrame(
      snapshot: snapshot,
      frameBytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(transition.accepted, isFalse);
    expect(controller.phase, ArcBlueprintLiveScanPhase.topScanning);
  });
}
