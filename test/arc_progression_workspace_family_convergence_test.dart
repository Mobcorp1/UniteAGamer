import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('progression workspace exposes the full tracker family', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/widgets/'
      'arc_progression_workspace_bar.dart',
    );

    expect(source, contains('enum ArcProgressionWorkspace'));
    expect(source, contains('crafting'));
    expect(
      source,
      contains("return '/trading-hub/arc-raiders/progress-trackers';"),
    );
    expect(source, contains("return '/trading-hub/arc-raiders/scrappy';"));
    expect(source, contains("return '/trading-hub/arc-raiders/bench';"));
    expect(source, contains("return '/trading-hub/arc-raiders/quests';"));
    expect(source, contains("return '/trading-hub/arc-raiders/crafting';"));
    expect(
      source,
      contains("return '/trading-hub/arc-raiders/raid-planner/hunt-targets';"),
    );
    expect(source, contains('rootNavigator: true'));
    expect(source, isNot(contains('ArcScrappyRepository')));
    expect(source, isNot(contains('TradingRepository')));
    expect(source, isNot(contains('StreamBuilder')));
  });

  test('progress tracker landing joins progression workspace', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_progress_trackers_screen.dart',
    );
    expect(source, contains('ArcProgressionWorkspaceBar('));
    expect(source, contains('ArcProgressionWorkspace.overview'));
    expect(source, contains('FeatureAccess.watchAvailabilityMap'));
    expect(source, contains('Crafting Planner'));
  });

  test(
    'scrappy, bench and quest modes share one progression workspace bar',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
      );
      expect(source, contains('ArcProgressionWorkspaceBar('));
      expect(source, contains('ArcProgressionWorkspace.scrappy'));
      expect(source, contains('ArcProgressionWorkspace.bench'));
      expect(source, contains('ArcProgressionWorkspace.quest'));
      expect(source, contains('_repository.watchMyScrappyStates()'));
      expect(source, contains('ArcProgressionRepository'));
      expect(source, contains('ArcUserPersonalisationRepository'));
      expect(source, contains('ArcQuestProgressState.startingOrReset'));
      expect(source, contains('ArcQuestProgressState.continuing'));
      expect(source, contains('ScrappyFeedQueueSection('));
    },
  );

  test('crafting joins tracker family as its own workspace', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_crafting_planner_screen.dart',
    );
    expect(source, contains('ArcProgressionWorkspace.crafting'));
    expect(source, contains('planForFavouriteLoadout'));
    expect(source, contains('recyclables.length'));
    expect(source, contains('SmartTradeAssistScreen.routeName'));
    expect(source, contains('ArcRaidIntelligenceScreen.routeName'));
  });

  test('hunt targets joins tracker family without replacing hunt logic', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/raid_planner/screens/'
      'raid_planner_hunt_targets_screen.dart',
    );
    expect(source, contains('ArcProgressionWorkspaceBar('));
    expect(source, contains('ArcProgressionWorkspace.hunts'));
    expect(source, contains('_repository.watchBlueprintStates()'));
    expect(source, contains('_repository.watchActiveListings()'));
    expect(source, contains('_autoSyncHunts('));
    expect(source, contains('_saveBlueprintStates('));
  });

  test('tracker family convergence stays navigation-only', () {
    final overview = read(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_progress_trackers_screen.dart',
    );
    expect(overview, contains('Scrappy Tracker'));
    expect(overview, contains('Bench Tracker'));
    expect(overview, contains('Quest Tracker'));
    expect(overview, contains('Crafting Planner'));
    expect(overview, contains('Hunt Targets'));
  });
}
