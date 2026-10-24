import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_quick_actions_sheet.dart';

void main() {
  const blueprint = ArcBlueprint(
    id: 'pass19-test',
    name: 'Test Blueprint',
    category: 'Attachments',
    group: 'Test',
    sortOrder: 1,
    rarity: ArcBlueprintRarity.rare,
    icon: Icons.settings,
  );

  Future<ArcBlueprintQuickAction?> openSheet(
    WidgetTester tester,
    ArcBlueprintState state,
    String actionKey,
  ) async {
    ArcBlueprintQuickAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<ArcBlueprintQuickAction>(
                  context: context,
                  backgroundColor: const Color(0xFF0C1B26),
                  builder: (_) => ArcBlueprintQuickActionsSheet(
                    blueprint: blueprint,
                    state: state,
                  ),
                );
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    // First frame installs the route; second advances the entrance animation.
    // A single 500ms pump leaves the bottom sheet off the test viewport.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('blueprint-action-clear')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-action-intel')), findsOneWidget);
    final action = find.byKey(Key(actionKey));
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    // The modal's electric charge rotates continually while mounted.
    // Bound the dismissal pumps instead of waiting for every ticker to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return result;
  }

  testWidgets('missing blueprint offers explicit Add / Clear / Intel', (
    tester,
  ) async {
    final original = ArcBlueprintState.empty(blueprint.id);
    final result = await openSheet(tester, original, 'blueprint-action-add');
    expect(result, ArcBlueprintQuickAction.add);
    expect(
      original.owned,
      isFalse,
    ); // Merely opening/tapping tile did not write.
  });

  testWidgets('missing blueprint Intel never automatically marks owned', (
    tester,
  ) async {
    final original = ArcBlueprintState.empty(blueprint.id);
    final result = await openSheet(tester, original, 'blueprint-action-intel');
    expect(result, ArcBlueprintQuickAction.intel);
    expect(original.owned, isFalse);
  });

  testWidgets('missing blueprint Clear remains accessible', (tester) async {
    final result = await openSheet(
      tester,
      ArcBlueprintState.empty(blueprint.id),
      'blueprint-action-clear',
    );
    expect(result, ArcBlueprintQuickAction.clear);
  });

  testWidgets('owned blueprint keeps duplicate controls and Clear / Intel', (
    tester,
  ) async {
    final owned = ArcBlueprintState.empty(
      blueprint.id,
    ).copyWith(owned: true, dupesOwned: 2);
    final result = await openSheet(
      tester,
      owned,
      'blueprint-action-remove-dupe',
    );
    expect(result, ArcBlueprintQuickAction.removeDuplicate);
    expect(owned.dupesOwned, 2);
  });
}
