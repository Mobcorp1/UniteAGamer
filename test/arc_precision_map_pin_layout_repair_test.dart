import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_precision_map_pin.dart';

void main() {
  Widget compositeHead() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Text('2', style: TextStyle(fontSize: 7)),
          ),
        ),
      ],
    );
  }

  testWidgets('collapsed precision pin lays out composite heads safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ArcPrecisionMapPin(
              selected: false,
              accent: Colors.pinkAccent,
              head: compositeHead(),
              label: 'Blueprint cluster',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ArcPrecisionMapPin), findsOneWidget);
  });

  testWidgets(
    'expanded precision pin keeps composite head and details stable',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArcPrecisionMapPin(
                selected: true,
                accent: Colors.cyanAccent,
                head: compositeHead(),
                label: 'Metro Station',
                detail: 'Underground access',
                coordinateText: 'X 0.4231 • Y 0.6178',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Metro Station'), findsOneWidget);
      expect(find.text('X 0.4231 • Y 0.6178'), findsOneWidget);
    },
  );
}
