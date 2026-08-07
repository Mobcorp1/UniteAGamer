import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_uploaded_image_processor.dart';

void main() {
  test('uploaded images require automatic grid detection', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(22, 24, 28));
    expect(
      () => const ArcBlueprintUploadedImageProcessor().process(
        Uint8List.fromList(img.encodePng(image)),
      ),
      throwsFormatException,
    );
  });

  test('empty bytes are rejected', () {
    expect(
      () => const ArcBlueprintUploadedImageProcessor().process(Uint8List(0)),
      throwsFormatException,
    );
  });
}
