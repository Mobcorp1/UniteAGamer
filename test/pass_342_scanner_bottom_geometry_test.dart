import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_dual_capture_merge_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';

void main() {
  test('manual top capture rectifies to the five-row recognition geometry', () {
    final bytes = const ArcBlueprintPerspectiveCropper().rectify(
      imageBytes: _cameraImageBytes(),
      viewportSize: const Size(1200, 900),
      calibration: const ArcBlueprintEdgeCalibration.defaults(),
    );

    final decoded = img.decodeImage(bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 500);
  });

  test(
    'manual bottom capture rectifies to the four-row recognition geometry',
    () {
      final bytes = const ArcBlueprintPerspectiveCropper().rectify(
        imageBytes: _cameraImageBytes(),
        viewportSize: const Size(1200, 900),
        calibration: const ArcBlueprintEdgeCalibration.defaults(),
        outputRows: ArcBlueprintCanonicalGrid.bottomRows,
      );

      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1000);
      expect(decoded.height, 400);

      final analysis = const ArcBlueprintPhotoPixelAnalyzer(
        columns: ArcBlueprintCanonicalGrid.columns,
        rows: ArcBlueprintCanonicalGrid.bottomRows,
        validColumnCountsByRow: ArcBlueprintCanonicalGrid.bottomRowColumnCounts,
      ).analyze(bytes: bytes, captureId: 'bottom');

      expect(analysis.succeeded, isTrue);
      expect(analysis.samples, hasLength(33));
      expect(
        analysis.samples.where(
          (sample) => sample.rowIndex == 3 && sample.columnIndex > 2,
        ),
        isEmpty,
      );
    },
  );

  test(
    'bottom capture samples map deterministically to canonical rows 6-9',
    () {
      final top = <ArcBlueprintPhotoOccupancySample>[
        for (final position in ArcBlueprintCanonicalGrid.topCapturePositions())
          _sample(
            'top',
            position.localRowIndex,
            position.columnIndex,
            position.canonicalIndex.isEven ? 0.90 : 0.08,
          ),
      ];
      final bottom = <ArcBlueprintPhotoOccupancySample>[
        for (final position
            in ArcBlueprintCanonicalGrid.bottomCapturePositions())
          _sample(
            'bottom',
            position.localRowIndex,
            position.columnIndex,
            position.localRowIndex == 0
                ? position.columnIndex.isOdd
                      ? 0.90
                      : 0.08
                : position.canonicalIndex.isEven
                ? 0.90
                : 0.08,
          ),
      ];

      final result = const ArcBlueprintDualCaptureMergeEngine().merge(
        topSamples: top,
        bottomSamples: bottom,
      );

      expect(result.succeeded, isTrue);
      expect(
        result.samples,
        hasLength(ArcBlueprintCanonicalGrid.totalPositions),
      );
      expect(result.samples[49].rowIndex, 4);
      expect(result.samples[49].columnIndex, 9);
      expect(result.samples[50].captureId, 'bottom');
      expect(result.samples[50].rowIndex, 5);
      expect(result.samples[50].columnIndex, 0);
      expect(result.samples.last.captureId, 'bottom');
      expect(result.samples.last.rowIndex, 8);
      expect(result.samples.last.columnIndex, 2);
    },
  );

  test('duplicated top boundary samples are not shifted into row 6', () {
    final top = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 5; row++)
        for (var column = 0; column < 10; column++)
          _sample('top', row, column, row == 4 && column < 5 ? 0.95 : 0.10),
    ];
    final bottom = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 10; column++)
          _sample(
            'bottom',
            row,
            column,
            row == 0 ? (column < 5 ? 0.95 : 0.10) : 0.10,
          ),
      for (var column = 0; column < 3; column++)
        _sample('bottom', 3, column, 0.10),
    ];

    final result = const ArcBlueprintDualCaptureMergeEngine().merge(
      topSamples: top,
      bottomSamples: bottom,
    );

    expect(result.succeeded, isFalse);
    expect(result.samples, isEmpty);
    expect(result.error, contains('appears to repeat'));
  });
}

Uint8List _cameraImageBytes() {
  final image = img.Image(width: 1600, height: 1200);
  img.fill(image, color: img.ColorRgb8(8, 10, 14));
  for (var y = 0; y < image.height; y += 80) {
    img.drawLine(
      image,
      x1: 0,
      y1: y,
      x2: image.width - 1,
      y2: y,
      color: img.ColorRgb8(24, 28, 36),
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

ArcBlueprintPhotoOccupancySample _sample(
  String captureId,
  int row,
  int column,
  double score,
) {
  return ArcBlueprintPhotoOccupancySample(
    captureId: captureId,
    rowIndex: row,
    columnIndex: column,
    occupancyScore: score,
  );
}
