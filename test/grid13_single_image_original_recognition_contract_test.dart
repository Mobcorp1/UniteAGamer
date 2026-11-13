import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Grid 13 uses one 17x6 registered capture with manual collection-update safety', () {
    final source = File('lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart').readAsStringSync();
    expect(source, contains('normalizeLocatedGrid(located)'));
    expect(source, contains('ArcBlueprintPhotoOccupancyEngine('));
    expect(source, contains('columns: 17'));
    expect(source, contains('columns: 17'));
    expect(source, contains('automaticUpdateBlockReason('));
    expect(source, contains('ArcBlueprintPhotoImportService().apply('));
    expect(source, contains('Update Blueprint Collection'));
    expect(source, isNot(contains('ArcBlueprintDualCaptureMergeEngine')));
  });

  test('Original six-signal thresholds remain unchanged', () {
    final structure = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_owned_cell_structure_verifier.dart',
    ).readAsStringSync();
    expect(structure, contains('singleGridBlueprintIds'));
    expect(structure, contains('_evaluateRequiredSignals('));
    expect(structure, contains('failedSignals'));
    final marker = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_ownership_marker_verification_engine.dart',
    ).readAsStringSync();
    expect(marker, contains('minimumCorroboratedMarkerEvidence'));
    final template = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart',
    ).readAsStringSync();
    expect(template, contains('this.ownedThreshold = 0.84'));
    final calibration = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_personal_calibration_engine.dart',
    ).readAsStringSync();
    expect(calibration, contains('this.baseOwnedThreshold = 0.84'));
  });
}
