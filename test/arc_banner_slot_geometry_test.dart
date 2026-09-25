import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_workspace_bar.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(640, 360),
    const Size(740, 360),
    const Size(1600, 1000),
  ]) {
    testWidgets(
      'Blueprint ad lifecycle preserves workspace geometry at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final eligible = ValueNotifier(true);
        final creative = ValueNotifier(0);
        addTearDown(eligible.dispose);
        addTearDown(creative.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: BlueprintGridScreen(
              showFirstRunTutorial: false,
              loadViewMode: () async => ArcBlueprintGridViewMode.fullOverview,
              saveViewMode: (_) async {},
              blueprintStateSnapshotStream: () => Stream.value(
                ArcBlueprintStateSnapshot.loaded(userId: 'test', states: {}),
              ),
              favouriteLoadoutStream: () => Stream.value(null),
              bannerSlot: ArcBlueprintBannerSlot(
                eligibility: eligible,
                banner: ValueListenableBuilder<int>(
                  valueListenable: creative,
                  builder: (_, value, _) => value == 0
                      ? const SizedBox.shrink()
                      : value == 1
                      ? const SizedBox(height: 58, child: Text('Creative'))
                      : const Text('Unavailable'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final grid = find.byKey(
          const Key('blueprint-authoritative-grid-viewport'),
        );
        final before = tester.getRect(grid);
        final workspaceDock = find.byType(ArcBlueprintWorkspaceDock);
        expect(workspaceDock, findsOneWidget);

        final compactLandscape = size.width > size.height && size.height <= 720;
        final banner = find.byKey(const Key('blueprint-banner-slot'));
        if (compactLandscape) {
          expect(banner, findsNothing);
          expect(before.height, greaterThan(100));
          expect(before.overlaps(tester.getRect(workspaceDock)), isFalse);
        } else {
          expect(banner, findsOneWidget);
          expect(before.overlaps(tester.getRect(banner)), isFalse);
          expect(
            tester.getRect(banner).bottom,
            lessThanOrEqualTo(tester.getRect(workspaceDock).top),
          );
        }

        for (final phase in [1, 2, 0]) {
          creative.value = phase;
          await tester.pump();
          expect(tester.getRect(grid), before);
        }

        eligible.value = false;
        await tester.pump();
        expect(find.byKey(const Key('blueprint-banner-slot')), findsNothing);
        expect(
          tester.getRect(grid).height,
          greaterThanOrEqualTo(before.height),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
