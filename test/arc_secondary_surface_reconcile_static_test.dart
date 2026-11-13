import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARC reconciled secondary surface contracts', () {
    test(
      'Communications Centre keeps safe actions and ARC feed primitives',
      () {
        final source = _read('trading_notifications_screen.dart');

        expect(source, contains('ArcRaidersHeroBanner'));
        expect(source, contains('ArcTacticalStatTile'));
        expect(source, contains('ArcTacticalStatusPill'));
        expect(source, contains('ArcRaidersSectionCard'));
        expect(source, contains('ArcRaidersStatePanel'));
        expect(source, contains("activeLabel: 'messages'"));
        expect(source, contains('Could not mark messages as read. Try again.'));
        expect(
          source,
          contains('Message opened, but read status could not sync.'),
        );
        expect(source, contains('Could not delete the message. Try again.'));
      },
    );

    test(
      'My Intel preserves current shell while using shared ARC states/cards',
      () {
        final source = _read('my_intel_screen.dart');

        expect(source, contains('drawer: const AppDrawer()'));
        expect(source, contains('appBar: const UagAppBar('));
        expect(source, contains("activeLabel: 'My Intel'"));
        expect(source, isNot(contains('ArcRaidersPageHeader(')));
        expect(source, isNot(contains('_IntelHero(')));
        expect(source, isNot(contains("'RECENT INTEL'")));
        expect(source, contains('_IntelSummary('));
        expect(source, contains('visibleReports: latest.length'));
        expect(source, contains('ArcRaidersSectionCard'));
        expect(source, contains('ArcRaidersStatePanel'));
        expect(source, contains('ArcTacticalStatusPill'));
        expect(source, isNot(contains('class _IntelMessage')));
      },
    );

    test('Smart Build separates failed streams from empty build state', () {
      final source = _read('arc_smart_build_trade_draft_screen.dart');

      expect(source, contains('loadoutSnapshot.hasError'));
      expect(source, contains('blueprintSnapshot.hasError'));
      expect(source, contains('ArcRaidersStatePanel'));
      expect(source, contains('ArcRaidersSectionCard'));
      expect(source, contains("activeLabel: 'Trading'"));
      expect(source, contains('ArcLoadoutIntegrationEngine.evaluate'));
      expect(source, contains('watchFavouriteLoadout()'));
      expect(source, contains('watchMyBlueprintStates()'));
    });

    test('Intel Explorer distinguishes loading/error/empty states', () {
      final source = _read('arc_intel_explorer_screen.dart');

      expect(source, contains('snapshot.hasError'));
      expect(source, contains('ConnectionState.waiting'));
      expect(source, contains('ArcRaidersHeroBanner'));
      expect(source, contains('ArcRaidersStatePanel'));
      expect(source, contains('ArcRaidersSectionCard'));
      expect(source, contains('controller.dispose();'));
      expect(source, contains('watchIntelForBlueprint'));
    });

    test(
      'Wall of Legends preserves current navigation and converges cards',
      () {
        final source = _read('wall_of_legends_screen.dart');

        expect(source, contains('drawer: const AppDrawer()'));
        expect(source, contains('appBar: const UagAppBar('));
        expect(source, contains("activeLabel: 'DISCOVER'"));
        expect(source, isNot(contains('ArcRaidersHeroBanner(')));
        expect(source, isNot(contains('ArcRaidersPageHeader(')));
        expect(source, contains('_wallSummary(entries.length)'));
        expect(source, contains("'Permanent recognition'"));
        expect(source, contains('ArcTacticalStatusPill'));
        expect(source, contains('ArcRaidersSectionCard'));
        expect(source, contains('ArcRaidersStatePanel'));
        expect(source, isNot(contains('ChoiceChip(')));
      },
    );

    test(
      'Closed Beta Feedback retains richer current layout and safe report id',
      () {
        final source = _read('arc_beta_feedback_screen.dart');

        expect(source, isNot(contains('ArcRaidersPageHeader(')));
        expect(source, contains('ArcRaidersHeroBanner'));
        expect(source, contains('ArcRaidersSectionCard'));
        expect(source, contains('ArcTacticalStatusPill'));
        expect(source, contains('ArcUiTokens.inputDecoration'));
        expect(source, contains('id.length <= 8'));
        expect(source, isNot(contains('ChoiceChip(')));
      },
    );

    test('reconciled screens do not expose raw stream errors', () {
      for (final filename in const [
        'trading_notifications_screen.dart',
        'my_intel_screen.dart',
        'arc_smart_build_trade_draft_screen.dart',
        'arc_intel_explorer_screen.dart',
        'wall_of_legends_screen.dart',
        'arc_beta_feedback_screen.dart',
      ]) {
        final source = _read(filename);
        expect(source, isNot(contains('snapshot.error.toString()')));
        expect(source, isNot(contains(r'${snapshot.error}')));
      }
    });
  });
}

String _read(String filename) {
  return File(
    'lib/features/trading_hub/arc_raiders/screens/$filename',
  ).readAsStringSync();
}
