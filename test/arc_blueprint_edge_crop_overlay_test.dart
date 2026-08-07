import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_edge_crop_overlay.dart';

void main() {
  testWidgets('edge crop overlay exposes four one-axis handles', (
    tester,
  ) async {
    var calibration = const ArcBlueprintEdgeCalibration.defaults();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ArcBlueprintEdgeCropOverlay(
                  calibration: calibration,
                  onChanged: (value) => setState(() => calibration = value),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('blueprint-crop-edge-top')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-bottom')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-left')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-right')), findsOneWidget);
    expect(
      find.byKey(const Key('blueprint-corner-calibration-overlay')),
      findsNothing,
    );

    final before = calibration;
    await tester.drag(
      find.byKey(const Key('blueprint-crop-edge-left')),
      const Offset(40, 60),
    );
    await tester.pump();

    expect(calibration.left, greaterThan(before.left));
    expect(calibration.top, before.top);
    expect(calibration.bottom, before.bottom);
  });
}
