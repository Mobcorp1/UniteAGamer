import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'Play Like A Pro exposes guides, routine and coach as one workspace',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/widgets/'
        'arc_play_like_a_pro_workspace_bar.dart',
      );

      expect(source, contains('enum ArcPlayLikeAProWorkspace'));
      expect(source, contains('guides, routine, coach'));
      expect(source, contains("return 'Guides';"));
      expect(source, contains("return 'Pro Routine';"));
      expect(source, contains("return 'Session Coach';"));
      expect(source, contains('SingleChildScrollView'));
      expect(source, isNot(contains('PlayLikeAProRepository')));
      expect(source, isNot(contains('PlayLikeAProGuideRepository')));
    },
  );

  test(
    'root Play Like A Pro screen exposes the previously orphaned guide library',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/'
        'play_like_a_pro_screen.dart',
      );

      expect(source, contains('ArcPlayLikeAProWorkspaceBar('));
      expect(source, contains('ArcPlayLikeAProWorkspace.routine'));
      expect(source, contains('ArcPlayLikeAProWorkspace.guides'));
      expect(source, contains('ArcPlayLikeAProWorkspace.coach'));
      expect(source, contains('PlayLikeAProDiscoverScreen('));
      expect(source, contains('PlayLikeAProRoutineScreen('));
      expect(source, contains('_buildSessionCoach(context)'));
      expect(source, contains('_repository.watchState()'));
    },
  );

  test(
    'expert guidance remains personalised by profile and Favourite Loadout',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/'
        'play_like_a_pro_discover_screen.dart',
      );

      expect(source, contains('PlayLikeAProRecommendationEngine'));
      expect(source, contains('watchProfile()'));
      expect(source, contains('watchFavouriteLoadout()'));
      expect(source, contains('_engine.rank('));
      expect(source, contains('Recommended for you'));
    },
  );

  test('guide detail bridges expert guidance into the wider UAG ecosystem', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/'
      'play_like_a_pro_guide_detail_screen.dart',
    );

    expect(source, contains('ArcRaidIntelligenceScreen.routeName'));
    expect(source, contains('BlueprintGridScreen.routeName'));
    expect(source, contains('FavouriteLoadoutScreen.routeName'));
    expect(source, contains('RaidPlannerScreen.routeName'));
    expect(source, contains('ArcMatchRiderScreen.routeName'));
    expect(source, contains('plannerRelevant'));
    expect(source, contains('matchRelevant'));
  });

  test('existing guide and routine engines remain the source of truth', () {
    final discover = read(
      'lib/features/trading_hub/arc_raiders/screens/'
      'play_like_a_pro_discover_screen.dart',
    );
    final routine = read(
      'lib/features/trading_hub/arc_raiders/screens/'
      'play_like_a_pro_routine_screen.dart',
    );

    expect(discover, contains('_repository.loadPublishedGuides()'));
    expect(routine, contains('PlayLikeAProRoutineEngine'));
    expect(routine, contains('PlayLikeAProMixtapeLibrary'));
  });
}
