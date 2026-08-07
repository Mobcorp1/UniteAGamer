import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_cell_analyzer.dart';

void main() {
  test(
    'all-empty grid remains empty instead of producing relative false positives',
    () {
      final image = img.Image(width: 1000, height: 500);

      for (var row = 0; row < 5; row++) {
        for (var column = 0; column < 10; column++) {
          final shade = 14 + ((row + column) % 5);
          img.fillRect(
            image,
            x1: column * 100,
            y1: row * 100,
            x2: ((column + 1) * 100) - 1,
            y2: ((row + 1) * 100) - 1,
            color: img.ColorRgb8(shade, shade + 1, shade + 2),
          );
        }
      }

      final results = const ArcBlueprintCellAnalyzer(
        columns: 10,
        rows: 5,
      ).analyze(image);

      expect(results, hasLength(50));
      expect(results.every((result) => result.occupancyScore <= 0.28), isTrue);
    },
  );

  test(
    'textured artwork is recognised without forcing neighbouring empty cells',
    () {
      final image = img.Image(width: 1000, height: 500);
      img.fill(image, color: img.ColorRgb8(14, 16, 20));

      for (final index in <int>[0, 7, 24, 39, 49]) {
        final row = index ~/ 10;
        final column = index % 10;
        final left = column * 100;
        final top = row * 100;

        img.fillRect(
          image,
          x1: left + 8,
          y1: top + 8,
          x2: left + 92,
          y2: top + 92,
          color: img.ColorRgb8(38, 96, 158),
        );

        for (var line = 0; line < 8; line++) {
          img.drawLine(
            image,
            x1: left + 10,
            y1: top + 12 + (line * 10),
            x2: left + 90,
            y2: top + 28 + (line * 8),
            color: line.isEven
                ? img.ColorRgb8(230, 88, 35)
                : img.ColorRgb8(52, 205, 225),
            thickness: 3,
          );
        }
      }

      final results = const ArcBlueprintCellAnalyzer(
        columns: 10,
        rows: 5,
      ).analyze(image);

      for (var index = 0; index < results.length; index++) {
        if (<int>[0, 7, 24, 39, 49].contains(index)) {
          expect(results[index].occupancyScore, greaterThanOrEqualTo(0.72));
        } else {
          expect(results[index].occupancyScore, lessThanOrEqualTo(0.28));
        }
      }
    },
  );

  test(
    'first-column clipped artwork is recovered by multi-window consensus',
    () {
      final image = img.Image(width: 1000, height: 500);
      img.fill(image, color: img.ColorRgb8(12, 14, 18));

      img.fillRect(
        image,
        x1: 0,
        y1: 108,
        x2: 88,
        y2: 190,
        color: img.ColorRgb8(42, 118, 185),
      );
      for (var line = 0; line < 7; line++) {
        img.drawLine(
          image,
          x1: 0,
          y1: 112 + (line * 10),
          x2: 86,
          y2: 126 + (line * 9),
          color: img.ColorRgb8(225, 78 + (line * 8), 38),
          thickness: 3,
        );
      }

      final results = const ArcBlueprintCellAnalyzer(
        columns: 10,
        rows: 5,
      ).analyze(image);

      expect(results[10].occupancyScore, greaterThanOrEqualTo(0.72));
      expect(results[10].windowAgreement, greaterThan(0.35));
    },
  );

  test('returns one result for every cell', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(10, 10, 12));

    final results = const ArcBlueprintCellAnalyzer(
      columns: 10,
      rows: 5,
    ).analyze(image);

    expect(results, hasLength(50));
  });
}
