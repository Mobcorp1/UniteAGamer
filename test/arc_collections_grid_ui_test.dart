import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Collections Grid entry provides Blueprints, Stencils, Designs and gallery upload', (tester) async {
    tester.view.physicalSize = const Size(1100, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: ArcFrozenTrailSingleGridCaptureScreen()));
    await tester.pump();
    expect(find.text('COLLECTIONS GRID'), findsOneWidget);
    expect(find.byKey(const Key('collections-grid-tab-blueprints')), findsOneWidget);
    expect(find.byKey(const Key('collections-grid-tab-stencils')), findsOneWidget);
    expect(find.byKey(const Key('collections-grid-tab-designs')), findsOneWidget);
    final upload = find.byKey(const Key('frozen-trail-single-capture-screenshot'));
    expect(upload, findsOneWidget);
    // Upload is the primary flow: users should not scroll past the preview.
    final bounds = tester.getRect(upload);
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(540));
    // No camera alignment wizard in the standard closed-beta route.
    expect(find.byKey(const Key('frozen-trail-single-capture-camera')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
