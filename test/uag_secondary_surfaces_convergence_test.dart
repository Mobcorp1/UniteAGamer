import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('beta feedback uses ARC convergence hierarchy and guarded reporting', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart',
    );

    expect(text, contains("title: 'BETA FEEDBACK'"));
    expect(text, contains("title: 'HELP HARDEN THE ARC NETWORK'"));
    expect(text, contains("label: 'Private beta report'"));
    expect(text, contains("labelText: 'What happened?'"));
    expect(text, contains("'SEND BETA FEEDBACK'"));
    expect(text, contains('catch (_)'));
  });

  test('wall of legends exposes permanent recognition hierarchy', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart',
    );

    expect(text, contains("title: 'IMMORTALISED IN THE UAG NETWORK'"));
    expect(text, contains("label: 'Admin curated'"));
    expect(text, contains('ArcCompanionBottomDock'));
    expect(text, contains('UagAppBar'));
  });

  test('my intel exposes report context and production state panels', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart',
    );

    expect(text, contains("title: 'MY INTEL'"));
    expect(text, contains("title: 'Syncing your intel'"));
    expect(text, contains("label: 'Raider linked'"));
    expect(text, contains('_IntelHero(totalReports: docs.length)'));
  });

  test('help centre exposes support command hierarchy', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart',
    );

    expect(text, contains("title: 'FIELD SUPPORT // UAG NETWORK'"));
    expect(text, contains("label: 'Safety policies'"));
    expect(text, contains("labelText: 'Search Help Centre'"));
    expect(text, contains('UagAppBar'));
  });

  test('progress trackers advertise the four focused tracker systems', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart',
    );

    expect(text, contains("label: 'Scrappy resources'"));
    expect(text, contains("label: 'Bench readiness'"));
    expect(text, contains("label: 'Quest blockers'"));
    expect(text, contains("label: 'Hunt targets'"));
  });

  test('future hub uses honest roadmap states and guarded community writes', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart',
    );

    expect(text, isNot(contains("'PLANNED'")));
    expect(text, isNot(contains("'ROADMAP'")));
    expect(text, contains("'EXPLORING'"));
    expect(text, contains('Could not submit your suggestion. Try again.'));
    expect(text, contains('Could not update your vote. Try again.'));
  });
}
