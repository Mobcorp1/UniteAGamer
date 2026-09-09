import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/onboarding/screens/uag_raider_agreement_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

void main() {
  test('Raider Agreement is versioned beyond legacy legal acceptance', () {
    expect(UagRaiderAgreementScreen.agreementVersion, greaterThan(4));
  });

  test('new onboarding personalisation goals are available', () {
    expect(
      ArcPersonalisationGoal.values,
      contains(ArcPersonalisationGoal.huntARat),
    );
    expect(
      ArcPersonalisationGoal.values,
      contains(ArcPersonalisationGoal.findBlueprintIntel),
    );
    expect(
      ArcPersonalisationGoal.values,
      contains(ArcPersonalisationGoal.playLikeAPro),
    );
  });
}
