import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// Use the official native mock already installed with Firebase Core.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
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

  for (final size in const [
    Size(360, 640),
    Size(390, 844),
    Size(844, 390),
    Size(1440, 900),
  ]) {
    testWidgets(
      'Discover group and system hierarchy fits ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        expect(FirebaseAuth.instance.currentUser, isNull);
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.theme, home: const ArcRaidersHubScreen()),
        );
        await _pumpDiscovery(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Top-level Discover layout must fit this viewport.',
        );
        expect(find.text('DISCOVER UAG'), findsOneWidget);
        expect(find.text('Choose a UAG system group'), findsOneWidget);
        expect(find.text('OPEN SYSTEM'), findsNothing);
        expect(find.byTooltip('Back to all systems'), findsNothing);

        // The selected first group comes from the live widget's catalogue. No
        // group label, catalogue order or former flat feature name is hard-coded.
        await tester.ensureVisible(find.text('OPEN GROUP').first);
        final openGroup = find.text('OPEN GROUP').hitTestable();
        expect(
          openGroup,
          findsWidgets,
          reason:
              'A visible group CTA must be tappable, including in landscape.',
        );
        await tester.tap(openGroup.first);
        await _pumpDiscovery(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Opening a group must not overflow.',
        );
        expect(find.text('OPEN GROUP'), findsNothing);
        await tester.ensureVisible(find.text('OPEN SYSTEM').first);
        expect(
          find.text('OPEN SYSTEM').hitTestable(),
          findsWidgets,
          reason: 'A system CTA must remain visible after opening the group.',
        );
        expect(find.text('Choose a UAG system group'), findsNothing);
        final breadcrumb = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').startsWith('DISCOVER UAG  >  '),
        );
        expect(breadcrumb, findsOneWidget);
        final firstBreadcrumb = tester.widget<Text>(breadcrumb).data;
        final back = find.byTooltip('Back to all systems');
        await tester.ensureVisible(back);
        expect(back.hitTestable(), findsOneWidget);
        await tester.tap(back);
        await _pumpDiscovery(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Group back restores a usable top-level layout.',
        );
        expect(find.text('Choose a UAG system group'), findsOneWidget);
        expect(find.text('OPEN SYSTEM'), findsNothing);
        expect(find.byTooltip('Back to all systems'), findsNothing);

        // Verify the same selected group can be reopened after returning; this
        // catches stale child-carousel/breadcrumb state without opening a gated
        // feature, querying user documents or invoking any paid action.
        await tester.ensureVisible(find.text('OPEN GROUP').first);
        await tester.tap(find.text('OPEN GROUP').hitTestable().first);
        await _pumpDiscovery(tester);
        expect(tester.widget<Text>(breadcrumb).data, firstBreadcrumb);
        await tester.ensureVisible(find.text('OPEN SYSTEM').first);
        expect(find.text('OPEN SYSTEM').hitTestable(), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}

Future<void> _pumpDiscovery(WidgetTester tester) async {
  // Discovery has continuous electric-border/drawer animations, so deliberately
  // avoid pumpAndSettle; these frames finish group switch animations.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}
