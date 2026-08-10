import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_personal_calibration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

ArcBlueprintPhotoOccupancySample sample(
  int index,
  double score, {
  String captureId = 'top',
}) {
  return ArcBlueprintPhotoOccupancySample(
    captureId: captureId,
    rowIndex: index ~/ 10,
    columnIndex: index % 10,
    occupancyScore: score,
  );
}

ArcBlueprintState state(String id, {required bool owned}) {
  return ArcBlueprintState(
    blueprintId: id,
    owned: owned,
    dupesOwned: 0,
    priorityRank: 0,
    updatedAt: DateTime(2026),
  );
}

void main() {
  final ids = List<String>.generate(20, (index) => 'bp_$index');

  test('weak new-owned candidate is suppressed relative to strong anchors', () {
    final existing = <String, ArcBlueprintState>{
      for (var i = 0; i < 10; i++) ids[i]: state(ids[i], owned: true),
    };

    final samples = <ArcBlueprintPhotoOccupancySample>[
      for (var i = 0; i < 10; i++) sample(i, 0.96),
      sample(10, 0.86),
      sample(11, 0.97),
    ];

    final result = const ArcBlueprintPersonalCalibrationEngine().calibrate(
      orderedBlueprintIds: ids,
      samples: samples,
      existing: existing,
    );

    expect(result.knownOwnedAnchors, 10);
    expect(result.globalOwnedFloor, greaterThan(0.89));
    expect(result.suppressedCandidateCount, 1);

    final weak = result.samples.firstWhere(
      (item) => item.rowIndex == 1 && item.columnIndex == 0,
    );
    final strong = result.samples.firstWhere(
      (item) => item.rowIndex == 1 && item.columnIndex == 1,
    );

    expect(weak.occupancyScore, 0.82);
    expect(strong.occupancyScore, 0.97);
  });

  test('existing owned cell is never suppressed', () {
    final existing = <String, ArcBlueprintState>{
      for (var i = 0; i < 10; i++) ids[i]: state(ids[i], owned: true),
    };

    final samples = <ArcBlueprintPhotoOccupancySample>[
      for (var i = 0; i < 9; i++) sample(i, 0.97),
      sample(9, 0.85),
    ];

    final result = const ArcBlueprintPersonalCalibrationEngine().calibrate(
      orderedBlueprintIds: ids,
      samples: samples,
      existing: existing,
    );

    expect(result.samples.last.occupancyScore, 0.85);
  });

  test('insufficient ownership anchors keep base 0.84 behaviour', () {
    final existing = <String, ArcBlueprintState>{
      for (var i = 0; i < 3; i++) ids[i]: state(ids[i], owned: true),
    };

    final samples = <ArcBlueprintPhotoOccupancySample>[
      for (var i = 0; i < 3; i++) sample(i, 0.98),
      sample(10, 0.85),
    ];

    final result = const ArcBlueprintPersonalCalibrationEngine().calibrate(
      orderedBlueprintIds: ids,
      samples: samples,
      existing: existing,
    );

    expect(result.globalOwnedFloor, 0.84);
    expect(result.suppressedCandidateCount, 0);
    expect(result.samples.last.occupancyScore, 0.85);
  });

  test(
    'capture-specific floor adapts independently when enough anchors exist',
    () {
      final ids = List<String>.generate(30, (index) => 'bp_$index');
      final existing = <String, ArcBlueprintState>{
        for (var i = 0; i < 8; i++) ids[i]: state(ids[i], owned: true),
      };

      final samples = <ArcBlueprintPhotoOccupancySample>[
        for (var i = 0; i < 4; i++) sample(i, 0.98, captureId: 'top'),
        for (var i = 4; i < 8; i++) sample(i, 0.90, captureId: 'bottom'),
        sample(10, 0.90, captureId: 'top'),
        sample(11, 0.86, captureId: 'bottom'),
      ];

      final result = const ArcBlueprintPersonalCalibrationEngine().calibrate(
        orderedBlueprintIds: ids,
        samples: samples,
        existing: existing,
      );

      expect(result.captureOwnedFloors['top'], greaterThan(0.90));
      expect(result.captureOwnedFloors['bottom'], greaterThanOrEqualTo(0.84));
    },
  );
}
