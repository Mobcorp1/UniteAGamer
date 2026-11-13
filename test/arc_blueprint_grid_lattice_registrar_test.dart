import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_lattice_registrar.dart';

Uint8List buildOffsetGrid() {
  final image = img.Image(width: 1080, height: 540);
  img.fill(image, color: img.ColorRgb8(9, 14, 28));

  const left = 36;
  const top = 18;
  const cellWidth = 100;
  const cellHeight = 100;

  for (var row = 0; row <= 5; row++) {
    final y = top + row * cellHeight;
    for (var x = left; x <= left + 1000; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixelRgb(x, y, 220, 235, 250);
      }
    }
  }

  for (var column = 0; column <= 10; column++) {
    final x = left + column * cellWidth;
    for (var y = top; y <= top + 500; y++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixelRgb(x, y, 220, 235, 250);
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('lattice registrar snaps a slightly loose capture to 10x5 geometry', () {
    const registrar = ArcBlueprintGridLatticeRegistrar();

    final result = registrar.register(
      bytes: buildOffsetGrid(),
      columns: 10,
      rows: 5,
    );

    final decoded = img.decodeImage(result.imageBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 500);
    expect(result.refined, isTrue);
  });
}
