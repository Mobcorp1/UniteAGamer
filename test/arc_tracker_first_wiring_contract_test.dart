import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('player onboarding is two steps while admin preview retains four', () {
    final s = File('lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart').readAsStringSync();
    expect(s, contains('widget.adminPreview ? 4 : 2'));
    expect(s, contains('if (_step == 1 && !widget.adminPreview)'));
    expect(s, contains('trackerFirst: true'));
    expect(s, contains('const BlueprintGridScreen()'));
    expect(s, contains('askForPlatform: widget.adminPreview'));
    expect(s, contains('if (_selectedPlatforms.isNotEmpty)'));
    expect(s, contains('if (askForPlatform)'));
    expect(s, contains('buildOnboardingLegalAcceptedMap('));
    expect(s, contains("prefs.setString('uag_tracker_first_uid', user.uid)"));
    expect(s, contains('!_legalComplete'));
  });

  test('trader identity shows the saved Raider image and frame overlay', () {
    final repo = File('lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart').readAsStringSync();
    final strip = File('lib/features/trading_hub/arc_raiders/widgets/trading_cosmetic_identity_strip.dart').readAsStringSync();
    expect(repo, contains("profileData?['avatarId']"));
    expect(strip, contains('UagRaiderAvatar('));
    expect(strip, contains('avatarId: cosmetics.avatarId'));
    expect(strip, isNot(contains('child: CircleAvatar(')));
    expect(strip, contains('if (frameAsset != null && frameAsset.isNotEmpty)'));
  });

  test('the established Raider Setup gate remains for legacy accounts', () {
    final gate = File('lib/screens/build/app_entry_gate.dart').readAsStringSync();
    expect(gate, contains('arcDefersFullRaiderSetup('));
    expect(gate, contains('if (deferredSnapshot.data == true) return destination;'));
    expect(gate, contains('return ArcRaiderSetupGate('));
    expect(gate, contains('return const ArcMandatoryOnboardingScreen();'));
  });
}
