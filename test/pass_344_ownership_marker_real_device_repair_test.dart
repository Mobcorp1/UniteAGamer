import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_ownership_marker_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';

Uint8List grid({required bool shiftedMarkers, required bool bookOnly}) {
  final image = img.Image(width: 1000, height: 500);
  img.fill(image, color: img.ColorRgb8(14, 18, 38));
  if (shiftedMarkers) {
    // Marker is shifted left of PASS 343's fixed lower-left ROI.
    img.fillRect(
      image,
      x1: 2,
      y1: 370,
      x2: 9,
      y2: 388,
      color: img.ColorRgb8(245, 245, 245),
    );
    img.fillRect(
      image,
      x1: 10,
      y1: 372,
      x2: 16,
      y2: 388,
      color: img.ColorRgb8(230, 235, 240),
    );
    img.drawLine(
      image,
      x1: 66,
      y1: 420,
      x2: 73,
      y2: 427,
      color: img.ColorRgb8(250, 250, 250),
      thickness: 3,
    );
    img.drawLine(
      image,
      x1: 73,
      y1: 427,
      x2: 84,
      y2: 412,
      color: img.ColorRgb8(250, 250, 250),
      thickness: 3,
    );
  }
  if (bookOnly) {
    // Deliberately medium-strength book-like patch with no completion tick,
    // modelling the G6 Surge Coil false positive from the device trace.
    // Keep this deliberately small: the real G6 Surge Coil trace measured
    // book=0.529, tick=0.000. The previous fixture filled too much of the ROI
    // and accidentally measured ~0.945, which represents strong/reliable
    // book evidence rather than the medium false-positive case being tested.
    img.fillRect(
      image,
      x1: 8,
      y1: 370,
      x2: 11,
      y2: 376,
      color: img.ColorRgb8(205, 205, 205),
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

ArcBlueprintTemplateVerificationSample template(double similarity) =>
    ArcBlueprintTemplateVerificationSample(
      blueprintId: 'bp',
      blueprintName: 'Expected',
      canonicalIndex: 30,
      rowIndex: 3,
      columnIndex: 0,
      captureId: 'top',
      templateSimilarity: similarity,
      multiSignalEvidence: 0.97,
      finalScore: 0.97,
      templateAvailable: true,
      suppressed: false,
    );

const sample = ArcBlueprintPhotoOccupancySample(
  captureId: 'top',
  rowIndex: 3,
  columnIndex: 0,
  occupancyScore: 0.97,
);

void main() {
  test('shifted ownership glyphs survive residual capture drift', () {
    final result = const ArcBlueprintOwnershipMarkerVerificationEngine().verify(
      topBytes: grid(shiftedMarkers: true, bookOnly: false),
      bottomBytes: grid(shiftedMarkers: false, bookOnly: false),
      samples: const [sample],
      templateDiagnostics: [template(0.60)],
    );
    expect(result.samples.single.occupancyScore, 0.97);
    expect(result.diagnostics.single.suppressed, isFalse);
  });

  test('medium book-only evidence cannot override a missing tick', () {
    final result = const ArcBlueprintOwnershipMarkerVerificationEngine().verify(
      topBytes: grid(shiftedMarkers: false, bookOnly: true),
      bottomBytes: grid(shiftedMarkers: false, bookOnly: false),
      samples: const [sample],
      templateDiagnostics: [template(0.60)],
    );
    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.diagnostics.single.suppressed, isTrue);
  });
}
