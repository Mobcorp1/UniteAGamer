import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcMapMarkerFilterPreset {
  blueprintOpportunities,
  navigation,
  lootRun,
  communityIntel,
  everything,
}

extension ArcMapMarkerFilterPresetX on ArcMapMarkerFilterPreset {
  String get label {
    switch (this) {
      case ArcMapMarkerFilterPreset.blueprintOpportunities:
        return 'Blueprint Opportunities';
      case ArcMapMarkerFilterPreset.navigation:
        return 'Navigation';
      case ArcMapMarkerFilterPreset.lootRun:
        return 'Loot Run';
      case ArcMapMarkerFilterPreset.communityIntel:
        return 'Community Intel';
      case ArcMapMarkerFilterPreset.everything:
        return 'Everything';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcMapMarkerFilterPreset.blueprintOpportunities:
        return Icons.extension_rounded;
      case ArcMapMarkerFilterPreset.navigation:
        return Icons.assistant_navigation;
      case ArcMapMarkerFilterPreset.lootRun:
        return Icons.inventory_2_rounded;
      case ArcMapMarkerFilterPreset.communityIntel:
        return Icons.hub_rounded;
      case ArcMapMarkerFilterPreset.everything:
        return Icons.layers_rounded;
    }
  }
}

@immutable
class ArcMapMarkerFilterItem {
  const ArcMapMarkerFilterItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.apply,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool Function(ArcRaidMapFilterState filters) isSelected;
  final ArcRaidMapFilterState Function(
    ArcRaidMapFilterState filters,
    bool selected,
  )
  apply;
}

@immutable
class ArcMapMarkerFilterGroup {
  const ArcMapMarkerFilterGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<ArcMapMarkerFilterItem> items;
}

class ArcMapMarkerCatalog {
  const ArcMapMarkerCatalog._();

  static const List<ArcMapMarkerFilterPreset> presets =
      ArcMapMarkerFilterPreset.values;

  static final List<ArcMapMarkerFilterGroup> groups = [
    ArcMapMarkerFilterGroup(
      id: 'objectives',
      label: 'Objectives',
      icon: Icons.track_changes_rounded,
      items: [
        ArcMapMarkerFilterItem(
          id: 'missingBlueprints',
          label: 'Blueprint Opportunities',
          icon: Icons.extension_rounded,
          isSelected: (filters) => filters.missingBlueprints,
          apply: (filters, selected) =>
              filters.copyWith(missingBlueprints: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'topWanted',
          label: 'Top 5 Wanted',
          icon: Icons.local_fire_department_rounded,
          isSelected: (filters) => filters.topWanted,
          apply: (filters, selected) => filters.copyWith(topWanted: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'favouriteLoadout',
          label: 'Favourite Loadout',
          icon: Icons.star_rounded,
          isSelected: (filters) => filters.favouriteLoadout,
          apply: (filters, selected) =>
              filters.copyWith(favouriteLoadout: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'tradePreparation',
          label: 'Trade Preparation',
          icon: Icons.swap_horiz_rounded,
          isSelected: (filters) => filters.tradePreparation,
          apply: (filters, selected) =>
              filters.copyWith(tradePreparation: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'operations',
          label: 'Operations',
          icon: Icons.checklist_rounded,
          isSelected: (filters) => filters.operations,
          apply: (filters, selected) => filters.copyWith(operations: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'quests',
          label: 'Quests',
          icon: Icons.assignment_rounded,
          isSelected: (filters) => filters.quests,
          apply: (filters, selected) => filters.copyWith(quests: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'squadObjectives',
          label: 'Squad Objectives',
          icon: Icons.groups_rounded,
          isSelected: (filters) => filters.squadObjectives,
          apply: (filters, selected) =>
              filters.copyWith(squadObjectives: selected),
        ),
      ],
    ),
    ArcMapMarkerFilterGroup(
      id: 'map',
      label: 'Map',
      icon: Icons.map_rounded,
      items: [
        ArcMapMarkerFilterItem(
          id: 'mapBasics',
          label: 'POIs, Spawns & Extracts',
          icon: Icons.place_rounded,
          isSelected: (filters) => filters.mapBasics,
          apply: (filters, selected) => filters.copyWith(mapBasics: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'routeOnly',
          label: 'Current Route Only',
          icon: Icons.route_rounded,
          isSelected: (filters) => filters.routeOnly,
          apply: (filters, selected) => filters.copyWith(routeOnly: selected),
        ),
      ],
    ),
    ArcMapMarkerFilterGroup(
      id: 'loot',
      label: 'Loot Sources',
      icon: Icons.inventory_2_rounded,
      items: [
        ArcMapMarkerFilterItem(
          id: 'lootSources',
          label: 'Caches, Cases & Containers',
          icon: Icons.inventory_2_rounded,
          isSelected: (filters) => filters.lootSources,
          apply: (filters, selected) => filters.copyWith(lootSources: selected),
        ),
      ],
    ),
    ArcMapMarkerFilterGroup(
      id: 'intel',
      label: 'Intel',
      icon: Icons.hub_rounded,
      items: [
        ArcMapMarkerFilterItem(
          id: 'communityIntel',
          label: 'Community Reports',
          icon: Icons.people_alt_rounded,
          isSelected: (filters) => filters.communityIntel,
          apply: (filters, selected) =>
              filters.copyWith(communityIntel: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'researchedIntel',
          label: 'Researched Intel',
          icon: Icons.science_rounded,
          isSelected: (filters) => filters.researchedIntel,
          apply: (filters, selected) =>
              filters.copyWith(researchedIntel: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'confirmedIntel',
          label: 'Confirmed Intel',
          icon: Icons.verified_rounded,
          isSelected: (filters) => filters.confirmedIntel,
          apply: (filters, selected) =>
              filters.copyWith(confirmedIntel: selected),
        ),
      ],
    ),
    ArcMapMarkerFilterGroup(
      id: 'quality',
      label: 'Quality',
      icon: Icons.tune_rounded,
      items: [
        ArcMapMarkerFilterItem(
          id: 'highConfidence',
          label: 'High Confidence Only',
          icon: Icons.verified_user_rounded,
          isSelected: (filters) => filters.highConfidence,
          apply: (filters, selected) =>
              filters.copyWith(highConfidence: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'includeLimitedEvidence',
          label: 'Include Limited Evidence',
          icon: Icons.help_outline_rounded,
          isSelected: (filters) => filters.includeLimitedEvidence,
          apply: (filters, selected) =>
              filters.copyWith(includeLimitedEvidence: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'hideDisputed',
          label: 'Hide Disputed',
          icon: Icons.report_problem_outlined,
          isSelected: (filters) => filters.hideDisputed,
          apply: (filters, selected) =>
              filters.copyWith(hideDisputed: selected),
        ),
        ArcMapMarkerFilterItem(
          id: 'hideStale',
          label: 'Hide Stale',
          icon: Icons.history_toggle_off_rounded,
          isSelected: (filters) => filters.hideStale,
          apply: (filters, selected) => filters.copyWith(hideStale: selected),
        ),
      ],
    ),
  ];

  static ArcRaidMapFilterState applyPreset(
    ArcMapMarkerFilterPreset preset, {
    String searchQuery = '',
  }) {
    switch (preset) {
      case ArcMapMarkerFilterPreset.blueprintOpportunities:
        return ArcRaidMapFilterState.defaults.copyWith(
          searchQuery: searchQuery,
        );
      case ArcMapMarkerFilterPreset.navigation:
        return const ArcRaidMapFilterState(
          missingBlueprints: false,
          mapBasics: true,
          communityIntel: false,
          researchedIntel: false,
          confirmedIntel: false,
        ).copyWith(searchQuery: searchQuery);
      case ArcMapMarkerFilterPreset.lootRun:
        return const ArcRaidMapFilterState(
          missingBlueprints: false,
          lootSources: true,
          mapBasics: true,
          communityIntel: false,
          researchedIntel: false,
          confirmedIntel: false,
        ).copyWith(searchQuery: searchQuery);
      case ArcMapMarkerFilterPreset.communityIntel:
        return const ArcRaidMapFilterState(
          missingBlueprints: false,
          communityIntel: true,
          researchedIntel: true,
          confirmedIntel: true,
          mapBasics: true,
        ).copyWith(searchQuery: searchQuery);
      case ArcMapMarkerFilterPreset.everything:
        return const ArcRaidMapFilterState(
          missingBlueprints: true,
          topWanted: true,
          favouriteLoadout: true,
          tradePreparation: true,
          operations: true,
          quests: true,
          squadObjectives: true,
          lootSources: true,
          mapBasics: true,
          communityIntel: true,
          researchedIntel: true,
          confirmedIntel: true,
          includeLimitedEvidence: true,
          hideDisputed: false,
          hideStale: false,
        ).copyWith(searchQuery: searchQuery);
    }
  }

  static ArcMapMarkerFilterPreset? matchingPreset(
    ArcRaidMapFilterState filters,
  ) {
    for (final preset in presets) {
      final candidate = applyPreset(preset, searchQuery: filters.searchQuery);
      if (_sameConfiguration(candidate, filters)) return preset;
    }
    return null;
  }

  static bool _sameConfiguration(
    ArcRaidMapFilterState a,
    ArcRaidMapFilterState b,
  ) {
    return a.missingBlueprints == b.missingBlueprints &&
        a.topWanted == b.topWanted &&
        a.favouriteLoadout == b.favouriteLoadout &&
        a.tradePreparation == b.tradePreparation &&
        a.operations == b.operations &&
        a.quests == b.quests &&
        a.squadObjectives == b.squadObjectives &&
        a.lootSources == b.lootSources &&
        a.mapBasics == b.mapBasics &&
        a.communityIntel == b.communityIntel &&
        a.researchedIntel == b.researchedIntel &&
        a.confirmedIntel == b.confirmedIntel &&
        a.highConfidence == b.highConfidence &&
        a.includeLimitedEvidence == b.includeLimitedEvidence &&
        a.hideDisputed == b.hideDisputed &&
        a.hideStale == b.hideStale &&
        a.routeOnly == b.routeOnly;
  }
}
