import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_ownership_marker_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';

Uint8List _blankGrid({required int rows}) {
  final image = img.Image(width: 1000, height: rows * 100);
  img.fill(image, color: img.ColorRgb8(14, 18, 38));
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _gridWithMarkers({
  required int rows,
  required bool book,
  required bool tick,
  int bookWidth = 18,
  int tickThickness = 3,
}) {
  final image = img.Image(width: 1000, height: rows * 100);
  img.fill(image, color: img.ColorRgb8(14, 18, 38));

  if (book) {
    img.fillRect(
      image,
      x1: 7,
      y1: 70,
      x2: 7 + bookWidth,
      y2: 91,
      color: img.ColorRgb8(242, 242, 242),
    );
  }

  if (tick) {
    img.drawLine(
      image,
      x1: 72,
      y1: 21,
      x2: 80,
      y2: 28,
      color: img.ColorRgb8(248, 248, 248),
      thickness: tickThickness,
    );
    img.drawLine(
      image,
      x1: 80,
      y1: 28,
      x2: 92,
      y2: 11,
      color: img.ColorRgb8(248, 248, 248),
      thickness: tickThickness,
    );
  }

  return Uint8List.fromList(img.encodePng(image));
}

ArcBlueprintPhotoOccupancySample _sample(double score) =>
    ArcBlueprintPhotoOccupancySample(
      captureId: 'top',
      rowIndex: 0,
      columnIndex: 0,
      occupancyScore: score,
    );

ArcBlueprintTemplateVerificationSample _template(double score) =>
    ArcBlueprintTemplateVerificationSample(
      blueprintId: 'expected',
      blueprintName: 'Expected',
      canonicalIndex: 0,
      rowIndex: 0,
      columnIndex: 0,
      captureId: 'top',
      templateSimilarity: score,
      multiSignalEvidence: 0.99,
      finalScore: 0.99,
      templateAvailable: true,
      suppressed: false,
    );

void main() {
  const engine = ArcBlueprintOwnershipMarkerVerificationEngine();

  test('PASS 345 rejects 0.974 candidate with weak corroboration', () {
    final top = _gridWithMarkers(
      rows: 5,
      book: false,
      tick: true,
      tickThickness: 2,
    );

    final result = engine.verify(
      topBytes: top,
      bottomBytes: _blankGrid(rows: 4),
      samples: [_sample(0.974)],
      templateDiagnostics: [_template(0.632)],
    );

    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.diagnostics.single.suppressed, isTrue);
  });

  test('PASS 345 rejects 0.960 candidate with weak marker evidence', () {
    final result = engine.verify(
      topBytes: _blankGrid(rows: 5),
      bottomBytes: _blankGrid(rows: 4),
      samples: [_sample(0.960)],
      templateDiagnostics: [_template(0.628)],
    );

    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.diagnostics.single.suppressed, isTrue);
  });

  test(
    'PASS 345 accepts sub-0.98 candidate with strong corroborated markers',
    () {
      final top = _gridWithMarkers(rows: 5, book: true, tick: true);

      final result = engine.verify(
        topBytes: top,
        bottomBytes: _blankGrid(rows: 4),
        samples: [_sample(0.972)],
        templateDiagnostics: [_template(0.576)],
      );

      expect(result.samples.single.occupancyScore, 0.972);
      expect(
        result.diagnostics.single.markerEvidence,
        greaterThanOrEqualTo(0.70),
      );
      expect(result.diagnostics.single.suppressed, isFalse);
    },
  );

  test(
    'PASS 345 keeps high-confidence candidate despite asymmetric marker crop',
    () {
      final top = _gridWithMarkers(
        rows: 5,
        book: false,
        tick: true,
        tickThickness: 2,
      );

      final result = engine.verify(
        topBytes: top,
        bottomBytes: _blankGrid(rows: 4),
        samples: [_sample(0.997)],
        templateDiagnostics: [_template(0.811)],
      );

      expect(result.samples.single.occupancyScore, 0.997);
      expect(result.diagnostics.single.suppressed, isFalse);
    },
  );

  test('PASS 345 preserves reliable strong book-only drift fallback', () {
    final top = _gridWithMarkers(
      rows: 5,
      book: true,
      tick: false,
      bookWidth: 20,
    );

    final result = engine.verify(
      topBytes: top,
      bottomBytes: _blankGrid(rows: 4),
      samples: [_sample(0.970)],
      templateDiagnostics: [_template(0.600)],
    );

    expect(
      result.diagnostics.single.bookMarkerEvidence,
      greaterThanOrEqualTo(0.68),
    );
    expect(result.samples.single.occupancyScore, 0.970);
    expect(result.diagnostics.single.suppressed, isFalse);
  });

  test('PASS 345 never promotes evidence below the owned threshold', () {
    final top = _gridWithMarkers(rows: 5, book: true, tick: true);

    final result = engine.verify(
      topBytes: top,
      bottomBytes: _blankGrid(rows: 4),
      samples: [_sample(0.50)],
      templateDiagnostics: [_template(0.90)],
    );

    expect(result.samples.single.occupancyScore, 0.50);
    expect(result.diagnostics.single.suppressed, isFalse);
  });
}
