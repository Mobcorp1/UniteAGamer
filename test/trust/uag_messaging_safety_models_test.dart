import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/uag_messaging_safety_models.dart';

void main() {
  group('UagMessageModerationEngine', () {
    const engine = UagMessageModerationEngine();

    test('allows ordinary trading messages', () {
      final decision = engine.classify(
        'Can trade after 7pm? I have the blueprint.',
      );

      expect(decision.state, UagModerationState.allowed);
      expect(decision.canDeliver, isTrue);
    });

    test('warns for private contact details and payment requests', () {
      final decision = engine.classify(
        'PayPal me and use my phone 07123456789.',
      );

      expect(decision.state, UagModerationState.warned);
      expect(decision.action, UagModerationAction.warnAndAllowEdit);
      expect(decision.triggeredRules, contains('off_platform_payment_request'));
    });

    test('quarantines phishing and blocked domains', () {
      final decision = engine.classify(
        'Go to https://bit.ly/test and send your 2FA login code.',
      );

      expect(decision.state, UagModerationState.quarantined);
      expect(decision.needsQueue, isTrue);
      expect(decision.triggeredRules, contains('credential_phishing'));
    });

    test('blocks severe abuse for human review', () {
      final decision = engine.classify('I will kill you.');

      expect(decision.state, UagModerationState.blocked);
      expect(decision.action, UagModerationAction.blockAndEscalate);
      expect(decision.needsQueue, isTrue);
    });
  });

  group('UagUserBlock', () {
    test('creates deterministic block IDs', () {
      expect(UagUserBlock.idFor('user-a', 'user-b'), 'user-a_user-b');
    });
  });

  group('UagModerationStateX', () {
    test('parses release candidate backend wire states', () {
      expect(
        UagModerationStateX.fromWire('warning_required'),
        UagModerationState.warningRequired,
      );
      expect(
        UagModerationStateX.fromWire('provider_unavailable'),
        UagModerationState.providerUnavailable,
      );
      expect(
        UagModerationStateX.fromWire('manually_reviewed'),
        UagModerationState.manuallyReviewed,
      );
    });
  });
}
