import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_three_state_grid_classifier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  test(
    'solid-black and translucent empty cells stay empty; unambiguous blue artwork is owned; weak dark strip stays uncertain',
    () {
      final image = img.Image(width: 1700, height: 600);
      img.fill(image, color: img.ColorRgb8(8, 9, 10));
      // Synthetic grey frame on each of the physical 91 cells.
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < (row == 5 ? 6 : 17); col++) {
          img.fillRect(
            image,
            x1: col * 100 + 5,
            y1: row * 100 + 5,
            x2: col * 100 + 94,
            y2: row * 100 + 94,
            color: img.ColorRgb8(64, 67, 71),
          );
          img.fillRect(
            image,
            x1: col * 100 + 9,
            y1: row * 100 + 9,
            x2: col * 100 + 90,
            y2: row * 100 + 90,
            color: img.ColorRgb8(7, 8, 10),
          );
        }
      }
      // slot 1: current near-solid black unowned card.
      // slot 2: older translucent empty card with very faint scene detail.
      img.fillRect(
        image,
        x1: 109,
        y1: 9,
        x2: 190,
        y2: 90,
        color: img.ColorRgb8(22, 24, 28),
      );
      // slot 23: normal blue artwork, card row 2 col 6.
      img.fillRect(
        image,
        x1: 512,
        y1: 114,
        x2: 587,
        y2: 175,
        color: img.ColorRgb8(21, 64, 143),
      );
      // slot 34: dark card where only a strip has a blue hue, little white.
      // 16/76 = 21% of face width; no bright pixel requirement.
      img.fillRect(
        image,
        x1: 1612,
        y1: 114,
        x2: 1627,
        y2: 175,
        color: img.ColorRgb8(9, 44, 90),
      );
      final bytes = Uint8List.fromList(img.encodePng(image));
      final samples = const ArcBlueprintThreeStateGridClassifier().analyze(
        bytes,
      );
      expect(samples, hasLength(91));
      final decisions = const ArcBlueprintPhotoOccupancyEngine(columns: 17)
          .classify(
            orderedBlueprintIds: List.generate(91, (i) => 'bp_$i'),
            samples: samples,
          );
      expect(decisions.errors, isEmpty);
      expect(decisions.decisions[0].state, ArcBlueprintPhotoCellState.missing);
      expect(decisions.decisions[1].state, ArcBlueprintPhotoCellState.missing);
      expect(decisions.decisions[22].state, ArcBlueprintPhotoCellState.owned);
      expect(decisions.decisions[33].state, ArcBlueprintPhotoCellState.uncertain);
      expect(decisions.decisions[34].state, ArcBlueprintPhotoCellState.missing);
    },
  );
}
