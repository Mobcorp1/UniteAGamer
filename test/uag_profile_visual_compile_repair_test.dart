import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V2 out-of-scope title regression is removed', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('UagProfileGlyphKind.fromLabel(title)')));
    expect(
      source,
      contains('final tileWidth = (constraints.maxWidth - gap) / 2'),
    );
    expect(source, contains('UagProfileGlyph('));
  });
}
