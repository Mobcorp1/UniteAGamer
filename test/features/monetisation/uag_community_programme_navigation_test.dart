import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// Firebase's installed platform package exposes its official native test host.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/uag_benefits_community_rewards_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/uag_creator_programme_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_refer_a_raider_panel.dart';
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

  // Use signed-out native mocks: actual programme widgets render, but no user
  // document is read and no form/claim/payment/contract action is submitted.
  for (final width in [320.0, 390.0, 1080.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'community programmes navigate at $width with text scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          expect(FirebaseAuth.instance.currentUser, isNull);
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              theme: AppTheme.theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const UagBenefitsCommunityRewardsScreen(),
            ),
          );
          await _pumpRoute(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Programme landing must fit.',
          );
          expect(find.text('OPEN YOUR REWARDS'), findsOneWidget);
          expect(find.text('OPEN CREATOR PROGRAM'), findsOneWidget);
          expect(find.text('EXPLORE HUNTER RATS'), findsOneWidget);

          final rewards = find.text('OPEN YOUR REWARDS');
          final creator = find.text('OPEN CREATOR PROGRAM');
          final hunter = find.text('EXPLORE HUNTER RATS');
          final rewardsPosition = tester.getTopLeft(rewards);
          final creatorPosition = tester.getTopLeft(creator);
          if (width < 760) {
            expect(creatorPosition.dy, greaterThan(rewardsPosition.dy));
          } else {
            expect(creatorPosition.dx, greaterThan(rewardsPosition.dx));
          }

          await tester.ensureVisible(rewards);
          await tester.tap(rewards);
          await _pumpRoute(tester);
          expect(find.byType(UagReferARaiderPanel), findsOneWidget);
          expect(find.text('Your Community Rewards'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Community detail must fit.',
          );
          navigator.currentState!.pop();
          await _pumpRoute(tester);

          await tester.ensureVisible(creator);
          await tester.tap(creator);
          await _pumpRoute(tester);
          expect(find.byType(UagCreatorProgrammeScreen), findsOneWidget);
          expect(find.text('UAG Creator Program'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Creator entry must fit.',
          );
          navigator.currentState!.pop();
          await _pumpRoute(tester);

          await tester.ensureVisible(hunter);
          await tester.tap(hunter);
          await _pumpRoute(tester);
          expect(find.text('Hunter Rats'), findsOneWidget);
          expect(find.text('OPEN CONTRACTS'), findsOneWidget);
          expect(find.textContaining('COUNTRY LEADERBOARD'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Hunter planned-state detail must fit.',
          );
          navigator.currentState!.pop();
          await _pumpRoute(tester);
          expect(
            find.byType(UagBenefitsCommunityRewardsScreen),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'Returning preserves the programme landing.',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  }
}

Future<void> _pumpRoute(WidgetTester tester) async {
  // Bounded pumping also works when the shared drawer owns a repeat animation.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}
