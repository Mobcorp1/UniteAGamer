import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';

void main() {
  test('Grid33 auto-fit trims dark margins and returns canonical size', () {
    final image = image_codec.Image(width: 1700, height: 600);
    image_codec.fill(image, color: image_codec.ColorRgb8(0, 0, 0));

    // Simulate a manually aligned camera crop with dark outer margins.
    image_codec.fillRect(
      image,
      x1: 90,
      y1: 42,
      x2: 1605,
      y2: 555,
      color: image_codec.ColorRgb8(20, 60, 170),
    );

    // Add a few dark empty cells inside the grid so the fit follows the
    // outer lattice rather than assuming every cell is blue.
    for (final rect in const [
      [180, 70, 260, 150],
      [770, 270, 850, 350],
      [1240, 455, 1320, 535],
    ]) {
      image_codec.fillRect(
        image,
        x1: rect[0],
        y1: rect[1],
        x2: rect[2],
        y2: rect[3],
        color: image_codec.ColorRgb8(3, 6, 10),
      );
    }

    final bytes = Uint8List.fromList(image_codec.encodeJpg(image, quality: 97));
    final output = arcGrid33AutoFitForTest(bytes);
    final decoded = image_codec.decodeImage(output);

    expect(decoded, isNotNull);
    expect(decoded!.width, 1700);
    expect(decoded.height, 600);

    // The post-fit frame should start very close to blue content.
    // Original positions x=50 and x=1650 are black margins. After a
    // successful fit those same coordinates should fall inside the blue
    // lattice (unlike the extreme edge, where conservative padding remains).
    final leftProbe = decoded.getPixel(50, 300);
    final rightProbe = decoded.getPixel(1650, 300);
    expect(leftProbe.b.toInt(), greaterThan(leftProbe.r.toInt()));
    expect(rightProbe.b.toInt(), greaterThan(rightProbe.r.toInt()));
  });
}
