import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_ownership_marker_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';

Uint8List _grid({
  required int rows,
  required bool markers,
  bool blueNoise = false,
}) {
  final image = img.Image(width: 1000, height: rows * 100);
  img.fill(image, color: img.ColorRgb8(14, 18, 38));

  if (blueNoise) {
    img.fillRect(
      image,
      x1: 8,
      y1: 8,
      x2: 91,
      y2: 91,
      color: img.ColorRgb8(20, 74, 170),
    );
    for (var x = 15; x < 90; x += 12) {
      img.drawLine(
        image,
        x1: x,
        y1: 10,
        x2: x,
        y2: 90,
        color: img.ColorRgb8(76, 112, 214),
      );
    }
  }

  if (markers) {
    // Synthetic lower-left book-like white glyph.
    img.fillRect(
      image,
      x1: 9,
      y1: 74,
      x2: 18,
      y2: 88,
      color: img.ColorRgb8(245, 245, 245),
    );
    img.fillRect(
      image,
      x1: 19,
      y1: 76,
      x2: 27,
      y2: 88,
      color: img.ColorRgb8(225, 230, 238),
    );

    // Synthetic upper-right tick-like white glyph.
    img.drawLine(
      image,
      x1: 75,
      y1: 20,
      x2: 81,
      y2: 26,
      color: img.ColorRgb8(248, 248, 248),
      thickness: 3,
    );
    img.drawLine(
      image,
      x1: 81,
      y1: 26,
      x2: 91,
      y2: 12,
      color: img.ColorRgb8(248, 248, 248),
      thickness: 3,
    );
  }

  return Uint8List.fromList(img.encodePng(image));
}

ArcBlueprintTemplateVerificationSample _template({
  required double similarity,
}) => ArcBlueprintTemplateVerificationSample(
  blueprintId: 'bp',
  blueprintName: 'Expected Blueprint',
  canonicalIndex: 0,
  rowIndex: 0,
  columnIndex: 0,
  captureId: 'top',
  templateSimilarity: similarity,
  multiSignalEvidence: 0.97,
  finalScore: 0.97,
  templateAvailable: true,
  suppressed: false,
);

const _strongSample = ArcBlueprintPhotoOccupancySample(
  captureId: 'top',
  rowIndex: 0,
  columnIndex: 0,
  occupancyScore: 0.97,
);

void main() {
  test('owned UI markers preserve a strong candidate', () {
    final result = const ArcBlueprintOwnershipMarkerVerificationEngine().verify(
      topBytes: _grid(rows: 5, markers: true, blueNoise: true),
      bottomBytes: _grid(rows: 4, markers: false),
      samples: const [_strongSample],
      templateDiagnostics: [_template(similarity: 0.58)],
    );

    expect(result.samples.single.occupancyScore, 0.97);
    expect(result.suppressedCandidateCount, 0);
    expect(result.diagnostics.single.bookMarkerEvidence, greaterThan(0.22));
    expect(result.diagnostics.single.tickMarkerEvidence, greaterThan(0.18));
    expect(result.diagnostics.single.suppressed, isFalse);
  });

  test('blue card-like background without owned markers is suppressed', () {
    final result = const ArcBlueprintOwnershipMarkerVerificationEngine().verify(
      topBytes: _grid(rows: 5, markers: false, blueNoise: true),
      bottomBytes: _grid(rows: 4, markers: false),
      samples: const [_strongSample],
      templateDiagnostics: [_template(similarity: 0.59)],
    );

    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.suppressedCandidateCount, 1);
    expect(result.diagnostics.single.markerEvidence, lessThan(0.20));
    expect(result.diagnostics.single.suppressed, isTrue);
  });

  test('marker verifier never promotes weak evidence', () {
    const weak = ArcBlueprintPhotoOccupancySample(
      captureId: 'top',
      rowIndex: 0,
      columnIndex: 0,
      occupancyScore: 0.41,
    );

    final result = const ArcBlueprintOwnershipMarkerVerificationEngine().verify(
      topBytes: _grid(rows: 5, markers: true),
      bottomBytes: _grid(rows: 4, markers: false),
      samples: const [weak],
      templateDiagnostics: [_template(similarity: 0.90)],
    );

    expect(result.samples.single.occupancyScore, 0.41);
    expect(result.suppressedCandidateCount, 0);
  });

  test(
    'exceptionally strong artwork match protects a marker-obscured card',
    () {
      final result = const ArcBlueprintOwnershipMarkerVerificationEngine()
          .verify(
            topBytes: _grid(rows: 5, markers: false, blueNoise: true),
            bottomBytes: _grid(rows: 4, markers: false),
            samples: const [_strongSample],
            templateDiagnostics: [_template(similarity: 0.86)],
          );

      expect(result.samples.single.occupancyScore, 0.97);
      expect(result.suppressedCandidateCount, 0);
    },
  );
}
