import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_match_compatibility_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_session_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';

void main() {
  test('Trials is available for session intent and priority', () {
    expect(ArcPlayerSessionCatalog.sessionIntents, contains('Trials'));
    expect(ArcPlayerSessionCatalog.priorities, contains('Trials'));
    expect(ArcPlayerSessionCatalog.normalizeIntent('trial'), 'Trials');
    expect(ArcPlayerSessionCatalog.normalizePriority('trial runs'), 'Trials');
  });

  test('matching Trials intent and priority improves compatibility', () {
    final base = ArcMatchRiderProfile.empty('me').copyWith(
      goals: const <String>['Trials'],
      sessionIntent: 'Trials',
      currentPriority: 'Trials',
    );
    final matching = ArcMatchRiderProfile.empty('other').copyWith(
      goals: const <String>['Trials'],
      sessionIntent: 'Trials',
      currentPriority: 'Trials',
    );
    final flexible = ArcMatchRiderProfile.empty('other-2');

    const engine = ArcMatchCompatibilityEngine();
    final matchingResult = engine.score(me: base, other: matching);
    final flexibleResult = engine.score(me: base, other: flexible);

    expect(matchingResult.score, greaterThan(flexibleResult.score));
    expect(matchingResult.reasons, contains('Same session intent: Trials'));
    expect(matchingResult.reasons, contains('Same priority: Trials'));
  });
}
