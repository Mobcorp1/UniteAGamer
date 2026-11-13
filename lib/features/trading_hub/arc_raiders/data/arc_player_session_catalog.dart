import 'package:flutter/material.dart';

class ArcPlayerSessionCatalog {
  const ArcPlayerSessionCatalog._();

  static const String defaultIntent = 'Flexible';
  static const String defaultPriority = 'Balanced progression';

  static const List<String> sessionIntents = <String>[
    'Flexible',
    'Trials',
    'Quests',
    'Blueprint farming',
    'Trading',
    'PvP',
    'PvE',
    'Resource farming',
    'Helping others',
    'Squad up',
    'Solo for now',
  ];

  static const List<String> priorities = <String>[
    'Balanced progression',
    'Trials',
    'Blueprint progress',
    'Quest progress',
    'Trading',
    'Favourite loadout',
    'Bench upgrades',
    'Reputation',
    'Resource farming',
  ];

  static String normalizeIntent(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final option in sessionIntents) {
      if (option.toLowerCase() == normalized) return option;
    }
    if (normalized == 'trial' || normalized == 'trial runs') return 'Trials';
    if (normalized == 'quest team' || normalized == 'questing') return 'Quests';
    if (normalized == 'blueprint runs') return 'Blueprint farming';
    if (normalized == 'trade focused') return 'Trading';
    return defaultIntent;
  }

  static String normalizePriority(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final option in priorities) {
      if (option.toLowerCase() == normalized) return option;
    }
    if (normalized == 'trial' || normalized == 'trial runs') return 'Trials';
    return defaultPriority;
  }

  static String intentDescription(String value) => switch (normalizeIntent(
    value,
  )) {
    'Trials' =>
      'Focus this session on Trials progress and compatible teammates.',
    'Quests' =>
      'Prioritise quest steps and players working on the same objectives.',
    'Blueprint farming' =>
      'Hunt missing blueprints and useful duplicate trade stock.',
    'Trading' =>
      'Look for listings, direct matches and trade-chain opportunities.',
    'PvP' => 'Seek confident combat-focused runs and compatible PvP players.',
    'PvE' => 'Focus on ARC encounters, objectives and steady progression.',
    'Resource farming' =>
      'Collect materials needed for upgrades, crafting and trades.',
    'Helping others' =>
      'Support other raiders with quests, progression and learning.',
    'Squad up' => 'Find compatible players and form a squad for this session.',
    'Solo for now' =>
      'Keep recommendations useful without actively seeking a squad.',
    _ => 'Keep recommendations balanced across your current progression needs.',
  };

  static String priorityDescription(String value) => switch (normalizePriority(
    value,
  )) {
    'Trials' =>
      'Put Trials at the top of Command Centre and match recommendations.',
    'Blueprint progress' =>
      'Prioritise missing blueprints, Intel and trade routes.',
    'Quest progress' => 'Surface quest steps and related raid targets first.',
    'Trading' =>
      'Prioritise direct matches, chains and watched trade readiness.',
    'Favourite loadout' =>
      'Focus recommendations on completing your saved build.',
    'Bench upgrades' =>
      'Surface materials and actions needed for bench progression.',
    'Reputation' =>
      'Prioritise trusted activity and reputation-building actions.',
    'Resource farming' =>
      'Focus on materials required for current progression.',
    _ => 'Balance the strongest available progression opportunities.',
  };

  static IconData iconFor(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('trial')) return Icons.emoji_events_rounded;
    if (normalized.contains('blueprint')) return Icons.description_rounded;
    if (normalized.contains('quest')) return Icons.flag_rounded;
    if (normalized.contains('trad')) return Icons.swap_horiz_rounded;
    if (normalized.contains('pvp')) return Icons.gps_fixed_rounded;
    if (normalized.contains('pve')) return Icons.shield_rounded;
    if (normalized.contains('resource')) return Icons.inventory_2_rounded;
    if (normalized.contains('help')) return Icons.volunteer_activism_rounded;
    if (normalized.contains('squad')) return Icons.groups_rounded;
    if (normalized.contains('solo')) return Icons.person_rounded;
    if (normalized.contains('loadout')) return Icons.construction_rounded;
    if (normalized.contains('bench')) return Icons.build_rounded;
    if (normalized.contains('reputation')) return Icons.verified_rounded;
    return Icons.hub_rounded;
  }
}
