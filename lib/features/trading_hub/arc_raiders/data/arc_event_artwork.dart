/// Stable event artwork paths. Unknown future conditions use a valid existing
/// raid asset rather than a missing path.
class ArcEventArtwork {
  const ArcEventArtwork._();

  static const String operations =
      'assets/arc_raiders/operations/claim_operations_card.webp';
  static const String nomadicTrader =
      'assets/arc_raiders/operations/check_nomadic_trader_card.webp';
  static const String fallback =
      'assets/arc_raiders/operations/weekly_raid_card.webp';

  static const Map<String, String> conditionSlugs = {
    'night raid': 'night_raid',
    'electromagnetic storm': 'electromagnetic_storm',
    'bloom': 'bloom',
    'cold snap': 'cold_snap',
    'hurricane': 'hurricane',
    'close scrutiny': 'close_scrutiny',
    'harvester': 'harvester',
    'matriarch': 'matriarch',
    'prospecting probes': 'prospecting_probes',
    'uncovered caches': 'uncovered_caches',
    'husk graveyard': 'husk_graveyard',
    'lush blooms': 'lush_blooms',
    'bird city': 'bird_city',
    'locked gate': 'locked_gate',
    'hidden bunker': 'hidden_bunker',
    'launch tower loot': 'launch_tower_loot',
    'beachcombing': 'beachcombing',
    'last resort': 'last_resort',
  };

  static String forCondition(String name) {
    final normalized = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final canonical = normalized == 'em storm'
        ? 'electromagnetic storm'
        : normalized == 'lush bloom'
            ? 'lush blooms'
            : normalized;
    final slug = conditionSlugs[canonical];
    if (slug == null) return fallback;
    return 'assets/arc_raiders/conditions/${slug}.svg';
  }
}
