import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  testWidgets('loadout star is accessible and does not trigger tile tap', (
    tester,
  ) async {
    var tileTapCount = 0;
    var starTapCount = 0;
    const label = 'Add Test Blueprint to Favourite Loadout';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 150,
              height: 190,
              child: BlueprintTile(
                blueprint: const ArcBlueprint(
                  id: 'test-blueprint',
                  name: 'Test Blueprint',
                  category: 'Weapons',
                  group: 'Test',
                  sortOrder: 1,
                  rarity: ArcBlueprintRarity.rare,
                  icon: Icons.extension_rounded,
                ),
                state: const ArcBlueprintState(
                  blueprintId: 'test-blueprint',
                  owned: true,
                  dupesOwned: 0,
                  priorityRank: 0,
                  updatedAt: null,
                ),
                landscape: false,
                rarityColor: AppTheme.neonCyan,
                loadoutAction: Semantics(
                  button: true,
                  label: label,
                  child: InkWell(
                    onTap: () => starTapCount++,
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.star_border_rounded),
                    ),
                  ),
                ),
                onTap: () => tileTapCount++,
                onLongPress: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(label), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pump();

    expect(starTapCount, 1);
    expect(tileTapCount, 0);

    await tester.tap(find.text('Test Blueprint'));
    await tester.pump();

    expect(tileTapCount, 1);
  });
}
