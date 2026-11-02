import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/research/uag_research_catalogue.dart';

void main() {
  test('research blueprint recipes have unique ids and positive material costs', () {
    final recipes = UagResearchCatalogue.recipes.where((r) => r.kind == 'blueprint').toList();
    expect(recipes.length, 15);
    expect(recipes.map((r) => r.id).toSet().length, recipes.length);
    for (final recipe in recipes) {
      expect(recipe.stationLevel, inInclusiveRange(1, 3));
      expect(recipe.researchPoints, greaterThan(0));
      expect(recipe.materials, isNotEmpty);
      for (final item in recipe.materials) {
        expect(item.quantity, greaterThan(0));
      }
    }
    expect(UagResearchCatalogue.researchableBlueprints['canto']?.researchPoints, 2000);
    expect(UagResearchCatalogue.researchableBlueprints['bantam']?.stationLevel, 1);
  });
}
