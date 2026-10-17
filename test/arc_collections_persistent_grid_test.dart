import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Stencil catalogue maps user-confirmed lowercase WebP names and slots', () {
    expect(ArcStencilCatalogue.names.length, 14);
    expect(ArcStencilCatalogue.assetAt(2), 'assets/arc_raiders/blueprints/slipstream.webp');
    expect(ArcStencilCatalogue.assetAt(3), 'assets/arc_raiders/blueprints/tortoise.webp');
    expect(ArcStencilCatalogue.assetAt(5), 'assets/arc_raiders/blueprints/milky-terracotta.webp');
    expect(ArcStencilCatalogue.assetAt(6), 'assets/arc_raiders/blueprints/curulean.webp');
    expect(ArcStencilCatalogue.assetAt(7), 'assets/arc_raiders/blueprints/dusty-camo.webp');
    expect(ArcStencilCatalogue.assetAt(9), 'assets/arc_raiders/blueprints/dragons-breath.webp');
  });

  test('Native screenshot ownership remains additive and duplicates stay manual', () {
    const kind = ArcNativeCollectionKind.stencils;
    final first = ArcAdditionalCollectionState.merge(
      const ArcAdditionalCollectionState(), kind, <int>{2,3,5,6,7,9}, const {},
    );
    expect(first.ownedSlots.length, 6);
    expect(first.duplicateTotal, 0);
    final withManualDupe = ArcAdditionalCollectionState.merge(
      first, kind, const <int>{}, const <int,int>{2: 2},
    );
    expect(withManualDupe.duplicateCounts[2], 2);
    final secondScreenshot = ArcAdditionalCollectionState.merge(
      withManualDupe, kind, const <int>{3}, const {},
    );
    expect(secondScreenshot.ownedSlots.length, 6);
    expect(secondScreenshot.duplicateCounts[2], 2);
    final removeDupe = ArcAdditionalCollectionState.merge(
      secondScreenshot, kind, const {}, const <int,int>{2:0},
    );
    expect(removeDupe.ownedSlots.contains(2), isTrue);
    expect(removeDupe.duplicateCounts, isEmpty);
    expect(() => ArcAdditionalCollectionState.merge(first, kind, <int>{99}, const {}), throwsRangeError);
  });

  test('Save and Continue can finish without any NEW owned slots', () {
    const kind = ArcNativeCollectionKind.stencils;
    final prior = ArcAdditionalCollectionState.merge(
      const ArcAdditionalCollectionState(), kind, <int>{2,3,5,6,7,9}, const {},
    );
    final noChange = ArcAdditionalCollectionState.merge(
      prior, kind, <int>{2,3}, const {},
    );
    expect(noChange.ownedSlots, prior.ownedSlots);
  });

  testWidgets('Saved Stencils show individual cards, filters and a debug ad layout', (tester) async {
    tester.view.physicalSize = const Size(1100, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    await tester.pumpWidget(MaterialApp(home: ArcAdditionalCollectionsScreen(
      initialKind: ArcNativeCollectionKind.stencils,
      adBanner: const SizedBox(height: 52, child: Text('TEST AD SLOT')),
      loader: (_) async => ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(), ArcNativeCollectionKind.stencils,
        <int>{2,3,5,6,7,9}, const <int,int>{2:1},
      ),
      saver: (_, slots, dupes) async => ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(), ArcNativeCollectionKind.stencils,
        slots, dupes,
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collections-tab-stencils')), findsOneWidget);
    expect(find.byKey(const Key('collections-tab-designs')), findsOneWidget);
    expect(find.byKey(const Key('collections-saved-slot-2')), findsOneWidget);
    expect(find.byKey(const Key('collections-saved-slot-14')), findsOneWidget);
    expect(find.byKey(const Key('collections-upload-native-screenshot')), findsOneWidget);
    expect(find.byKey(const Key('collections-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('collections-filter-needed')), findsOneWidget);
    expect(find.byKey(const Key('collections-tab-dupes')), findsOneWidget);
    expect(find.byKey(const Key('collections-share')), findsOneWidget);
    expect(find.byKey(const Key('collections-pinch-zoom-grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('collections-filter-needed')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('collections-tab-dupes')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('collections-tab-designs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collections-design-readable-gallery')), findsOneWidget);
    expect(find.byKey(const Key('collections-saved-slot-1')), findsOneWidget);
    final designs = tester.widget<GridView>(
      find.byKey(const Key('collections-design-readable-gallery')),
    );
    expect(designs.semanticChildCount, 100);
    // In-game slot order is preserved but rendered in a 3-column scroll.

    expect(find.text('TEST AD SLOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
