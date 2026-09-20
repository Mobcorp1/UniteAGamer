import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

ArcRaidIntelligenceScreen screen({
  Stream<Map<String, ArcBlueprintState>> Function()? states,
}) => ArcRaidIntelligenceScreen(
  blueprintStates: states ?? () => Stream.value({}),
  favouriteLoadout: () => Stream.value(null),
  dropReports: () => Stream.value([]),
  communityReports: (_) => Stream.value([]),
  publishedMarkers: (_) => Stream.value([]),
  loadActiveRoute: () async => null,
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(390, 844),
    const Size(640, 360),
    const Size(740, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1280, 900),
    const Size(1600, 1000),
  ]) {
    testWidgets('map workspace ${size.width} x ${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: screen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final map = tester.getRect(find.byKey(const Key('raid-map-viewport')));
      expect(map.height, greaterThan(size.height * .48));
      expect(map.width, greaterThan(size.width * .7));
      for (final label in ['Zoom in', 'Zoom out', 'Fit map', 'Map tools']) {
        expect(find.byTooltip(label).hitTestable(), findsOneWidget);
      }
      final controls = tester.getRect(
        find.byKey(const Key('map-zoom-controls')),
      );
      final route = tester.getRect(find.byKey(const Key('map-route-strip')));
      expect(controls.overlaps(route), isFalse);
      if (find.byKey(const Key('map-layer-selector')).evaluate().isNotEmpty) {
        final layer = tester.getRect(
          find.byKey(const Key('map-layer-selector')),
        );
        expect(controls.overlaps(layer), isFalse);
        expect(route.overlaps(layer), isFalse);
      }
      final renderer = tester.widget<ArcRaidIntelligenceMapRenderer>(
        find.byType(ArcRaidIntelligenceMapRenderer),
      );
      renderer.onMarkerSelected!(
        const ArcRaidMapMarker(
          id: 'fixture',
          mapId: 'blue_gate',
          category: ArcRaidMapMarkerCategory.poi,
          label: 'Selected location fixture',
          point: ArcNormalizedPoint(x: .5, y: .5),
          detail: 'Useful location context',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Selected location fixture'), findsOneWidget);
      expect(find.text('Useful location context'), findsOneWidget);
      expect(
        find.text('Selected location fixture').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  }
  testWidgets('map stream failure remains explicit with map usable and retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: screen(
          states: () {
            attempts++;
            return attempts == 1
                ? Stream.error(StateError('offline'))
                : Stream.value({});
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.textContaining('Some intel sources unavailable'),
      findsOneWidget,
    );
    expect(find.byTooltip('Zoom in').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(attempts, 2);
    expect(find.textContaining('Some intel sources unavailable'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
