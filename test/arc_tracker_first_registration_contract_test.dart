import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_onboarding_setup.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_cosmetic_identity.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';

void main() {
  test('tracker-first completion defers setup and leaves progression unknown', () {
    final record = buildArcOnboardingCompletionPayload(
      riderName: 'Raider123',
      primaryGoal: 'completeBlueprints',
      blueprintSetupMode: 'importScreenshots',
      recommendedFirstSystem: 'blueprintTracker',
      legalAccepted: const {'termsOfServiceAccepted': true, 'ageConfirmationAccepted': true},
      trackerFirst: true,
    );
    expect(record['arcMandatoryOnboardingComplete'], isTrue);
    final state = record['arcOnboarding'] as Map<String, dynamic>;
    expect(state['version'], 8);
    expect(state['flow'], ['identity', 'legal']);
    expect(state['setupMode'], 'trackerFirst');
    expect(state['nextRequiredSetup'], isEmpty);
    expect(state['deferredSetup'], containsAll(['profileDetails', 'availability']));
    expect(state['progressStage'], ArcRaiderProgressStage.unsure.name);
    expect(state['blueprintOwnership'], ArcBlueprintOwnershipState.unsure.name);
    expect(arcDefersFullRaiderSetup(record), isTrue);
    expect(arcNeedsMandatoryOnboarding(record), isFalse);
  });

  test('legacy and uncompleted users retain existing full setup gating', () {
    expect(arcDefersFullRaiderSetup(const {}), isFalse);
    expect(arcDefersFullRaiderSetup(const {'arcOnboarding': {'version': 8, 'setupMode': 'trackerFirst'}}), isFalse);
    expect(arcDefersFullRaiderSetup(const {
      'arcMandatoryOnboardingComplete': true,
      'arcOnboarding': {'version': 7, 'setupMode': 'full'},
    }), isFalse);
  });

  test('new tracker-only account starts private and not enrolled in trading', () {
    final data = buildArcOnboardingAccountProfilePayload(
      email: 'raider@example.com', riderName: 'Raider123',
    );
    expect((data['modules'] as Map)['trader'], isFalse);
    expect(data['visibleInSearch'], isFalse);
    expect((data['arcOnboarding'] as Map)['platforms'], isEmpty);
  });

  test('cosmetic identity carries the selected avatar ID', () {
    const identity = TradingCosmeticIdentity(
      uid: 'user-1', displayName: 'Raider', avatarId: 'nova',
    );
    expect(identity.avatarId, 'nova');
    expect(TradingCosmeticIdentity.empty.avatarId, isEmpty);
  });
}
