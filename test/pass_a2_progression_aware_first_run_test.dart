import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding captures Raider, Blueprint and quest progression state', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'RAIDER PROGRESSION'"));
    expect(source, contains("'New to ARC'"));
    expect(source, contains("'Fresh Expedition'"));
    expect(source, contains("'Already underway'"));
    expect(source, contains("'DO YOU OWN ANY BLUEPRINTS RIGHT NOW?'"));
    expect(source, contains("'Starting / reset quests'"));
    expect(source, contains("'Continuing my quests'"));
  });

  test('zero-Blueprint users are routed through Favourite Loadout logic', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/arc_onboarding_personalisation_builder.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("blueprintOwnership == ArcBlueprintOwnershipState.none"),
    );
    expect(source, contains("return 'favouriteLoadout';"));
  });

  test(
    'onboarding persists progression context before entering first system',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
      ).readAsStringSync();

      expect(source, contains('progressStage: progressStage'));
      expect(source, contains('blueprintOwnership: blueprintOwnership'));
      expect(source, contains('questProgress: questProgress'));
      expect(source, contains('_personalisationRepository.markComplete'));
      expect(
        source,
        contains('_completionDestination(recommendedFirstSystem)'),
      );
    },
  );

  test('My Hub respects zero-Blueprint progression after onboarding', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/my_hub_screen.dart',
    ).readAsStringSync();

    expect(source, contains('personalisation.blueprintOwnership'));
    expect(source, contains('ArcBlueprintOwnershipState.none'));
    expect(source, contains("return _featureByTitle('My Loadout');"));
  });
}
