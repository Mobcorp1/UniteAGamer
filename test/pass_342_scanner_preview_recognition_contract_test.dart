import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capture preview and recognition use the same stored section bytes', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(source, contains('final bottomBytes = _draft.bottomImageBytes;'));
    expect(source, contains('final bytes = _bytesFor(_activeSection);'));
    expect(source, contains('Image.memory(bytes, fit: BoxFit.cover)'));
    expect(source, contains('bytes: bottomBytes'));
    expect(source, isNot(contains('previewBottomBytes')));
    expect(source, isNot(contains('recognitionBottomBytes')));
  });
}
