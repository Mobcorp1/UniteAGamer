import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_owned_cell_structure_verifier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';

Uint8List buildGrid({required bool ownedFirstCell}) {
  final image = img.Image(width: 1000, height: 500);
  img.fill(image, color: img.ColorRgb8(8, 15, 32));

  // Common white/cyan cell borders. These must NOT count as owned markers.
  for (var row = 0; row < 5; row++) {
    for (var col = 0; col < 10; col++) {
      final x0 = col * 100 + 3;
      final y0 = row * 100 + 3;
      final x1 = col * 100 + 96;
      final y1 = row * 100 + 96;
      for (var x = x0; x <= x1; x++) {
        image.setPixelRgb(x, y0, 185, 220, 245);
        image.setPixelRgb(x, y1, 185, 220, 245);
      }
      for (var y = y0; y <= y1; y++) {
        image.setPixelRgb(x0, y, 185, 220, 245);
        image.setPixelRgb(x1, y, 185, 220, 245);
      }
    }
  }

  if (ownedFirstCell) {
    // Vivid blue/purple art panel.
    for (var y = 8; y < 73; y++) {
      for (var x = 8; x < 92; x++) {
        image.setPixelRgb(x, y, 24, 78, 196);
      }
    }

    // Pale Blueprint grid inside the art panel.
    for (final x in <int>[25, 45, 65, 85]) {
      for (var y = 10; y < 72; y++) {
        image.setPixelRgb(x, y, 116, 182, 245);
      }
    }
    for (final y in <int>[24, 42, 60]) {
      for (var x = 10; x < 91; x++) {
        image.setPixelRgb(x, y, 116, 182, 245);
      }
    }

    // Black footer strip.
    for (var y = 77; y < 95; y++) {
      for (var x = 8; x < 92; x++) {
        image.setPixelRgb(x, y, 4, 6, 12);
      }
    }

    // Book-shaped white block in lower-left footer.
    for (var y = 80; y < 92; y++) {
      for (var x = 10; x < 27; x++) {
        if (x != 18) image.setPixelRgb(x, y, 242, 244, 238);
      }
    }

    // Tick-shaped white marker in upper-right.
    for (var i = 0; i < 11; i++) {
      final x = 72 + i;
      final y = 19 + (i ~/ 2);
      image.setPixelRgb(x, y, 245, 245, 242);
      if (x + 1 < 95) image.setPixelRgb(x + 1, y, 245, 245, 242);
    }
    for (var i = 0; i < 13; i++) {
      final x = 81 + i;
      final y = 24 - (i ~/ 2);
      if (x < 95 && y >= 5) {
        image.setPixelRgb(x, y, 245, 245, 242);
        image.setPixelRgb(x, y + 1, 245, 245, 242);
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

const candidate = ArcBlueprintPhotoOccupancySample(
  captureId: 'top',
  rowIndex: 0,
  columnIndex: 0,
  occupancyScore: 0.97,
);

const diagnostic = ArcBlueprintTemplateVerificationSample(
  blueprintId: 'expected',
  blueprintName: 'Expected',
  canonicalIndex: 0,
  rowIndex: 0,
  columnIndex: 0,
  captureId: 'top',
  templateSimilarity: 0.60,
  multiSignalEvidence: 0.97,
  finalScore: 0.97,
  templateAvailable: true,
  suppressed: false,
);

void main() {
  test('empty bordered cell cannot pass as owned', () {
    const verifier = ArcBlueprintOwnedCellStructureVerifier();

    final result = verifier.verify(
      topBytes: buildGrid(ownedFirstCell: false),
      bottomBytes: Uint8List.fromList(
        img.encodePng(img.Image(width: 1000, height: 400)),
      ),
      samples: const [candidate],
      templateDiagnostics: const [diagnostic],
    );

    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.diagnostics.single.suppressed, isTrue);
  });

  test('real owned-card structure survives', () {
    const verifier = ArcBlueprintOwnedCellStructureVerifier();

    final result = verifier.verify(
      topBytes: buildGrid(ownedFirstCell: true),
      bottomBytes: Uint8List.fromList(
        img.encodePng(img.Image(width: 1000, height: 400)),
      ),
      samples: const [candidate],
      templateDiagnostics: const [diagnostic],
    );

    expect(result.samples.single.occupancyScore, greaterThanOrEqualTo(0.84));
    expect(result.diagnostics.single.suppressed, isFalse);
  });
}
