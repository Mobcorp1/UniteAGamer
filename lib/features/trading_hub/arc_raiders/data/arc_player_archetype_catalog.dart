import 'package:flutter/material.dart';

class ArcPlayerArchetype {
  const ArcPlayerArchetype({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.aliases = const <String>[],
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<String> aliases;

  Map<String, dynamic> toMap() {
    return {'id': id, 'label': label, 'description': description};
  }
}

class ArcPlayerArchetypeCatalog {
  const ArcPlayerArchetypeCatalog._();

  static const balanced = ArcPlayerArchetype(
    id: 'balanced-raider',
    label: 'Balanced Raider',
    description: 'Blends quests, blueprints, loot, trading and squad play.',
    icon: Icons.explore_rounded,
    aliases: <String>['Balanced'],
  );

  static const questDriven = ArcPlayerArchetype(
    id: 'quest-driven-raider',
    label: 'Quest-driven Raider',
    description: 'Prioritises quests, unlocks and guided progression.',
    icon: Icons.flag_rounded,
    aliases: <String>['Quest focused', 'Quest-driven', 'Quest driven'],
  );

  static const blueprintGrinder = ArcPlayerArchetype(
    id: 'blueprint-grinder',
    label: 'Blueprint Grinder',
    description:
        'Prioritises blueprint collection, duplicates and trade value.',
    icon: Icons.description_rounded,
    aliases: <String>['Blueprint grinder', 'Blueprint farming'],
  );

  static const helper = ArcPlayerArchetype(
    id: 'helper-support-player',
    label: 'Helper / Support Player',
    description: 'Focuses on team utility, survival and helping the squad.',
    icon: Icons.volunteer_activism_rounded,
    aliases: <String>['Squad support', 'Helper', 'Support Player'],
  );

  static const trader = ArcPlayerArchetype(
    id: 'trader-resource-runner',
    label: 'Trader / Resource Runner',
    description: 'Builds stash value, materials and safe extraction routes.',
    icon: Icons.handshake_rounded,
    aliases: <String>['Loot runner', 'Resource running', 'Trader'],
  );

  static const pvpHunter = ArcPlayerArchetype(
    id: 'pvp-hunter',
    label: 'PvP Hunter',
    description: 'Prioritises combat readiness and confident raids.',
    icon: Icons.local_fire_department_rounded,
    aliases: <String>['PvP hunter', 'PvP focused'],
  );

  static const ratHunter = ArcPlayerArchetype(
    id: 'rat-hunter',
    label: 'Rat Hunter',
    description:
        'Actively hunts campers, ambushers, hidden threats and opportunistic attackers.',
    icon: Icons.radar_rounded,
    aliases: <String>[
      'Rat hunter',
      'Anti-rat',
      'Ambush hunter',
      'Camper hunter',
    ],
  );

  static const casual = ArcPlayerArchetype(
    id: 'casual-squad-player',
    label: 'Casual Squad Player',
    description: 'Prefers low-pressure play, discovery and flexible goals.',
    icon: Icons.groups_rounded,
    aliases: <String>['Casual explorer', 'Casual'],
  );

  static const all = <ArcPlayerArchetype>[
    balanced,
    questDriven,
    blueprintGrinder,
    helper,
    trader,
    pvpHunter,
    ratHunter,
    casual,
  ];

  static const defaultLabel = 'Balanced Raider';

  static List<String> get labels =>
      all.map((item) => item.label).toList(growable: false);

  static ArcPlayerArchetype fromLabel(String value) {
    final normalized = _normalize(value);
    for (final archetype in all) {
      if (_normalize(archetype.label) == normalized ||
          _normalize(archetype.id) == normalized ||
          archetype.aliases.any((alias) => _normalize(alias) == normalized)) {
        return archetype;
      }
    }
    return ArcPlayerArchetype(
      id: normalized.isEmpty ? 'custom' : normalized.replaceAll(' ', '-'),
      label: value.trim(),
      description: 'Custom raider identity',
      icon: Icons.person_pin_circle_rounded,
    );
  }

  static List<String> normalizeLabels(
    Iterable<dynamic> values, {
    bool includeDefaultWhenEmpty = false,
  }) {
    final labels = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) continue;
      final archetype = fromLabel(raw);
      final key = _normalize(archetype.label);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      labels.add(archetype.label);
    }

    if (labels.isEmpty && includeDefaultWhenEmpty) {
      labels.add(defaultLabel);
    }

    return labels;
  }

  static List<String> normalizeFromMap(
    Map<String, dynamic> map,
    List<String> keys, {
    bool includeDefaultWhenEmpty = false,
  }) {
    final values = <dynamic>[];
    for (final key in keys) {
      final raw = map[key];
      if (raw is Iterable) {
        values.addAll(raw);
      } else if (raw != null) {
        values.add(raw);
      }
    }
    return normalizeLabels(
      values,
      includeDefaultWhenEmpty: includeDefaultWhenEmpty,
    );
  }

  static String descriptionFor(String value) => fromLabel(value).description;

  static IconData iconFor(String value) => fromLabel(value).icon;

  static bool hasRatHunter(Iterable<String> values) {
    return normalizeLabels(values).contains(ratHunter.label);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
