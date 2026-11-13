import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

void main() {
  test('top live section produces all 50 canonical cell samples', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(10, 12, 16));

    final result = const ArcBlueprintLiveOccupancyEngine().analyzeFrame(
      frameImage: image,
      detection: _topDetection(),
      section: ArcBlueprintGridSection.top,
      captureId: 'live-top',
    );

    expect(result.succeeded, isTrue, reason: result.error);
    expect(result.samples, hasLength(50));
    expect(result.samples.first.rowIndex, 0);
    expect(result.samples.last.rowIndex, 4);
    expect(result.samples.last.columnIndex, 9);
  });

  test('bottom live section produces a local 5-row scan segment', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(10, 12, 16));

    final result = const ArcBlueprintLiveOccupancyEngine().analyzeFrame(
      frameImage: image,
      detection: _bottomDetection(),
      section: ArcBlueprintGridSection.bottom,
      captureId: 'live-bottom',
    );

    expect(result.succeeded, isTrue, reason: result.error);
    expect(result.samples, hasLength(50));
    expect(result.samples.first.rowIndex, 0);
    expect(result.samples.last.rowIndex, 4);
    expect(result.samples.last.columnIndex, 9);
  });
}

ArcBlueprintGridDetection _topDetection() {
  return ArcBlueprintGridDetection(
    topLeft: const Offset(0, 0),
    topRight: const Offset(1, 0),
    bottomLeft: const Offset(0, 1),
    bottomRight: const Offset(1, 1),
    confidence: 0.95,
    message: 'locked',
    columns: 10,
    rows: 5,
    verticalDividers: <double>[
      for (var index = 0; index <= 10; index++) index / 10,
    ],
    horizontalDividers: <double>[
      for (var index = 0; index <= 5; index++) index / 5,
    ],
  );
}

ArcBlueprintGridDetection _bottomDetection() {
  return ArcBlueprintGridDetection(
    topLeft: const Offset(0, 0),
    topRight: const Offset(1, 0),
    bottomLeft: const Offset(0, 1),
    bottomRight: const Offset(1, 1),
    confidence: 0.95,
    message: 'locked',
    columns: 10,
    rows: 5,
    verticalDividers: <double>[
      for (var index = 0; index <= 10; index++) index / 10,
    ],
    horizontalDividers: <double>[
      for (var index = 0; index <= 5; index++) index / 5,
    ],
  );
}
