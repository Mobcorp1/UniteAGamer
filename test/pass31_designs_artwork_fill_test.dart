import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viewport in const <Size>[Size(1100, 600), Size(844, 390)]) {
    testWidgets(
      'PASS31 Designs artwork fills each card edge and name follows image at $viewport',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: ArcAdditionalCollectionsScreen(
              initialKind: ArcNativeCollectionKind.designs,
              loader: (_) async => const ArcAdditionalCollectionState(),
              designNameLoader: () async => const <int, String>{},
              adBanner: const SizedBox(width: 320, height: 50),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const slot = 1; // Printed Lab Sofa artwork is shipped in PASS26.
        final card = find.byKey(const Key('collections-saved-slot-$slot'));
        final artwork =
            find.byKey(const Key('collections-design-artwork-frame-$slot'));
        final title = find.byKey(const Key('collections-design-name-$slot'));
        expect(card, findsOneWidget);
        expect(artwork, findsOneWidget);
        expect(title, findsOneWidget);

        final cardRect = tester.getRect(card);
        final artRect = tester.getRect(artwork);
        final titleRect = tester.getRect(title);

        // The 1px border is retained, but former 2px inner padding is gone.
        expect(artRect.left - cardRect.left, inInclusiveRange(0, 1.2));
        expect(cardRect.right - artRect.right, inInclusiveRange(0, 1.2));
        expect(artRect.top - cardRect.top, inInclusiveRange(0, 1.2));
        expect(artRect.width, greaterThan(cardRect.width - 2.5));

        // No vertical spacer between the image and the design name.
        expect(titleRect.top - artRect.bottom, inInclusiveRange(-0.2, 1.2));
        expect(find.text('01'), findsNothing);
        final grid = tester.widget<GridView>(
          find.byKey(const Key('collections-design-readable-gallery')),
        );
        expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          17,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('PASS31 affects only Designers card art, not collection slot identities',
      () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    expect(source, contains('final slot = index + 1;'));
    expect(source, contains('itemCount: _kind.slots'));
    expect(source, contains('ArcDesignReferenceCatalogue.nameAt(slot)'));
    expect(source, contains('scale: 1.10,'));
    expect(source, contains('key: Key(\'collections-design-artwork-frame-\$slot\')'));
    expect(source, contains('alignment: Alignment.topCenter,'));
    expect(source, contains('final rowHeight = math.max('));
    expect(source, contains('const columns = 17;'));
    expect(source, contains("if (_kind == ArcNativeCollectionKind.designs) {"));
  });
}
