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

void main() {
  test('0.995 whole-cell score without ownership evidence is suppressed', () {
    const engine = ArcBlueprintOwnershipMarkerVerificationEngine();

    final result = engine.verify(
      topBytes: _blankGrid(rows: 5),
      bottomBytes: _blankGrid(rows: 4),
      samples: const [
        ArcBlueprintPhotoOccupancySample(
          captureId: 'top',
          rowIndex: 0,
          columnIndex: 0,
          occupancyScore: 0.995,
        ),
      ],
      templateDiagnostics: const [
        ArcBlueprintTemplateVerificationSample(
          blueprintId: 'expected',
          blueprintName: 'Expected',
          canonicalIndex: 0,
          rowIndex: 0,
          columnIndex: 0,
          captureId: 'top',
          templateSimilarity: 0.600,
          multiSignalEvidence: 0.995,
          finalScore: 0.995,
          templateAvailable: true,
          suppressed: false,
        ),
      ],
    );

    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.diagnostics.single.suppressed, isTrue);
  });
}
