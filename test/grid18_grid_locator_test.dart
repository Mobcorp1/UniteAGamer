import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_single_grid_locator.dart';

void main() {
  test(
    'full screenshot header/margins are excluded; final six cells retained',
    () {
      final scene = img.Image(width: 1900, height: 950);
      img.fill(scene, color: img.ColorRgb8(8, 13, 19));
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < (row == 5 ? 6 : 17); col++) {
          final x0 = 95 + col * 98;
          final y0 = 210 + row * 92;
          for (var y = y0; y < y0 + 67; y++) {
            for (var x = x0; x < x0 + 86; x++) {
              scene.setPixelRgb(x, y, 12, 55, 208);
            }
          }
          // Grey/white book strip remains under the blue artwork.
          for (var y = y0 + 67; y < y0 + 83; y++) {
            for (var x = x0; x < x0 + 86; x++) {
              scene.setPixelRgb(x, y, 12, 18, 31);
            }
          }
          scene.setPixelRgb(x0 + 4, y0 + 76, 248, 248, 248);
        }
      }
      final result = const ArcBlueprintSingleGridLocator().locate(
        Uint8List.fromList(img.encodePng(scene)),
      );
      final crop = img.decodeImage(result)!;
      expect(crop.width, greaterThan(1500));
      expect(crop.height, greaterThan(470));
      expect(crop.height, lessThan(650));
      // Top and bottom owned cells both remain blue after localization.
      expect(crop.getPixel(25, 20).b, greaterThan(80));
      expect(crop.getPixel(25, crop.height - 45).b, greaterThan(60));
    },
  );
  test('no Blueprint grid is rejected, never classified as all missing', () {
    final image = img.Image(width: 1800, height: 800);
    img.fill(image, color: img.ColorRgb8(8, 13, 19));
    expect(
      () => const ArcBlueprintSingleGridLocator().locate(
        Uint8List.fromList(img.encodePng(image)),
      ),
      throwsFormatException,
    );
  });
}
