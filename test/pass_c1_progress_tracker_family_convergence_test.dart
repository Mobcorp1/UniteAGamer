import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('C1 landing is flat and tracker-first', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_progress_trackers_screen.dart',
    );

    expect(text, contains("'TRACKER WORKSPACES'"));
    expect(text, contains('Open the progression tool you need now.'));
    expect(text, isNot(contains('ArcRaidersHeroBanner(')));
    expect(text, contains('FeatureAccess.watchAvailabilityMap'));
    expect(text, contains('Tracker access unavailable'));
    expect(text, contains('BoxConstraints(minHeight: 88)'));
  });

  test('C1 Scrappy and Bench remove large decorative hero images', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    );

    expect(text, isNot(contains('arc_hub_scrappy_tracker.webp')));
    expect(text, isNot(contains('arc_hub_bench_tracker.webp')));
    expect(text, contains("'FEED PLAN'"));
    expect(text, contains("'CHOOSE A BENCH'"));
    expect(text, contains("role: ArcSurfaceRole.panel"));
  });

  test('C1 Quest Tracker exposes non-destructive expedition quest context', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    );

    expect(text, contains('ArcUserPersonalisationRepository'));
    expect(text, contains('ArcQuestProgressState.startingOrReset'));
    expect(text, contains('ArcQuestProgressState.continuing'));
    expect(text, contains("'EXPEDITION QUEST PLAN"));
    expect(
      text,
      contains(
        'Context only - changing this does not erase Quest Tracker progress.',
      ),
    );
    expect(text, contains('profile.copyWith(questProgress: state)'));
  });

  test(
    'C1 Quest board stacks on narrow layouts and uses columns when wide',
    () {
      final text = source(
        'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
      );

      expect(text, contains('final useColumns = width >= 720;'));
      expect(text, contains('if (!useColumns)'));
      expect(text, contains("title: 'Needed'"));
      expect(text, contains("title: 'In Progress'"));
      expect(text, contains("title: 'Complete'"));
    },
  );

  test(
    'C1 tracker repository exposes error state rather than silent empty data',
    () {
      final text = source(
        'lib/features/trading_hub/arc_raiders/repositories/'
        'arc_scrappy_repository.dart',
      );

      expect(text, contains('StreamTransformer<'));
      expect(text, contains('handleError: (error, stackTrace, sink)'));
      expect(text, contains('>.error(error)'));
    },
  );

  test('C1 screen distinguishes restore, auth and sync failure states', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    );

    expect(text, contains('_repository.watchMyScrappyStates()'));
    expect(text, contains('ArcScrappyRepositoryStateStatus.restoring'));
    expect(text, contains('ArcScrappyRepositoryStateStatus.loading'));
    expect(text, contains('ArcScrappyRepositoryStateStatus.unauthenticated'));
    expect(text, contains('ArcScrappyRepositoryStateStatus.error'));
    expect(text, contains('No empty progress has been assumed.'));
    expect(text, contains('Showing your last loaded tracker progress'));
  });

  test('C1 preserves progression write authorities', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    );

    expect(text, contains('_repository.saveScrappyState('));
    expect(text, contains('_repository.resetAllScrappyStates('));
    expect(text, contains('confirmQuestCompleted('));
    expect(text, contains('confirmScrappyUpgrade('));
    expect(text, contains('confirmBenchUpgrade('));
  });

  test('C1 preserves Scrappy Bench Quest routes', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    );

    expect(
      text,
      contains("static const routeName = '/trading-hub/arc-raiders/scrappy';"),
    );
    expect(
      text,
      contains(
        "static const benchRouteName = '/trading-hub/arc-raiders/bench';",
      ),
    );
    expect(
      text,
      contains(
        "static const questRouteName = '/trading-hub/arc-raiders/quests';",
      ),
    );
  });
}
