import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart';

void main() {
  final viewports = <Size>[
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1280, 900),
    const Size(1440, 1000),
  ];

  for (final viewport in viewports) {
    testWidgets(
      'Blueprint Tracker renders authoritative grid at ${viewport.width.toInt()} wide',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: BlueprintGridScreen(
              showFirstRunTutorial: false,
              loadViewMode: () async => ArcBlueprintGridViewMode.fullOverview,
              saveViewMode: (_) async {},
              blueprintStateSnapshotStream: () =>
                  Stream<ArcBlueprintStateSnapshot>.value(
                    ArcBlueprintStateSnapshot.loaded(
                      userId: 'blueprint-grid-regression-test',
                      states: const <String, ArcBlueprintState>{},
                    ),
                  ),
              favouriteLoadoutStream: () => Stream.value(null),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.byKey(const Key('blueprint-authoritative-grid')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('blueprint-authoritative-grid-viewport')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('blueprint-authoritative-grid-view')),
          findsOneWidget,
        );
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.byTooltip('Zoom in'), findsOneWidget);
        expect(find.byTooltip('Reset grid view'), findsOneWidget);
        expect(find.byTooltip('Zoom out'), findsOneWidget);
        expect(find.byType(BlueprintTile), findsWidgets);

        final gridView = tester.widget<GridView>(
          find.byKey(const Key('blueprint-authoritative-grid-view')),
        );
        expect(
          gridView.semanticChildCount,
          ArcBlueprintSeedData.blueprints.length,
        );

        final ordered = [...ArcBlueprintSeedData.blueprints]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        expect(find.text(ordered.first.name), findsOneWidget);
        expect(find.text(ordered.last.name), findsOneWidget);

        final viewportBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('blueprint-authoritative-grid-viewport')),
        );
        final dockBox = tester.renderObject<RenderBox>(
          find.byType(ArcCompanionBottomDock),
        );
        expect(viewportBox.size.width, greaterThan(0));
        expect(viewportBox.size.height, greaterThan(120));
        expect(dockBox.size.height, lessThan(96));

        final gridTop = tester
            .getTopLeft(
              find.byKey(const Key('blueprint-authoritative-grid-viewport')),
            )
            .dy;
        final gridBottom = tester
            .getBottomLeft(
              find.byKey(const Key('blueprint-authoritative-grid-viewport')),
            )
            .dy;
        final dockTop = tester
            .getTopLeft(find.byType(ArcCompanionBottomDock))
            .dy;
        final visibleGridHeight =
            math.min(gridBottom, dockTop) - math.max(gridTop, 0);
        expect(visibleGridHeight, greaterThan(120));

        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pump();
        await tester.tap(find.byTooltip('Reset grid view'));
        await tester.pump();
        await tester.tap(find.byTooltip('Zoom out'));
        await tester.pump();

        final center = tester.getCenter(
          find.byKey(const Key('blueprint-authoritative-grid-viewport')),
        );
        final firstFinger = await tester.createGesture(pointer: 1);
        final secondFinger = await tester.createGesture(pointer: 2);
        await firstFinger.down(center - const Offset(8, 0));
        await secondFinger.down(center + const Offset(8, 0));
        await tester.pump();
        await firstFinger.moveTo(center - const Offset(28, 0));
        await secondFinger.moveTo(center + const Offset(28, 0));
        await tester.pump();
        await firstFinger.up();
        await secondFinger.up();
        await tester.pump(const Duration(milliseconds: 80));

        expect(tester.takeException(), isNull);
      },
    );
  }
}
