import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_location_picker.dart';
import 'arc_raid_endpoint_resolver_test.dart' show spawn, exit;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'live markers replace choices, map taps select endpoints, chosen exit survives new spawn and is invalidated on unpublish',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stream = StreamController<List<ArcAdminMapMarker>>();
      addTearDown(stream.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ArcRaidIntelligenceScreen(
            scrappyStates: () => Stream.value({}),
            progressionRecords: () => Stream.value(ArcProgressionRecords.empty),
            blueprintStates: () => Stream.value({
              for (final b in ArcBlueprintSeedData.blueprints)
                b.id: ArcBlueprintState(
                  blueprintId: b.id,
                  owned: true,
                  dupesOwned: 0,
                  priorityRank: 0,
                  updatedAt: null,
                ),
            }),
            favouriteLoadout: () => Stream.value(null),
            dropReports: () => Stream.value([]),
            communityReports: (_) => Stream.value([]),
            publishedMarkers: (_) => stream.stream,
            loadActiveRoute: () async => null,
          ),
        ),
      );
      await tester.pump();
      final second = spawn.copyWith(
        id: 'live-player-2',
        name: 'Second player spawn',
      );
      stream.add([spawn, second, exit]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      ArcRaidIntelligenceMapRenderer renderer() =>
          tester.widget(find.byType(ArcRaidIntelligenceMapRenderer));
      final initial = renderer();
      expect(
        initial.state.visibleMarkers
            .where((m) => m.category == ArcRaidMapMarkerCategory.spawn)
            .map((m) => m.payloadId),
        containsAll([spawn.id, second.id]),
      );
      expect(
        initial.state.visibleMarkers.any((m) => m.label.contains('Spawn Band')),
        isFalse,
      );
      initial.onMarkerSelected!(
        initial.state.visibleMarkers.firstWhere((m) => m.payloadId == spawn.id),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final pickers = tester
          .widgetList<ArcRaidLocationPicker>(find.byType(ArcRaidLocationPicker))
          .toList();
      final exitPicker = pickers.firstWhere(
        (p) => p.label == 'Planned Extraction',
      );
      expect(exitPicker.options.map((e) => e.id), [exit.id]);
      expect(
        find.textContaining('Confirm recommended extraction:'),
        findsOneWidget,
      );
      renderer().onMarkerSelected!(
        renderer().state.visibleMarkers.firstWhere(
          (m) => m.payloadId == exit.id,
        ),
      );
      await tester.pump();
      renderer().onMarkerSelected!(
        renderer().state.visibleMarkers.firstWhere(
          (m) => m.payloadId == second.id,
        ),
      );
      await tester.pump();
      expect(
        renderer().highlightedMarkerIds,
        containsAll([
          'endpoint_spawn_${second.id}',
          'endpoint_exit_${exit.id}',
        ]),
      );
      expect(
        find.textContaining('Confirm recommended extraction:'),
        findsNothing,
      );
      final chosen = tester
          .widgetList<ArcRaidLocationPicker>(find.byType(ArcRaidLocationPicker))
          .firstWhere((p) => p.label == 'Planned Extraction');
      expect(chosen.selected?.id, exit.id);
      stream.add([spawn, second]);
      // Endpoint reconciliation is intentionally post-frame. The map renderer can
      // schedule its own frame while the live marker stream is rebuilding, so
      // settle the queue before asserting the reconciled selection.
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final stale = tester
          .widgetList<ArcRaidLocationPicker>(find.byType(ArcRaidLocationPicker))
          .firstWhere((p) => p.label == 'Planned Extraction');
      expect(stale.selected, isNull);
      expect(find.textContaining('no longer published'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
