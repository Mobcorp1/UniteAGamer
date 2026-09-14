import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart';

class _BlueprintRepo extends Fake implements ArcBlueprintRepository {
  @override
  Stream<ArcDropIntel> watchIntelForBlueprint(String id) =>
      const Stream.empty();
}

class _Markers extends ArcAdminMapEditorRepository {
  final updates = StreamController<List<ArcAdminMapMarker>>.broadcast();
  String? requestedMap;
  @override
  Stream<List<ArcAdminMapMarker>> watchPublishedMap(String mapId) {
    requestedMap = mapId;
    return updates.stream;
  }
}

void main() {
  testWidgets(
    'report picker uses live published map locations and retains selection by ID',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final markers = _Markers();
      addTearDown(markers.updates.close);
      final blueprint = ArcBlueprintSeedData.blueprints.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArcBlueprintDropReportSheet(
              blueprint: blueprint,
              initialState: ArcBlueprintState.empty(blueprint.id),
              repository: _BlueprintRepo(),
              markerRepository: markers,
              rarityColor: Colors.cyan,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      await tap('Drop Report');
      await tap('Select Source');
      await tap('Found Personally');
      await tap('Select Map');
      await tap('Stella Montis');
      expect(markers.requestedMap, 'stella_montis');
      const poi = ArcAdminMapMarker(
        id: 'actual_document',
        mapId: 'stella_montis',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Live Town Hall',
        point: ArcNormalizedPoint(x: .2, y: .3),
        state: ArcAdminMapMarkerState.published,
      );
      markers.updates.add([
        poi,
        poi.copyWith(
          id: 'draft',
          name: 'Draft Place',
          state: ArcAdminMapMarkerState.draft,
        ),
        poi.copyWith(
          id: 'other',
          name: 'Other Map Place',
          mapId: 'buried_city',
        ),
        poi.copyWith(
          id: 'loot',
          name: 'Weapon Case',
          kind: ArcAdminMapMarkerKind.weaponCase,
        ),
      ]);
      await tester.pumpAndSettle();
      await tap('Select Area / POI');
      expect(find.text('Live Town Hall'), findsOneWidget);
      expect(find.text('Draft Place'), findsNothing);
      expect(find.text('Other Map Place'), findsNothing);
      expect(find.text('Weapon Case'), findsNothing);
      await tap('Live Town Hall');
      markers.updates.add([
        poi.copyWith(
          name: 'Renamed Town Hall',
          layer: ArcRaidMapLayer.underground,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Renamed Town Hall'), findsOneWidget);
      expect(find.text('Live Town Hall'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
