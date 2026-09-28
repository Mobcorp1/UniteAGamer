import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';

void main() {
  for (final size in <Size>[
    const Size(640, 360),
    const Size(740, 360),
    const Size(844, 390),
    const Size(1360, 600),
  ]) {
    testWidgets(
      'compact landscape spends height on the Blueprint grid at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: BlueprintGridScreen(
              showFirstRunTutorial: false,
              loadViewMode: () async => ArcBlueprintGridViewMode.fullOverview,
              saveViewMode: (_) async {},
              blueprintStateSnapshotStream: () => Stream.value(
                ArcBlueprintStateSnapshot.loaded(
                  userId: 'test',
                  states: const {},
                ),
              ),
              favouriteLoadoutStream: () => Stream.value(null),
              bannerSlot: const SizedBox(height: 58, child: Text('Creative')),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final viewport = find.byKey(
          const Key('blueprint-authoritative-grid-viewport'),
        );
        final rail = find.byKey(
          const Key('blueprint-grid-vertical-command-rail'),
        );
        expect(viewport, findsOneWidget);
        expect(rail, findsOneWidget);
        expect(
          find.byKey(const Key('blueprint-grid-horizontal-command-bar')),
          findsNothing,
        );
        expect(find.byType(ArcCompanionBottomDock), findsNothing);

        final viewportRect = tester.getRect(viewport);
        final railRect = tester.getRect(rail);
        expect(viewportRect.overlaps(railRect), isFalse);
        expect(viewportRect.height, greaterThan(size.height * 0.65));

        if (size.width >= 1180) {
          final ad = find.text('Creative');
          final adLane = find.byKey(const Key('blueprint-side-ad-right'));
          expect(ad, findsOneWidget);
          expect(adLane, findsOneWidget);
          expect(viewportRect.overlaps(tester.getRect(ad)), isFalse);
          final adLaneRect = tester.getRect(adLane);
          expect(adLaneRect.left, greaterThanOrEqualTo(railRect.right));
          expect(
            tester.getRect(ad).left,
            greaterThanOrEqualTo(adLaneRect.left),
          );
          expect(tester.getRect(ad).right, lessThanOrEqualTo(adLaneRect.right));
        }

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
