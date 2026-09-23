import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('command centre removes nested duplicate headings on compact layouts', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    );

    expect(source, contains("const title = 'OPS SNAPSHOT';"));
    expect(source, contains('_actionConsole(commandMoves, showHeader: false)'));
    expect(
      source,
      contains('_systemCarousel(state, carouselTiles, showHeader: false)'),
    );
    expect(
      source,
      contains('_systemIntelligencePanel(state, tiles[activeIndex])'),
    );
    expect(source, contains('_seasonResetEntry(showTitle: false)'));
    expect(source, contains('bool showHeader = true'));
    expect(source, contains('bool showTitle = true'));
    expect(source, isNot(contains("const title = 'COMMAND CENTRE';")));
  });

  test('my hub keeps unique overview metrics and action-led priorities', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/my_hub_screen.dart',
    );

    expect(source, contains("label: 'Collected'"));
    expect(source, contains("label: 'Missing'"));
    expect(source, contains("label: 'Duplicates'"));
    expect(source, isNot(contains("label: 'Blueprints'")));
    expect(source, isNot(contains('_featureStripBody()')));
    expect(source, contains("title: 'Priorities'"));
    expect(source, contains('Hunt queue:'));
    expect(source, contains('Trade opportunity:'));
    expect(source, isNot(contains(r'Signed in as $_displayName.')));
  });

  test('support and tracker overviews use one page identity layer', () {
    final screens = <String>[
      'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart',
    ];

    for (final path in screens) {
      final source = read(path);
      expect(source, isNot(contains('ArcRaidersPageHeader(')), reason: path);
    }
  });

  test('generic explanatory pill rows are removed where content already says it', () {
    final help = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart',
    );
    final feedback = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart',
    );
    final progress = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart',
    );
    final wall = read(
      'lib/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart',
    );

    expect(help, isNot(contains('Searchable guidance')));
    expect(help, isNot(contains('Direct system routes')));
    expect(feedback, isNot(contains('Private beta report')));
    expect(feedback, isNot(contains('No screenshot required')));
    expect(progress, isNot(contains('Scrappy resources')));
    expect(progress, isNot(contains('Bench readiness')));
    expect(wall, isNot(contains("label: 'Admin curated'")));
  });

  test('my intel consolidates report counts into a single compact summary', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart',
    );

    expect(source, isNot(contains("'RECENT INTEL'")));
    expect(source, contains('_IntelSummary('));
    expect(source, contains('visibleReports: latest.length'));
    expect(source, contains(r"label: '$totalReports submitted'"));
    expect(source, contains(r"$visibleReports recent"));
    expect(
      source,
      isNot(contains(r'Showing $visibleReports of $totalReports')),
    );
    expect(source, isNot(contains("label: 'Raider linked'")));
    expect(source, isNot(contains(r"label: '${latest.length} shown'")));
  });

  test('density pass preserves data and submission authority', () {
    final command = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
    );
    final myHub = read(
      'lib/features/trading_hub/arc_raiders/screens/my_hub_screen.dart',
    );
    final intel = read(
      'lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart',
    );
    final help = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart',
    );
    final feedback = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart',
    );
    final progress = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart',
    );
    final wall = read(
      'lib/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart',
    );

    expect(command, contains('ArcCommandCentreEngine.build('));
    expect(myHub, contains('_blueprintRepository.watchMyBlueprintStates()'));
    expect(intel, contains("collection('arc_blueprint_drop_reports')"));
    expect(intel, contains('doc.reference.set({'));
    expect(intel, contains('SetOptions(merge: true)'));
    expect(intel, contains('.delete()'));
    expect(help, contains('ArcHelpCentreCatalog.categories'));
    expect(feedback, contains('final id = await _repository.submit('));
    expect(progress, contains('FeatureAccess.watchAvailabilityMap('));
    expect(wall, contains('_repository.watchEntries()'));
  });
}
