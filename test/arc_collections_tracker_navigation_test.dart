import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_collections_tracker_screen.dart';

void main() {
  testWidgets('Collections Tracker exposes every collection and update action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: ArcCollectionsTrackerScreen(previewMode: true),
    ));
    expect(find.text('COLLECTIONS TRACKER'), findsOneWidget);
    expect(find.byKey(const Key('collections-tracker-blueprints')), findsOneWidget);
    expect(find.byKey(const Key('collections-tracker-stencils')), findsOneWidget);
    expect(find.byKey(const Key('collections-tracker-designs')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('collections-tracker-manage-blueprints')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('collections-tracker-scan')), findsOneWidget);
    expect(find.byKey(const Key('collections-tracker-manage-blueprints')), findsOneWidget);
  });

  test('Collections Tracker has an independent route and visible launchers', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('ArcCollectionsTrackerScreen'));
    expect(main, contains('case BlueprintGridScreen.routeName:'));
    expect(main, contains('case ArcCollectionsTrackerScreen.routeName:'));
    expect(main, contains('const ArcCollectionsTrackerScreen()'));
    final hub = File('lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart').readAsStringSync();
    expect(hub, contains('Collections Tracker'));
    expect(hub, contains('BlueprintGridScreen.routeName'));
    // The Favourite Loadout item picker depends on the legacy route's args.
    final loadout = File('lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart').readAsStringSync();
    expect(loadout, contains('BlueprintGridTargetPickArgs'));
    expect(loadout, contains('BlueprintGridScreen.routeName'));
    expect(loadout, isNot(contains('ArcCollectionsTrackerScreen.routeName')));
    expect(loadout, contains('blueprint_grid_screen.dart'));
  });
}
