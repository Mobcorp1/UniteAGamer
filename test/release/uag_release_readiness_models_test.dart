import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/release/models/uag_release_readiness_models.dart';

void main() {
  group('UagReleaseReadinessSnapshot', () {
    test('merges remote checks over safe defaults', () {
      final snapshot = UagReleaseReadinessSnapshot.fromMap({
        'checks': [
          {
            'id': 'legal_operator',
            'label': 'Operator and legal details',
            'state': 'configuration_required',
            'owner': 'Mike/legal',
            'detail': 'Operator details supplied but solicitor review remains.',
          },
          {
            'id': 'web_build',
            'label': 'Web build',
            'state': 'ready',
            'owner': 'Codex',
            'detail': 'Release build completed.',
          },
        ],
      });

      expect(snapshot.checks.any((check) => check.id == 'java_21'), isTrue);
      expect(snapshot.checks.any((check) => check.id == 'web_build'), isTrue);
      expect(snapshot.blockerCount, 0);
      expect(snapshot.configurationRequiredCount, greaterThanOrEqualTo(1));
      expect(snapshot.canCallClosedBetaReady, isTrue);
    });

    test('keeps default blocker when no operator/legal override exists', () {
      final snapshot = UagReleaseReadinessSnapshot.fromMap({});

      expect(snapshot.blockerCount, 1);
      expect(snapshot.canCallClosedBetaReady, isFalse);
      expect(
        snapshot.checks
            .firstWhere((check) => check.id == 'legal_operator')
            .state,
        UagReleaseReadinessState.blocked,
      );
    });
  });

  group('UagReleaseReadinessState', () {
    test('parses wire aliases', () {
      expect(
        UagReleaseReadinessStateX.fromWire('config_required'),
        UagReleaseReadinessState.configurationRequired,
      );
      expect(
        UagReleaseReadinessStateX.fromWire('manual_qa_required'),
        UagReleaseReadinessState.manualQaRequired,
      );
    });
  });
}
