import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  test(
    'clear is explicit, persisted, and legacy replay cannot resurrect it',
    () {
      const kind = ArcNativeCollectionKind.stencils;
      final original = ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(),
        kind,
        <int>{1, 4},
        <int, int>{1: 2},
      );
      final cleared = ArcAdditionalCollectionState.merge(
        original,
        kind,
        const <int>{},
        const <int, int>{},
        clearOwned: <int>{1},
      );
      expect(cleared.ownedSlots, contains(4));
      expect(cleared.ownedSlots, isNot(contains(1)));
      expect(cleared.duplicateCounts, isNot(contains(1)));
      expect(cleared.clearedSlots, contains(1));
      final roundTrip = ArcAdditionalCollectionState.decode(
        cleared.encode(),
        kind,
      );
      expect(roundTrip.ownedSlots, isNot(contains(1)));
      final withLegacy = ArcAdditionalCollectionState.merge(
        roundTrip,
        kind,
        <int>{1, 4}.difference(roundTrip.clearedSlots),
        const <int, int>{},
      );
      expect(withLegacy.ownedSlots, isNot(contains(1)));
      final restored = ArcAdditionalCollectionState.merge(
        withLegacy,
        kind,
        <int>{1},
        const <int, int>{},
      );
      expect(restored.ownedSlots, contains(1));
      expect(restored.clearedSlots, isNot(contains(1)));
    },
  );

  test('Designs remain slot-indexed and cannot be cleared out of range', () {
    const kind = ArcNativeCollectionKind.designs;
    expect(
      () => ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(),
        kind,
        const <int>{},
        const <int, int>{},
        clearOwned: <int>{101},
      ),
      throwsRangeError,
    );
    final saved = ArcAdditionalCollectionState.merge(
      const ArcAdditionalCollectionState(),
      kind,
      <int>{5},
      const <int, int>{},
    );
    final cleared = ArcAdditionalCollectionState.merge(
      saved,
      kind,
      const <int>{},
      const <int, int>{},
      clearOwned: <int>{5},
    );
    expect(cleared.ownedSlots, isEmpty);
  });

  test('Verdigris and Sacrifice retain in-game slots and exact assets', () {
    expect(ArcStencilCatalogue.nameAt(1), 'Verdigris');
    expect(
      ArcStencilCatalogue.assetAt(1),
      'assets/arc_raiders/blueprints/verdigris.webp',
    );
    expect(ArcStencilCatalogue.nameAt(4), 'Sacrifice');
    expect(
      ArcStencilCatalogue.assetAt(4),
      'assets/arc_raiders/blueprints/sacrifice.webp',
    );
  });

  for (final kind in ArcNativeCollectionKind.values) {
    testWidgets(
      '${kind.name} tile exposes Add Clear Intel without changing ownership on open',
      (tester) async {
        var state = const ArcAdditionalCollectionState();
        await tester.pumpWidget(
          MaterialApp(
            home: ArcAdditionalCollectionsScreen(
              initialKind: kind,
              loader: (_) async => state,
              saver: (_, owned, dupes) async {
                state = ArcAdditionalCollectionState.merge(
                  state,
                  kind,
                  owned,
                  dupes,
                );
                return state;
              },
              clearer: (_, slot) async {
                state = ArcAdditionalCollectionState.merge(
                  state,
                  kind,
                  const <int>{},
                  const <int, int>{},
                  clearOwned: <int>{slot},
                );
                return state;
              },
              adBanner: const SizedBox(height: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('collections-saved-slot-1')));
        // Build the route first, then complete the transition. The animated
        // electric border intentionally prevents pumpAndSettle while open.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const Key('collections-action-add')), findsOneWidget);
        expect(
          find.byKey(const Key('collections-action-clear')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('collections-action-intel')),
          findsOneWidget,
        );
        expect(state.ownedSlots, isEmpty);
        final intel = find.byKey(const Key('collections-action-intel'));
        await tester.ensureVisible(intel);
        await tester.pump();
        await tester.tap(intel);
        // Dismiss the actions sheet and complete the resulting Intel route.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byKey(const Key('collections-intel-status')),
          findsOneWidget,
        );
        expect(state.ownedSlots, isEmpty);
      },
    );
  }
}
