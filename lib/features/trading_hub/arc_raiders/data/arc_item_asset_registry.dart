class ArcItemAssetRegistry {
  const ArcItemAssetRegistry._();

  static const String runtimeBase = 'assets/arc_raiders/scrappy_resources/';
  static const String targetCanonicalBase = 'assets/arc_raiders/items/';

  // Const-safe Scrappy paths.
  static const String dogCollar = '${runtimeBase}dog_collar.webp';
  static const String lemons = '${runtimeBase}lemons.webp';
  static const String apricots = '${runtimeBase}apricots.webp';
  static const String pricklyPears = '${runtimeBase}prickly_pears.webp';
  static const String olives = '${runtimeBase}olives.webp';
  static const String catBed = '${runtimeBase}cat_bed.webp';
  static const String mushrooms = '${runtimeBase}mushrooms.webp';
  static const String veryComfortablePillows =
      '${runtimeBase}very_comfortable_pillows.webp';

  static const Map<String, String> _aliases = {
    'apricot': 'apricots',
    'lemon': 'lemons',
    'prickly-pear': 'prickly-pears',
    'very-comfortable-pillow': 'very-comfortable-pillows',
    'wasp-driver': 'wasp-drivers',
    'hornet-driver': 'hornet-drivers',
    'snitch-scanner': 'snitch-scanners',
    'leaper-pulse-unit': 'leaper-pulse-units',
    'surveyor-vault': 'surveyor-vaults',
    'fireball-burner': 'fireball-burners',
    'rocketeer-driver': 'rocketeer-drivers',
    'bastion-cell': 'bastion-cells',
    'tick-pod': 'tick-pods',
    'electrical-component': 'electrical-components',
    'mechanical-component': 'mechanical-components',
    'advanced-electrical-component': 'advanced-electrical-components',
    'advanced-mechanical-component': 'advanced-mechanical-components',
    'wire': 'wires',
  };

  static String canonicalId(String itemId) {
    final clean = itemId.trim().toLowerCase();
    return _aliases[clean] ?? clean;
  }

  // These resource IDs are valid upgrade requirements, but individual
  // artwork has not been supplied yet. Use one explicitly labelled neutral
  // fallback rather than a broken image or a different item's picture.
  static const String upgradeArtworkPending =
      '${runtimeBase}upgrade_resource_art_pending.webp';

  static const Set<String> _pendingArtworkItemIds = <String>{
    'arc-data-modules',
    'radial-presses',
    'emperor-modulators',
    'planks',
    'battered-paperbacks',
    'mini-pumps',
    'calculators',
    'raider-logbooks',
    'skulker-targeters',
    'differential-microphones',
    'exodus-technical-handbooks',
    'bully-fragmenters',
    'thermal-shakers',
    'frigate-inductors',
  };

  static String assetPathForId(String itemId) {
    final id = canonicalId(itemId);
    // Existing confirmed singular artwork; do not duplicate under a fake name.
    if (id == 'magnetic-accelerators') {
      return '${runtimeBase}magnetic_accelerator.webp';
    }
    if (_pendingArtworkItemIds.contains(id)) {
      return upgradeArtworkPending;
    }
    return '$runtimeBase${id.replaceAll('-', '_')}.webp';
  }

  static String targetItemAssetPathForId(String itemId) {
    final id = canonicalId(itemId);
    return '$targetCanonicalBase${id.replaceAll('-', '_')}.webp';
  }
}
