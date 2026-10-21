import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_workspace.dart';

void main() {
  testWidgets('compact Amplification Mod slot opens its weapon editor',
      (tester) async {
    const state = ArcAmplificationState(
      plannedPerks: <String, String>{'Rattler': 'magazine_geometry_101'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcAmplificationAttachmentSlot(
            weapon: 'Rattler',
            accent: Colors.cyan,
            compact: true,
            progressStream: Stream<ArcAmplificationState>.value(state),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AMP'), findsOneWidget);
    await tester.tap(find.text('AMP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('RATTLER · AMPLIFICATION MOD'), findsOneWidget);
    expect(find.text('Drum Mag'), findsOneWidget);
    expect(find.text('Open Research Station'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('AMP'), findsOneWidget);
  });

  testWidgets('wide mod slot is separate from ordinary attachment chips',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcAmplificationAttachmentSlot(
            weapon: 'Kettle',
            accent: Colors.pink,
            progressStream: Stream<ArcAmplificationState>.value(
              ArcAmplificationState.empty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AMPLIFICATION'), findsOneWidget);
    // Empty is the perk label. Its secondary status must not repeat it.
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.text('AMPLIFICATION'));
    await tester.pumpAndSettle();
    expect(find.textContaining('KETTLE · AMPLIFICATION MOD'), findsOneWidget);
  });

  testWidgets('single-subscription updates reach an already open AMP editor',
      (tester) async {
    final controller = StreamController<ArcAmplificationState>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcAmplificationAttachmentSlot(
            weapon: 'Rattler',
            accent: Colors.cyan,
            compact: true,
            progressStream: controller.stream,
          ),
        ),
      ),
    );
    controller.add(ArcAmplificationState.empty);
    await tester.pumpAndSettle();
    expect(find.text('AMP'), findsOneWidget);
    await tester.tap(find.text('AMP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('RATTLER · AMPLIFICATION MOD'), findsOneWidget);
    expect(find.text('Open Research Station'), findsOneWidget);
    controller.add(
      const ArcAmplificationState(
        plannedPerks: <String, String>{'Rattler': 'magazine_geometry_101'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drum Mag'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('AMP'), findsOneWidget);
  });

  testWidgets('unsupported weapons have no artificial Amplification slot',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcAmplificationAttachmentSlot(
            weapon: 'Tempest',
            accent: Colors.cyan,
            progressStream: Stream<ArcAmplificationState>.value(
              ArcAmplificationState.empty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AMPLIFICATION'), findsNothing);
    expect(find.text('AMP'), findsNothing);
  });
}
