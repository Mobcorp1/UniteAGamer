import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_research_quantity_dialog.dart';

void main() {
  testWidgets('stock entry saves five and returns without framework assertions',
      (tester) async {
    int? saved;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              saved = await showDialog<int>(
                context: context,
                builder: (_) => const ArcResearchQuantityDialog(
                  title: 'Bastion Cell stock',
                  initialValue: 0,
                ),
              );
            },
            child: const Text('Edit stock'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Edit stock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, 5);
    expect(tester.takeException(), isNull);
    // Repeat opening the route: controller must be owned by the dialog.
    await tester.tap(find.text('Edit stock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid values cannot be saved', (tester) async {
    int? saved;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              saved = await showDialog<int>(
                context: context,
                builder: (_) => const ArcResearchQuantityDialog(
                  title: 'Set quantity',
                  initialValue: 0,
                  maxValue: 5,
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from 0 to 5'), findsOneWidget);
    expect(saved, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
