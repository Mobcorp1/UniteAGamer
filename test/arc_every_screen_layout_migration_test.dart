import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_page_carousel.dart';

void main() {
  testWidgets('dashboard split pane uses desktop columns and mobile stack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1366, 768)),
          child: Scaffold(
            body: SizedBox(
              width: 1000,
              child: ArcResponsiveSplitPane(
                primary: SizedBox(key: Key('mission'), height: 80),
                secondary: SizedBox(key: Key('objectives'), height: 80),
              ),
            ),
          ),
        ),
      ),
    );

    final missionDesktop = tester.getTopLeft(find.byKey(const Key('mission')));
    final objectivesDesktop = tester.getTopLeft(
      find.byKey(const Key('objectives')),
    );
    expect(objectivesDesktop.dx, greaterThan(missionDesktop.dx));
    expect(objectivesDesktop.dy, missionDesktop.dy);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(390, 800)),
          child: Scaffold(
            body: SizedBox(
              width: 390,
              child: ArcResponsiveSplitPane(
                primary: SizedBox(key: Key('mission'), height: 80),
                secondary: SizedBox(key: Key('objectives'), height: 80),
              ),
            ),
          ),
        ),
      ),
    );

    final missionMobile = tester.getTopLeft(find.byKey(const Key('mission')));
    final objectivesMobile = tester.getTopLeft(
      find.byKey(const Key('objectives')),
    );
    expect(objectivesMobile.dy, greaterThan(missionMobile.dy));
  });

  testWidgets('form and catalogue grids adapt without stretched cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1200, 800)),
          child: Scaffold(
            body: SizedBox(
              width: 760,
              child: ArcFormGrid(
                children: [
                  SizedBox(key: Key('field-one'), height: 44),
                  SizedBox(key: Key('field-two'), height: 44),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final firstField = tester.getTopLeft(find.byKey(const Key('field-one')));
    final secondField = tester.getTopLeft(find.byKey(const Key('field-two')));
    expect(secondField.dx, greaterThan(firstField.dx));
    expect(secondField.dy, firstField.dy);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(390, 800)),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              child: ArcFormGrid(
                children: [
                  SizedBox(key: Key('field-one'), height: 44),
                  SizedBox(key: Key('field-two'), height: 44),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final firstMobile = tester.getTopLeft(find.byKey(const Key('field-one')));
    final secondMobile = tester.getTopLeft(find.byKey(const Key('field-two')));
    expect(secondMobile.dy, greaterThan(firstMobile.dy));
  });

  testWidgets('canonical carousel handles desktop arrows one item and empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1366, 768)),
          child: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 220,
              child: UagPageCarousel(
                pages: [
                  ColoredBox(color: Colors.red, child: SizedBox.expand()),
                  ColoredBox(color: Colors.green, child: SizedBox.expand()),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: UagPageCarousel(pages: [Text('single-card')]),
          ),
        ),
      ),
    );
    expect(find.text('single-card'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: UagPageCarousel(pages: []),
          ),
        ),
      ),
    );
    expect(find.byType(PageView), findsNothing);
  });

  test(
    'route manifest covers reachable full-screen routes without duplicates',
    () {
      final file = File('docs/design/global_layout_screen_manifest.csv');
      expect(file.existsSync(), isTrue);

      final rows = file.readAsLinesSync();
      expect(rows.first, startsWith('route,screen_name,source_file'));

      final routes = <String>[];
      for (final row in rows.skip(1)) {
        if (row.trim().isEmpty) continue;
        final route = row.split(',').first.trim();
        routes.add(route);
      }

      expect(routes.length, greaterThanOrEqualTo(48));
      expect(routes.toSet().length, routes.length);
      expect(routes, contains('/trading-hub/arc-raiders/command-centre'));
      expect(routes, contains('/trading-hub/arc-raiders/blueprints'));
      expect(routes, contains('/trading-hub/arc-raiders/operations'));
      expect(routes, contains('/trading-hub/arc-raiders/trader-hub'));
      expect(routes, contains('/admin-console'));
    },
  );
}
