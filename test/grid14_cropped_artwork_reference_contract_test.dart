import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Grid 14 matches artwork without requiring its removed footer', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart',
    ).readAsStringSync();
    expect(source, contains('artworkOnly: singleGrid'));
    expect(source, contains('artworkOnly ? 0.78 : 0.92'));
    expect(source, contains('_similarity(capturedSignature, template)'));
    expect(source, contains('this.minimumTemplateSimilarity = 0.34'));
    expect(source, contains('this.strongTemplateSimilarity = 0.58'));
  });
  test('capture registration, occupancy decision and writes are separate stages', () {
    final screen = File('lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart').readAsStringSync();
    expect(screen, contains('normalizeLocatedGrid(located)'));
    expect(screen, contains('ArcBlueprintPhotoOccupancyEngine('));
    expect(screen, contains('automaticUpdateBlockReason('));
    expect(screen, contains('ArcBlueprintPhotoImportService().apply('));
    expect(screen, contains('Update Blueprint Collection'));
  });
}
