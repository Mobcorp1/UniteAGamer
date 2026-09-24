enum ArcRaiderGoalSource {
  quest,
  blueprint,
  huntTarget,
  crafting,
  bench,
  research,
  favouriteLoadout,
  project,
  trade,
}

enum ArcRaiderGoalCooperation { cooperative, personal, scarceSharedLoot }

enum ArcRaiderGoalRouteConfidence { verified, strong, provisional, unrouted }

enum ArcRaiderGoalConditionFit { none, preferred, required }

class ArcRaiderGoal {
  const ArcRaiderGoal({
    required this.id,
    required this.label,
    required this.source,
    required this.cooperation,
    this.priority = 3,
    this.mapNames = const <String>[],
    this.conditionNames = const <String>[],
    this.poiIds = const <String>[],
    this.conditionFit = ArcRaiderGoalConditionFit.none,
    this.routeConfidence = ArcRaiderGoalRouteConfidence.unrouted,
    this.reason = '',
  });

  final String id;
  final String label;
  final ArcRaiderGoalSource source;
  final ArcRaiderGoalCooperation cooperation;
  final int priority;
  final List<String> mapNames;
  final List<String> conditionNames;
  final List<String> poiIds;
  final ArcRaiderGoalConditionFit conditionFit;
  final ArcRaiderGoalRouteConfidence routeConfidence;
  final String reason;

  bool get routable =>
      routeConfidence != ArcRaiderGoalRouteConfidence.unrouted &&
      mapNames.isNotEmpty;

  bool get cooperative => cooperation == ArcRaiderGoalCooperation.cooperative;

  bool get scarceSharedLoot =>
      cooperation == ArcRaiderGoalCooperation.scarceSharedLoot;
}

class ArcRaidCandidate {
  const ArcRaidCandidate({
    required this.mapName,
    required this.conditionName,
    required this.isLive,
    this.startUtc,
    this.endUtc,
  });

  final String mapName;
  final String conditionName;
  final bool isLive;
  final DateTime? startUtc;
  final DateTime? endUtc;

  bool get isStandard {
    final normalized = conditionName.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'normal' ||
        normalized == 'none' ||
        normalized.contains('standard raid') ||
        normalized.contains('no event');
  }

  String get key =>
      '${mapName.trim().toLowerCase()}|${conditionName.trim().toLowerCase()}|'
      '${startUtc?.toUtc().toIso8601String() ?? 'standard'}';
}

class ArcRaidRecommendation {
  const ArcRaidRecommendation({
    required this.candidate,
    required this.score,
    required this.matchedGoals,
    required this.questGoalCount,
    required this.blueprintGoalCount,
    required this.verifiedGoalCount,
    required this.reasons,
  });

  final ArcRaidCandidate candidate;
  final int score;
  final List<ArcRaiderGoal> matchedGoals;
  final int questGoalCount;
  final int blueprintGoalCount;
  final int verifiedGoalCount;
  final List<String> reasons;

  int get goalCount => matchedGoals.length;

  String get progressLabel =>
      '$goalCount tracked goal${goalCount == 1 ? '' : 's'} aligned';
}

class ArcRaidRecommendationSet {
  const ArcRaidRecommendationSet({
    required this.ranked,
    this.bestNow,
    this.bestStandard,
    this.bestUpcoming,
  });

  final List<ArcRaidRecommendation> ranked;
  final ArcRaidRecommendation? bestNow;
  final ArcRaidRecommendation? bestStandard;
  final ArcRaidRecommendation? bestUpcoming;

  static const empty = ArcRaidRecommendationSet(
    ranked: <ArcRaidRecommendation>[],
  );
}
