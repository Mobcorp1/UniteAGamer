import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_capture_boundary_overlay.dart';

void main() {
  test('extra large boundary uses the full portrait scanner viewport', () {
    final rect = ArcBlueprintCaptureBoundaryOverlay.frameRectFor(
      const Size(400, 800),
    );

    expect(rect.width, closeTo(400, 0.01));
    expect(rect.height, closeTo(800, 0.01));
    expect(rect, const Rect.fromLTWH(0, 0, 400, 800));
  });

  test('extra large boundary uses the full landscape scanner viewport', () {
    final rect = ArcBlueprintCaptureBoundaryOverlay.frameRectFor(
      const Size(1200, 500),
    );

    expect(rect.width, closeTo(1200, 0.01));
    expect(rect.height, closeTo(500, 0.01));
    expect(rect, const Rect.fromLTWH(0, 0, 1200, 500));
  });

  test('smaller presets remain smaller than the full viewport', () {
    final medium = ArcBlueprintCaptureBoundaryOverlay.frameRectFor(
      const Size(400, 800),
      boundarySize: ArcBlueprintBoundarySize.medium,
    );

    expect(medium.width, lessThan(400));
    expect(medium.height, lessThan(800));
  });

  testWidgets('boundary overlay contains no duplicate internal grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: ArcBlueprintCaptureBoundaryOverlay(isAligned: false),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('blueprint-capture-boundary-overlay')),
      findsOneWidget,
    );
    expect(find.byType(GridView), findsNothing);
  });
}
