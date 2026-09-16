import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_admin_workspace_bar.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('admin family exposes one compact navigation contract', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_admin_workspace_bar.dart',
    );

    expect(source, contains('enum ArcAdminWorkspace'));
    expect(source, contains('console, mapIntel, mapIcons'));
    expect(source, contains("return '/admin-console';"));
    expect(source, contains("return '/admin-map-intel-editor';"));
    expect(source, contains("return '/admin-map-filter-icons';"));
    expect(source, contains('rootNavigator: true'));
    expect(source, isNot(contains('FirebaseFirestore')));
    expect(source, isNot(contains('ArcAdminMapEditorRepository')));
  });

  test('admin console joins workspace without replacing access authority', () {
    final source = read('lib/screens/build/admin_console_screen.dart');

    expect(source, contains('ArcAdminWorkspaceBar('));
    expect(source, contains('ArcAdminWorkspace.console'));
    expect(
      source,
      contains("userData['isAdmin'] == true || userData['isDev'] == true"),
    );
    expect(source, contains(".collection('config')"));
    expect(source, contains(".doc('feature_access')"));
    expect(source, contains('FeatureAccess.updatePayloadForAvailability'));
    expect(source, contains('UagReleaseReadinessPanel'));
    expect(source, contains('UagAdminBroadcastPanel'));
    expect(source, contains('ArcRaiderContractsAdminPanel'));
  });

  test('map intel editor joins admin family and preserves repository wiring', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart',
    );

    expect(source, contains('ArcAdminWorkspaceBar('));
    expect(source, contains('ArcAdminWorkspace.mapIntel'));
    expect(source, contains('ArcAdminMapEditorRepository'));
    expect(source, contains('_repository.saveDraftMarkers('));
    expect(source, contains('_repository.publishAll('));
    expect(source, contains('_repository.saveImportCache('));
    expect(source, contains('_repository.archive('));
  });

  test('map icon atlas joins admin family and preserves taxonomy authority', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_map_filter_icon_review_screen.dart',
    );

    expect(source, contains('ArcAdminWorkspaceBar('));
    expect(source, contains('ArcAdminWorkspace.mapIcons'));
    expect(source, contains('ArcMapFilterTaxonomy.arc'));
    expect(source, contains('ArcMapFilterTaxonomy.extraction'));
    expect(source, contains('ArcMapFilterTaxonomy.loot'));
    expect(
      source,
      contains('ArcMapFilterIconRegistry.communityReportRatIconKey'),
    );
  });

  testWidgets('admin workspace bar remains usable at Sony-class width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: ArcAdminWorkspaceBar(
              current: ArcAdminWorkspace.console,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONSOLE'), findsOneWidget);
    expect(find.text('MAP INTEL'), findsOneWidget);
    expect(find.text('MAP ICONS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
