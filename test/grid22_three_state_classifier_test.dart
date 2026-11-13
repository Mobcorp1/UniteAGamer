import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_three_state_grid_classifier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  test('91 positions, black empty, blue owned, grey uncertain', () {
    final image = img.Image(width: 1700, height: 600);
    img.fill(image, color: img.ColorRgb8(0, 0, 0));
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < (row == 5 ? 6 : 17); col++) {
        final color = row == 0 && col == 0
            ? img.ColorRgb8(12, 12, 12)
            : row == 0 && col == 1
            ? img.ColorRgb8(90, 90, 90)
            : img.ColorRgb8(10, 50, 175);
        img.fillRect(
          image,
          x1: col * 100 + 5,
          y1: row * 100 + 5,
          x2: col * 100 + 94,
          y2: row * 100 + 94,
          color: color,
        );
        if (!(row == 0 && col < 2)) {
          img.fillRect(
            image,
            x1: col * 100 + 42,
            y1: row * 100 + 22,
            x2: col * 100 + 56,
            y2: row * 100 + 40,
            color: img.ColorRgb8(235, 240, 245),
          );
        }
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(image));
    final samples = const ArcBlueprintThreeStateGridClassifier().analyze(bytes);
    expect(samples.length, 91);
    final ids = List.generate(91, (index) => 'blueprint_$index');
    final result = const ArcBlueprintPhotoOccupancyEngine(
      columns: 17,
    ).classify(orderedBlueprintIds: ids, samples: samples);
    expect(result.errors, isEmpty);
    expect(result.decisions[0].state, ArcBlueprintPhotoCellState.missing);
    expect(result.decisions[1].state, ArcBlueprintPhotoCellState.uncertain);
    expect(result.decisions[2].state, ArcBlueprintPhotoCellState.owned);
    expect(result.decisions[90].rowIndex, 5);
    expect(result.decisions[90].columnIndex, 5);
  });
}
