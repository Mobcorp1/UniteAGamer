import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
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
  Future<void> publish(ArcAdminMapMarker marker) async {}

  @override
  Future<void> publishAll(Iterable<ArcAdminMapMarker> markers) async {}

  @override
  String exportJson(Iterable<ArcAdminMapMarker> markers) => '[]';
}

void main() {
  testWidgets('Admin Map Editor exposes calibration and Intel controls', (
    tester,
  ) async {
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
    expect(find.text('Publish Selected'), findsOneWidget);
  });
}
