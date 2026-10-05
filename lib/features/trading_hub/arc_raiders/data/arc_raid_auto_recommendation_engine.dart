import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_opportunity_engine.dart';

class ArcRaidAutoRecommendation {
  const ArcRaidAutoRecommendation({
    required this.mapId,
    required this.mapName,
    required this.conditionName,
    required this.targetLabel,
    required this.region,
    required this.startUtc,
    required this.endUtc,
    required this.live,
    required this.insideSavedPlaytime,
    required this.fromNomadicTrader,
    required this.fromBlueprint,
    required this.officialLive,
  });

  final String mapId;
  final String mapName;
  final String conditionName;
  final String targetLabel;
  final ArcServerRegion region;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool live;
  final bool insideSavedPlaytime;
  final bool fromNomadicTrader;
  final bool fromBlueprint;
  final bool officialLive;

  String get signature =>
      '$mapId|$conditionName|${region.name}|${startUtc.millisecondsSinceEpoch}|$targetLabel';

  String get statusLabel => live ? 'RUN NOW' : 'NEXT PLAY WINDOW';
}

class ArcRaidAutoRecommendationEngine {
  const ArcRaidAutoRecommendationEngine();

  ArcRaidAutoRecommendation? recommend({
    required ArcRegionalMapConditionsSnapshot snapshot,
    required ArcAvailability availability,
    required ArcTraderProfile profile,
    required ArcNomadicTraderTrackerSnapshot nomadicTraderTracker,
    required Map<String, ArcBlueprintState> blueprintStates,
    ArcSavedLoadout? favouriteLoadout,
    List<ArcRaidObjective> trackedObjectives = const <ArcRaidObjective>[],
    DateTime? nowUtc,
  }) {
    if (!snapshot.isOfficialLive) return null;
    final now = nowUtc ?? snapshot.serverNowUtc;
    final homeRegion = _homeRegion(profile);
    final targetOrigins = <_TargetOrigin>[];

    final loadoutSignals = _loadoutSignals(favouriteLoadout);
    for (final rule in ArcRegionalOpportunityEngine.missingBlueprintRules(
      blueprintStates,
    )) {
      final prioritized = blueprintStates[rule.id]?.isPrioritized == true;
      final loadoutRelevant = loadoutSignals.contains(_normalise(rule.label));
      targetOrigins.add(
        _TargetOrigin(
          rule: rule,
          priority: loadoutRelevant
              ? 122
              : prioritized
              ? 115
              : 65,
          fromBlueprint: true,
          fromNomadicTrader: false,
        ),
      );
    }

    targetOrigins.addAll(_nomadicTargets(nomadicTraderTracker));
    targetOrigins.addAll(_trackedObjectiveTargets(trackedObjectives));
    if (targetOrigins.isEmpty) return null;

    final hasSavedAvailability = availability.weeks
        .expand((week) => week.slots)
        .any((slot) => slot.enabled);
    if (!hasSavedAvailability) return null;
    final candidates = <_RankedRecommendation>[];

    for (final origin in _dedupeOrigins(targetOrigins)) {
      final opportunities = ArcRegionalOpportunityEngine.recommendationsForTargets(
        snapshot: snapshot,
        targets: <ArcConditionTargetRule>[origin.rule],
        availability: availability,
        homeRegion: homeRegion,
        nowUtc: now,
        limit: 24,
      );

      for (final opportunity in opportunities) {
        if (opportunity.region != homeRegion) {
          continue;
        }
        if (!opportunity.insideSavedPlaytime) {
          continue;
        }
        final mapId = ArcMapAssetRegistry.canonicalMapIdFor(
          opportunity.condition.mapDisplayName,
        );
        if (mapId == null ||
            !ArcRaidIntelligenceSeedData.supportedMapIds.contains(mapId)) {
          continue;
        }

        var score = origin.priority.toDouble();
        if (opportunity.live) score += 120;
        if (opportunity.insideSavedPlaytime) score += 85;
        if (opportunity.homeRegion) score += 35;
        final minutesUntil = opportunity.window.startUtc
            .difference(now)
            .inMinutes;
        if (minutesUntil > 0) {
          score -= (minutesUntil / 120).clamp(0, 30).toDouble();
        }

        candidates.add(
          _RankedRecommendation(
            score: score,
            recommendation: ArcRaidAutoRecommendation(
              mapId: mapId,
              mapName: opportunity.condition.mapDisplayName,
              conditionName: opportunity.condition.conditionName,
              targetLabel: origin.rule.label,
              region: opportunity.region,
              startUtc: opportunity.window.startUtc,
              endUtc: opportunity.window.endUtc,
              live: opportunity.live,
              insideSavedPlaytime: opportunity.insideSavedPlaytime,
              fromNomadicTrader: origin.fromNomadicTrader,
              fromBlueprint: origin.fromBlueprint,
              officialLive: snapshot.isOfficialLive,
            ),
          ),
        );
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) return scoreCompare;
      final timeCompare = left.recommendation.startUtc.compareTo(
        right.recommendation.startUtc,
      );
      if (timeCompare != 0) return timeCompare;
      return left.recommendation.mapName.compareTo(right.recommendation.mapName);
    });
    return candidates.first.recommendation;
  }

  List<_TargetOrigin> _trackedObjectiveTargets(
    List<ArcRaidObjective> objectives,
  ) {
    final result = <_TargetOrigin>[];
    for (final objective in objectives) {
      final item = objective.itemName.trim();
      if (item.isEmpty) continue;
      final basePriority = switch (objective.system) {
        'Quest' => 110,
        'Nomadic Trader' => 108,
        'Scrappy' => 94,
        'Bench' => 92,
        _ => 80,
      };
      for (final rule in _rulesMatchingResource(item)) {
        result.add(
          _TargetOrigin(
            rule: rule,
            priority: basePriority,
            fromNomadicTrader: objective.system == 'Nomadic Trader',
            fromBlueprint: false,
          ),
        );
      }
    }
    return result;
  }

  Set<String> _loadoutSignals(ArcSavedLoadout? loadout) {
    if (loadout == null) return const <String>{};
    return <String>{
      loadout.primaryWeapon,
      loadout.secondaryWeapon,
      ...loadout.primaryAttachments,
      ...loadout.secondaryAttachments,
    }
        .map(_normalise)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  List<_TargetOrigin> _nomadicTargets(
    ArcNomadicTraderTrackerSnapshot tracker,
  ) {
    if (!tracker.trackingKnown) return const <_TargetOrigin>[];
    final result = <_TargetOrigin>[];

    var purchaseIndex = 0;
    for (final purchase in tracker.purchases) {
      if (purchase.alreadyPurchased) continue;
      for (final requirement in purchase.requirements) {
        if (requirement.remainingQty <= 0) continue;
        for (final rule in _rulesMatchingResource(requirement.name)) {
          result.add(
            _TargetOrigin(
              rule: rule,
              priority: (108 - (purchaseIndex * 3)).clamp(88, 108).toInt(),
              fromNomadicTrader: true,
              fromBlueprint: false,
            ),
          );
        }
      }
      purchaseIndex += 1;
    }

    // If the player is tracking a value goal rather than a purchase recipe,
    // use only existing verified condition rules that can be tied back to the
    // Nomadic Trader's own resource catalogue. No new drop relationship is
    // invented here.
    if (tracker.remainingValue > 0) {
      final resources = tracker.highTier
          ? ArcNomadicTraderCatalog.highTierResources
          : ArcNomadicTraderCatalog.lowTierResources;
      for (final resource in resources) {
        if (resource.id == 'duplicate_blueprint') continue;
        for (final rule in _rulesMatchingResource(resource.name)) {
          result.add(
            _TargetOrigin(
              rule: rule,
              priority: 78 + (resource.value / 2000).clamp(0, 8).round(),
              fromNomadicTrader: true,
              fromBlueprint: false,
            ),
          );
        }
      }
    }

    return result;
  }

  Iterable<ArcConditionTargetRule> _rulesMatchingResource(String resource) {
    final resourceTokens = _distinctiveTokens(resource);
    if (resourceTokens.isEmpty) return const <ArcConditionTargetRule>[];
    return ArcRegionalOpportunityEngine.itemRules.where((rule) {
      if (!rule.verifiedConditionLink) return false;
      final ruleTokens = _distinctiveTokens(rule.label);
      return resourceTokens.intersection(ruleTokens).isNotEmpty;
    });
  }

  List<_TargetOrigin> _dedupeOrigins(List<_TargetOrigin> values) {
    final byKey = <String, _TargetOrigin>{};
    for (final value in values) {
      final key = '${value.rule.id}|${value.rule.conditions.join(',')}|${value.rule.maps.join(',')}';
      final current = byKey[key];
      if (current == null || value.priority > current.priority) {
        byKey[key] = current == null
            ? value
            : value.copyWith(
                fromBlueprint:
                    value.fromBlueprint || current.fromBlueprint,
                fromNomadicTrader:
                    value.fromNomadicTrader || current.fromNomadicTrader,
              );
      } else {
        byKey[key] = current.copyWith(
          fromBlueprint: current.fromBlueprint || value.fromBlueprint,
          fromNomadicTrader:
              current.fromNomadicTrader || value.fromNomadicTrader,
        );
      }
    }
    return byKey.values.toList(growable: false);
  }

  Set<String> _distinctiveTokens(String value) {
    const ignored = <String>{
      'arc',
      'loot',
      'part',
      'parts',
      'reward',
      'rewards',
      'material',
      'materials',
      'reactor',
      'unit',
      'driver',
      'cell',
    };
    return _normalise(value)
        .split(' ')
        .where((token) => token.length >= 5 && !ignored.contains(token))
        .toSet();
  }

  ArcServerRegion _homeRegion(ArcTraderProfile profile) {
    final value = _normalise('${profile.serverPreference} ${profile.region}');
    if (value.contains('brazil')) return ArcServerRegion.brazil;
    if (value.contains('oceania') ||
        value.contains('australia') ||
        value.contains('new zealand')) {
      return ArcServerRegion.oceania;
    }
    if (value.contains('east asia') ||
        value.contains('asia') ||
        value.contains('japan') ||
        value.contains('korea')) {
      return ArcServerRegion.eastAsia;
    }
    if (value.contains('north america') ||
        value.contains('usa') ||
        value.contains('united states') ||
        value.contains('canada')) {
      return ArcServerRegion.northAmerica;
    }
    return ArcServerRegion.europe;
  }

  String _normalise(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _TargetOrigin {
  const _TargetOrigin({
    required this.rule,
    required this.priority,
    required this.fromNomadicTrader,
    required this.fromBlueprint,
  });

  final ArcConditionTargetRule rule;
  final int priority;
  final bool fromNomadicTrader;
  final bool fromBlueprint;

  _TargetOrigin copyWith({
    bool? fromNomadicTrader,
    bool? fromBlueprint,
  }) {
    return _TargetOrigin(
      rule: rule,
      priority: priority,
      fromNomadicTrader: fromNomadicTrader ?? this.fromNomadicTrader,
      fromBlueprint: fromBlueprint ?? this.fromBlueprint,
    );
  }
}

class _RankedRecommendation {
  const _RankedRecommendation({
    required this.score,
    required this.recommendation,
  });

  final double score;
  final ArcRaidAutoRecommendation recommendation;
}
