import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';

void main() {
  testWidgets(
    'ARC companion dock shrink-wraps inside scaffold bottom navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: ArcCompanionBottomDock(activeLabel: 'systems'),
          ),
        ),
      );

      final dockBox = tester.renderObject<RenderBox>(
        find.byType(ArcCompanionBottomDock),
      );

      expect(dockBox.size.height, lessThan(96));
    },
  );
}
