import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const <Size>[Size(1100, 600), Size(844, 390)]) {
    testWidgets('PASS30 fits two Design rows and balances controls at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ArcAdditionalCollectionsScreen(
          initialKind: ArcNativeCollectionKind.designs,
          loader: (_) async => const ArcAdditionalCollectionState(),
          designNameLoader: () async => const <int, String>{},
          adBanner: const SizedBox(
            width: 320,
            height: 50,
            child: Text('TEST 320x50 AD'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final gridFinder =
          find.byKey(const Key('collections-design-readable-gallery'));
      final grid = tester.widget<GridView>(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 17);
      expect(grid.semanticChildCount, 100);
      final viewportHeight = tester.getSize(gridFinder).height;
      // Exactly two fully visible rows, including all grid padding and gap.
      expect(delegate.mainAxisExtent,
          closeTo((viewportHeight - 10 - 3) / 2, 0.2));

      expect(find.text('01'), findsNothing);
      expect(find.text('02'), findsNothing);
      expect(find.byKey(const Key('collections-saved-slot-1')), findsOneWidget);
      expect(find.byKey(const Key('collections-saved-slot-18')), findsOneWidget);
      expect(find.byKey(const Key('collections-designs-bottom-dock')),
          findsOneWidget);
      expect(find.byKey(const Key('collections-design-fitted-ad')),
          findsOneWidget);
      expect(find.text('TEST 320x50 AD'), findsOneWidget);

      final ad = tester.getRect(
          find.byKey(const Key('collections-design-fitted-ad')));
      expect(ad.width, inInclusiveRange(326.0, 344.0));
      final left = tester
          .getRect(find.byKey(const Key('collections-filter-all')));
      final needed = tester
          .getRect(find.byKey(const Key('collections-filter-needed')));
      final camera = tester
          .getRect(find.byKey(const Key('collections-upload-native-screenshot')));
      final share =
          tester.getRect(find.byKey(const Key('collections-share')));
      expect(left.right, lessThan(needed.left));
      expect(needed.right, lessThan(ad.left));
      expect(ad.right, lessThan(camera.left));
      expect(camera.right, lessThan(share.left));
      expect(find.byKey(const Key('collections-filter-needed')), findsOneWidget);
      expect(find.byKey(const Key('collections-save-continue')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PASS30 keeps Stencils original tools rail untouched',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: ArcAdditionalCollectionsScreen(
        initialKind: ArcNativeCollectionKind.stencils,
        loader: (_) async => const ArcAdditionalCollectionState(),
        adBanner: const SizedBox(height: 50, child: Text('STENCIL AD')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collections-designs-bottom-dock')),
        findsNothing);
    expect(find.byKey(const Key('collections-pinch-zoom-grid')),
        findsOneWidget);
    expect(find.byKey(const Key('collections-filter-all')), findsOneWidget);
    expect(find.text('STENCIL AD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('PASS30 preserves save, ownership and original design slot identity', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    expect(source, contains('final slot = index + 1;'));
    expect(source, contains('itemCount: _kind.slots'));
    expect(source, contains('ArcDesignReferenceCatalogue.nameAt(slot)'));
    expect(source, contains('onPressed: _loaded && !_busy ? _saveAndContinue : null'));
    expect(source, contains('physics: const AlwaysScrollableScrollPhysics()'));
    expect(source, isNot(contains("slot.toString().padLeft(2, '0')")));
  });
}
