import '../models/arc_collection_models.dart';
import 'arc_blueprint_seed_data.dart';

class ArcFrozenTrailCollectionCatalogue {
  const ArcFrozenTrailCollectionCatalogue._();

  static const blueprintGrid = ArcCollectionGridSpec(
    type: ArcCollectionType.blueprints,
    totalSlots: 91,
    rowColumnCounts: <int>[17, 17, 17, 17, 17, 6],
  );

  static const stencilGrid = ArcCollectionGridSpec(
    type: ArcCollectionType.stencils,
    totalSlots: 14,
    rowColumnCounts: <int>[9, 5],
  );

  static const designGrid = ArcCollectionGridSpec(
    type: ArcCollectionType.designs,
    totalSlots: 100,
    rowColumnCounts: <int>[17, 17, 17, 17, 17, 15],
  );

  static const specs = <ArcCollectionType, ArcCollectionGridSpec>{
    ArcCollectionType.blueprints: blueprintGrid,
    ArcCollectionType.stencils: stencilGrid,
    ArcCollectionType.designs: designGrid,
  };

  /// Frozen Trail Blueprint positions, updated using in-game main and mule
  /// account verification. Unknown positions are never assigned ownership.
  ///
  /// Important: an unowned in-game cell is not an empty physical slot. The
  /// first 17 positions preserve the first 17 entries of the old canonical
  /// order; cells 12 and 13 are simply unowned in the supplied screenshot.
  static const verifiedLegacyBlueprintEntries = <ArcCollectionEntry>[
    ArcCollectionEntry(
      id: 'extended-shotgun-mag-iii',
      name: 'Extended Shotgun Mag III',
      type: ArcCollectionType.blueprints,
      slot: 1,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'angled-grip-iii',
      name: 'Angled Grip III',
      type: ArcCollectionType.blueprints,
      slot: 2,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'pulse-mine',
      name: 'Pulse Mine',
      type: ArcCollectionType.blueprints,
      slot: 3,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'silencer-ii',
      name: 'Silencer II',
      type: ArcCollectionType.blueprints,
      slot: 4,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'red-light-stick',
      name: 'Red Light Stick',
      type: ArcCollectionType.blueprints,
      slot: 5,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'tactical-mk-3-revival',
      name: 'Tactical Mk. 3 (Revival)',
      type: ArcCollectionType.blueprints,
      slot: 6,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'compensator-ii',
      name: 'Compensator II',
      type: ArcCollectionType.blueprints,
      slot: 7,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'muzzle-brake-iii',
      name: 'Muzzle Brake III',
      type: ArcCollectionType.blueprints,
      slot: 8,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'tactical-mk-3-defensive',
      name: 'Tactical Mk. 3 (Defensive)',
      type: ArcCollectionType.blueprints,
      slot: 9,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'vita-spray',
      name: 'Vita Spray',
      type: ArcCollectionType.blueprints,
      slot: 10,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'medium-gun-parts',
      name: 'Medium Gun Parts',
      type: ArcCollectionType.blueprints,
      slot: 11,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'tagging-grenade',
      name: 'Tagging Grenade',
      type: ArcCollectionType.blueprints,
      slot: 12,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'crash-mat',
      name: 'Crash Mat',
      type: ArcCollectionType.blueprints,
      slot: 13,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'bobcat',
      name: 'Bobcat',
      type: ArcCollectionType.blueprints,
      slot: 14,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'defibrillator',
      name: 'Defibrillator',
      type: ArcCollectionType.blueprints,
      slot: 15,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'jupiter',
      name: 'Jupiter',
      type: ArcCollectionType.blueprints,
      slot: 16,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'extended-medium-mag-ii',
      name: 'Extended Medium Mag II',
      type: ArcCollectionType.blueprints,
      slot: 17,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'muzzle-brake-ii',
      name: 'Muzzle Brake II',
      type: ArcCollectionType.blueprints,
      slot: 86,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'snap-hook',
      name: 'Snap Hook',
      type: ArcCollectionType.blueprints,
      slot: 91,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
  ];

  static const frozenTrailBlueprintAdditions = <ArcCollectionEntry>[
    ArcCollectionEntry(
      id: 'vita-shot',
      name: 'Vita Shot',
      type: ArcCollectionType.blueprints,
      slot: 38,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'extended-light-mag-iii',
      name: 'Extended Light Mag III',
      type: ArcCollectionType.blueprints,
      slot: 60,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'burletta',
      name: 'Burletta',
      type: ArcCollectionType.blueprints,
      slot: 89,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'advanced-camera',
      name: 'Advanced Camera',
      type: ArcCollectionType.blueprints,
      slot: 46,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'banjo',
      name: 'Banjo',
      type: ArcCollectionType.blueprints,
      slot: 40,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      sourceLabel: 'Frozen Trail blueprint',
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'bantam',
      name: 'Bantam',
      type: ArcCollectionType.blueprints,
      slot: 62,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'emperor-gateway-conduit',
      name: 'Emperor Gateway Conduit',
      type: ArcCollectionType.blueprints,
      slot: 68,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'grappling-hook',
      name: 'Grappling Hook',
      type: ArcCollectionType.blueprints,
      slot: 58,
      confidence: ArcCollectionSlotConfidence.confirmedItemUnknownSlot,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'stiletto',
      name: 'Stiletto',
      type: ArcCollectionType.blueprints,
      slot: 26,
      confidence: ArcCollectionSlotConfidence.confirmedItemUnknownSlot,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'tether-launcher',
      name: 'Tether Launcher',
      type: ArcCollectionType.blueprints,
      slot: 56,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
    ArcCollectionEntry(
      id: 'yank-grenade',
      name: 'Yank Grenade',
      type: ArcCollectionType.blueprints,
      slot: 88,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.supported,
      tradeStatus: ArcCollectionEconomyStatus.supported,
    ),
  ];

  static const stencilEntries = <ArcCollectionEntry>[
    ArcCollectionEntry(
      id: 'milky-terracotta',
      name: 'Milky Terracotta',
      type: ArcCollectionType.stencils,
      slot: 5,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      duplicateStatus: ArcCollectionEconomyStatus.unknown,
      tradeStatus: ArcCollectionEconomyStatus.unknown,
    ),
    ArcCollectionEntry(
      id: 'dragons-breath',
      name: "Dragon's Breath",
      type: ArcCollectionType.stencils,
      slot: 9,
      confidence: ArcCollectionSlotConfidence.verifiedInGame,
      sourceLabel: 'Collector Set DLC',
      duplicateStatus: ArcCollectionEconomyStatus.unknown,
      tradeStatus: ArcCollectionEconomyStatus.unknown,
    ),
  ];

  static const designEntries = <ArcCollectionEntry>[];

  /// Existing Blueprint identity is always sourced from the old canonical seed.
  /// Slots are display positions, NEVER persistence/ownership keys.
  /// Positions 60, 62 and 89 are verified in-game; stable IDs are preserved.
  /// Legacy ownership IDs and duplicate counts are never rewritten.
  static const legacyBlueprintSlotOrder = <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    41,
    42,
    43,
    44,
    45,
    47,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    57,
    59,
    58,
    61,
    63,
    64,
    65,
    66,
    67,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
    82,
    83,
    84,
    85,
    86,
    87,
    88,
    90,
    91,
  ];

  static const verifiedGridSlots = <int>{
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    25,
    29,
    30,
    32,
    33,
    35,
    36,
    37,
    39,
    41,
    42,
    43,
    44,
    47,
    48,
    49,
    50,
    52,
    53,
    61,
    63,
    65,
    66,
    67,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    80,
    85,
    86,
    91,
  };

  static List<ArcCollectionEntry> get mappedLegacyBlueprintEntries {
    final existingIds = verifiedLegacyBlueprintEntries.map((e) => e.id).toSet();
    final seeds = ArcBlueprintSeedData.blueprints;
    if (seeds.length != legacyBlueprintSlotOrder.length) {
      throw StateError(
        'Frozen Trail legacy Blueprint seed count changed; migration must be reviewed.',
      );
    }
    return <ArcCollectionEntry>[
      for (var index = 0; index < seeds.length; index++)
        if (!existingIds.contains(seeds[index].id) &&
            legacyBlueprintSlotOrder[index] != 58 &&
            seeds[index].id != 'vita-shot' &&
            seeds[index].id != 'burletta' &&
            seeds[index].id != 'extended-light-mag-iii')
          ArcCollectionEntry(
            id: seeds[index].id,
            name: seeds[index].name,
            type: ArcCollectionType.blueprints,
            slot: legacyBlueprintSlotOrder[index],
            confidence:
                verifiedGridSlots.contains(legacyBlueprintSlotOrder[index])
                ? ArcCollectionSlotConfidence.verifiedInGame
                : ArcCollectionSlotConfidence.unverified,
            duplicateStatus: ArcCollectionEconomyStatus.supported,
            tradeStatus: ArcCollectionEconomyStatus.supported,
          ),
    ];
  }

  /// These names match the incoming PNG-to-WebP asset workflow; no new assets
  /// are required at install time. Asset display must be wired in the live UI.
  static const frozenTrailArtworkPaths = <String, String>{
    'yank-grenade': 'assets/arc_raiders/blueprints/yank-grenade.webp',
    'grappling-hook': 'assets/arc_raiders/blueprints/grappling-hook.webp',
    'tether-launcher': 'assets/arc_raiders/blueprints/tether-launcher.webp',
    'stiletto': 'assets/arc_raiders/blueprints/stiletto.webp',
    'banjo': 'assets/arc_raiders/blueprints/banjo.webp',
    'advanced-camera': 'assets/arc_raiders/blueprints/advanced-camera.webp',
    'bantam': 'assets/arc_raiders/blueprints/bantam.webp',
    'emperor-gateway-conduit':
        'assets/arc_raiders/blueprints/emperor-gateway-conduit.webp',
  };

  static List<ArcCollectionEntry> get blueprintEntries => <ArcCollectionEntry>[
    ...verifiedLegacyBlueprintEntries,
    ...mappedLegacyBlueprintEntries,
    ...frozenTrailBlueprintAdditions,
  ];

  static List<ArcCollectionEntry> entriesFor(ArcCollectionType type) {
    return switch (type) {
      ArcCollectionType.blueprints => blueprintEntries,
      ArcCollectionType.stencils => stencilEntries,
      ArcCollectionType.designs => designEntries,
    };
  }

  static ArcCollectionEntry? entryAtSlot(ArcCollectionType type, int slot) {
    for (final entry in entriesFor(type)) {
      if (entry.slot == slot) return entry;
    }
    return null;
  }
}
