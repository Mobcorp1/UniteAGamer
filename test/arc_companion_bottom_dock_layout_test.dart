import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

void main() {
  testWidgets(
    'ARC companion dock exposes the five canonical product families',
    (tester) async {
      _setView(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpDock(tester, 'systems');

      final dockBox = tester.renderObject<RenderBox>(
        find.byType(ArcCompanionBottomDock),
      );

      expect(dockBox.size.height, lessThan(96));
      expect(find.text('RUN'), findsOneWidget);
      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.text('TRACK'), findsOneWidget);
      expect(find.text('TRADE'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('MESSAGES'), findsNothing);
    },
  );

  testWidgets('ARC companion dock compacts in mobile landscape', (
    tester,
  ) async {
    _setView(tester, const Size(844, 390));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDock(tester, 'Favourite Loadout');

    final dockBox = tester.renderObject<RenderBox>(
      find.byType(ArcCompanionBottomDock),
    );

    expect(dockBox.size.height, lessThan(72));
    expect(
      tester.widget<Text>(find.text('TRACK')).style?.color,
      ArcUiTokens.primaryAccent,
    );
  });

  testWidgets('social and intel surfaces map to deliberate product families', (
    tester,
  ) async {
    _setView(tester, const Size(390, 844));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDock(tester, 'Match Raider');
    _expectActiveLane(tester, 'PROFILE');

    await _pumpDock(tester, 'Community Intel');
    _expectActiveLane(tester, 'DISCOVER');

    await _pumpDock(tester, 'My Intel');
    _expectActiveLane(tester, 'TRACK');
  });

  testWidgets('dock stays inside responsive height budgets', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cases = <(Size, double)>[
      (Size(360, 640), 96),
      (Size(390, 844), 96),
      (Size(430, 932), 96),
      (Size(844, 390), 72),
      (Size(768, 1024), 96),
      (Size(1440, 900), 96),
    ];

    for (final (size, maxHeight) in cases) {
      _setView(tester, size);
      await _pumpDock(tester, 'Command Centre');

      final dockBox = tester.renderObject<RenderBox>(
        find.byType(ArcCompanionBottomDock),
      );
      expect(
        dockBox.size.height,
        lessThan(maxHeight),
        reason: 'Dock height at ${size.width}x${size.height}',
      );
    }
  });

  testWidgets('major beta routes map to the five canonical dock families', (
    tester,
  ) async {
    _setView(tester, const Size(390, 844));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cases = <String, String>{
      'Command Centre': 'RUN',
      'Raid Planner': 'RUN',
      'Raid Intelligence': 'RUN',
      'Operations': 'RUN',
      'Discover UAG': 'DISCOVER',
      'Arc Systems': 'DISCOVER',
      'Community Intel': 'DISCOVER',
      'Community Rewards': 'DISCOVER',
      'Wall of Legends': 'DISCOVER',
      'Report a Rat': 'DISCOVER',
      'Progress Trackers': 'TRACK',
      'Blueprint Tracker': 'TRACK',
      'Favourite Loadout': 'TRACK',
      'My Intel': 'TRACK',
      'Trading': 'TRADE',
      'Smart Trade Assist': 'TRADE',
      'Nomadic Trader': 'TRADE',
      'Profile & Reputation': 'PROFILE',
      'Raider Profile': 'PROFILE',
      'Match Raider': 'PROFILE',
      'Notifications': 'PROFILE',
      'My Hub': 'PROFILE',
      'Settings': 'PROFILE',
      'Plans & Referrals': 'PROFILE',
      'Help Centre': 'PROFILE',
      'Beta Feedback': 'PROFILE',
      'Legal & Privacy': 'PROFILE',
    };

    for (final entry in cases.entries) {
      await _pumpDock(tester, entry.key);
      _expectActiveLane(tester, entry.value);
    }
  });
}

void _setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

Future<void> _pumpDock(WidgetTester tester, String activeLabel) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: ArcCompanionBottomDock(activeLabel: activeLabel),
      ),
    ),
  );
  await tester.pump();
}

void _expectActiveLane(WidgetTester tester, String lane) {
  expect(
    tester.widget<Text>(find.text(lane)).style?.color,
    ArcUiTokens.primaryAccent,
    reason: '$lane should be the active bottom-dock lane.',
  );
}
