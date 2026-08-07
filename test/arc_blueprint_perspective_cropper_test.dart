import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

void main() {
  test('perspective correction produces fixed 10 by 5 geometry', () {
    final source = img.Image(width: 240, height: 160);
    img.fill(source, color: img.ColorRgb8(20, 30, 40));
    img.fillRect(
      source,
      x1: 30,
      y1: 20,
      x2: 220,
      y2: 145,
      color: img.ColorRgb8(180, 190, 200),
    );

    const cropper = ArcBlueprintPerspectiveCropper(
      outputWidth: 100,
      outputHeight: 50,
    );
    final result = cropper.rectifyDetection(
      imageBytes: Uint8List.fromList(img.encodePng(source)),
      detection: const ArcBlueprintGridDetection(
        topLeft: Offset(0.125, 0.125),
        topRight: Offset(0.916, 0.125),
        bottomLeft: Offset(0.125, 0.906),
        bottomRight: Offset(0.916, 0.906),
        confidence: 0.9,
        message: 'Grid locked',
      ),
    );

    final decoded = img.decodeImage(result);
    expect(decoded, isNotNull);
    expect(decoded!.width, 100);
    expect(decoded.height, 50);
  });
}
