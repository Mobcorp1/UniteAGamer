import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Unowned Stencils are greyscale and dim, owned Stencils remain full colour', (tester) async {
    tester.view.physicalSize = const Size(1100, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ArcAdditionalCollectionsScreen(
          initialKind: ArcNativeCollectionKind.stencils,
          loader: (_) async => const ArcAdditionalCollectionState(
            ownedSlots: <int>{2, 16},
          ),
          adBanner: const SizedBox(width: 320, height: 50),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The first and eighteenth stencils have not been collected.
    for (final slot in <int>[1, 18]) {
      final filter = find.byKey(Key('collections-stencil-unowned-filter-$slot'));
      expect(filter, findsOneWidget);
      expect(
        find.descendant(of: filter, matching: find.byType(Opacity)),
        findsOneWidget,
      );
      final faded = tester.widget<Opacity>(
        find.descendant(of: filter, matching: find.byType(Opacity)),
      );
      expect(faded.opacity, 0.45);
      expect(
        find.descendant(
          of: filter,
          matching: find.byKey(Key('collections-stencil-artwork-$slot')),
        ),
        findsOneWidget,
      );
    }

    // Existing and newly added owned cards retain unfiltered art.
    for (final slot in <int>[2, 16]) {
      expect(
        find.byKey(Key('collections-stencil-unowned-filter-$slot')),
        findsNothing,
      );
      expect(find.byKey(Key('collections-stencil-artwork-$slot')), findsOneWidget);
    }

    expect(find.byKey(const Key('collections-saved-slot-18')), findsOneWidget);
    expect(find.text('2/18 OWNED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
