import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_lattice_registrar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_three_state_grid_classifier.dart';

void main() {
  // Ground truth fixture only. NEVER add these slot positions to application
  // ownership/classification logic: actual players own different collections.
  const emptySlots = <int>{2, 9, 38, 55, 60, 62, 87, 89};

  Uint8List syntheticPhoto({
    required int left,
    required int top,
    required int colPitch,
    required int rowPitch,
  }) {
    final image = img.Image(width: 1700, height: 600);
    img.fill(image, color: img.ColorRgb8(6, 9, 14));
    for (var slot = 1; slot <= 91; slot++) {
      final row = (slot - 1) ~/ 17;
      final col = (slot - 1) % 17;
      final x = left + col * colPitch;
      final y = top + row * rowPitch;
      final right = x + (colPitch * .85).round();
      final bottom = y + (rowPitch * .80).round();
      // Visible neutral card border, including around unowned/black cells.
      img.fillRect(
        image,
        x1: x,
        y1: y,
        x2: right,
        y2: bottom,
        color: img.ColorRgb8(115, 140, 157),
      );
      img.fillRect(
        image,
        x1: x + 3,
        y1: y + 3,
        x2: right - 3,
        y2: bottom - 3,
        color: emptySlots.contains(slot)
            ? img.ColorRgb8(6, 9, 14)
            : img.ColorRgb8(18, 69, 177),
      );
      if (!emptySlots.contains(slot)) {
        // A small neutral icon mimics the bright object inside blue cards.
        img.fillRect(
          image,
          x1: x + colPitch ~/ 3,
          y1: y + rowPitch ~/ 3,
          x2: x + colPitch ~/ 3 + 8,
          y2: y + rowPitch ~/ 3 + 8,
          color: img.ColorRgb8(203, 216, 218),
        );
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 96));
  }

  for (final scenario in [
    (left: 38, top: 28, colPitch: 94, rowPitch: 88),
    (left: 16, top: 10, colPitch: 99, rowPitch: 96),
  ]) {
    test('Grid34 aligns 17x6 card gaps with shifted/scaled camera crop: $scenario', () {
      final raw = syntheticPhoto(
        left: scenario.left,
        top: scenario.top,
        colPitch: scenario.colPitch,
        rowPitch: scenario.rowPitch,
      );
      final fitted = const ArcBlueprintCameraLatticeRegistrar().register(raw);
      final image = img.decodeImage(fitted.bytes);
      expect(image, isNotNull);
      expect(image!.width, 1700);
      expect(image.height, 600);
      expect((fitted.left - scenario.left).abs(), lessThan(17));
      expect((fitted.top - scenario.top).abs(), lessThan(17));
      expect((fitted.columnPitch - scenario.colPitch).abs(), lessThan(5));
      expect((fitted.rowPitch - scenario.rowPitch).abs(), lessThan(6));
      expect(fitted.columnScore, greaterThan(.13));
      expect(fitted.rowScore, greaterThan(.12));

      final cells = const ArcBlueprintThreeStateGridClassifier().analyze(
        fitted.bytes,
      );
      expect(cells.length, 91);
      final owned = <int>[];
      final missing = <int>[];
      final uncertain = <int>[];
      for (final cell in cells) {
        final slot = cell.rowIndex * 17 + cell.columnIndex + 1;
        if (cell.occupancyScore >= .9) {
          owned.add(slot);
        } else if (cell.occupancyScore < .1) {
          missing.add(slot);
        } else {
          uncertain.add(slot);
        }
      }
      // A camera geometry pass must NEVER turn an empty cell into an owned
      // Blueprint. The legacy three-state classifier is deliberately cautious:
      // slight JPEG/border bleed can turn black slots into 0.50 (review)
      // rather than 0.03 (confidently missing). That is safe, not a false
      // positive. Detecting 'missing' with confidence is a separate task.
      expect(owned.length, 83);
      expect(owned.toSet().intersection(emptySlots), isEmpty);
      expect(missing.toSet().union(uncertain.toSet()), emptySlots);
      expect(missing.length + uncertain.length, emptySlots.length);
    });
  }

  test('Grid34 refuses a solid image with no recurring card gaps', () {
    final flat = img.Image(width: 1700, height: 600);
    img.fill(flat, color: img.ColorRgb8(22, 74, 170));
    final bytes = Uint8List.fromList(img.encodeJpg(flat, quality: 95));
    expect(
      () => const ArcBlueprintCameraLatticeRegistrar().register(bytes),
      throwsA(isA<FormatException>()),
    );
  });
}
