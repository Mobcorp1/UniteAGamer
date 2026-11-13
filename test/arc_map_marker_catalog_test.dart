import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('Blueprint Opportunities is the global default marker preset', () {
    const defaults = ArcRaidMapFilterState.defaults;

    expect(defaults.missingBlueprints, isTrue);
    expect(defaults.topWanted, isFalse);
    expect(defaults.favouriteLoadout, isFalse);
    expect(defaults.tradePreparation, isFalse);
    expect(defaults.operations, isFalse);
    expect(defaults.quests, isFalse);
    expect(defaults.squadObjectives, isFalse);
    expect(defaults.lootSources, isFalse);
    expect(defaults.mapBasics, isFalse);
    expect(defaults.communityIntel, isFalse);
    expect(defaults.researchedIntel, isFalse);
    expect(defaults.confirmedIntel, isFalse);
    expect(
      ArcMapMarkerCatalog.matchingPreset(defaults),
      ArcMapMarkerFilterPreset.blueprintOpportunities,
    );
  });

  test('shared marker catalog exposes every production filter group', () {
    expect(
      ArcMapMarkerCatalog.groups.map((group) => group.id),
      containsAll(<String>['objectives', 'map', 'loot', 'intel', 'quality']),
    );

    final ids = ArcMapMarkerCatalog.groups
        .expand((group) => group.items)
        .map((item) => item.id)
        .toSet();

    expect(ids, contains('missingBlueprints'));
    expect(ids, contains('mapBasics'));
    expect(ids, contains('lootSources'));
    expect(ids, contains('communityIntel'));
    expect(ids, contains('highConfidence'));
  });

  test('presets are map-agnostic filter configurations', () {
    final navigation = ArcMapMarkerCatalog.applyPreset(
      ArcMapMarkerFilterPreset.navigation,
    );
    final loot = ArcMapMarkerCatalog.applyPreset(
      ArcMapMarkerFilterPreset.lootRun,
    );
    final everything = ArcMapMarkerCatalog.applyPreset(
      ArcMapMarkerFilterPreset.everything,
    );

    expect(navigation.mapBasics, isTrue);
    expect(navigation.missingBlueprints, isFalse);
    expect(loot.lootSources, isTrue);
    expect(loot.mapBasics, isTrue);
    expect(everything.missingBlueprints, isTrue);
    expect(everything.communityIntel, isTrue);
    expect(everything.hideDisputed, isFalse);
  });
}
