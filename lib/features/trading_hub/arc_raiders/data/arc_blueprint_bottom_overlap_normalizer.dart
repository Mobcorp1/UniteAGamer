import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ArcBlueprintBottomOverlapNormalizer {
  const ArcBlueprintBottomOverlapNormalizer();

  Uint8List removeRegisteredOverlap(Uint8List registeredFiveRowBytes) {
    final decoded = img.decodeImage(registeredFiveRowBytes);
    if (decoded == null) {
      throw const FormatException(
        'The registered bottom Blueprint capture could not be decoded.',
      );
    }

    final image = img.bakeOrientation(decoded);
    final normalized = image.width == 1000 && image.height == 500
        ? image
        : img.copyResize(
            image,
            width: 1000,
            height: 500,
            interpolation: img.Interpolation.cubic,
          );

    // Registration has already snapped the physical cell lattice to 100 px
    // per row. The overlap is therefore exactly the first 100 px row.
    final bottomFourRows = img.copyCrop(
      normalized,
      x: 0,
      y: 100,
      width: 1000,
      height: 400,
    );

    return Uint8List.fromList(img.encodeJpg(bottomFourRows, quality: 96));
  }
}
