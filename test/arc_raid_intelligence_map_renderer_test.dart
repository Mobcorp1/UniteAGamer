import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart';

void main() {
  testWidgets('renders tactical schematic map and marker semantics', (
    tester,
  ) async {
    final controller = TransformationController();
    final state = const ArcRaidIntelligenceEngine().build(mapId: 'blue_gate');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 520,
            child: ArcRaidIntelligenceMapRenderer(
              state: state,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Surface • calibrated game map'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Blue Gate Raid Intelligence map')),
      findsOneWidget,
    );
  });
}
