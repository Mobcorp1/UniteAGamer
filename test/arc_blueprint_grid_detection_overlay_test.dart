import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_grid_detection_overlay.dart';

void main() {
  testWidgets('renders detected panel and segmented grid overlay', (
    tester,
  ) async {
    const detection = ArcBlueprintGridDetection(
      topLeft: Offset(0.1, 0.1),
      topRight: Offset(0.9, 0.1),
      bottomLeft: Offset(0.1, 0.9),
      bottomRight: Offset(0.9, 0.9),
      confidence: 0.9,
      message: 'Grid locked',
      columns: 10,
      rows: 5,
      verticalDividers: <double>[
        0.1,
        0.18,
        0.26,
        0.34,
        0.42,
        0.50,
        0.58,
        0.66,
        0.74,
        0.82,
        0.90,
      ],
      horizontalDividers: <double>[0.1, 0.26, 0.42, 0.58, 0.74, 0.90],
    );

    final image = img.Image(width: 16, height: 9);
    img.fill(image, color: img.ColorRgb8(12, 12, 16));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcBlueprintGridDetectionOverlay(
            imageBytes: Uint8List.fromList(img.encodePng(image)),
            detection: detection,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('blueprint-grid-detection-overlay')),
      findsOneWidget,
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
