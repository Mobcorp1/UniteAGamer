import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('custom Profile glyph source is analyzer clean by contract', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/foundation/uag_profile_glyph.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('MathCos')));
    expect(source, isNot(contains('MathSin')));
    expect(source, contains('_axisCos'));
    expect(source, contains('_axisSin'));
    expect(
      source,
      contains('class _UagProfileGlyphPainter extends CustomPainter'),
    );
  });
}
