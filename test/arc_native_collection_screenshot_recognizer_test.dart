import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';

Future<Uint8List> fixture(String name) => File('test/fixtures/$name').readAsBytes();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const recognizer = ArcNativeCollectionScreenshotRecognizer();

  test('Native PS5 Stencils screenshot gives 6 of 14 in exact positions', () async {
    final scan = recognizer.analyse(
      await fixture('stencils_ps5_native.jpg'), ArcNativeCollectionKind.stencils);
    expect(scan.slots.length, 14);
    expect(scan.count(ArcNativeSlotState.owned), 6);
    expect(scan.count(ArcNativeSlotState.missing), 8);
    expect(scan.count(ArcNativeSlotState.review), 0);
    expect(scan.slots.where((s) => s.state == ArcNativeSlotState.owned)
      .map((s) => s.slot).toList(), <int>[2, 3, 5, 6, 7, 9]);
  });

  test('Native PS5 Designs screenshot gives 50 of 100 in exact positions', () async {
    final scan = recognizer.analyse(
      await fixture('designs_ps5_native.jpg'), ArcNativeCollectionKind.designs);
    expect(scan.slots.length, 100);
    expect(scan.count(ArcNativeSlotState.owned), 50);
    expect(scan.count(ArcNativeSlotState.missing), 50);
    expect(scan.count(ArcNativeSlotState.review), 0);
    expect(scan.slots.where((s) => s.state == ArcNativeSlotState.owned)
      .map((s) => s.slot).toList(), <int>[
        1, 4, 5, 6, 9, 10, 13, 15, 16, 17, 19, 20, 21, 23, 25,
        28, 35, 36, 41, 42, 43, 45, 46, 50, 53, 56, 59, 62, 63, 64,
        65, 66, 70, 71, 74, 75, 76, 77, 80, 81, 82, 83, 85, 86,
        88, 89, 90, 92, 99, 100,
      ]);
  });

  test('native profile refuses a blank screen', () {
    final blank = img.Image(width: 2048, height: 1152);
    img.fill(blank, color: img.ColorRgb8(0, 0, 0));
    expect(() => recognizer.analyse(Uint8List.fromList(img.encodeJpg(blank)),
      ArcNativeCollectionKind.designs), throwsFormatException);
  });

  test('native profile refuses rotated/cropped photo aspect', () {
    final blank = img.Image(width: 1440, height: 1080);
    expect(() => recognizer.analyse(Uint8List.fromList(img.encodeJpg(blank)),
      ArcNativeCollectionKind.stencils), throwsFormatException);
  });

  test('owned slot decoding ignores wrong collection ranges', () {
    expect(ArcCollectionSlotRepository.decodeOwned(<dynamic>[1, 6, 6, 15, -1, '7'],
      ArcNativeCollectionKind.stencils), <int>{1, 6});
  });
}
