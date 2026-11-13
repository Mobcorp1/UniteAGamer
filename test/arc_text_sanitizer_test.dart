import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/arc_text_sanitizer.dart';

void main() {
  group('ArcTextSanitizer', () {
    test('normalises common mojibake sequences used in user-facing copy', () {
      String chars(List<int> codes) => String.fromCharCodes(codes);

      expect(
        ArcTextSanitizer.sanitize(chars([0x00C2, 0x00A3])),
        ArcTextSanitizer.pound,
      );
      expect(
        ArcTextSanitizer.sanitize(chars([0x00E2, 0x20AC, 0x00A2])),
        ArcTextSanitizer.bullet,
      );
      expect(ArcTextSanitizer.sanitize(chars([0x00E2, 0x20AC, 0x00A6])), '...');
      expect(ArcTextSanitizer.sanitize(chars([0x00E2, 0x20AC, 0x2122])), "'");
      expect(
        ArcTextSanitizer.sanitize(chars([0x00E2, 0x2020, 0x201D])),
        ArcTextSanitizer.arrowBoth,
      );
      expect(
        ArcTextSanitizer.sanitize(chars([0x00E2, 0x0153, 0x201C])),
        ArcTextSanitizer.check,
      );
      expect(
        ArcTextSanitizer.sanitize(chars([0x00C3, 0x2014])),
        ArcTextSanitizer.multiplication,
      );
    });

    test(
      'metadata lines skip empty values and use the canonical separator',
      () {
        expect(
          ArcTextSanitizer.metadataLine(['Raid', ' ', null, 'Ready']),
          'Raid${ArcTextSanitizer.separator()}Ready',
        );
      },
    );
  });
}
