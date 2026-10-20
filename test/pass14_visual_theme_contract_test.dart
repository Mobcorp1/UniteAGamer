import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  test('UAG global Material theme uses exact brand colours', () {
    final theme = AppTheme.theme;
    expect(theme.colorScheme.primary, const Color(0xFF19E6F2));
    expect(theme.colorScheme.secondary, const Color(0xFFFF3B8D));
    expect(theme.dialogTheme.backgroundColor, AppTheme.cardBackgroundDeep);
    expect(theme.bottomSheetTheme.modalBackgroundColor, AppTheme.cardBackgroundDeep);
    expect(theme.popupMenuTheme.color, AppTheme.cardBackgroundDeep);
    expect(theme.filledButtonTheme.style, isNotNull);
    expect(theme.textButtonTheme.style, isNotNull);
    expect(theme.outlinedButtonTheme.style, isNotNull);
    expect(theme.chipTheme.backgroundColor, AppTheme.cardBackgroundAlt);
  });

  testWidgets('Unstyled confirmation remains dark, never white/blue', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: Builder(builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text('Own Stencil?'),
              content: Text('Confirm a spare copy'),
            ),
          ),
          child: const Text('Open duplicate confirmation'),
        )),
      ),
    ));
    await tester.tap(find.text('Open duplicate confirmation'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    final context = tester.element(find.byType(AlertDialog));
    expect(dialog.backgroundColor ?? Theme.of(context).dialogTheme.backgroundColor,
        AppTheme.cardBackgroundDeep);
    expect(Theme.of(context).colorScheme.primary, AppTheme.neonCyan);
    expect(Theme.of(context).colorScheme.secondary, AppTheme.neonPink);
  });

  test('Collections duplicate accent variants are prohibited', () {
    const paths = <String>[
      'lib/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart',
      'lib/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_collection_overview_screen.dart',
      'lib/features/trading_hub/arc_raiders/screens/arc_collections_tracker_screen.dart',
      'lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart',
    ];
    const variants = <String>[
      '0xFFFF3C97', '0xFFFF61B6', '0xFFFF8FC1', '0xFF8B426D',
      '0xFFFF4FAB', '0xFFFF90CA', '0xFFFF4EA4',
    ];
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final code = file.readAsStringSync();
      for (final variant in variants) {
        expect(code.contains(variant), isFalse,
            reason: '$path bypasses UAG canonical pink with $variant');
      }
    }
  });
}
