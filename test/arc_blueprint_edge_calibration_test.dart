import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';

void main() {
  test('top and bottom controls resize height symmetrically', () {
    const original = ArcBlueprintEdgeCalibration.defaults();
    final centre = (original.top + original.bottom) / 2;

    final fromTop = original.moveEdge(ArcBlueprintCropEdge.top, 0.20);
    expect((fromTop.top + fromTop.bottom) / 2, closeTo(centre, 0.0001));
    expect(centre - fromTop.top, closeTo(fromTop.bottom - centre, 0.0001));

    final fromBottom = original.moveEdge(ArcBlueprintCropEdge.bottom, 0.80);
    expect((fromBottom.top + fromBottom.bottom) / 2, closeTo(centre, 0.0001));
    expect(
      centre - fromBottom.top,
      closeTo(fromBottom.bottom - centre, 0.0001),
    );
  });

  test('left and right controls resize width symmetrically', () {
    const original = ArcBlueprintEdgeCalibration.defaults();
    final centre = (original.left + original.right) / 2;

    final fromLeft = original.moveEdge(ArcBlueprintCropEdge.left, 0.18);
    expect((fromLeft.left + fromLeft.right) / 2, closeTo(centre, 0.0001));
    expect(centre - fromLeft.left, closeTo(fromLeft.right - centre, 0.0001));

    final fromRight = original.moveEdge(ArcBlueprintCropEdge.right, 0.82);
    expect((fromRight.left + fromRight.right) / 2, closeTo(centre, 0.0001));
    expect(centre - fromRight.left, closeTo(fromRight.right - centre, 0.0001));
  });

  test('paired edge movement keeps crop valid and inside viewport', () {
    const original = ArcBlueprintEdgeCalibration.defaults();

    final resized = original
        .moveEdge(ArcBlueprintCropEdge.left, 0.99)
        .moveEdge(ArcBlueprintCropEdge.top, 0.99);

    expect(resized.isValid, isTrue);
    expect(resized.left, greaterThanOrEqualTo(0));
    expect(resized.top, greaterThanOrEqualTo(0));
    expect(resized.right, lessThanOrEqualTo(1));
    expect(resized.bottom, lessThanOrEqualTo(1));
    expect(
      resized.right - resized.left,
      greaterThanOrEqualTo(ArcBlueprintEdgeCalibration.minimumWidth),
    );
    expect(
      resized.bottom - resized.top,
      greaterThanOrEqualTo(ArcBlueprintEdgeCalibration.minimumHeight),
    );
  });

  test('legacy four-corner json migrates to rectangular edges', () {
    final migrated = ArcBlueprintEdgeCalibration.fromJson({
      'topLeftX': 0.10,
      'topLeftY': 0.20,
      'topRightX': 0.90,
      'topRightY': 0.18,
      'bottomLeftX': 0.12,
      'bottomLeftY': 0.82,
      'bottomRightX': 0.88,
      'bottomRightY': 0.84,
    });

    expect(migrated.left, closeTo(0.11, 0.001));
    expect(migrated.top, closeTo(0.19, 0.001));
    expect(migrated.right, closeTo(0.89, 0.001));
    expect(migrated.bottom, closeTo(0.83, 0.001));
    expect(migrated.isValid, isTrue);
  });
}
