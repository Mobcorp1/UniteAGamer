import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_capture_draft.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_photo_capture_session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ArcBlueprintPhotoCaptureSessionRepository.instance.clear();
  });

  test('dual capture stores independent top and bottom snapshots', () async {
    final top = Uint8List.fromList([1, 2, 3]);
    final bottom = Uint8List.fromList([7, 8, 9]);

    await ArcBlueprintPhotoCaptureSessionRepository.instance.saveDualCapture(
      topBytes: top,
      bottomBytes: bottom,
      topFileName: 'top.jpg',
      bottomFileName: 'bottom.jpg',
    );

    top[0] = 99;
    bottom[0] = 88;

    final draft = ArcBlueprintPhotoCaptureSessionRepository.instance.current;
    expect(draft.topImageBytes, [1, 2, 3]);
    expect(draft.bottomImageBytes, [7, 8, 9]);
    expect(draft.topFileName, 'top.jpg');
    expect(draft.bottomFileName, 'bottom.jpg');
    expect(draft.isComplete, isTrue);
  });

  test('saving bottom section does not replace existing top section', () async {
    final repository = ArcBlueprintPhotoCaptureSessionRepository.instance;
    await repository.saveSection(
      section: ArcBlueprintCaptureSection.top,
      bytes: Uint8List.fromList([1, 1]),
      fileName: 'top.jpg',
    );
    await repository.saveSection(
      section: ArcBlueprintCaptureSection.bottom,
      bytes: Uint8List.fromList([2, 2]),
      fileName: 'bottom.jpg',
    );

    final draft = repository.current;
    expect(draft.topImageBytes, [1, 1]);
    expect(draft.bottomImageBytes, [2, 2]);
  });
}
