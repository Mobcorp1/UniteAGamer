import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';

Future<Uint8List> _asset(String path) async {
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

Uint8List _gridWithCell(Uint8List art, {required int rows}) {
  final canvas = img.Image(width: 1000, height: rows * 100);
  img.fill(canvas, color: img.ColorRgb8(18, 20, 22));
  final decoded = img.decodeImage(art)!;
  final fitted = img.copyResize(decoded, width: 84, height: 84);
  img.compositeImage(canvas, fitted, dstX: 8, dstY: 8);
  return Uint8List.fromList(img.encodePng(canvas));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('matching expected artwork does not suppress strong evidence', () async {
    final blueprint = ArcBlueprintSeedData.blueprints.first;
    final art = await _asset(blueprint.imageAssetPath!);
    final top = _gridWithCell(art, rows: 5);
    final bottomCanvas = img.Image(width: 1000, height: 400);
    img.fill(bottomCanvas, color: img.ColorRgb8(18, 20, 22));

    final result = await const ArcBlueprintTemplateVerificationEngine().verify(
      topBytes: top,
      bottomBytes: Uint8List.fromList(img.encodePng(bottomCanvas)),
      samples: const <ArcBlueprintPhotoOccupancySample>[
        ArcBlueprintPhotoOccupancySample(
          captureId: 'top',
          rowIndex: 0,
          columnIndex: 0,
          occupancyScore: 0.91,
        ),
      ],
    );

    expect(result.samples.single.occupancyScore, greaterThanOrEqualTo(0.84));
    expect(result.diagnostics.single.blueprintId, blueprint.id);
    expect(result.diagnostics.single.templateAvailable, isTrue);
    expect(result.diagnostics.single.suppressed, isFalse);
  });

  test('wrong expected artwork can only suppress strong evidence', () async {
    final expected = ArcBlueprintSeedData.blueprints.first;
    final wrong = ArcBlueprintSeedData.blueprints[1];
    final art = await _asset(wrong.imageAssetPath!);
    final top = _gridWithCell(art, rows: 5);
    final bottomCanvas = img.Image(width: 1000, height: 400);
    img.fill(bottomCanvas, color: img.ColorRgb8(18, 20, 22));

    final result =
        await const ArcBlueprintTemplateVerificationEngine(
          minimumTemplateSimilarity: 0.99,
        ).verify(
          topBytes: top,
          bottomBytes: Uint8List.fromList(img.encodePng(bottomCanvas)),
          samples: const <ArcBlueprintPhotoOccupancySample>[
            ArcBlueprintPhotoOccupancySample(
              captureId: 'top',
              rowIndex: 0,
              columnIndex: 0,
              occupancyScore: 0.91,
            ),
          ],
        );

    expect(result.diagnostics.single.blueprintId, expected.id);
    expect(result.samples.single.occupancyScore, lessThan(0.84));
    expect(result.diagnostics.single.suppressed, isTrue);
  });

  test('template verifier never promotes weak visual evidence', () async {
    final blueprint = ArcBlueprintSeedData.blueprints.first;
    final art = await _asset(blueprint.imageAssetPath!);
    final top = _gridWithCell(art, rows: 5);
    final bottomCanvas = img.Image(width: 1000, height: 400);
    img.fill(bottomCanvas, color: img.ColorRgb8(18, 20, 22));

    final result = await const ArcBlueprintTemplateVerificationEngine().verify(
      topBytes: top,
      bottomBytes: Uint8List.fromList(img.encodePng(bottomCanvas)),
      samples: const <ArcBlueprintPhotoOccupancySample>[
        ArcBlueprintPhotoOccupancySample(
          captureId: 'top',
          rowIndex: 0,
          columnIndex: 0,
          occupancyScore: 0.30,
        ),
      ],
    );

    expect(result.samples.single.occupancyScore, 0.30);
  });
}
