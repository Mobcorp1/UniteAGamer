import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';

void main() {
  testWidgets('ArcPageViewport constrains standard desktop content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1600, 900)),
          child: Scaffold(body: ArcPageViewport(child: SizedBox.expand())),
        ),
      ),
    );
    final viewportFinder = find.byType(ArcPageViewport);
    expect(viewportFinder, findsOneWidget);

    final constrainedBoxFinder = find.descendant(
      of: viewportFinder,
      matching: find.byType(ConstrainedBox),
    );

    expect(constrainedBoxFinder, findsOneWidget);

    final constrainedBox = tester.widget<ConstrainedBox>(constrainedBoxFinder);

    expect(
      constrainedBox.constraints.maxWidth,
      ArcLayoutTokens.standardContentWidth,
    );
  });

  testWidgets('ArcAdaptiveGrid uses more than one column on desktop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1400, 900)),
          child: Scaffold(
            body: SizedBox(
              width: 1200,
              child: ArcAdaptiveGrid(
                children: [
                  SizedBox(key: Key('one'), height: 60),
                  SizedBox(key: Key('two'), height: 60),
                  SizedBox(key: Key('three'), height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const Key('one')));
    final second = tester.getTopLeft(find.byKey(const Key('two')));
    expect(second.dx, greaterThan(first.dx));
    expect(second.dy, first.dy);
  });

  testWidgets('ArcPageHeader moves actions below title on compact screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(390, 800)),
          child: Scaffold(
            body: ArcPageHeader(
              title: 'Test page',
              subtitle: 'Responsive subtitle',
              trailing: [TextButton(onPressed: null, child: Text('ACTION'))],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test page'), findsOneWidget);
    expect(find.text('ACTION'), findsOneWidget);
  });
}
