import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_live_targeting_overlay.dart';

void main() {
  testWidgets('renders top targeting brackets while searching', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 700,
            child: ArcBlueprintLiveTargetingOverlay(
              detection: null,
              isLocked: false,
              isBottomCapture: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ArcBlueprintLiveTargetingOverlay), findsOneWidget);
  });

  testWidgets('renders detected locked grid', (tester) async {
    const detection = ArcBlueprintGridDetection(
      topLeft: Offset(0.10, 0.20),
      topRight: Offset(0.90, 0.20),
      bottomLeft: Offset(0.10, 0.80),
      bottomRight: Offset(0.90, 0.80),
      confidence: 0.90,
      message: 'Grid locked',
      columns: 10,
      rows: 5,
      verticalDividers: <double>[
        0.10,
        0.18,
        0.26,
        0.34,
        0.42,
        0.50,
        0.58,
        0.66,
        0.74,
        0.82,
        0.90,
      ],
      horizontalDividers: <double>[0.20, 0.32, 0.44, 0.56, 0.68, 0.80],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 700,
            child: ArcBlueprintLiveTargetingOverlay(
              detection: detection,
              isLocked: true,
              isBottomCapture: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ArcBlueprintLiveTargetingOverlay), findsOneWidget);
  });

  testWidgets('renders lower-section guide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 700,
            child: ArcBlueprintLiveTargetingOverlay(
              detection: null,
              isLocked: false,
              isBottomCapture: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ArcBlueprintLiveTargetingOverlay), findsOneWidget);
  });
}
