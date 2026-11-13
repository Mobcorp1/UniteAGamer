import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_owned_cell_structure_verifier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';

Uint8List _grid({
  int rowIndex = 0,
  required bool bluePanel,
  required bool darkFooter,
  required bool book,
  required bool tick,
  bool lowContrast = false,
}) {
  final image = img.Image(width: 1000, height: 500);
  img.fill(image, color: img.ColorRgb8(8, 15, 32));

  final y0 = rowIndex * 100;

  if (bluePanel) {
    final body = lowContrast
        ? const <int>[8, 48, 90]
        : const <int>[24, 78, 196];
    for (var y = y0 + 8; y < y0 + 73; y++) {
      for (var x = 8; x < 92; x++) {
        image.setPixelRgb(x, y, body[0], body[1], body[2]);
      }
    }

    if (!lowContrast) {
      for (final x in <int>[25, 45, 65, 85]) {
        for (var y = y0 + 10; y < y0 + 72; y++) {
          image.setPixelRgb(x, y, 116, 182, 245);
        }
      }
      for (final localY in <int>[24, 42, 60]) {
        for (var x = 10; x < 91; x++) {
          image.setPixelRgb(x, y0 + localY, 116, 182, 245);
        }
      }
    }
  }

  if (darkFooter) {
    final footer = lowContrast
        ? const <int>[24, 28, 34]
        : const <int>[4, 6, 12];
    for (var y = y0 + 77; y < y0 + 95; y++) {
      for (var x = 8; x < 92; x++) {
        image.setPixelRgb(x, y, footer[0], footer[1], footer[2]);
      }
    }
  } else {
    // Explicitly bright footer so "darkFooter=false" cannot accidentally pass
    // just because the blank test image itself is dark.
    for (var y = y0 + 77; y < y0 + 95; y++) {
      for (var x = 8; x < 92; x++) {
        image.setPixelRgb(x, y, 40, 100, 180);
      }
    }
  }

  if (book) {
    for (var y = y0 + 80; y < y0 + 92; y++) {
      for (var x = 10; x < 27; x++) {
        if (x != 18) image.setPixelRgb(x, y, 242, 244, 238);
      }
    }
  }

  if (tick) {
    for (var i = 0; i < 11; i++) {
      final x = 72 + i;
      final y = y0 + 19 + (i ~/ 2);
      image.setPixelRgb(x, y, 245, 245, 242);
      if (x + 1 < 95) image.setPixelRgb(x + 1, y, 245, 245, 242);
    }
    for (var i = 0; i < 13; i++) {
      final x = 81 + i;
      final y = y0 + 24 - (i ~/ 2);
      if (x < 95 && y >= y0 + 5) {
        image.setPixelRgb(x, y, 245, 245, 242);
        image.setPixelRgb(x, y + 1, 245, 245, 242);
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _blankBottom() =>
    Uint8List.fromList(img.encodePng(img.Image(width: 1000, height: 400)));

ArcBlueprintTemplateVerificationSample _diagnostic({
  required int canonicalIndex,
  required int rowIndex,
  required double artworkSimilarity,
  required double rawEvidence,
}) {
  return ArcBlueprintTemplateVerificationSample(
    blueprintId: 'expected-$canonicalIndex',
    blueprintName: 'Expected $canonicalIndex',
    canonicalIndex: canonicalIndex,
    rowIndex: rowIndex,
    columnIndex: 0,
    captureId: 'top',
    templateSimilarity: artworkSimilarity,
    multiSignalEvidence: rawEvidence,
    finalScore: rawEvidence,
    templateAvailable: true,
    suppressed: false,
  );
}

ArcBlueprintOwnedCellStructureResult _verifyTop({
  required Uint8List top,
  double artworkSimilarity = 0.70,
  double sampleEvidence = 0.30,
  double rawEvidence = 0.30,
}) {
  const verifier = ArcBlueprintOwnedCellStructureVerifier();
  return verifier.verify(
    topBytes: top,
    bottomBytes: _blankBottom(),
    samples: [
      ArcBlueprintPhotoOccupancySample(
        captureId: 'top',
        rowIndex: 0,
        columnIndex: 0,
        occupancyScore: sampleEvidence,
      ),
    ],
    templateDiagnostics: [
      _diagnostic(
        canonicalIndex: 0,
        rowIndex: 0,
        artworkSimilarity: artworkSimilarity,
        rawEvidence: rawEvidence,
      ),
    ],
  );
}

void main() {
  test('all six signals own without any combined confidence threshold', () {
    final result = _verifyTop(
      top: _grid(bluePanel: true, darkFooter: true, book: true, tick: true),
      // Deliberately well below the old 0.70 proposal floor.
      sampleEvidence: 0.30,
      rawEvidence: 0.30,
    );

    expect(result.diagnostics.single.classification, 'owned');
    expect(result.samples.single.occupancyScore, greaterThanOrEqualTo(0.84));
  });

  test('missing blue panel blocks automatic ownership', () {
    final result = _verifyTop(
      top: _grid(bluePanel: false, darkFooter: true, book: true, tick: true),
    );

    expect(result.diagnostics.single.classification, isNot('owned'));
  });

  test('missing dark footer blocks automatic ownership', () {
    final result = _verifyTop(
      top: _grid(bluePanel: true, darkFooter: false, book: true, tick: true),
    );

    expect(result.diagnostics.single.classification, isNot('owned'));
  });

  test('missing footer contrast blocks automatic ownership', () {
    final result = _verifyTop(
      top: _grid(
        bluePanel: true,
        darkFooter: true,
        book: true,
        tick: true,
        lowContrast: true,
      ),
    );

    expect(result.diagnostics.single.footerDarkCoverage, greaterThan(0.48));
    expect(result.diagnostics.single.footerContrast, lessThan(0.08));
    expect(result.diagnostics.single.classification, isNot('owned'));
  });

  test('missing book blocks automatic ownership', () {
    final result = _verifyTop(
      top: _grid(bluePanel: true, darkFooter: true, book: false, tick: true),
      // Real Tagging Grenade false-positive artwork score was 0.615.
      artworkSimilarity: 0.615,
      sampleEvidence: 0.998,
      rawEvidence: 0.998,
    );

    expect(result.diagnostics.single.bookShapeEvidence, lessThan(0.18));
    expect(result.diagnostics.single.classification, isNot('owned'));
  });

  test('missing tick blocks automatic ownership', () {
    final result = _verifyTop(
      top: _grid(bluePanel: true, darkFooter: true, book: true, tick: false),
      sampleEvidence: 0.998,
      rawEvidence: 0.998,
    );

    expect(result.diagnostics.single.tickShapeEvidence, lessThan(0.18));
    expect(result.diagnostics.single.classification, isNot('owned'));
  });

  test('weak artwork match blocks automatic ownership', () {
    final result = _verifyTop(
      top: _grid(bluePanel: true, darkFooter: true, book: true, tick: true),
      // Latest false-positive row-5 cluster was roughly 0.477-0.518.
      artworkSimilarity: 0.518,
      sampleEvidence: 0.998,
      rawEvidence: 0.998,
    );

    expect(result.diagnostics.single.classification, isNot('owned'));
  });

  test('overlap cannot stitch five-of-six signals across two photos', () {
    const verifier = ArcBlueprintOwnedCellStructureVerifier();

    final result = verifier.verify(
      // Top view has the book but no tick.
      topBytes: _grid(
        rowIndex: 4,
        bluePanel: true,
        darkFooter: true,
        book: true,
        tick: false,
      ),
      bottomBytes: _blankBottom(),
      // Bottom overlap has the tick but no book.
      bottomFiveRowBytes: _grid(
        rowIndex: 0,
        bluePanel: true,
        darkFooter: true,
        book: false,
        tick: true,
      ),
      samples: const [
        ArcBlueprintPhotoOccupancySample(
          captureId: 'top',
          rowIndex: 4,
          columnIndex: 0,
          occupancyScore: 0.998,
        ),
      ],
      templateDiagnostics: [
        _diagnostic(
          canonicalIndex: 40,
          rowIndex: 4,
          artworkSimilarity: 0.70,
          rawEvidence: 0.998,
        ),
      ],
    );

    expect(result.diagnostics.single.classification, isNot('owned'));
    expect(result.samples.single.occupancyScore, lessThan(0.84));
  });

  test('one independently complete overlap photo can prove row five', () {
    const verifier = ArcBlueprintOwnedCellStructureVerifier();

    final result = verifier.verify(
      // Top copy is poor.
      topBytes: _grid(
        rowIndex: 4,
        bluePanel: true,
        darkFooter: true,
        book: true,
        tick: false,
      ),
      bottomBytes: _blankBottom(),
      // The bottom overlap independently contains all six signals.
      bottomFiveRowBytes: _grid(
        rowIndex: 0,
        bluePanel: true,
        darkFooter: true,
        book: true,
        tick: true,
      ),
      samples: const [
        ArcBlueprintPhotoOccupancySample(
          captureId: 'top',
          rowIndex: 4,
          columnIndex: 0,
          occupancyScore: 0.60,
        ),
      ],
      templateDiagnostics: [
        _diagnostic(
          canonicalIndex: 40,
          rowIndex: 4,
          artworkSimilarity: 0.70,
          rawEvidence: 0.60,
        ),
      ],
    );

    expect(result.diagnostics.single.overlapCorroborated, isTrue);
    expect(result.diagnostics.single.classification, 'owned');
    expect(result.samples.single.occupancyScore, greaterThanOrEqualTo(0.84));
  });
}
