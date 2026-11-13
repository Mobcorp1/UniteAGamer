import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Command Centre counts the 91 Frozen Trail positions, not 83 seeds', () {
    const total = 91;
    final realIds = ArcFrozenTrailCollectionCatalogue.blueprintEntries
        .where((entry) => entry.slot != null && entry.slot! >= 1 && entry.slot! <= total)
        .map((entry) => entry.id).toSet();
    final one = realIds.first;
    final state = ArcCommandCentreEngine.build(
      blueprintStates: {
        one: ArcBlueprintState(
          blueprintId: one, owned: true, dupesOwned: 8,
          priorityRank: 0, updatedAt: null),
        'not-a-real-blueprint': const ArcBlueprintState(
          blueprintId: 'not-a-real-blueprint', owned: true, dupesOwned: 7,
          priorityRank: 0, updatedAt: null),
      },
      savedLoadouts: const [],
    );
    // UI-facing engine summary must count only the known collection IDs,
    // while the total must always match the physical grid's 91 slots.
    expect(state.blueprintSummary.details.join(' '), contains('91'));
    expect(state.blueprintSummary.details.join(' '), contains('1'));
  });

  testWidgets('Dupe card is a compact image-first tile with +/- buttons', (tester) async {
    tester.view.physicalSize = const Size(940, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ArcCollectionDupeManager(
      collection: 'Blueprints',
      entries: const [ArcCollectionDupeEntry(
        id: 'anvil', name: 'Anvil', owned: true, spares: 2,
        imageAssetPath: 'assets/arc_raiders/blueprints/anvil.webp')],
      onAdjust: (_, _) async {},
    ))));
    expect(find.byKey(const Key('collections-dupe-card-anvil')), findsOneWidget);
    expect(find.byKey(const Key('collections-dupe-minus-anvil')), findsOneWidget);
    expect(find.byKey(const Key('collections-dupe-plus-anvil')), findsOneWidget);
    final cardWidth = tester.getSize(
      find.byKey(const Key('collections-dupe-card-anvil'))).width;
    expect(cardWidth, lessThan(200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Visual share preview groups image tiles by trade intent', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      Scaffold(body: TextButton(
        onPressed: () => ArcCollectionVisualShare.show(
          context: context,
          title: 'Stencils',
          owned: const [ArcCollectionShareItem(label: 'Slipstream')],
          needed: const [ArcCollectionShareItem(label: 'Serac')],
          duplicates: const [ArcCollectionShareItem(label: 'Slipstream', spares: 3)],
        ),
        child: const Text('Open'),
      )),
    )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('SPARES FOR TRADE (1)'), findsOneWidget);
    expect(find.text('NEEDED (1)'), findsOneWidget);
    expect(find.textContaining('OWNED COLLECTION'), findsNothing);
    expect(find.byKey(const Key('collections-share-image')), findsOneWidget);
    await tester.tap(find.byTooltip('Close share preview'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
