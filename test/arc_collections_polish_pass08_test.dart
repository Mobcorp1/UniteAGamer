import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Designs retains 17 game-ordered columns and scrolls after three rows', (tester) async {
    tester.view.physicalSize = const Size(1100, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: ArcAdditionalCollectionsScreen(
      initialKind: ArcNativeCollectionKind.designs,
      adBanner: const SizedBox(height: 65, child: Text('TEST AD SLOT')),
      loader: (_) async => const ArcAdditionalCollectionState(),
      designNameLoader: () async => const <int, String>{},
    )));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byKey(
      const Key('collections-design-readable-gallery')));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 17);
    expect(grid.semanticChildCount, 100);
    expect(delegate.mainAxisExtent, greaterThan(90));
    expect(find.byKey(const Key('collections-saved-slot-1')), findsOneWidget);
    expect(find.byKey(const Key('collections-saved-slot-4')), findsOneWidget);
    expect(find.byKey(const Key('collections-saved-slot-18')), findsOneWidget);
    expect(find.text('Printed Lab Sofa'), findsOneWidget);
    expect(find.text('Multicolored Geometric Sofa'), findsOneWidget);
    expect(find.text('TEST AD SLOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stencil owned-item sheet fits compact landscape without overflow', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: ArcAdditionalCollectionsScreen(
      initialKind: ArcNativeCollectionKind.stencils,
      adBanner: const SizedBox(height: 50),
      loader: (_) async => ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(), ArcNativeCollectionKind.stencils,
        <int>{7}, const <int, int>{}),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collections-saved-slot-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collections-increase-dupes')), findsOneWidget);
    expect(find.byKey(const Key('collections-decrease-dupes')), findsOneWidget);
    expect(find.textContaining('Cosmetic tradeability'), findsNothing);
    expect(find.textContaining('Screenshot recognition does not'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dupes fits at least six thumbnail cards across landscape', (tester) async {
    tester.view.physicalSize = const Size(950, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 714, child: ArcCollectionDupeManager(
      collection: 'Blueprints',
      entries: List.generate(7, (index) => ArcCollectionDupeEntry(
        id: 'i$index', name: 'Item $index', owned: true,
        spares: index == 0 ? 999 : 1)),
      onAdjust: (_, _) async {},
    ))))));
    await tester.pump();
    final first = tester.getTopLeft(find.byKey(const Key('collections-dupe-card-i0')));
    final sixth = tester.getTopLeft(find.byKey(const Key('collections-dupe-card-i5')));
    expect(first.dy, sixth.dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Share preview omits owned inventory and promotes only spares and needed', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      Scaffold(body: TextButton(
        onPressed: () => ArcCollectionVisualShare.show(
          context: context, title: 'Blueprints',
          owned: const [ArcCollectionShareItem(label: 'Only owned')],
          needed: const [ArcCollectionShareItem(label: 'Wanted')],
          duplicates: const [ArcCollectionShareItem(label: 'Spare', spares: 2)],
        ), child: const Text('Share'),
      )),
    )));
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('SPARES FOR TRADE (1)'), findsOneWidget);
    expect(find.text('NEEDED (1)'), findsOneWidget);
    expect(find.textContaining('OWNED COLLECTION'), findsNothing);
    expect(find.text('Only owned'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
