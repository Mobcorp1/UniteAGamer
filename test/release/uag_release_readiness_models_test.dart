import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/release/models/uag_release_readiness_models.dart';

void main() {
  group('UagReleaseReadinessSnapshot', () {
    test('merges remote checks over safe defaults', () {
      final snapshot = UagReleaseReadinessSnapshot.fromMap({
        'checks': [
          {
            'id': 'legal_review',
            'label': 'Independent UK legal review',
            'state': 'deferred',
            'owner': 'MobCorp Limited',
            'detail': 'Professional review is planned after revenue begins.',
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
      expect(snapshot.deferredCount, greaterThanOrEqualTo(1));
      expect(snapshot.canCallClosedBetaReady, isTrue);
    });

    test('operator details are no longer a default release blocker', () {
      final snapshot = UagReleaseReadinessSnapshot.fromMap({});

      expect(snapshot.blockerCount, 0);
      expect(snapshot.canCallClosedBetaReady, isTrue);
      expect(
        snapshot.checks
            .firstWhere((check) => check.id == 'legal_operator')
            .state,
        UagReleaseReadinessState.ready,
      );
      expect(
        snapshot.checks.firstWhere((check) => check.id == 'java_21').state,
        UagReleaseReadinessState.deferred,
      );
      expect(
        snapshot.checks
            .firstWhere((check) => check.id == 'google_play_billing')
            .state,
        UagReleaseReadinessState.configurationRequired,
      );
      expect(
        snapshot.checks
            .firstWhere((check) => check.id == 'legal_self_audit')
            .state,
        UagReleaseReadinessState.ready,
      );
      expect(
        snapshot.checks
            .firstWhere((check) => check.id == 'account_deletion')
            .state,
        UagReleaseReadinessState.configurationRequired,
      );
      expect(
        snapshot.checks.firstWhere((check) => check.id == 'legal_review').state,
        UagReleaseReadinessState.deferred,
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
      expect(
        UagReleaseReadinessStateX.fromWire('deferred'),
        UagReleaseReadinessState.deferred,
      );
    });
  });
}
