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
  ArcAdminMapMarker? movedMarker;
  bool failMove = false;
  int saveCalls = 0;
  int archiveCalls = 0;

  @override
  Future<ArcAdminMapMarker> updateMarker({
    required ArcAdminMapMarker original,
    required ArcAdminMapMarker edited,
  }) async {
    if (failMove) throw StateError("Persistence failed");
    movedMarker = edited;
    return edited;
  }

  final List<ArcAdminMapMarker> savedMarkers = <ArcAdminMapMarker>[];

  @override
  Future<List<ArcAdminMapMarker>> loadDrafts(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    return [
      for (final marker in savedMarkers.isEmpty ? initialMarkers : savedMarkers)
        if (marker.id == movedMarker?.id) movedMarker! else marker,
    ].where((marker) => marker.mapId == mapId).toList(growable: false);
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
    saveCalls++;
    savedMarkers
      ..clear()
      ..addAll(
        markers
            .map((marker) => ArcAdminMapMarker.fromMap(marker.toMap()))
            .where((marker) => marker.mapId == mapId && marker.layer == layer),
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
  Future<void> archive(String markerId) async {
    archiveCalls++;
  }

  @override
  Future<void> archiveAll(Iterable<String> markerIds) async {}

  @override
  Future<void> saveCoverageReport(ArcWorldIntelCoverageReport report) async {}

  @override
  String exportJson(Iterable<ArcAdminMapMarker> markers) => '[]';
}

void main() {
  for (final size in const [
    Size(320, 740),
    Size(430, 932),
    Size(640, 360),
    Size(740, 360),
    Size(844, 390),
    Size(768, 1024),
    Size(1024, 768),
    Size(1280, 900),
  ]) {
    testWidgets('canvas visibility is reversible and read-only at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final markers = [
        for (final kind in [
          ArcAdminMapMarkerKind.poi,
          ArcAdminMapMarkerKind.blueprint,
          ArcAdminMapMarkerKind.lootContainer,
          ArcAdminMapMarkerKind.resourceNode,
        ])
          ArcAdminMapMarker(
            id: 'visibility_${kind.name}',
            mapId: 'buried_city',
            layer: ArcRaidMapLayer.surface,
            kind: kind,
            name: kind.label,
            point: const ArcNormalizedPoint(x: .3, y: .4),
            description: 'Preserve metadata',
          ),
      ];
      final repository = _FakeAdminMapEditorRepository(initialMarkers: markers);
      await tester.pumpWidget(
        MaterialApp(
          home: ArcAdminMapEditorScreen(
            repository: repository,
            appBar: AppBar(title: const Text('Editor')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final pins = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('admin-map-marker-'),
      );
      final initialCount = pins.evaluate().length;
      expect(initialCount, greaterThanOrEqualTo(markers.length));
      final toggle = find.byKey(const Key('admin-map-toggle-items'));
      expect(toggle.hitTestable(), findsOneWidget);
      expect(find.text('Hide Icons'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(pins, findsNothing);
        expect(find.text('Show Icons'), findsOneWidget);
        expect(repository.saveCalls, 0);
        expect(repository.archiveCalls, 0);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(pins, findsNWidgets(initialCount));
      }
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      for (final marker in markers) {
        expect(
          repository.savedMarkers.singleWhere((m) => m.id == marker.id).toMap(),
          marker.toMap(),
        );
      }
      expect(
        repository.savedMarkers.map((m) => m.id).toSet().length,
        repository.savedMarkers.length,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(1400, 1000), Size(320, 740), Size(740, 360)]) {
    for (final example in [
      (
        kind: ArcAdminMapMarkerKind.upgrade,
        option: 'Scrappy • Dog Collar',
        label: 'Dog Collar',
        itemId: 'dog-collar',
        subtypeId: 'upgrade_dog_collar',
      ),
      (
        kind: ArcAdminMapMarkerKind.upgrade,
        option: 'Bench • Rusted Tools',
        label: 'Rusted Tools',
        itemId: 'rusted-tools',
        subtypeId: 'upgrade_rusted_tools',
      ),
      (
        kind: ArcAdminMapMarkerKind.lootContainer,
        option: 'Loot & Containers • Wheelie Bin',
        label: 'Wheelie Bin',
        itemId: null,
        subtypeId: 'wheelie_bin',
      ),
    ]) {
      testWidgets(
        '${example.label} can be created while hidden, saved, reloaded, edited, moved and deleted at $size',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = _FakeAdminMapEditorRepository();
          Future<void> tapVisible(Finder finder) async {
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            await tester.tap(finder);
            await tester.pumpAndSettle();
          }

          Future<void> openEditor() async {
            await tester.pumpWidget(
              MaterialApp(
                home: ArcAdminMapEditorScreen(
                  repository: repository,
                  appBar: AppBar(title: const Text('Editor')),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          await openEditor();
          await tester.tap(find.byKey(const Key('admin-map-toggle-items')));
          await tester.pumpAndSettle();
          await tapVisible(find.byKey(const Key('admin-map-create-poi')));
          await tester.pumpAndSettle();
          final canvas = find
              .descendant(
                of: find.byType(InteractiveViewer),
                matching: find.byType(Image),
              )
              .first;

          await tester.tap(
            find.byType(DropdownButtonFormField<ArcAdminMapMarkerKind>),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(example.kind.label),
            200,
            scrollable: find.byType(Scrollable).last,
            maxScrolls: 30,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(example.kind.label).last);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(ValueKey<ArcAdminMapMarkerKind>(example.kind)),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(example.option),
            200,
            scrollable: find.byType(Scrollable).last,
            maxScrolls: 40,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(example.option).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Place on Map'));
          await tester.pumpAndSettle();
          await tapVisible(canvas);
          await tester.pumpAndSettle();
          await tapVisible(find.text('Save Changes'));
          await tester.pumpAndSettle();
          final saved = repository.savedMarkers.singleWhere(
            (m) => m.subtypeId == example.subtypeId,
          );
          expect(saved.kind, example.kind);
          expect(saved.toMap()['kind'], example.kind.name);
          expect(saved.itemId, example.itemId);
          expect(saved.subtypeLabel, example.label);
          final pin = find.byKey(
            ValueKey<String>('admin-map-marker-${saved.id}'),
          );
          expect(pin, findsNothing);
          await tapVisible(find.byKey(const Key('admin-map-toggle-items')));
          await tester.pumpAndSettle();
          expect(pin, findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          await openEditor();
          expect(pin, findsOneWidget);
          expect(find.text('Hide Icons'), findsOneWidget);
          await tapVisible(pin);
          await tester.pumpAndSettle();
          await tapVisible(find.text('Edit Marker').first);
          await tester.pumpAndSettle();
          final field = tester.widget<DropdownButtonFormField<String?>>(
            find.byKey(ValueKey<ArcAdminMapMarkerKind>(example.kind)),
          );
          expect(field.initialValue, example.subtypeId);
          await tester.ensureVisible(find.widgetWithText(TextField, 'Name'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextField, 'Name'),
            '${example.label} edited',
          );
          await tester.tap(find.text('Apply Edit'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(pin);
          await tester.pumpAndSettle();
          await tester.drag(pin, const Offset(120, 80));
          await tester.pumpAndSettle();
          await tapVisible(find.text('Save Changes'));
          await tester.pumpAndSettle();
          final edited = repository.savedMarkers.singleWhere(
            (m) => m.id == saved.id,
          );
          expect(edited.name, '${example.label} edited');
          expect(edited.itemId, saved.itemId);
          expect(edited.subtypeId, saved.subtypeId);
          expect(edited.point.toMap(), isNot(saved.point.toMap()));
          await tapVisible(find.text('Delete Marker').first);
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(ElevatedButton, 'Archive POI').last,
          );
          await tester.pumpAndSettle();
          expect(pin, findsNothing);
          expect(repository.archiveCalls, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final outcome in ['cancel', 'success', 'failure']) {
    testWidgets('cross-layer edit $outcome preserves canonical marker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const marker = ArcAdminMapMarker(
        id: 'stable_published_poi',
        mapId: 'stella_montis',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Move Test POI',
        point: ArcNormalizedPoint(x: .25, y: .25),
        state: ArcAdminMapMarkerState.published,
        aliases: [' Old POI ', 'Old POI'],
        sourceLabel: '',
        subtypeId: 'future.catalogue.id',
        subtypeLabel: 'Future catalogue label',
        description: 'Keep description',
        seedReferenceId: 'canonical_poi',
      );
      final repo = _FakeAdminMapEditorRepository(initialMarkers: [marker])
        ..failMove = outcome == 'failure';
      await tester.pumpWidget(
        MaterialApp(
          home: ArcAdminMapEditorScreen(
            repository: repo,
            appBar: AppBar(title: const Text('Editor')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mapField = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(mapField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stella Montis').last);
      await tester.pumpAndSettle();
      final pin = find.byKey(
        const ValueKey('admin-map-marker-stable_published_poi'),
      );
      await tester.tap(pin);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Marker').first);
      await tester.pumpAndSettle();
      final layerField = find.byKey(const Key('edit-marker-layer'));
      final field = tester.widget<DropdownButtonFormField<ArcRaidMapLayer>>(
        layerField,
      );
      expect(field.initialValue, ArcRaidMapLayer.surface);
      await tester.tap(layerField);
      await tester.pumpAndSettle();
      expect(find.text('Layer 3'), findsNothing);
      await tester.tap(find.text('Level 2').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Edit'));
      await tester.pumpAndSettle();
      expect(
        find.text('Move Move Test POI from Surface to Level 2?'),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(
          outcome == 'cancel' ? TextButton : FilledButton,
          outcome == 'cancel' ? 'Cancel' : 'Move marker',
        ),
      );
      await tester.pumpAndSettle();
      if (outcome == 'success') {
        expect(pin, findsNothing);
        final saved = repo.movedMarker!;
        expect(saved.id, marker.id);
        expect(saved.state, ArcAdminMapMarkerState.published);
        expect(saved.point.toMap(), marker.point.toMap());
        expect(saved.aliases, marker.aliases);
        expect(saved.sourceLabel, marker.sourceLabel);
        expect(saved.subtypeId, marker.subtypeId);
        expect(saved.subtypeLabel, marker.subtypeLabel);
        expect(saved.seedReferenceId, marker.seedReferenceId);
        final layerSelector = find.byType(
          DropdownButtonFormField<ArcRaidMapLayer>,
        );
        await tester.tap(layerSelector.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Level 2').last);
        await tester.pumpAndSettle();
        expect(pin, findsOneWidget);
      } else {
        expect(repo.movedMarker, isNull);
        expect(pin, findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

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
    expect(find.text('Add Map Point'), findsOneWidget);
    expect(find.text('Add Blueprint Location'), findsOneWidget);
    expect(find.text('UAG MARKER PALETTE'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(find.text('Resource'), findsOneWidget);
    expect(find.text('ARC Spawn'), findsOneWidget);
    expect(find.text('Containers'), findsOneWidget);
    expect(find.text('Hazard'), findsOneWidget);
    expect(find.text('Publish Marker'), findsOneWidget);
    expect(find.text('Edit Marker'), findsOneWidget);
    expect(find.text('Delete Marker'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    final mapEditorScrollable = find
        .descendant(
          of: find.byKey(const Key('map-editor-precision-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> reveal(String text) async {
      final state = tester.state<ScrollableState>(mapEditorScrollable);

      while (find.text(text).evaluate().isEmpty &&
          state.position.pixels < state.position.maxScrollExtent) {
        final next = (state.position.pixels + 300).clamp(
          0.0,
          state.position.maxScrollExtent,
        );
        state.position.jumpTo(next);
        await tester.pumpAndSettle();
      }

      expect(find.text(text), findsWidgets);
    }

    await reveal('ADVANCED MAP TOOLS');
    await tester.tap(find.text('ADVANCED MAP TOOLS'));
    await tester.pumpAndSettle();
    expect(find.text('Export Marker Data'), findsOneWidget);
    expect(find.text('Import Marker Data'), findsOneWidget);
    expect(find.text('Process Imported Map Data'), findsOneWidget);

    await reveal('FILTER MARKERS');
    await tester.tap(find.text('FILTER MARKERS').first);
    await tester.pumpAndSettle();
    await reveal('Confidence filter');
    expect(find.text('Confidence filter'), findsOneWidget);
    expect(find.text('Source permission'), findsOneWidget);
    expect(find.text('Evidence type'), findsOneWidget);
    expect(find.text('Grid'), findsOneWidget);

    await tester.tap(find.text('Save Changes'));
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

    await tester.tap(markerFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Marker').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-marker-layer')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.drag(markerFinder, const Offset(120, 80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
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
