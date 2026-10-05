import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_drop_report_carousel_picker.dart';

void main() {
  testWidgets('carousel selection requires an explicit centered choice', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await showArcDropReportCarouselPicker<String>(
                  context: context,
                  title: 'Map',
                  items: const ['Buried City', 'Spaceport', 'The Blue Gate'],
                  labelBuilder: (item) => item,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Use Buried City'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(find.text('Use Spaceport'), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(find.text('Use Spaceport'));
    await tester.pumpAndSettle();
    expect(selected, 'Spaceport');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'carousel can open and close repeatedly without framework errors',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  opens += 1;
                  await showArcDropReportCarouselPicker<String>(
                    context: context,
                    title: 'Additional Blueprint',
                    items: const ['Osprey', 'Anvil', 'Canto'],
                    labelBuilder: (item) => item,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Use Osprey'), findsOneWidget);
        await tester.tap(find.text('Use Osprey'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      expect(opens, 3);
    },
  );
}
