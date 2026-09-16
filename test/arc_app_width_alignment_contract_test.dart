import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_responsive_page_shell.dart';

void main() {
  for (final width in <double>[390, 1440]) {
    testWidgets('responsive page content fills its canonical width at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArcResponsivePageShell(
              safeArea: false,
              scrollable: false,
              includeDockPadding: false,
              padding: EdgeInsets.zero,
              child: Container(key: const Key('content')),
            ),
          ),
        ),
      );

      final rendered = tester.getSize(find.byKey(const Key('content'))).width;
      final expected = width < 1180 ? width : 1180.0;
      expect(rendered, expected);
      expect(tester.takeException(), isNull);
    });
  }
}
