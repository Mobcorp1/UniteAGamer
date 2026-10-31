import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const <Size>[Size(1100, 600), Size(844, 390)]) {
    testWidgets('PASS32 Stencils ad is fitted between bottom controls at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ArcAdditionalCollectionsScreen(
          initialKind: ArcNativeCollectionKind.stencils,
          adBanner: const SizedBox(
            width: 320,
            height: 50,
            child: Text('STENCIL TEST 320x50 AD'),
          ),
          loader: (_) async => ArcAdditionalCollectionState.merge(
            const ArcAdditionalCollectionState(),
            ArcNativeCollectionKind.stencils,
            <int>{1, 4, 6},
            const <int, int>{},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('collections-stencils-bottom-dock')), findsOneWidget);
      expect(find.byKey(const Key('collections-designs-bottom-dock')), findsNothing);
      expect(find.byKey(const Key('collections-stencil-fitted-ad')), findsOneWidget);
      expect(find.byKey(const Key('collections-stencil-owned-count')), findsOneWidget);
      expect(find.text('STENCIL TEST 320x50 AD'), findsOneWidget);
      expect(find.byKey(const Key('collections-pinch-zoom-grid')), findsOneWidget);
      expect(find.byKey(const Key('collections-saved-slot-1')), findsOneWidget);
      expect(find.byKey(const Key('collections-saved-slot-14')), findsOneWidget);

      final ad = tester.getRect(find.byKey(const Key('collections-stencil-fitted-ad')));
      final all = tester.getRect(find.byKey(const Key('collections-filter-all')));
      final needed = tester.getRect(find.byKey(const Key('collections-filter-needed')));
      final camera = tester.getRect(
        find.byKey(const Key('collections-upload-native-screenshot')));
      final share = tester.getRect(find.byKey(const Key('collections-share')));

      expect(ad.width, inInclusiveRange(326.0, 344.0));
      expect(all.right, lessThan(needed.left));
      expect(needed.right, lessThan(ad.left));
      expect(ad.right, lessThan(camera.left));
      expect(camera.right, lessThan(share.left));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('collections-filter-needed')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('collections-filter-all')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PASS32 Stencils preserve saved quantities and tab switching',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const saved = ArcAdditionalCollectionState(
      ownedSlots: <int>{1, 2},
      duplicateCounts: <int, int>{2: 1},
    );
    await tester.pumpWidget(MaterialApp(
      home: ArcAdditionalCollectionsScreen(
        initialKind: ArcNativeCollectionKind.stencils,
        adBanner: const SizedBox(width: 320, height: 50),
        loader: (_) async => saved,
        designNameLoader: () async => const <int, String>{},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('2/14 OWNED'), findsOneWidget);
    expect(find.byKey(const Key('collections-saved-slot-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('collections-tab-designs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collections-designs-bottom-dock')), findsOneWidget);
    expect(find.byKey(const Key('collections-stencils-bottom-dock')), findsNothing);
    expect(find.byKey(const Key('collections-design-readable-gallery')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('PASS32 changes presentation only, not stencil ordering or persistence', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    expect(screen, contains('Widget _collectionsBottomDock(bool hasPending)'));
    expect(screen, contains('bottomNavigationBar: _collectionsBottomDock(hasPending)'));
    expect(screen, contains('collections-stencils-bottom-dock'));
    expect(screen, contains('collections-stencil-fitted-ad'));
    expect(screen, contains('onPressed: _loaded && !_busy ? _saveAndContinue : null'));
    expect(screen, contains('ArcStencilCatalogue.assetAt(slot)'));
    expect(screen, contains('itemCount: _kind.slots'));
    expect(screen, contains('final slot = index + 1;'));
    expect(screen, isNot(contains('_toolsRail(hasPending)')));
  });
}
