import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_delta_review_screen.dart';

void main() {
  testWidgets('delta review defaults proposed additions selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArcBlueprintPhotoDeltaReviewScreen(
          uncertainIgnoredCount: 25,
          proposedAdditions: [
            ArcBlueprintPhotoCellDecision(
              blueprintId: 'extended-shotgun-mag-iii',
              blueprintIndex: 0,
              state: ArcBlueprintPhotoCellState.owned,
              confidence: 0.96,
              sourceCaptureId: 'top',
              rowIndex: 0,
              columnIndex: 0,
            ),
          ],
        ),
      ),
    );

    expect(find.text('REVIEW NEW BLUEPRINTS'), findsOneWidget);
    expect(find.textContaining('25 uncertain slots'), findsOneWidget);
    expect(find.text('Update Blueprint Grid'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('Keep Tracker Unchanged'), findsOneWidget);
  });

  testWidgets('delta review applies selected additions without confirmation', (
    tester,
  ) async {
    final applied = <ArcBlueprintPhotoCellDecision>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ArcBlueprintPhotoDeltaReviewScreen(
          uncertainIgnoredCount: 0,
          proposedAdditions: const [
            ArcBlueprintPhotoCellDecision(
              blueprintId: 'extended-medium-magazine-iii',
              blueprintIndex: 81,
              state: ArcBlueprintPhotoCellState.owned,
              confidence: 0.96,
              sourceCaptureId: 'bottom',
              rowIndex: 8,
              columnIndex: 1,
            ),
          ],
          applySelected: (selected) async {
            applied.addAll(selected);
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('blueprint-delta-apply')));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(applied, hasLength(1));
    expect(applied.single.blueprintId, 'extended-medium-magazine-iii');
    expect(applied.single.manuallyConfirmed, isTrue);
  });
}
