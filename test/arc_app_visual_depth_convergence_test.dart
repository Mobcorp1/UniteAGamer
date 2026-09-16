import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_social_links_editor.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  test('shared ARC visual depth contracts remain wired', () {
    final tokens = File(
      'lib/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart',
    ).readAsStringSync();
    final formSurface = File(
      'lib/features/trading_hub/arc_raiders/widgets/foundation/arc_form_surface.dart',
    ).readAsStringSync();
    final shell = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    ).readAsStringSync();
    final commandCentre = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    expect(tokens, contains('gradient: LinearGradient('));
    expect(tokens, contains('role == ArcSurfaceRole.raised'));
    expect(formSurface, contains("'ARC OPERATIONS'"));
    expect(formSurface, contains('selected: _expanded'));
    expect(shell, contains("'ARC OPERATIONS'"));
    expect(shell, contains('Icons.blur_on_rounded'));
    expect(profile, contains('_profileDetailTile('));
    expect(profile, contains('role: ArcSurfaceRole.raised'));
    expect(commandCentre, contains('maxLines: 2'));
  });

  testWidgets('social links editor stays compact on Sony-class width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ArcSocialLinksEditor(
                initialLinks: const [],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('PUBLIC'), findsNWidgets(9));
    expect(find.byType(SwitchListTile), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
