import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_collections_screen.dart';

void main() {
  testWidgets('Collections screen exposes all three Frozen Trail grids', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ArcCollectionsScreen()));
    await tester.pump();

    expect(find.text('BLUEPRINTS'), findsOneWidget);
    expect(find.text('STENCILS'), findsOneWidget);
    expect(find.text('DESIGNS'), findsOneWidget);
    expect(find.text('91 SLOTS'), findsOneWidget);

    await tester.tap(find.text('STENCILS'));
    await tester.pump();
    expect(find.text('14 SLOTS'), findsOneWidget);

    await tester.tap(find.text('DESIGNS'));
    await tester.pump();
    expect(find.text('100 SLOTS'), findsOneWidget);
  });
}
