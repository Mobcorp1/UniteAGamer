import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_orientation_prompt.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';

void main() {
  Future<void> pumpPrompt(
    WidgetTester tester, {
    required Size size,
    bool coverContent = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: ArcOrientationPrompt(
            message: 'Rotate the device to view the complete 17-column grid.',
            coverContent: coverContent,
          ),
        ),
      ),
    );
  }

  for (final viewport in <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(568, 320),
    const Size(844, 390),
  ]) {
    testWidgets('rotation instruction is compact and fits $viewport', (
      tester,
    ) async {
      await pumpPrompt(tester, size: viewport);
      final card = find.byKey(const Key('arc-orientation-card'));

      expect(card, findsOneWidget);
      expect(find.text('ROTATE TO LANDSCAPE'), findsOneWidget);
      expect(tester.getSize(card).width, lessThanOrEqualTo(360));
      expect(tester.getSize(card).width, lessThan(viewport.width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scanner prompt hides live camera under cinematic art', (
    tester,
  ) async {
    await pumpPrompt(
      tester,
      size: const Size(390, 844),
      coverContent: true,
    );
    expect(find.byType(UagCinematicBackground), findsOneWidget);
    expect(find.byKey(const Key('arc-orientation-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape advisory is non-blocking and only visible in portrait', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcLandscapeAdvisory(message: 'Rotate for extra space.'),
        ),
      ),
    );
    expect(find.byKey(const Key('arc-landscape-advisory')), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(find.byKey(const Key('arc-landscape-advisory')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('rotation treatment is shared across landscape-only workspaces', () {
    for (final file in <String>[
      'lib/features/trading_hub/arc_raiders/screens/arc_collections_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart',
    ]) {
      expect(
        File(file).readAsStringSync(),
        contains('ArcOrientationPrompt('),
        reason: file,
      );
    }
    final crop = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart',
    ).readAsStringSync();
    expect('ArcOrientationPrompt('.allMatches(crop).length, 3);
  });

  test('global theme owns framework controls and backdrop is not duplicated', () {
    final theme = File('lib/widgets/theme.dart').readAsStringSync();
    for (final component in <String>[
      'textButtonTheme:',
      'outlinedButtonTheme:',
      'chipTheme:',
      'popupMenuTheme:',
      'tooltipTheme:',
      'dialogTheme:',
      'bottomSheetTheme:',
    ]) {
      expect(theme, contains(component));
    }
    final systems = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_systems_page_wrapper.dart',
    ).readAsStringSync();
    expect(systems, isNot(contains('ArcBlueprintGridBackground()')));
  });
}
