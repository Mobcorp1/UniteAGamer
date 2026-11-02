import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

/// The same canonical 91-position catalogue shown by the Collections grid.
class ArcCanonicalBlueprintCatalogue {
  const ArcCanonicalBlueprintCatalogue._();

  static List<ArcBlueprint> get blueprints {
    final seeds = {for (final bp in ArcBlueprintSeedData.blueprints) bp.id: bp};
    final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries;
    final ids = <String>{};
    return [
      for (final entry in entries)
        if (ids.add(entry.id))
          ArcBlueprint(
            id: entry.id,
            name: entry.name,
            category: seeds[entry.id]?.category ?? 'Blueprints',
            group: seeds[entry.id]?.group ?? 'Frozen Trail',
            sortOrder: entry.slot ?? entries.indexOf(entry),
            rarity: seeds[entry.id]?.rarity ?? ArcBlueprintRarity.uncommon,
            icon: seeds[entry.id]?.icon ?? Icons.inventory_2_outlined,
            imageAssetPath: seeds[entry.id]?.imageAssetPath ??
                ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths[entry.id],
            intelHint: seeds[entry.id]?.intelHint ?? 'Frozen Trail Blueprint',
          ),
    ];
  }

  static ArcBlueprint? byName(String name) {
    final sought = name.trim().toLowerCase();
    for (final bp in blueprints) {
      if (bp.name.trim().toLowerCase() == sought || bp.id == sought) return bp;
    }
    return null;
  }

  static List<ArcBlueprint> missing(Map<String, ArcBlueprintState> states) =>
      blueprints.where((bp) => states[bp.id]?.owned != true).toList(growable: false);
}
