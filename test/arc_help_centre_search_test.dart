import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// Use the installed Firebase package's official native test host.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    final heading = FontLoader(AppTheme.headingFontFamily)
      ..addFont(rootBundle.load('assets/fonts/SpaceGrotesk-SemiBold.ttf'));
    final body = FontLoader(AppTheme.bodyFontFamily)
      ..addFont(
        rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'),
      );
    await heading.load();
    await body.load();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 390.0, 1080.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Help search recovers at $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        expect(FirebaseAuth.instance.currentUser, isNull);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const ArcHelpCentreScreen(),
          ),
        );
        await _pumpHelp(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Help landing must fit.',
        );
        expect(find.text('Where should I start?'), findsOneWidget);

        final search = find.byType(TextField);
        await tester.ensureVisible(search);
        await tester.enterText(search, 'How do I mark a blueprint?');
        await _pumpHelp(tester);
        expect(find.text('Where should I start?'), findsNothing);
        expect(find.text('How do I mark a blueprint?'), findsWidgets);
        expect(find.text('BLUEPRINT TRACKER'), findsOneWidget);

        final category = tester.getTopLeft(find.text('Blueprint Tracker'));
        final answers = tester.getTopLeft(find.text('BLUEPRINT TRACKER'));
        if (width == 1080 && scale == 1) {
          expect(answers.dx, greaterThan(category.dx));
        } else {
          expect(answers.dy, greaterThan(category.dy));
        }
        final question = find.descendant(
          of: find.byType(ExpansionTile),
          matching: find.text('How do I mark a blueprint?'),
        );
        await tester.ensureVisible(question);
        await _pumpHelp(tester);
        await tester.tap(question);
        await _pumpHelp(tester);
        expect(
          find.textContaining('Tap a blueprint for details'),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Expanded answer must fit.',
        );

        await tester.ensureVisible(search);
        await tester.enterText(search, 'zzzz-no-such-help-topic-zzzz');
        await _pumpHelp(tester);
        expect(find.text('No matching topics'), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);
        expect(find.text('BLUEPRINT TRACKER'), findsNothing);
        expect(find.text('Where should I start?'), findsNothing);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Empty search must fit.',
        );

        final clear = find.byTooltip('Clear search');
        await tester.ensureVisible(clear);
        await _pumpHelp(tester);
        await tester.tap(clear);
        await _pumpHelp(tester);
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(find.text('No matching topics'), findsNothing);
        expect(find.text('Where should I start?'), findsOneWidget);
        expect(find.text('Blueprint Tracker'), findsOneWidget);
        expect(find.byTooltip('Clear search'), findsNothing);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Clearing restores topics.',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}

Future<void> _pumpHelp(WidgetTester tester) async {
  // The shared drawer may own a repeating animation; keep pumping bounded.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}
