import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/utils/web_version_info.dart';

void main() {
  group('Web version metadata', () {
    test('builds a version payload with a non-empty build id', () {
      final metadata = WebVersionMetadata(
        buildId: 'abc123',
        builtAt: '2026-07-24T00:00:00.000Z',
        branch: 'beta-stabilisation',
      );

      final payload = metadata.toJson();

      expect(payload['buildId'], 'abc123');
      expect(payload['builtAt'], '2026-07-24T00:00:00.000Z');
      expect(payload['branch'], 'beta-stabilisation');
      expect(payload['buildId'], isNotEmpty);
    });

    test('falls back to a generated build id when input is missing', () {
      final metadata = WebVersionMetadata.fromInputs(
        buildId: '',
        builtAt: '',
        branch: '',
      );

      expect(metadata.buildId, isNotEmpty);
      expect(metadata.builtAt, isNotEmpty);
      expect(metadata.branch, isNotEmpty);
    });
  });
}
