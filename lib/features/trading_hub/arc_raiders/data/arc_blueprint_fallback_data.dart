import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';

class ArcBlueprintResearchedFallback {
  const ArcBlueprintResearchedFallback({
    required this.blueprintName,
    required this.maps,
    required this.events,
    required this.sources,
    required this.confidenceLabel,
    required this.notes,
  });

  final String blueprintName;
  final List<String> maps;
  final List<String> events;
  final List<String> sources;
  final String confidenceLabel;
  final String notes;
}

class ArcBlueprintFallbackData {
  ArcBlueprintFallbackData._();

  static const Map<String, ArcBlueprintResearchedFallback> byBlueprintName = {
    'Crash Mat': ArcBlueprintResearchedFallback(
      blueprintName: 'Crash Mat',
      maps: ['Riven Tides'],
      events: ['Day Raid', 'Beachcombing'],
      sources: ['Riven Tides loot containers', 'Beach / Harbor routes'],
      confidenceLabel: 'User-confirmed',
      notes:
          'User confirmed Crash Mat blueprint on Riven Tides Day Raid. Keep Riven Tides-only until wider reports prove otherwise.',
    ),
    'Powered Descender': ArcBlueprintResearchedFallback(
      blueprintName: 'Powered Descender',
      maps: ['Riven Tides'],
      events: ['Day Raid', 'Night Raid', 'Beachcombing'],
      sources: [
        'Riven Tides loot containers',
        'Turbine / vertical traversal routes',
      ],
      confidenceLabel: 'User-confirmed',
      notes:
          'User confirmed Powered Descender on Riven Tides Day Raid and Night Raid.',
    ),
    'White Flag': ArcBlueprintResearchedFallback(
      blueprintName: 'White Flag',
      maps: ['Riven Tides'],
      events: ['Day Raid', 'Beachcombing'],
      sources: ['Riven Tides general loot', 'Beachcombing routes'],
      confidenceLabel: 'Patch-seeded',
      notes:
          'Official Riven Tides item. Use Riven Tides fallback until user intel replaces this.',
    ),
    'Tactical Mk. 3 (Smoke)': ArcBlueprintResearchedFallback(
      blueprintName: 'Tactical Mk. 3 (Smoke)',
      maps: ['Riven Tides'],
      events: ['Day Raid', 'Night Raid', 'Beachcombing'],
      sources: ['Riven Tides tactical/support loot routes'],
      confidenceLabel: 'Patch-seeded',
      notes:
          'Official Riven Tides augment. Treat as Riven Tides-first until user reports confirm broader pools.',
    ),
  };

  static ArcBlueprintResearchedFallback? forBlueprint(ArcBlueprint blueprint) {
    return byBlueprintName[blueprint.name.trim()];
  }
}
