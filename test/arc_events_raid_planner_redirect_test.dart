import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_events_screen.dart';

void main() {
  testWidgets('saved Events links replace the route with Raid Planner', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    const arguments = {'source': 'saved-events-link'};
    RouteSettings? plannerSettings;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Home destination')),
        routes: {
          ArcEventsScreen.routeName: (_) => const ArcEventsScreen(),
          RaidPlannerScreen.routeName: (context) {
            plannerSettings = ModalRoute.of(context)!.settings;
            return const Scaffold(body: Text('Raid Planner destination'));
          },
        },
      ),
    );

    navigator.currentState!.pushNamed(
      ArcEventsScreen.routeName,
      arguments: arguments,
    );
    await tester.pumpAndSettle();
    expect(find.text('Raid Planner destination'), findsOneWidget);
    expect(find.byType(ArcEventsScreen), findsNothing);
    expect(plannerSettings?.name, RaidPlannerScreen.routeName);
    expect(plannerSettings?.arguments, arguments);
    expect(tester.takeException(), isNull);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
    expect(find.byType(ArcEventsScreen), findsNothing);
  });
}
