import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';

void main() {
  test('Actual Blueprint grid exposes category tabs and destinations', () {
    final grid = File(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    ).readAsStringSync();
    final other = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
    ).readAsStringSync();
    expect(grid, contains('ArcCollectionsCategoryBar('));
    expect(grid, contains('ArcNativeCollectionKind.stencils'));
    expect(grid, contains('ArcNativeCollectionKind.designs'));
    expect(other, contains('ArcCollectionsCategoryBar('));
    expect(grid, contains('_buildBlueprintHeaderTitle(context)'));
  });
  testWidgets('All three collections are visible and can be selected', (tester) async {
    var selected = ArcCollectionsCategory.blueprints;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ArcCollectionsCategoryBar(
        selected: ArcCollectionsCategory.blueprints,
        onSelected: (next) => selected = next,
      )),
    ));
    expect(find.text('BLUEPRINTS'), findsOneWidget);
    expect(find.text('STENCILS'), findsOneWidget);
    expect(find.text('DESIGNS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('collections-tab-stencils')));
    expect(selected, ArcCollectionsCategory.stencils);
    await tester.tap(find.byKey(const Key('collections-tab-designs')));
    expect(selected, ArcCollectionsCategory.designs);
  });
}
