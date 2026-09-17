import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('beta feedback uses one ARC identity layer and guarded reporting', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart',
    );

    expect(text, contains("title: 'Closed Beta Feedback'"));
    expect(text, contains("title: 'HELP HARDEN THE ARC NETWORK'"));
    expect(text, isNot(contains("title: 'BETA FEEDBACK'")));
    expect(text, isNot(contains("label: 'Private beta report'")));
    expect(text, contains("labelText: 'What happened?'"));
    expect(text, contains("'SEND BETA FEEDBACK'"));
    expect(text, contains('catch (_)'));
  });

  test(
    'wall of legends keeps permanent recognition without duplicate summary pills',
    () {
      final text = source(
        'lib/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart',
      );

      expect(text, contains("title: 'Wall of Legends'"));
      expect(text, contains("title: 'IMMORTALISED IN THE UAG NETWORK'"));
      expect(text, isNot(contains("label: 'Admin curated'")));
      expect(text, contains('ArcCompanionBottomDock'));
      expect(text, contains('UagAppBar'));
    },
  );

  test(
    'my intel exposes consolidated report context and production states',
    () {
      final text = source(
        'lib/features/trading_hub/arc_raiders/screens/my_intel_screen.dart',
      );

      expect(text, contains("title: 'My Intel'"));
      expect(text, contains("title: 'Syncing your intel'"));
      expect(text, contains("'RECENT INTEL'"));
      expect(text, contains('visibleReports: latest.length'));
      expect(text, isNot(contains("title: 'MY INTEL'")));
      expect(text, isNot(contains("label: 'Raider linked'")));
    },
  );

  test(
    'help centre exposes support command hierarchy without explanatory pill duplication',
    () {
      final text = source(
        'lib/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart',
      );

      expect(text, contains("title: 'Help Centre'"));
      expect(text, contains("title: 'FIELD SUPPORT // UAG NETWORK'"));
      expect(text, isNot(contains("label: 'Safety policies'")));
      expect(text, contains("labelText: 'Search Help Centre'"));
      expect(text, contains('UagAppBar'));
    },
  );

  test('progress trackers advertise the four focused tracker systems once', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart',
    );

    expect(text, contains("title: 'Progress Trackers'"));
    expect(text, contains("title: 'TRACK WHAT MOVES THE RAID'"));
    expect(text, contains("title: 'Scrappy Tracker'"));
    expect(text, contains("title: 'Bench Tracker'"));
    expect(text, contains("title: 'Quest Tracker'"));
    expect(text, contains("title: 'Hunt Targets'"));
    expect(text, isNot(contains("label: 'Scrappy resources'")));
    expect(text, isNot(contains("label: 'Bench readiness'")));
    expect(text, isNot(contains("label: 'Quest blockers'")));
    expect(text, isNot(contains("label: 'Hunt targets'")));
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
