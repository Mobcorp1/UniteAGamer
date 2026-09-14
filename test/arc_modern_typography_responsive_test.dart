import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_section_header.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final heading = FontLoader(AppTheme.headingFontFamily)
      ..addFont(rootBundle.load('assets/fonts/SpaceGrotesk-SemiBold.ttf'));
    final body = FontLoader(AppTheme.bodyFontFamily)
      ..addFont(
        rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'),
      );
    await heading.load();
    await body.load();
  });

  test('all runtime ARC typography uses modern bundled families', () {
    expect(ArcUiTokens.display().fontFamily, 'SpaceGrotesk');
    expect(ArcUiTokens.sectionTitle().fontFamily, 'SpaceGrotesk');
    expect(AppTheme.theme.textTheme.headlineSmall!.fontFamily, 'SpaceGrotesk');
    expect(AppTheme.theme.textTheme.labelLarge!.fontFamily, 'Inter');
    // Keep legacy font assets available, but prevent direct runtime regressions.
    final legacy = RegExp(
      r'vt323|pressstart2p|press_start_2p',
      caseSensitive: false,
    );
    final contaminated = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => legacy.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList();
    expect(contaminated, isEmpty);
  });

  for (final width in [320.0, 390.0, 800.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('section actions fit width $width at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ArcTacticalPanel(
                    title: 'Community progression and tracking',
                    subtitle: 'Verified activity and your next milestone',
                    icon: Icons.groups_outlined,
                    trailing: TextButton(
                      onPressed: () => opened = true,
                      child: const Text('VIEW ACTIVITY'),
                    ),
                    child: const ArcSectionHeader(
                      title: 'Your activity',
                      subtitle: 'No verified activity to display yet.',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('VIEW ACTIVITY'));
        expect(opened, isTrue);
      });
    }
  }
}
