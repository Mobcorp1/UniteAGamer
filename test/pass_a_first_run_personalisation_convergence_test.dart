import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'onboarding keeps future-only systems out of the first objective list',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
      ).readAsStringSync();
      final start = source.indexOf('static const _goalOptions');
      final end = source.indexOf('];', start);
      final goals = source.substring(start, end);

      expect(goals, isNot(contains('ArcPersonalisationGoal.huntARat')));
      expect(goals, isNot(contains('ArcPersonalisationGoal.playLikeAPro')));
      expect(goals, contains('ArcPersonalisationGoal.exploreEverything'));
    },
  );

  test('first-run flow captures platform and awaits personalisation writes', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ArcGamePlatformSelector'));
    expect(source, contains('_profileRepository.savePlatformSelection'));
    expect(source, contains('_personalisationRepository.markComplete'));
    expect(source, isNot(contains('_runNonBlockingProfileSync')));
  });

  test('My Hub consumes the saved personalisation profile', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/my_hub_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ArcUserPersonalisationRepository'));
    expect(source, contains('_personalisationRepository.watchProfile()'));
    expect(source, contains("title: 'Your Focus'"));
  });

  test('profile links follow selected gaming platforms', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_social_links_editor.dart',
    ).readAsStringSync();

    expect(source, contains('selectedGamePlatforms'));
    expect(source, contains("'GAMING IDENTITIES'"));
    expect(source, contains("'SOCIAL & CREATOR LINKS'"));
  });

  test('Command Centre system carousel follows the saved focus', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final ArcUserPersonalisationProfile personalisation;'),
    );
    expect(
      source,
      contains('personalisation.interestFor(feature).isHighSignal'),
    );
    expect(source, contains("tile.title == 'Tool Deck'"));
  });
}
