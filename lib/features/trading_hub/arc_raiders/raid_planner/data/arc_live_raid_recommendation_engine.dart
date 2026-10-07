import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_trade_value_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_availability_window_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_raider_goal_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

/// Converges saved Raid Planner targets, priority Blueprint Tracker state,
/// active Quest progress and the official regional Map Conditions feed into the
/// recommendation engine used by Raid Intelligence.
class ArcLiveRaidRecommendationEngine {
  const ArcLiveRaidRecommendationEngine();

  /// Personal event intelligence is bounded by today's local sessions before
  /// scoring. The existing map/standard-raid recommender below stays available
  /// to Raid Intelligence and squad routing.
  ArcTodayRaidIntel buildTodayRecommendations({
    required List<RaidBlueprintTarget> effectiveTargets,
    required ArcAvailability availability,
    required ArcRegionalMapConditionsSnapshot regionalSnapshot,
    ArcServerRegion homeRegion = ArcServerRegion.europe,
    Iterable<String> itemTargetIds = const [],
    List<TradingListing> myListings = const [],
    String? currentUid,
    ArcQuestProgressionSnapshot questSnapshot =
        ArcQuestProgressionSnapshot.empty,
    Map<String, ArcQuestRouteHint> questRouteHints = const {},
    DateTime? nowUtc,
    ArcAvailabilityWindowResolver resolver =
        const ArcAvailabilityWindowResolver(),
  }) {
    // The personal calendar belongs to the device, not the schedule server.
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final sessions = resolver.todayWindows(availability, now: now);
    final activeTargets = effectiveTargets
        .where((t) => t.tier == RaidTargetTier.activeHunt)
        .toList();
    final questGoals =
        ArcRaiderGoalBridge.questGoals(
              questSnapshot,
              routeHints: questRouteHints,
            )
            .where(
              (goal) => questSnapshot.trackedQuestIds.contains(
                goal.id.substring('quest:'.length),
              ),
            )
            .toList(growable: false);
    final goals = <String, ArcRaiderGoal>{
      for (final goal in ArcRaiderGoalBridge.activeEventBlueprintGoals(
        activeTargets,
      ))
        goal.id: goal,
      for (final goal in questGoals)
        if (goal.routeConfidence == ArcRaiderGoalRouteConfidence.verified)
          goal.id: goal,
      for (final goal in ArcRaiderGoalBridge.tradeAcquisitionGoals(
        listings: myListings,
        currentUid: currentUid,
        now: now,
      ))
        goal.id: goal,
      for (final goal in ArcRaiderGoalBridge.conditionItemGoals(itemTargetIds))
        goal.id: goal,
    }.values.toList(growable: false);

    ArcTodayRaidIntel result(
      ArcTodayRaidIntelStatus status, [
      List<ArcTodayRaidRecommendation> recommendations = const [],
      Set<String> matchedGoalIds = const {},
    ]) => ArcTodayRaidIntel(
      status: status,
      playtime: sessions,
      recommendations: recommendations,
      matchedGoalIds: matchedGoalIds,
    );
    if (!resolver.hasUsableAvailability(availability)) {
      return result(ArcTodayRaidIntelStatus.noAvailability);
    }
    if (activeTargets.isEmpty && questGoals.isEmpty && goals.isEmpty) {
      return result(ArcTodayRaidIntelStatus.noGoals);
    }
    if (sessions.isEmpty) return result(ArcTodayRaidIntelStatus.noPlaytime);

    final ranked = <ArcTodayRaidRecommendation>[];
    for (final region in ArcServerRegion.values) {
      final candidates = <ArcRaidCandidate>[];
      final matchingSessions = <String, ArcPlaytimeWindow>{};
      for (final entry in regionalSnapshot.entries) {
        final window = entry.windowFor(region);
        if (window == null || !window.endUtc.isAfter(window.startUtc)) continue;
        ArcPlaytimeWindow? matchedSession;
        for (final session in sessions) {
          if (session.overlaps(window.startUtc, window.endUtc, now: now)) {
            matchedSession = session;
            break;
          }
        }
        if (matchedSession == null) continue;
        final candidate = ArcRaidCandidate(
          mapName: entry.mapDisplayName,
          conditionName: entry.conditionName,
          startUtc: window.startUtc,
          endUtc: window.endUtc,
          isLive: window.isActiveAt(now) && matchedSession.contains(now),
        );
        if (candidate.isStandard) continue;
        candidates.add(candidate);
        matchingSessions[candidate.key] = matchedSession;
      }
      final scored = const ArcRaidRecommendationEngine().build(
        goals: goals,
        candidates: candidates,
        nowUtc: now,
        requireEventCondition: true,
      );
      for (final recommendation in scored.ranked) {
        final session = matchingSessions[recommendation.candidate.key]!;
        ranked.add(
          ArcTodayRaidRecommendation(
            recommendation: recommendation,
            region: region,
            homeRegion: region == homeRegion,
            session: session,
            sessionPriority: recommendation.candidate.isLive
                ? 0
                : session.contains(now)
                ? 1
                : 2,
          ),
        );
      }
    }
    ranked.sort((a, b) {
      final session = a.sessionPriority.compareTo(b.sessionPriority);
      if (session != 0) return session;
      final score = b.recommendation.score.compareTo(a.recommendation.score);
      if (score != 0) return score;
      if (a.homeRegion != b.homeRegion) return a.homeRegion ? -1 : 1;
      final start = a.playableStartUtc.compareTo(b.playableStartUtc);
      if (start != 0) return start;
      final key = a.recommendation.candidate.key.compareTo(
        b.recommendation.candidate.key,
      );
      return key != 0 ? key : a.region.index.compareTo(b.region.index);
    });
    final seen = <String>{};
    final recommendations = <ArcTodayRaidRecommendation>[];
    final matchedGoalIds = <String>{};
    for (final item in ranked) {
      matchedGoalIds.addAll(item.recommendation.matchedGoals.map((g) => g.id));
      // Identical region windows offer no reason to switch servers.
      final candidate = item.recommendation.candidate;
      final key = '${candidate.key}|${candidate.endUtc?.toIso8601String()}';
      if (seen.add(key) && recommendations.length < 3) {
        recommendations.add(item);
      }
    }
    return result(
      recommendations.isEmpty
          ? ArcTodayRaidIntelStatus.noMatches
          : ArcTodayRaidIntelStatus.ready,
      List.unmodifiable(recommendations),
      Set.unmodifiable(matchedGoalIds),
    );
  }

  ArcRaidRecommendationSet build({
    required List<RaidBlueprintTarget> storedTargets,
    required Map<String, ArcBlueprintState> blueprintStates,
    required RaidPlannerEntitlement entitlement,
    required ArcProgressionRecords progressionRecords,
    required Map<String, ArcScrappyState> scrappyStates,
    required ArcRegionalMapConditionsSnapshot regionalSnapshot,
    ArcServerRegion region = ArcServerRegion.europe,
    DateTime? nowUtc,
  }) {
    final now = _effectiveNow(regionalSnapshot, nowUtc: nowUtc);
    final effectiveTargets = RaidPlannerEngine.effectiveTargets(
      storedTargets: storedTargets,
      states: blueprintStates,
      entitlement: entitlement,
    );
    final targetedIds = effectiveTargets
        .map((target) => target.blueprintId)
        .toSet();
    final progression = const ArcProgressionEngine().build(
      scrappyStates: scrappyStates,
      records: progressionRecords,
    );
    final goals = <ArcRaiderGoal>[
      ...ArcRaiderGoalBridge.blueprintGoals(effectiveTargets),
      ..._priorityBlueprintGoals(blueprintStates, excludedIds: targetedIds),
      ...ArcRaiderGoalBridge.questGoals(progression.quest),
    ];
    final candidates = _regionalCandidates(
      regionalSnapshot,
      region: region,
      nowUtc: now,
    );
    return const ArcRaidRecommendationEngine().build(
      goals: goals,
      candidates: candidates,
      nowUtc: now,
    );
  }

  String activeConditionLabelForMap({
    required ArcRegionalMapConditionsSnapshot regionalSnapshot,
    required ArcServerRegion region,
    required String mapDisplayName,
    DateTime? nowUtc,
  }) {
    final now = _effectiveNow(regionalSnapshot, nowUtc: nowUtc);
    final mapKey = _normalizeMap(mapDisplayName);
    final active =
        regionalSnapshot.entries
            .where((entry) => _normalizeMap(entry.mapDisplayName) == mapKey)
            .where((entry) => entry.windowFor(region)?.isActiveAt(now) == true)
            .map((entry) => entry.conditionName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (active.isEmpty) return ArcMapConditions.noSpecialCondition.label;
    return active.join(' + ');
  }

  List<ArcRaidCandidate> _regionalCandidates(
    ArcRegionalMapConditionsSnapshot snapshot, {
    required ArcServerRegion region,
    required DateTime nowUtc,
  }) {
    final candidates = <ArcRaidCandidate>[
      for (final mapName in _standardMaps)
        ArcRaidCandidate(
          mapName: mapName,
          conditionName: ArcMapConditions.noSpecialCondition.label,
          isLive: true,
        ),
    ];

    for (final entry in snapshot.entries) {
      final window = entry.windowFor(region);
      if (window == null || !window.endUtc.isAfter(nowUtc)) continue;
      candidates.add(
        ArcRaidCandidate(
          mapName: entry.mapDisplayName,
          conditionName: entry.conditionName,
          isLive: window.isActiveAt(nowUtc),
          startUtc: window.startUtc,
          endUtc: window.endUtc,
        ),
      );
    }
    return List<ArcRaidCandidate>.unmodifiable(candidates);
  }

  List<ArcRaiderGoal> _priorityBlueprintGoals(
    Map<String, ArcBlueprintState> states, {
    required Set<String> excludedIds,
  }) {
    final missing =
        states.values
            .where(
              (state) =>
                  !state.owned && !excludedIds.contains(state.blueprintId),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aPriority = a.priorityRank > 0;
            final bPriority = b.priorityRank > 0;
            if (aPriority != bPriority) return aPriority ? -1 : 1;
            if (aPriority && bPriority) {
              final rankCompare = a.priorityRank.compareTo(b.priorityRank);
              if (rankCompare != 0) return rankCompare;
            }

            final aBlueprint = _blueprintById(a.blueprintId);
            final bBlueprint = _blueprintById(b.blueprintId);
            if (aBlueprint != null && bBlueprint != null) {
              final marketCompare =
                  ArcBlueprintTradeValueCatalog.compareBlueprints(
                    aBlueprint,
                    bBlueprint,
                  );
              if (marketCompare != 0) return marketCompare;
            }
            return a.blueprintId.compareTo(b.blueprintId);
          });

    final goals = <ArcRaiderGoal>[];
    for (final state in missing.take(8)) {
      final blueprint = _blueprintById(state.blueprintId);
      if (blueprint == null) continue;
      final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
      if (hint.likelyMaps.isEmpty) continue;
      final conditions = ArcBlueprintIntelLibrary.playableConditions(
        hint.bestConditions,
      ).toList(growable: false);
      final mapSpecific = !ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps);
      final marketPoints = ArcBlueprintTradeValueCatalog.tradePointsFor(
        blueprint,
      );
      final explicitPriority = state.priorityRank > 0;
      final goalPriority = explicitPriority
          ? (4 - state.priorityRank).clamp(2, 4).toInt()
          : marketPoints >= 8
          ? 3
          : 2;
      goals.add(
        ArcRaiderGoal(
          id: explicitPriority
              ? 'priority-blueprint:${blueprint.id}'
              : 'missing-blueprint:${blueprint.id}',
          label: blueprint.name,
          source: ArcRaiderGoalSource.blueprint,
          cooperation: ArcRaiderGoalCooperation.scarceSharedLoot,
          priority: goalPriority,
          mapNames: List<String>.unmodifiable(hint.likelyMaps),
          conditionNames: conditions,
          conditionFit: conditions.isEmpty
              ? ArcRaiderGoalConditionFit.none
              : ArcRaiderGoalConditionFit.preferred,
          routeConfidence: mapSpecific || conditions.isNotEmpty
              ? ArcRaiderGoalRouteConfidence.strong
              : ArcRaiderGoalRouteConfidence.provisional,
          reason: explicitPriority
              ? hint.tip
              : '${hint.tip} UAG market value $marketPoints points; used as a fallback missing-Blueprint priority.',
        ),
      );
    }
    return List<ArcRaiderGoal>.unmodifiable(goals);
  }

  ArcBlueprint? _blueprintById(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint;
    }
    return null;
  }

  DateTime _effectiveNow(
    ArcRegionalMapConditionsSnapshot snapshot, {
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (!snapshot.isOfficialLive) return now;
    final elapsed = now.difference(snapshot.loadedAtUtc);
    if (elapsed.isNegative) return snapshot.serverNowUtc;
    return snapshot.serverNowUtc.add(elapsed);
  }

  String _normalizeMap(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.startsWith('the ')) {
      normalized = normalized.substring(4);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static const List<String> _standardMaps = <String>[
    ArcMapConditions.damBattlegroundsMap,
    ArcMapConditions.spaceportMap,
    ArcMapConditions.buriedCityMap,
    ArcMapConditions.blueGateMap,
    ArcMapConditions.stellaMontisMap,
    ArcMapConditions.rivenTidesMap,
  ];
}

enum ArcTodayRaidIntelStatus {
  noAvailability,
  noGoals,
  noPlaytime,
  noMatches,
  ready,
}

class ArcTodayRaidIntel {
  const ArcTodayRaidIntel({
    required this.status,
    required this.playtime,
    required this.recommendations,
    this.matchedGoalIds = const {},
  });
  final ArcTodayRaidIntelStatus status;
  final List<ArcPlaytimeWindow> playtime;
  final List<ArcTodayRaidRecommendation> recommendations;
  final Set<String> matchedGoalIds;
}

class ArcTodayRaidRecommendation {
  const ArcTodayRaidRecommendation({
    required this.recommendation,
    required this.region,
    required this.homeRegion,
    required this.session,
    required this.sessionPriority,
  });
  final ArcRaidRecommendation recommendation;
  final ArcServerRegion region;
  final bool homeRegion;
  final ArcPlaytimeWindow session;
  final int sessionPriority;
  DateTime get playableStartUtc =>
      recommendation.candidate.startUtc!.isAfter(session.startUtc)
      ? recommendation.candidate.startUtc!
      : session.startUtc;
  DateTime get playableEndUtc =>
      recommendation.candidate.endUtc!.isBefore(session.endUtc)
      ? recommendation.candidate.endUtc!
      : session.endUtc;
}
