import '../models/arc_blueprint_state.dart';
import '../models/arc_loadout_models.dart';
import '../models/arc_progression_models.dart';
import '../models/arc_user_personalisation_profile.dart';
import '../raid_planner/data/arc_regional_opportunity_engine.dart';
import '../raid_planner/data/raid_planner_event_schedule.dart';
import '../raid_planner/models/raid_planner_models.dart';

/// Presentation ranking only. Schedule and reward rules remain Planner-owned.
class ArcEventRelevance {
  const ArcEventRelevance({
    this.profile = ArcUserPersonalisationProfile.defaults,
    this.blueprints,
    this.loadouts = const [],
    this.progression = ArcProgressionSnapshotBundle.empty,
  });

  final ArcUserPersonalisationProfile profile;
  final Map<String, ArcBlueprintState>? blueprints;
  final List<ArcSavedLoadout> loadouts;
  final ArcProgressionSnapshotBundle progression;

  bool get showEverything =>
      !profile.hasExplicitPreferences ||
      !profile.reduceNoise ||
      profile.goals.contains(ArcPersonalisationGoal.exploreEverything);

  bool interested(ArcPersonalisationFeature feature) =>
      profile.interestFor(feature).isHighSignal;

  List<ArcEventMatch> rank({
    required DateTime nowUtc,
    List<RaidPlannerEventSlot> slots = RaidPlannerEventSchedule.slots,
    bool showAll = false,
  }) {
    final results = [
      for (final slot in slots)
        ArcEventMatch(
          slot: slot,
          startUtc: slot.activeStartFor(nowUtc),
          endUtc: slot.activeEndFor(nowUtc),
          reasons: reasonsFor(slot.eventName, slot.mapName),
        ),
    ];
    results.sort((a, b) {
      if (a.isActive(nowUtc) != b.isActive(nowUtc)) {
        return a.isActive(nowUtc) ? -1 : 1;
      }
      if (!showAll && !showEverything) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
      }
      final time = a.startUtc.compareTo(b.startUtc);
      if (time != 0) return time;
      return '${a.slot.mapName}|${a.slot.eventName}|${a.slot.lane}'.compareTo(
        '${b.slot.mapName}|${b.slot.eventName}|${b.slot.lane}',
      );
    });
    return results;
  }

  Map<String, int> reasonsFor(String event, String map) {
    final reasons = <String, int>{};
    final blueprintGoal =
        interested(ArcPersonalisationFeature.blueprintTracker) ||
        interested(ArcPersonalisationFeature.blueprintIntelligence);
    final loadoutGoal = interested(ArcPersonalisationFeature.favouriteLoadout);
    if (blueprints != null && (blueprintGoal || loadoutGoal)) {
      final loadoutNames = <String>{
        for (final loadout in loadouts) ...[
          loadout.primaryWeapon,
          loadout.secondaryWeapon,
          ...loadout.primaryAttachments,
          ...loadout.secondaryAttachments,
        ],
      }.map(_normal).toSet();
      for (final rule in ArcRegionalOpportunityEngine.missingBlueprintRules(
        blueprints!,
      )) {
        if (!_matches(rule, event, map)) continue;
        final loadoutMatch =
            loadoutGoal && loadoutNames.contains(_normal(rule.label));
        if (!blueprintGoal && !loadoutMatch) continue;
        final priority = blueprints![rule.id]?.isPrioritized == true;
        final label = loadoutMatch
            ? 'Saved loadout'
            : priority
            ? 'Priority Blueprint'
            : 'Missing Blueprint';
        reasons['$label: ${rule.label} (${rule.verifiedConditionLink ? 'Planner rule' : 'seed intel'})'] =
            loadoutMatch || priority ? 90 : 50;
      }
    }
    void objectives(String context, Iterable<ArcProgressionObjective> items) {
      for (final objective in items.where((item) => !item.complete)) {
        for (final rule in ArcRegionalOpportunityEngine.itemRules) {
          final names = rule.label.split('/').map(_normal);
          if (names.contains(_normal(objective.label)) &&
              _matches(rule, event, map)) {
            reasons['$context: ${objective.label} (Planner material rule)'] =
                80;
          }
        }
        final hint = _normal(objective.sourceHint ?? '');
        if (hint.contains(_normal(map)) && hint.isNotEmpty) {
          reasons['$context: ${objective.label} (map context only)'] = 30;
        }
      }
    }

    if (interested(ArcPersonalisationFeature.questTracker) &&
        progression.quest.trackingKnown) {
      final quest = progression.quest.activeQuest;
      if (quest?.status == ArcProgressionStatus.active) {
        objectives('Active quest', quest!.objectives);
      }
    }
    // Upgrade definitions carry seed counts; only use them when the tracker
    // reports a known, incomplete upgrade. Never reinterpret collected counts.
    if (interested(ArcPersonalisationFeature.scrappyTracker) &&
        progression.scrappy.trackingKnown &&
        !progression.scrappy.readyToUpgrade) {
      objectives(
        'Scrappy upgrade context',
        progression.scrappy.nextUpgrade?.objectives ?? [],
      );
    }
    if (interested(ArcPersonalisationFeature.benchTracker) &&
        progression.bench.trackingKnown &&
        !progression.bench.readyToUpgrade) {
      objectives(
        'Bench upgrade context',
        progression.bench.nextUpgrade?.objectives ?? [],
      );
    }
    if (interested(ArcPersonalisationFeature.raidPlanner) ||
        interested(ArcPersonalisationFeature.operations)) {
      reasons['Your raid / operations preference'] = 10;
    }
    return reasons;
  }

  static bool _matches(ArcConditionTargetRule rule, String event, String map) =>
      rule.conditions.map(_normal).contains(_normal(event)) &&
      (rule.maps.isEmpty || rule.maps.map(_normal).contains(_normal(map)));

  static String _normal(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceFirst(RegExp(r'^the '), '');
}

class ArcEventMatch {
  const ArcEventMatch({
    required this.slot,
    required this.startUtc,
    required this.endUtc,
    required this.reasons,
  });
  final RaidPlannerEventSlot slot;
  final DateTime startUtc;
  final DateTime endUtc;
  final Map<String, int> reasons;
  bool isActive(DateTime now) =>
      !now.isBefore(startUtc) && now.isBefore(endUtc);
  int get score => reasons.values.fold(0, (a, b) => a > b ? a : b);
  String get reason {
    if (reasons.isEmpty) return 'No confirmed link to your goals';
    final entries = reasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}
