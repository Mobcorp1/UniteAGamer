import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

void main() {
  test('top detection normalises to 1000 by 500', () {
    final source = img.Image(width: 600, height: 400);
    img.fill(source, color: img.ColorRgb8(20, 30, 40));

    const detection = ArcBlueprintGridDetection(
      topLeft: Offset(0.12, 0.10),
      topRight: Offset(0.91, 0.16),
      bottomLeft: Offset(0.17, 0.88),
      bottomRight: Offset(0.86, 0.82),
      confidence: 0.9,
      message: 'Grid locked',
      columns: 10,
      rows: 5,
      verticalDividers: <double>[
        0.12,
        0.199,
        0.278,
        0.357,
        0.436,
        0.515,
        0.594,
        0.673,
        0.752,
        0.831,
        0.91,
      ],
      horizontalDividers: <double>[0.10, 0.256, 0.412, 0.568, 0.724, 0.88],
    );

    final result = const ArcBlueprintPerspectiveCropper().rectifyDetection(
      imageBytes: Uint8List.fromList(img.encodePng(source)),
      detection: detection,
    );

    final decoded = img.decodeImage(result);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 500);
  });

  test('bottom three-row detection normalises to 1000 by 300', () {
    final source = img.Image(width: 600, height: 360);
    img.fill(source, color: img.ColorRgb8(20, 30, 40));

    const detection = ArcBlueprintGridDetection(
      topLeft: Offset(0.10, 0.16),
      topRight: Offset(0.92, 0.12),
      bottomLeft: Offset(0.14, 0.80),
      bottomRight: Offset(0.88, 0.84),
      confidence: 0.9,
      message: 'Grid locked',
      columns: 10,
      rows: 3,
      verticalDividers: <double>[
        0.10,
        0.182,
        0.264,
        0.346,
        0.428,
        0.51,
        0.592,
        0.674,
        0.756,
        0.838,
        0.92,
      ],
      horizontalDividers: <double>[0.16, 0.373, 0.586, 0.80],
    );

    final result = const ArcBlueprintPerspectiveCropper().rectifyDetection(
      imageBytes: Uint8List.fromList(img.encodePng(source)),
      detection: detection,
    );

    final decoded = img.decodeImage(result);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 300);
  });

  test('rejects invalid detector geometry', () {
    final source = img.Image(width: 300, height: 200);

    expect(
      () => const ArcBlueprintPerspectiveCropper().rectifyDetection(
        imageBytes: Uint8List.fromList(img.encodePng(source)),
        detection: const ArcBlueprintGridDetection.notFound(),
      ),
      throwsFormatException,
    );
  });
}
