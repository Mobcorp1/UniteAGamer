import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  testWidgets('Command Centre renders core mobile content at Sony-class width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final commandState = ArcCommandCentreEngine.build(
      blueprintStates: const {},
      savedLoadouts: const [],
    );
    final expeditionState = ArcExpeditionStateSnapshot.fromSeasonState(
      ArcSeasonState.initial(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: ArcCommandCentreContent(
            expeditionState: expeditionState,
            commandState: commandState,
            checklistState: const {},
            onAction: (_) {},
            onChecklistChanged: (_, _) {},
          ),
        ),
      ),
    );

    // Command Centre intentionally contains continuously animated presentation
    // elements. pumpAndSettle() therefore cannot be used as a render-health
    // assertion: the screen can be healthy while never becoming "settled".
    // Use bounded frames so the test validates visible Sony-class content
    // without waiting for intentional animations to stop.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.text('COMMAND CENTRE'), findsOneWidget);
    expect(find.text('PRIORITY MOVES'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ARC SYSTEMS'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.text('ARC SYSTEMS'), findsOneWidget);
    expect(find.text('FEATURES'), findsOneWidget);
  });
}
