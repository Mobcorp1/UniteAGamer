import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_review_screen.dart';

void main() {
  testWidgets('review screen lets user resolve an uncertain slot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.pumpAndSettle();

    expect(find.text('1 uncertain slots need your decision.'), findsOneWidget);
    final owned = find.text('Owned');
    expect(owned, findsOneWidget);
    final selector = find.byType(SegmentedButton<ArcBlueprintPhotoCellState>);
    expect(selector, findsOneWidget);
    tester
        .widget<SegmentedButton<ArcBlueprintPhotoCellState>>(selector)
        .onSelectionChanged!({ArcBlueprintPhotoCellState.owned});
    await tester.pump();
    expect(find.text('All 1 slots are ready to confirm.'), findsOneWidget);
  });
}
