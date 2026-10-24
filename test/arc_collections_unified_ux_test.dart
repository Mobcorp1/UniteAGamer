import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_reference_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '100 sourced Design names are unique; unknown game positions remain unassigned',
    () {
      expect(ArcDesignReferenceCatalogue.names.length, 100);
      expect(ArcDesignReferenceCatalogue.names.toSet().length, 100);
      expect(ArcDesignReferenceCatalogue.names, contains('Winter Table'));
      expect(
        ArcDesignReferenceCatalogue.names,
        contains('Study Armchair (Legendary)'),
      );
      expect(
        ArcDesignReferenceCatalogue.inGameNameForSlot(1, const {}),
        isNull,
      );
    },
  );

  for (final category in ArcCollectionsCategory.values) {
    testWidgets('Dupes tab appears after ${category.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArcCollectionsCategoryBar(
              selected: category,
              showDupes: true,
              onSelected: (_) {},
              onDupesSelected: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('collections-tab-dupes')), findsOneWidget);
      final names = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .toList();
      final idx = names.indexOf(category.name.toUpperCase());
      expect(idx, greaterThanOrEqualTo(0));
      expect(names[idx + 1], 'DUPES');
    });
  }

  testWidgets('Dupe search finds an unlisted owned item and saves +/-', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1040, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var spares = 0;
    Widget screen() => MaterialApp(
      home: Scaffold(
        body: ArcCollectionDupeManager(
          collection: 'Blueprints',
          entries: [
            ArcCollectionDupeEntry(
              id: 'a',
              name: 'Anvil',
              owned: true,
              spares: spares,
            ),
            const ArcCollectionDupeEntry(
              id: 'b',
              name: 'Bettina',
              owned: true,
              spares: 0,
            ),
          ],
          onAdjust: (id, delta) async {
            expect(id, 'a');
            spares += delta;
          },
        ),
      ),
    );
    await tester.pumpWidget(screen());
    expect(find.byKey(const Key('collections-dupes-search')), findsOneWidget);
    expect(find.textContaining('No spare copies saved yet'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('collections-dupes-search')),
      'Anv',
    );
    await tester.pump();
    expect(find.text('Anvil'), findsOneWidget);
    expect(find.text('Bettina'), findsNothing);
    await tester.tap(find.byKey(const Key('collections-dupe-plus-a')));
    await tester.pump();
    await tester.pumpWidget(screen());
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('collections-dupe-minus-a')));
    await tester.pump();
    await tester.pumpWidget(screen());
    await tester.pump();
    expect(spares, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Stencils persist one spare immediately, without changing owned slots',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var saved = ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(),
        ArcNativeCollectionKind.stencils,
        const <int>{2},
        const <int, int>{},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ArcAdditionalCollectionsScreen(
            initialKind: ArcNativeCollectionKind.stencils,
            adBanner: const SizedBox(
              height: 52,
              child: Text('Real ad injection test'),
            ),
            loader: (_) async => saved,
            saver: (_, slots, dupes) async =>
                saved = ArcAdditionalCollectionState.merge(
                  saved,
                  ArcNativeCollectionKind.stencils,
                  slots,
                  dupes,
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('collections-saved-slot-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final addDupe = find.byKey(const Key('collections-quick-add-dupe'));
      await tester.ensureVisible(addDupe);
      await tester.pump();
      await tester.tap(addDupe);
      await tester.pump(const Duration(milliseconds: 500));
      expect(saved.ownedSlots, contains(2));
      expect(saved.ownedSlots.length, 1);
      expect(saved.duplicateCounts[2], 1);
      expect(find.text('Real ad injection test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
