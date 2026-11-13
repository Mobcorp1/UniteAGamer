import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  testWidgets('global visual system renders the Blueprint Grid background', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: const ArcGlobalVisualSystem(
          child: Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    expect(find.byType(ArcBlueprintGridBackground), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor,
      Colors.transparent,
    );
  });

  testWidgets('ARC screen backdrop delegates to the canonical background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ArcRaidersScreenBackdrop())),
    );

    expect(find.byType(ArcBlueprintGridBackground), findsOneWidget);
  });
}
