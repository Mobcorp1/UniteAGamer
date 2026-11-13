import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_edge_crop_overlay.dart';

Uint8List _sampleStill() {
  final photo = image_codec.Image(width: 1200, height: 900);
  image_codec.fill(photo, color: image_codec.ColorRgb8(10, 18, 27));
  return Uint8List.fromList(image_codec.encodeJpg(photo, quality: 85));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Grid35 second step gives the still a near-full-height crop view',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(home: arcGrid35AlignmentForTest(_sampleStill())));
    await tester.pumpAndSettle();

    final frame = tester.getSize(find.byKey(const Key('grid35-expanded-alignment-photo')));
    expect(frame.width, greaterThan(480));
    expect(frame.height, greaterThan(350));
    expect(find.byKey(const Key('grid09-post-capture-alignment')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-left')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-right')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-top')), findsOneWidget);
    expect(find.byKey(const Key('blueprint-crop-edge-bottom')), findsOneWidget);
    expect(find.byKey(const Key('grid09-confirm-crop')), findsOneWidget);
  });

  testWidgets('Grid35 zoom controls change display transform without changing crop geometry',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(home: arcGrid35AlignmentForTest(_sampleStill())));
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('grid35-photo-zoom-pan')));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), closeTo(1, 0.001));
    final beforeCrop = tester.widget<ArcBlueprintEdgeCropOverlay>(
        find.byKey(const Key('grid09-post-capture-alignment'))).calibration.normalizedRect;
    await tester.tap(find.byKey(const Key('grid35-zoom-in')));
    await tester.pump();
    final afterZoomCrop = tester.widget<ArcBlueprintEdgeCropOverlay>(
        find.byKey(const Key('grid09-post-capture-alignment'))).calibration.normalizedRect;
    expect(afterZoomCrop, beforeCrop);
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), closeTo(1.5, 0.001));
    expect(find.text('150%'), findsOneWidget);
    expect(find.byKey(const Key('grid09-post-capture-alignment')), findsOneWidget);

    await tester.tap(find.byKey(const Key('grid35-fit-photo')));
    await tester.pump();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), closeTo(1, 0.001));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('Grid35 capture step has no duplicate cyan crop frame', (tester) async {
    tester.view.physicalSize = const Size(1000, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home: arcGrid35CameraForTest()));
    await tester.pump();
    expect(find.text('TAKE BLUEPRINT PHOTO'), findsOneWidget);
    expect(find.byKey(const Key('grid17-cyan-alignment-frame')), findsNothing);
    expect(find.byKey(const Key('grid09-post-capture-alignment')), findsNothing);
  });
}
