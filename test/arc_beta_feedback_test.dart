import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_beta_feedback.dart';

void main() {
  test('beta feedback submission includes diagnostic and workflow fields', () {
    const submission = ArcBetaFeedbackSubmission(
      uid: 'user-1',
      category: ArcBetaFeedbackCategory.trade,
      severity: ArcBetaFeedbackSeverity.high,
      reproducibility: ArcBetaFeedbackReproducibility.always,
      description: 'Trade chain card does not open.',
      expectedOutcome: 'Open the trade chain detail.',
      currentRoute: '/command-centre',
      platform: 'android',
      screenWidth: 412,
      screenHeight: 915,
      locale: 'en-GB',
    );

    final map = submission.toFirestore();

    expect(map['uid'], 'user-1');
    expect(map['category'], 'trade');
    expect(map['severity'], 'high');
    expect(map['reproducibility'], 'always');
    expect(map['currentRoute'], '/command-centre');
    expect(map['platform'], 'android');
    expect(map['status'], 'new');
    expect(map['createdAt'], isNotNull);
  });
}
