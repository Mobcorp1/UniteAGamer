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
  _FakeAdminMapEditorRepository({
    this.initialMarkers = const <ArcAdminMapMarker>[],
  });

  final List<ArcAdminMapMarker> initialMarkers;
  final List<ArcAdminMapMarker> savedMarkers = <ArcAdminMapMarker>[];

  @override
  Future<List<ArcAdminMapMarker>> loadDrafts(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    return initialMarkers
        .where((marker) => marker.mapId == mapId && marker.layer == layer)
        .toList(growable: false);
  }

  @override
  Future<void> saveDrafts(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {}

  @override
  Future<ArcAdminMapEditorSaveResult> saveDraftMarkers(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {
    savedMarkers
      ..clear()
      ..addAll(
        markers.where(
          (marker) => marker.mapId == mapId && marker.layer == layer,
        ),
      );
    return ArcAdminMapEditorSaveResult(
      collectionPath: ArcAdminMapEditorRepository.collectionName,
      savedCount: savedMarkers.length,
      savedAt: DateTime.utc(2026, 7, 29, 12),
    );
  }

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
  Future<void> archive(String markerId) async {}

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
    final repository = _FakeAdminMapEditorRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ArcAdminMapEditorScreen(
          repository: repository,
          appBar: AppBar(title: const Text('Admin Map & Intel Editor')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Admin Map & Intel Editor'), findsOneWidget);
    expect(find.text('Add POI'), findsOneWidget);
    expect(find.text('Add Historical Blueprint'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Import JSON'), findsOneWidget);
    expect(find.text('Populate UAG World'), findsOneWidget);
    expect(find.text('UAG MARKER PALETTE'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(find.text('Resource'), findsOneWidget);
    expect(find.text('ARC Spawn'), findsOneWidget);
    expect(find.text('Containers'), findsOneWidget);
    expect(find.text('Hazard'), findsOneWidget);
    expect(find.text('Publish Selected'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('IMPORT PIPELINE'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('IMPORT PIPELINE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Confidence filter'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Confidence filter'), findsOneWidget);
    expect(find.text('Source permission'), findsOneWidget);
    expect(find.text('Evidence type'), findsOneWidget);
    expect(find.text('Grid'), findsOneWidget);

    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();
    expect(repository.savedMarkers, isNotEmpty);
    expect(find.textContaining('Draft saved successfully'), findsOneWidget);

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

  testWidgets('dragging a marker persists changed normalized coordinates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const marker = ArcAdminMapMarker(
      id: 'coordinate_test_marker',
      mapId: 'buried_city',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.poi,
      name: 'Coordinate Test Hospital',
      point: ArcNormalizedPoint(x: 0.25, y: 0.25),
    );
    final repository = _FakeAdminMapEditorRepository(
      initialMarkers: const <ArcAdminMapMarker>[marker],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ArcAdminMapEditorScreen(
          repository: repository,
          appBar: AppBar(title: const Text('Admin Map & Intel Editor')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final markerFinder = find.byKey(
      const ValueKey<String>('admin-map-marker-coordinate_test_marker'),
    );
    expect(markerFinder, findsOneWidget);

    await tester.drag(markerFinder, const Offset(120, 80));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();

    final saved = repository.savedMarkers.firstWhere(
      (item) => item.id == marker.id,
    );
    expect(saved.point.x, isNot(closeTo(marker.point.x, 0.001)));
    expect(saved.point.y, isNot(closeTo(marker.point.y, 0.001)));
    expect(saved.point.x, inInclusiveRange(0.0, 1.0));
    expect(saved.point.y, inInclusiveRange(0.0, 1.0));
  });
}
