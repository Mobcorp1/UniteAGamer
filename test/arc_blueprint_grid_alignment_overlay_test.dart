import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_grid_alignment_overlay.dart';

void main() {
  testWidgets('alignment overlay renders fixed grid guide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 300,
            child: ArcBlueprintGridAlignmentOverlay(),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('blueprint-grid-alignment-overlay')),
      findsOneWidget,
    );
  });
}
