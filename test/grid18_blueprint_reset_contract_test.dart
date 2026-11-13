import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Clear Grid resets Frozen Trail additions and legacy blueprint ids', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    ).readAsStringSync();
    expect(source, contains('final allBlueprintIds = <String>{'));
    expect(source, contains('ArcBlueprintSeedData.blueprints'));
    expect(
      source,
      contains('ArcFrozenTrailCollectionCatalogue.blueprintEntries'),
    );
    expect(source, contains('resetAllBlueprintStates(allBlueprintIds)'));
  });
}
