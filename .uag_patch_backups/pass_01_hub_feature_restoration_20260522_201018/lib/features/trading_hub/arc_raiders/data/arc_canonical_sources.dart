enum ArcCanonicalKind {
  blueprint,
  resource,
  weapon,
  poi,
  container,
  trade,
  voice,
  quest,
  bench,
  unknown,
}

class ArcCanonicalSource {
  const ArcCanonicalSource({
    required this.kind,
    required this.canonicalPath,
    required this.owner,
    required this.adapters,
    required this.notes,
  });

  final ArcCanonicalKind kind;
  final String canonicalPath;
  final String owner;
  final List<String> adapters;
  final String notes;
}

class ArcCanonicalSources {
  const ArcCanonicalSources._();

  static const ArcCanonicalSource blueprints = ArcCanonicalSource(
    kind: ArcCanonicalKind.blueprint,
    canonicalPath:
        'lib/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart',
    owner: 'Blueprint Tracker',
    adapters: <String>[
      'arc_blueprint_fallback_data.dart',
      'arc_blueprint_intel_seed.dart',
      'arc_voice_item_database.dart',
      'unified_item_index.dart',
      'arc_trade_catalog.dart',
      'trade_items_data.dart',
    ],
    notes:
        'Blueprint Tracker owns blueprint identity, naming, category, row/group and rarity. Other files should adapt this data instead of redefining it.',
  );

  static const ArcCanonicalSource itemsResources = ArcCanonicalSource(
    kind: ArcCanonicalKind.resource,
    canonicalPath:
        'lib/features/trading_hub/arc_raiders/data/unified_item_index.dart',
    owner: 'Unified Item Index',
    adapters: <String>[
      'arc_scrappy_seed_data.dart',
      'arc_bench_upgrade_seed_data.dart',
      'arc_quest_requirement_seed_data.dart',
      'arc_trade_catalog.dart',
      'trade_items_data.dart',
      'arc_voice_item_database.dart',
    ],
    notes:
        'Unified Item Index should become the lookup source for resources, trinkets, quest items, scrappy items, weapons and tradeable objects.',
  );

  static const ArcCanonicalSource pois = ArcCanonicalSource(
    kind: ArcCanonicalKind.poi,
    canonicalPath:
        'lib/features/trading_hub/arc_raiders/data/arc_poi_data.dart',
    owner: 'Intel Reporting',
    adapters: <String>[
      'arc_location_descriptors.dart',
      'arc_drop_report_options.dart',
      'arc_map_conditions.dart',
      'raid_planner_event_schedule.dart',
    ],
    notes:
        'POI identity should live here. Intel, Raid Planner and voice lookups should reference these IDs.',
  );

  static const ArcCanonicalSource containers = ArcCanonicalSource(
    kind: ArcCanonicalKind.container,
    canonicalPath:
        'lib/features/trading_hub/arc_raiders/data/arc_container_types.dart',
    owner: 'Intel Reporting',
    adapters: <String>[
      'arc_blueprint_drop_report.dart',
      'arc_item_advice_index.dart',
      'arc_voice_item_database.dart',
    ],
    notes:
        'Container labels used by reports and voice should come from ArcContainerTypes.reportable.',
  );

  static const List<ArcCanonicalSource> all = <ArcCanonicalSource>[
    blueprints,
    itemsResources,
    pois,
    containers,
  ];

  static ArcCanonicalSource? forKind(ArcCanonicalKind kind) {
    for (final source in all) {
      if (source.kind == kind) return source;
    }
    return null;
  }
}
