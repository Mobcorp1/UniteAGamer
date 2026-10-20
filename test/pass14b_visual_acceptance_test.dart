import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';

void main() {
  test('Native date and time pickers inherit the ARC design contract', () {
    final theme = AppTheme.theme;
    expect(theme.datePickerTheme.backgroundColor, AppTheme.cardBackgroundDeep);
    expect(theme.datePickerTheme.headerBackgroundColor, AppTheme.cardBackgroundAlt);
    expect(theme.datePickerTheme.headerForegroundColor, AppTheme.neonCyan);
    expect(theme.timePickerTheme.backgroundColor, AppTheme.cardBackgroundDeep);
    expect(theme.timePickerTheme.dialBackgroundColor, AppTheme.cardBackgroundAlt);
    expect(theme.timePickerTheme.dialHandColor, AppTheme.neonPink);
    expect(theme.timePickerTheme.entryModeIconColor, AppTheme.neonCyan);
  });

  testWidgets('Collections tab controls retain exact labels and callback actions',
      (tester) async {
    ArcCollectionsCategory? selected;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: ArcCollectionsCategoryBar(
          selected: ArcCollectionsCategory.blueprints,
          showDupes: true,
          onSelected: (category) => selected = category,
        ),
      ),
    ));
    expect(find.text('BLUEPRINTS'), findsOneWidget);
    expect(find.text('STENCILS'), findsOneWidget);
    expect(find.text('DESIGNS'), findsOneWidget);
    expect(find.text('DUPES'), findsOneWidget);
    await tester.tap(find.byKey(const Key('collections-tab-stencils')));
    expect(selected, ArcCollectionsCategory.stencils);
  });

  test('Collections share and navigation enforce canonical accent references', () {
    const paths = <String>[
      'lib/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart',
      'lib/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_collections_tracker_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_collection_overview_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/uag_trade_invite_landing.dart',
    ];
    const oldAccents = <String>[
      '0xFF6CE6E9', '0xFF65E6F2', '0xFF68E3EB',
      '0xFF62E5EB', '0xFF33DCE8', '0xFFFF4BA0',
      '0xFFFF91C8', '0xFFE93895',
    ];
    for (final path in paths) {
      final code = File(path).readAsStringSync();
      for (final accent in oldAccents) {
        expect(code.contains(accent), isFalse,
            reason: '$path retains unapproved duplicated accent $accent');
      }
    }
  });

  test('Protected Blueprint grid and Favourite Loadout remain untouched by the pass', () {
    final grid = File('lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart');
    final tile = File('lib/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart');
    final loadout = File('lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart');
    expect(grid.existsSync(), isTrue);
    expect(tile.existsSync(), isTrue);
    expect(loadout.existsSync(), isTrue);
  });
}
