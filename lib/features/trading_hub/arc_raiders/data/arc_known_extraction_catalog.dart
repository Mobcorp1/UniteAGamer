class ArcKnownExtractionDefinition {
  const ArcKnownExtractionDefinition({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.type,
    required this.sourceNote,
  });

  final String id;
  final String name;
  final double x;
  final double y;
  final String type;
  final String sourceNote;
}

class ArcKnownExtractionCatalog {
  static const Map<String, List<ArcKnownExtractionDefinition>> byMap =
      <String, List<ArcKnownExtractionDefinition>>{
        'dam_battlegrounds': <ArcKnownExtractionDefinition>[
          ArcKnownExtractionDefinition(
            id: 'north_complex_elevator',
            name: 'North Complex Elevator',
            x: .67,
            y: .13,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'swampside_elevator',
            name: 'Swampside Elevator',
            x: .30,
            y: .43,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'water_treatment',
            name: 'Water Treatment',
            x: .44,
            y: .72,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'red_lakes_balcony_lift',
            name: 'Red Lakes Balcony Lift',
            x: .82,
            y: .76,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
        ],
        'spaceport': <ArcKnownExtractionDefinition>[
          ArcKnownExtractionDefinition(
            id: 'west_elevator',
            name: 'West Elevator',
            x: .13,
            y: .48,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'central_elevator',
            name: 'Central Elevator',
            x: .49,
            y: .48,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'south_elevator',
            name: 'South Elevator',
            x: .49,
            y: .86,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'east_elevator',
            name: 'East Elevator',
            x: .86,
            y: .48,
            type: 'Cargo elevator',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
        ],
        'buried_city': <ArcKnownExtractionDefinition>[
          ArcKnownExtractionDefinition(
            id: 'northern_station',
            name: 'Northern Station',
            x: .50,
            y: .13,
            type: 'Metro station',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'eastern_station',
            name: 'Eastern Station',
            x: .84,
            y: .51,
            type: 'Metro station',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'southern_station',
            name: 'Southern Station',
            x: .50,
            y: .87,
            type: 'Metro station',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'western_station',
            name: 'Western Station',
            x: .16,
            y: .51,
            type: 'Metro station',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
        ],
        'blue_gate': <ArcKnownExtractionDefinition>[
          ArcKnownExtractionDefinition(
            id: 'cliffside_airshaft',
            name: 'Cliffside Airshaft',
            x: .18,
            y: .32,
            type: 'Airshaft',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'forest_airshaft',
            name: 'Forest Airshaft',
            x: .28,
            y: .70,
            type: 'Airshaft',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'outlook_airshaft',
            name: 'Outlook Airshaft',
            x: .57,
            y: .46,
            type: 'Airshaft',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'warehouse_airshaft',
            name: 'Warehouse Airshaft',
            x: .82,
            y: .60,
            type: 'Airshaft',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
        ],
        'stella_montis': <ArcKnownExtractionDefinition>[
          ArcKnownExtractionDefinition(
            id: 'airshaft',
            name: 'Airshaft',
            x: .18,
            y: .42,
            type: 'Airshaft',
            sourceNote:
                'Web-verified type/name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'loading_bay_metro_station',
            name: 'Loading Bay Metro Station',
            x: .33,
            y: .74,
            type: 'Metro station',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
          ArcKnownExtractionDefinition(
            id: 'metro_station',
            name: 'Metro Station',
            x: .61,
            y: .48,
            type: 'Metro station',
            sourceNote: 'Web-verified name; admin-calibratable map position.',
          ),
        ],
      };

  static List<ArcKnownExtractionDefinition> forMap(String mapId) =>
      byMap[mapId] ?? const <ArcKnownExtractionDefinition>[];
}
