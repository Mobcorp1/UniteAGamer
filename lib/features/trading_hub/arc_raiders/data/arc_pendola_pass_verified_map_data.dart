class ArcPendolaPassVerifiedMapData {
  const ArcPendolaPassVerifiedMapData._();

  static const String mapId = 'pendola_pass';
  static const String displayName = 'Pendola Pass';
  static const String masterAssetPath =
      'assets/arc_raiders/maps/pendola_pass/pendola_pass_master.webp';

  static const List<String> observedConditions = <String>[
    'Redirection',
    'Frigate',
  ];

  // Labels read directly from the user's launch-day in-game map captures.
  // Coordinates are intentionally not guessed. They become map markers only
  // after each position is verified against the final master image.
  static const List<String> verifiedPoiLabelsPendingCoordinates = <String>[
    'Baggage Claim',
    'Castle',
    'Check In',
    'City Hall',
    'Comms Facility',
    'Container Storage',
    'Contamination Zone',
    'Departure Building',
    'Extraction Materials',
    'Fortifications',
    'Gate Control Building',
    'Hangar',
    'Loading Bay',
    'Metro Shopping Mall',
    'Monastery',
    'Research Administration',
    'Slopes',
    'Train Station',
    'Village',
  ];
}
