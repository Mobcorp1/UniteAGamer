import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';

class ArcRaidRecommendationEngine {
  const ArcRaidRecommendationEngine();

  ArcRaidRecommendationSet build({
    required List<ArcRaiderGoal> goals,
    required List<ArcRaidCandidate> candidates,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final routableGoals = goals
        .where((goal) => goal.routable)
        .toList(growable: false);
    if (routableGoals.isEmpty || candidates.isEmpty) {
      return ArcRaidRecommendationSet.empty;
    }

    final deduped = <String, ArcRaidCandidate>{};
    for (final candidate in candidates) {
      deduped[candidate.key] = candidate;
    }

    final ranked = <ArcRaidRecommendation>[];
    for (final candidate in deduped.values) {
      final recommendation = _score(candidate, routableGoals);
      if (recommendation.score > 0 && recommendation.matchedGoals.isNotEmpty) {
        ranked.add(recommendation);
      }
    }

    ranked.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) return scoreCompare;

      final questCompare = right.questGoalCount.compareTo(left.questGoalCount);
      if (questCompare != 0) return questCompare;

      final goalCompare = right.goalCount.compareTo(left.goalCount);
      if (goalCompare != 0) return goalCompare;

      if (left.candidate.isLive != right.candidate.isLive) {
        return left.candidate.isLive ? -1 : 1;
      }

      final leftStart = left.candidate.startUtc;
      final rightStart = right.candidate.startUtc;
      if (leftStart != null && rightStart != null) {
        final startCompare = leftStart.compareTo(rightStart);
        if (startCompare != 0) return startCompare;
      }

      final mapCompare = left.candidate.mapName.compareTo(
        right.candidate.mapName,
      );
      if (mapCompare != 0) return mapCompare;
      return left.candidate.conditionName.compareTo(
        right.candidate.conditionName,
      );
    });

    ArcRaidRecommendation? bestNow;
    ArcRaidRecommendation? bestStandard;
    ArcRaidRecommendation? bestUpcoming;

    for (final recommendation in ranked) {
      final candidate = recommendation.candidate;
      if (bestNow == null && candidate.isLive) {
        bestNow = recommendation;
      }
      if (bestStandard == null && candidate.isStandard) {
        bestStandard = recommendation;
      }
      final start = candidate.startUtc;
      if (bestUpcoming == null &&
          !candidate.isLive &&
          start != null &&
          start.isAfter(now)) {
        bestUpcoming = recommendation;
      }
    }

    return ArcRaidRecommendationSet(
      ranked: ranked,
      bestNow: bestNow,
      bestStandard: bestStandard,
      bestUpcoming: bestUpcoming,
    );
  }

  ArcRaidRecommendation _score(
    ArcRaidCandidate candidate,
    List<ArcRaiderGoal> goals,
  ) {
    final matched = <ArcRaiderGoal>[];
    var score = 0;
    var questCount = 0;
    var blueprintCount = 0;
    var verifiedCount = 0;
    var preferredConditionMatches = 0;
    var requiredConditionMatches = 0;

    for (final goal in goals) {
      final mapFit = _mapFit(goal, candidate.mapName);
      if (mapFit == 0) continue;

      final conditionMatch = _conditionMatches(
        goal.conditionNames,
        candidate.conditionName,
      );
      if (goal.conditionFit == ArcRaiderGoalConditionFit.required &&
          !conditionMatch) {
        continue;
      }

      final sourceWeight = _sourceWeight(goal.source);
      final priority = goal.priority.clamp(1, 5).toInt();
      final confidencePercent = _confidencePercent(goal.routeConfidence);

      var contribution =
          ((sourceWeight * priority * confidencePercent * mapFit) / 500000)
              .round()
              .clamp(1, 1000);

      if (conditionMatch) {
        switch (goal.conditionFit) {
          case ArcRaiderGoalConditionFit.none:
            contribution += (contribution * 0.05).round();
            break;
          case ArcRaiderGoalConditionFit.preferred:
            contribution += (contribution * 0.35).round();
            preferredConditionMatches++;
            break;
          case ArcRaiderGoalConditionFit.required:
            contribution += (contribution * 0.55).round();
            requiredConditionMatches++;
            break;
        }
      }

      matched.add(goal);
      score += contribution;

      if (goal.source == ArcRaiderGoalSource.quest) {
        questCount++;
      } else if (goal.source == ArcRaiderGoalSource.blueprint) {
        blueprintCount++;
      }

      if (goal.routeConfidence == ArcRaiderGoalRouteConfidence.verified) {
        verifiedCount++;
      }
    }

    if (matched.length > 1) {
      score += (matched.length - 1) * 12;
    }
    if (questCount > 1) {
      score += (questCount - 1) * 18;
    }
    if (requiredConditionMatches > 0) {
      score += requiredConditionMatches * 10;
    } else if (preferredConditionMatches > 0) {
      score += preferredConditionMatches * 5;
    }

    final reasons = <String>[];
    if (questCount > 0) {
      reasons.add(
        '$questCount active quest${questCount == 1 ? '' : 's'} can progress here',
      );
    }
    if (blueprintCount > 0) {
      reasons.add(
        '$blueprintCount Blueprint hunt${blueprintCount == 1 ? '' : 's'} aligned',
      );
    }
    if (matched.length > 1) {
      reasons.add('${matched.length} tracked goals overlap on this raid');
    }
    if (requiredConditionMatches > 0) {
      reasons.add(
        '$requiredConditionMatches condition-specific target'
        '${requiredConditionMatches == 1 ? '' : 's'} matched',
      );
    } else if (preferredConditionMatches > 0) {
      reasons.add(
        '$preferredConditionMatches target'
        '${preferredConditionMatches == 1 ? '' : 's'} boosted by this condition',
      );
    }
    if (verifiedCount > 0) {
      reasons.add(
        '$verifiedCount verified route'
        '${verifiedCount == 1 ? '' : 's'} in the score',
      );
    }

    return ArcRaidRecommendation(
      candidate: candidate,
      score: score,
      matchedGoals: List<ArcRaiderGoal>.unmodifiable(matched),
      questGoalCount: questCount,
      blueprintGoalCount: blueprintCount,
      verifiedGoalCount: verifiedCount,
      reasons: List<String>.unmodifiable(reasons.take(4)),
    );
  }

  int _mapFit(ArcRaiderGoal goal, String candidateMap) {
    final candidate = _normalize(candidateMap);
    if (candidate.isEmpty || goal.mapNames.isEmpty) return 0;

    var allMaps = false;
    for (final value in goal.mapNames) {
      final normalized = _normalize(value);
      if (normalized == 'all maps' ||
          normalized == 'all map' ||
          normalized == 'any map' ||
          normalized == 'eligible maps') {
        allMaps = true;
        continue;
      }
      if (_sameMap(normalized, candidate)) return 100;
    }

    return allMaps ? 68 : 0;
  }

  bool _conditionMatches(List<String> values, String candidateCondition) {
    if (values.isEmpty) return false;
    final candidate = _normalize(candidateCondition);
    if (candidate.isEmpty) return false;

    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized == 'any' ||
          normalized == 'all' ||
          normalized == 'any condition') {
        return true;
      }
      if (normalized == candidate) return true;
    }
    return false;
  }

  bool _sameMap(String left, String right) {
    String clean(String value) {
      final normalized = _normalize(value);
      if (normalized == 'the blue gate') return 'blue gate';
      return normalized;
    }

    return clean(left) == clean(right);
  }

  int _sourceWeight(ArcRaiderGoalSource source) {
    switch (source) {
      case ArcRaiderGoalSource.quest:
        return 100;
      case ArcRaiderGoalSource.huntTarget:
        return 82;
      case ArcRaiderGoalSource.blueprint:
        return 78;
      case ArcRaiderGoalSource.favouriteLoadout:
        return 60;
      case ArcRaiderGoalSource.crafting:
        return 54;
      case ArcRaiderGoalSource.bench:
        return 52;
      case ArcRaiderGoalSource.research:
        return 52;
      case ArcRaiderGoalSource.project:
        return 44;
      case ArcRaiderGoalSource.trade:
        return 34;
    }
  }

  int _confidencePercent(ArcRaiderGoalRouteConfidence confidence) {
    switch (confidence) {
      case ArcRaiderGoalRouteConfidence.verified:
        return 100;
      case ArcRaiderGoalRouteConfidence.strong:
        return 86;
      case ArcRaiderGoalRouteConfidence.provisional:
        return 62;
      case ArcRaiderGoalRouteConfidence.unrouted:
        return 0;
    }
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
