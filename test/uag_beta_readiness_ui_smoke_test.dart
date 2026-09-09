import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';

void main() {
  testWidgets('Discover carousel survives the beta viewport matrix', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cases = <(Size, double)>[
      (Size(360, 640), 96),
      (Size(390, 844), 96),
      (Size(430, 932), 96),
      (Size(844, 390), 72),
      (Size(768, 1024), 96),
      (Size(1440, 900), 96),
    ];

    for (final (size, maxDockHeight) in cases) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(const MaterialApp(home: ArcRaidersHubScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final exception = tester.takeException();
      if (exception != null) {
        if (exception is FlutterError) {
          printOnFailure(exception.toStringDeep());
        } else {
          printOnFailure(exception.toString());
        }
        _printHorizontalFlexOverflows(tester);
      }
      expect(
        exception,
        isNull,
        reason: 'Discover should render without Flutter errors at $size',
      );
      expect(find.text('DISCOVER UAG'), findsWidgets);
      expect(find.text('Command Centre'), findsWidgets);
      expect(find.byType(ArcCompanionBottomDock), findsOneWidget);

      final dockBox = tester.renderObject<RenderBox>(
        find.byType(ArcCompanionBottomDock),
      );
      expect(
        dockBox.size.height,
        lessThan(maxDockHeight),
        reason: 'Dock height at ${size.width}x${size.height}',
      );
    }
  });
}

void _printHorizontalFlexOverflows(WidgetTester tester) {
  void visit(RenderObject object) {
    if (object is RenderFlex && object.direction == Axis.horizontal) {
      var maxRight = 0.0;
      object.visitChildren((child) {
        if (child is RenderBox && child.parentData is FlexParentData) {
          final parentData = child.parentData! as FlexParentData;
          final right = parentData.offset.dx + child.size.width;
          if (right > maxRight) maxRight = right;
        }
      });

      final overflow = maxRight - object.size.width;
      if (overflow > 0.5) {
        printOnFailure(
          '${object.toStringShort()} overflow=${overflow.toStringAsFixed(1)} '
          'size=${object.size} creator=${object.debugCreator}',
        );
      }
    }

    object.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
}
