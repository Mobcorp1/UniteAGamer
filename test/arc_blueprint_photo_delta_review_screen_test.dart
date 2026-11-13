import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_delta_review_screen.dart';

void main() {
  Future<void> pumpReview(WidgetTester tester, {required Widget home}) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  testWidgets('scan result has no per-blueprint checkout controls', (
    tester,
  ) async {
    await pumpReview(
      tester,
      home: const ArcBlueprintPhotoDeltaReviewScreen(
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
    );

    expect(find.text('BLUEPRINT SCAN RESULT'), findsOneWidget);
    expect(find.text('Update Blueprint Grid'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('Update Blueprint Grid applies every detected addition once', (
    tester,
  ) async {
    final applied = <ArcBlueprintPhotoCellDecision>[];

    await pumpReview(
      tester,
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
    );

    await tester.tap(find.byKey(const Key('blueprint-delta-apply')));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single.blueprintId, 'extended-medium-magazine-iii');
    expect(applied.single.manuallyConfirmed, isTrue);
  });
}
