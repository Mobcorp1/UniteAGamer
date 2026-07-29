import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart';

class _FakeAdminMapEditorRepository extends ArcAdminMapEditorRepository {
  _FakeAdminMapEditorRepository();

  @override
  Future<List<ArcAdminMapMarker>> loadDrafts(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    return const <ArcAdminMapMarker>[];
  }

  @override
  Future<void> saveDrafts(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {}

  @override
  Future<List<ArcAdminMapMarker>> loadImportCache(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    return const <ArcAdminMapMarker>[];
  }

  @override
  Future<void> saveImportCache(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {}

  @override
  Future<List<ArcBlueprintDropReport>> loadRecentDropReports({
    int limit = 500,
  }) async {
    return const <ArcBlueprintDropReport>[];
  }

  @override
  Future<List<ArcCommunityIntelReport>> loadCommunityReports({
    int limit = 500,
  }) async {
    return const <ArcCommunityIntelReport>[];
  }

  @override
  Future<void> publish(ArcAdminMapMarker marker) async {}

  @override
  Future<void> publishAll(Iterable<ArcAdminMapMarker> markers) async {}

  @override
  Future<void> archiveAll(Iterable<String> markerIds) async {}

  @override
  Future<void> saveCoverageReport(ArcWorldIntelCoverageReport report) async {}

  @override
  String exportJson(Iterable<ArcAdminMapMarker> markers) => '[]';
}

void main() {
  testWidgets('Admin Map Editor exposes calibration and Intel controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ArcAdminMapEditorScreen(
          repository: _FakeAdminMapEditorRepository(),
          appBar: AppBar(title: const Text('Admin Map & Intel Editor')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Admin Map & Intel Editor'), findsOneWidget);
    expect(find.text('New Intel'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Import JSON'), findsOneWidget);
    expect(find.text('Populate UAG World'), findsOneWidget);
    expect(find.text('IMPORT PIPELINE'), findsOneWidget);
    expect(find.text('Publish Selected'), findsOneWidget);
    expect(find.text('Confidence filter'), findsOneWidget);
    expect(find.text('Source permission'), findsOneWidget);
    expect(find.text('Evidence type'), findsOneWidget);
    expect(find.text('Grid'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Dam Battlegrounds'), findsWidgets);
    expect(find.text('Spaceport'), findsWidgets);

    await tester.tap(find.text('Spaceport').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<ArcRaidMapLayer>).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsWidgets);
  });
}
