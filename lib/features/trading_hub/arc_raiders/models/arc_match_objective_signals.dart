class ArcMatchObjectiveSignals {
  const ArcMatchObjectiveSignals({
    this.ownedBlueprintIds = const <String>[],
    this.availableBlueprintIds = const <String>[],
    this.neededBlueprintIds = const <String>[],
    this.blueprintHuntIds = const <String>[],
    this.questIds = const <String>[],
    this.questChains = const <String>[],
    this.trialIds = const <String>[],
    this.benchGoalIds = const <String>[],
    this.favouriteLoadoutNeedIds = const <String>[],
    this.raidPlannerTargetIds = const <String>[],
    this.tradePreferences = const <String>[],
    this.availabilityDayKeys = const <String>[],
    this.timezone = '',
    this.giftFriendly = false,
    this.tradeOnly = false,
    this.helperMentor = false,
    this.lookingNow = false,
    this.away = false,
    this.reputationScore = 0,
    this.completedTrades = 0,
    this.noShows = 0,
    this.betrayalFlags = 0,
    this.isFavouriteRider = false,
    this.previousCompletedTrades = 0,
    this.previousSquadSessions = 0,
    this.previousBlueprintOffers = 0,
  });

  final List<String> ownedBlueprintIds;
  final List<String> availableBlueprintIds;
  final List<String> neededBlueprintIds;
  final List<String> blueprintHuntIds;
  final List<String> questIds;
  final List<String> questChains;
  final List<String> trialIds;
  final List<String> benchGoalIds;
  final List<String> favouriteLoadoutNeedIds;
  final List<String> raidPlannerTargetIds;
  final List<String> tradePreferences;
  final List<String> availabilityDayKeys;
  final String timezone;
  final bool giftFriendly;
  final bool tradeOnly;
  final bool helperMentor;
  final bool lookingNow;
  final bool away;
  final int reputationScore;
  final int completedTrades;
  final int noShows;
  final int betrayalFlags;
  final bool isFavouriteRider;
  final int previousCompletedTrades;
  final int previousSquadSessions;
  final int previousBlueprintOffers;

  static const empty = ArcMatchObjectiveSignals();

  ArcMatchObjectiveSignals copyWith({
    List<String>? ownedBlueprintIds,
    List<String>? availableBlueprintIds,
    List<String>? neededBlueprintIds,
    List<String>? blueprintHuntIds,
    List<String>? questIds,
    List<String>? questChains,
    List<String>? trialIds,
    List<String>? benchGoalIds,
    List<String>? favouriteLoadoutNeedIds,
    List<String>? raidPlannerTargetIds,
    List<String>? tradePreferences,
    List<String>? availabilityDayKeys,
    String? timezone,
    bool? giftFriendly,
    bool? tradeOnly,
    bool? helperMentor,
    bool? lookingNow,
    bool? away,
    int? reputationScore,
    int? completedTrades,
    int? noShows,
    int? betrayalFlags,
    bool? isFavouriteRider,
    int? previousCompletedTrades,
    int? previousSquadSessions,
    int? previousBlueprintOffers,
  }) {
    return ArcMatchObjectiveSignals(
      ownedBlueprintIds: ownedBlueprintIds ?? this.ownedBlueprintIds,
      availableBlueprintIds:
          availableBlueprintIds ?? this.availableBlueprintIds,
      neededBlueprintIds: neededBlueprintIds ?? this.neededBlueprintIds,
      blueprintHuntIds: blueprintHuntIds ?? this.blueprintHuntIds,
      questIds: questIds ?? this.questIds,
      questChains: questChains ?? this.questChains,
      trialIds: trialIds ?? this.trialIds,
      benchGoalIds: benchGoalIds ?? this.benchGoalIds,
      favouriteLoadoutNeedIds:
          favouriteLoadoutNeedIds ?? this.favouriteLoadoutNeedIds,
      raidPlannerTargetIds: raidPlannerTargetIds ?? this.raidPlannerTargetIds,
      tradePreferences: tradePreferences ?? this.tradePreferences,
      availabilityDayKeys: availabilityDayKeys ?? this.availabilityDayKeys,
      timezone: timezone ?? this.timezone,
      giftFriendly: giftFriendly ?? this.giftFriendly,
      tradeOnly: tradeOnly ?? this.tradeOnly,
      helperMentor: helperMentor ?? this.helperMentor,
      lookingNow: lookingNow ?? this.lookingNow,
      away: away ?? this.away,
      reputationScore: reputationScore ?? this.reputationScore,
      completedTrades: completedTrades ?? this.completedTrades,
      noShows: noShows ?? this.noShows,
      betrayalFlags: betrayalFlags ?? this.betrayalFlags,
      isFavouriteRider: isFavouriteRider ?? this.isFavouriteRider,
      previousCompletedTrades:
          previousCompletedTrades ?? this.previousCompletedTrades,
      previousSquadSessions:
          previousSquadSessions ?? this.previousSquadSessions,
      previousBlueprintOffers:
          previousBlueprintOffers ?? this.previousBlueprintOffers,
    );
  }

  Set<String> normalizedOwnedBlueprintIds() =>
      _normalizedSet(<String>[...ownedBlueprintIds, ...availableBlueprintIds]);

  Set<String> normalizedAvailableBlueprintIds() =>
      _normalizedSet(availableBlueprintIds);

  Set<String> normalizedNeededBlueprintIds() =>
      _normalizedSet(<String>[...neededBlueprintIds, ...blueprintHuntIds]);

  static List<String> normalizeList(Iterable<String> values) {
    final seen = <String>{};
    final output = <String>[];
    for (final value in values) {
      final normalized = normalizeId(value);
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      output.add(normalized);
    }
    return output;
  }

  static String normalizeId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static Set<String> _normalizedSet(Iterable<String> values) {
    return normalizeList(values).toSet();
  }
}
