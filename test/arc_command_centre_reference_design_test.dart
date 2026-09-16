import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

void main() {
  test('Command Centre follows the ARC Operations OS reference contract', () {
    final content = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
    ).readAsStringSync();

    expect(content, contains('ArcLayoutTokens.standardContentWidth'));
    expect(content, contains('ArcResponsiveSplitPane('));
    expect(content, contains('ArcAdaptiveGrid('));
    expect(content, contains("title: 'Tactical Overview'"));
    expect(content, contains("title: 'Daily Mission Board'"));
    expect(content, contains("title: 'ARC Systems'"));
    expect(content, contains("'COMMAND CENTRE'"));
    expect(content, isNot(contains('_commandAccordion')));
    expect(content, isNot(contains('ArcElectricActionBorder')));
    expect(
      screen,
      contains("subtitle: 'Live priorities, progression and operations'"),
    );
  });

  testWidgets(
    'Command Centre cards use the canonical restrained panel surface',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArcCommandCentreCard(
              child: SizedBox(width: 200, height: 80, child: Text('Reference')),
            ),
          ),
        ),
      );

      final cardFinder = find.ancestor(
        of: find.text('Reference'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      );
      final container = tester.widget<Container>(cardFinder.first);
      final decoration = container.decoration! as BoxDecoration;

      expect(
        decoration.borderRadius,
        BorderRadius.circular(ArcUiTokens.radiusXL),
      );
      expect(decoration.boxShadow, isNull);
      expect(find.text('Reference'), findsOneWidget);
    },
  );
}
