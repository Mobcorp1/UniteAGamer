import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_review_screen.dart';

void main() {
  testWidgets('review screen lets user resolve an uncertain slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArcBlueprintPhotoReviewScreen(
          analysisWarnings: <String>[],
          initialDecisions: [
            ArcBlueprintPhotoCellDecision(
              blueprintId: 'extended-shotgun-mag-iii',
              blueprintIndex: 0,
              state: ArcBlueprintPhotoCellState.uncertain,
              confidence: 0.5,
              sourceCaptureId: 'top',
              rowIndex: 0,
              columnIndex: 0,
            ),
          ],
        ),
      ),
    );

    expect(find.text('1 uncertain slots need your decision.'), findsOneWidget);
    await tester.tap(find.text('Owned'));
    await tester.pumpAndSettle();
    expect(find.text('All 1 slots are ready to confirm.'), findsOneWidget);
  });
}
