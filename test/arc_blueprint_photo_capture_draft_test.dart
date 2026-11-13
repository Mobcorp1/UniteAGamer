import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_capture_draft.dart';

void main() {
  test('capture draft requires top and bottom images', () {
    final top = Uint8List.fromList(const [1, 2, 3]);
    final bottom = Uint8List.fromList(const [4, 5, 6]);
    final topOnly = ArcBlueprintPhotoCaptureDraft().copyWith(
      topImageBytes: top,
      topFileName: 'top.png',
    );
    expect(topOnly.hasTop, isTrue);
    expect(topOnly.hasBottom, isFalse);
    expect(topOnly.isComplete, isFalse);
    expect(topOnly.completedSections, 1);

    final complete = topOnly.copyWith(
      bottomImageBytes: bottom,
      bottomFileName: 'bottom.png',
    );
    expect(complete.isComplete, isTrue);
    expect(complete.completedSections, 2);
  });

  test('clearing one section preserves the other', () {
    final bytes = Uint8List.fromList(const [1]);
    final draft = ArcBlueprintPhotoCaptureDraft(
      topImageBytes: bytes,
      bottomImageBytes: bytes,
      topFileName: 'top.png',
      bottomFileName: 'bottom.png',
    );
    final cleared = draft.copyWith(clearBottom: true);
    expect(cleared.hasTop, isTrue);
    expect(cleared.hasBottom, isFalse);
    expect(cleared.bottomFileName, isEmpty);
  });
}
