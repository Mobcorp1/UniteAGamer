import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_objective_signals.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';

enum ArcMatchIntelligenceTier {
  basic,
  enhanced,
  advanced;

  String get label {
    switch (this) {
      case ArcMatchIntelligenceTier.basic:
        return 'Basic Match Intelligence';
      case ArcMatchIntelligenceTier.enhanced:
        return 'Enhanced Match Intelligence';
      case ArcMatchIntelligenceTier.advanced:
        return 'Advanced Match Intelligence';
    }
  }

  String get shortLabel {
    switch (this) {
      case ArcMatchIntelligenceTier.basic:
        return 'Basic';
      case ArcMatchIntelligenceTier.enhanced:
        return 'Enhanced';
      case ArcMatchIntelligenceTier.advanced:
        return 'Advanced';
    }
  }
}

enum ArcMatchConfidenceLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ArcMatchConfidenceLevel.low:
        return 'Low confidence';
      case ArcMatchConfidenceLevel.medium:
        return 'Medium confidence';
      case ArcMatchConfidenceLevel.high:
        return 'High confidence';
    }
  }
}

class ArcMatchIntelligenceTierWeights {
  const ArcMatchIntelligenceTierWeights({
    required this.coreProfile,
    required this.availability,
    required this.communication,
    required this.squadIntent,
    required this.archetypeFit,
    required this.reputation,
    required this.relationship,
    required this.progression,
    required this.mapAndEventFit,
  });

  final int coreProfile;
  final int availability;
  final int communication;
  final int squadIntent;
  final int archetypeFit;
  final int reputation;
  final int relationship;
  final int progression;
  final int mapAndEventFit;
}

class ArcMatchIntelligenceConfig {
  const ArcMatchIntelligenceConfig({
    required this.basicWeights,
    required this.enhancedWeights,
    required this.advancedWeights,
    required this.minimumConfidence,
    required this.incompatiblePlatformPenalty,
    required this.unsafeReputationFloor,
    required this.unsafeBetrayalThreshold,
    required this.blueprintComplementarityCap,
    required this.competitionPenaltyCap,
    required this.staleProfileDays,
  });

  final ArcMatchIntelligenceTierWeights basicWeights;
  final ArcMatchIntelligenceTierWeights enhancedWeights;
  final ArcMatchIntelligenceTierWeights advancedWeights;
  final int minimumConfidence;
  final int incompatiblePlatformPenalty;
  final int unsafeReputationFloor;
  final int unsafeBetrayalThreshold;
  final int blueprintComplementarityCap;
  final int competitionPenaltyCap;
  final int staleProfileDays;

  ArcMatchIntelligenceTierWeights weightsFor(ArcMatchIntelligenceTier tier) {
    switch (tier) {
      case ArcMatchIntelligenceTier.basic:
        return basicWeights;
      case ArcMatchIntelligenceTier.enhanced:
        return enhancedWeights;
      case ArcMatchIntelligenceTier.advanced:
        return advancedWeights;
    }
  }

  static const defaults = ArcMatchIntelligenceConfig(
    basicWeights: ArcMatchIntelligenceTierWeights(
      coreProfile: 46,
      availability: 24,
      communication: 0,
      squadIntent: 0,
      archetypeFit: 0,
      reputation: 30,
      relationship: 0,
      progression: 0,
      mapAndEventFit: 0,
    ),
    enhancedWeights: ArcMatchIntelligenceTierWeights(
      coreProfile: 30,
      availability: 18,
      communication: 14,
      squadIntent: 12,
      archetypeFit: 14,
      reputation: 9,
      relationship: 3,
      progression: 0,
      mapAndEventFit: 0,
    ),
    advancedWeights: ArcMatchIntelligenceTierWeights(
      coreProfile: 22,
      availability: 13,
      communication: 10,
      squadIntent: 9,
      archetypeFit: 11,
      reputation: 7,
      relationship: 5,
      progression: 16,
      mapAndEventFit: 7,
    ),
    minimumConfidence: 28,
    incompatiblePlatformPenalty: 35,
    unsafeReputationFloor: -20,
    unsafeBetrayalThreshold: 3,
    blueprintComplementarityCap: 24,
    competitionPenaltyCap: 10,
    staleProfileDays: 30,
  );
}

class ArcMatchScoreBreakdown {
  const ArcMatchScoreBreakdown({
    required this.coreProfile,
    required this.availability,
    required this.communication,
    required this.squadIntent,
    required this.archetypeFit,
    required this.reputation,
    required this.relationship,
    required this.progression,
    required this.mapAndEventFit,
    required this.blueprintComplementarity,
    required this.competitionPenalty,
    required this.incompleteProfilePenalty,
  });

  final int coreProfile;
  final int availability;
  final int communication;
  final int squadIntent;
  final int archetypeFit;
  final int reputation;
  final int relationship;
  final int progression;
  final int mapAndEventFit;
  final int blueprintComplementarity;
  final int competitionPenalty;
  final int incompleteProfilePenalty;

  int get total =>
      coreProfile +
      availability +
      communication +
      squadIntent +
      archetypeFit +
      reputation +
      relationship +
      progression +
      mapAndEventFit +
      blueprintComplementarity -
      competitionPenalty -
      incompleteProfilePenalty;

  Map<String, int> toInternalMap() {
    return <String, int>{
      'coreProfile': coreProfile,
      'availability': availability,
      'communication': communication,
      'squadIntent': squadIntent,
      'archetypeFit': archetypeFit,
      'reputation': reputation,
      'relationship': relationship,
      'progression': progression,
      'mapAndEventFit': mapAndEventFit,
      'blueprintComplementarity': blueprintComplementarity,
      'competitionPenalty': competitionPenalty,
      'incompleteProfilePenalty': incompleteProfilePenalty,
    };
  }
}

class ArcMatchRankingMetadata {
  const ArcMatchRankingMetadata({
    required this.rankScore,
    required this.dataCompleteness,
    required this.staleProfile,
    required this.tieBreaker,
  });

  final int rankScore;
  final int dataCompleteness;
  final bool staleProfile;
  final String tieBreaker;
}

class ArcMatchCompatibilityResult {
  const ArcMatchCompatibilityResult({
    required this.score,
    required this.reasons,
    required this.tier,
    required this.confidence,
    required this.breakdown,
    required this.publicTags,
    required this.exclusionReasons,
    required this.ranking,
  });

  final int score;
  final List<String> reasons;
  final ArcMatchIntelligenceTier tier;
  final ArcMatchConfidenceLevel confidence;
  final ArcMatchScoreBreakdown breakdown;
  final List<String> publicTags;
  final List<String> exclusionReasons;
  final ArcMatchRankingMetadata ranking;

  bool get isExcluded => exclusionReasons.isNotEmpty;
  String get percentageLabel => '$score% Match';
  String get publicLabel => ArcMatchCompatibilityEngine.matchLabel(score);
  String get tierLabel => tier.label;
  String get confidenceLabel => confidence.label;
  String get publicExplanation =>
      ArcMatchCompatibilityEngine.protectedExplanation;

  Map<String, dynamic> toPublicMap() {
    return <String, dynamic>{
      'score': score,
      'percentageLabel': percentageLabel,
      'publicLabel': publicLabel,
      'publicExplanation': publicExplanation,
      'tier': tier.name,
      'tierLabel': tierLabel,
      'confidence': confidence.name,
      'confidenceLabel': confidenceLabel,
      'publicTags': publicTags,
      'excluded': isExcluded,
      'exclusionReasons': exclusionReasons,
    };
  }
}

class ArcMatchCompatibilityEngine {
  const ArcMatchCompatibilityEngine({
    this.config = ArcMatchIntelligenceConfig.defaults,
  });

  final ArcMatchIntelligenceConfig config;

  static const protectedExplanation =
      'Your score is based on compatibility signals from your profile, availability and activity.';

  static String matchLabel(int score) {
    if (score >= 85) return 'Strong fit';
    if (score >= 70) return 'Good fit';
    if (score >= 55) return 'Compatible';
    return 'Worth a look';
  }

  ArcMatchCompatibilityResult score({
    required ArcMatchRiderProfile me,
    required ArcMatchRiderProfile other,
    ArcMatchObjectiveSignals meSignals = ArcMatchObjectiveSignals.empty,
    ArcMatchObjectiveSignals otherSignals = ArcMatchObjectiveSignals.empty,
    ArcMatchIntelligenceTier tier = ArcMatchIntelligenceTier.advanced,
    Set<String> blockedUserIds = const <String>{},
    DateTime? now,
  }) {
    final evaluatedAt = now ?? DateTime.now();
    final normalizedMeSignals = _profileAdjustedSignals(me, meSignals);
    final normalizedOtherSignals = _profileAdjustedSignals(other, otherSignals);
    final weights = config.weightsFor(tier);
    final dataCompleteness = _dataCompleteness(me, other);
    final staleProfile = _isStale(other, evaluatedAt);
    final exclusions = _exclusions(
      me: me,
      other: other,
      otherSignals: normalizedOtherSignals,
      blockedUserIds: blockedUserIds,
    );
    final rawReputationScore = _rawReputationScore(normalizedOtherSignals);

    final coreProfileRaw = _coreProfileScore(me, other);
    final availabilityRaw = _availabilityRawScore(
      normalizedMeSignals,
      normalizedOtherSignals,
    );
    final communicationRaw = _communicationRawScore(me, other);
    final squadIntentRaw = _squadIntentRawScore(me, other);
    final archetypeFitRaw = _archetypeRawScore(me, other);
    final reputationRaw = _reputationRawScore(normalizedOtherSignals);
    final relationshipRaw = _relationshipRawScore(normalizedOtherSignals);
    final progressionRaw = _progressionRawScore(
      normalizedMeSignals,
      normalizedOtherSignals,
    );
    final mapAndEventFitRaw = _mapAndEventRawScore(me, other);
    final blueprintComplementarity = tier == ArcMatchIntelligenceTier.advanced
        ? _blueprintComplementarityScore(
            normalizedMeSignals,
            normalizedOtherSignals,
          )
        : 0;
    final competitionPenalty = tier == ArcMatchIntelligenceTier.advanced
        ? _competitionPenalty(normalizedMeSignals, normalizedOtherSignals)
        : 0;

    final coreProfile = _scaled(coreProfileRaw, weights.coreProfile);
    final availability = _scaled(availabilityRaw, weights.availability);
    final communication = tier.index >= ArcMatchIntelligenceTier.enhanced.index
        ? _scaled(communicationRaw, weights.communication)
        : 0;
    final squadIntent = tier.index >= ArcMatchIntelligenceTier.enhanced.index
        ? _scaled(squadIntentRaw, weights.squadIntent)
        : 0;
    final archetypeFit = tier.index >= ArcMatchIntelligenceTier.enhanced.index
        ? _scaled(archetypeFitRaw, weights.archetypeFit)
        : 0;
    final reputation = _scaled(reputationRaw, weights.reputation);
    final relationship = tier.index >= ArcMatchIntelligenceTier.enhanced.index
        ? _scaled(relationshipRaw, weights.relationship)
        : 0;
    final progression = tier == ArcMatchIntelligenceTier.advanced
        ? _scaled(progressionRaw, weights.progression)
        : 0;
    final mapAndEventFit = tier == ArcMatchIntelligenceTier.advanced
        ? _scaled(mapAndEventFitRaw, weights.mapAndEventFit)
        : 0;
    final incompleteProfilePenalty = ((100 - dataCompleteness) / 10).round();

    final breakdown = ArcMatchScoreBreakdown(
      coreProfile: coreProfile,
      availability: availability,
      communication: communication,
      squadIntent: squadIntent,
      archetypeFit: archetypeFit,
      reputation: reputation,
      relationship: relationship,
      progression: progression,
      mapAndEventFit: mapAndEventFit,
      blueprintComplementarity: blueprintComplementarity,
      competitionPenalty: competitionPenalty,
      incompleteProfilePenalty: incompleteProfilePenalty,
    );

    final scoreBase = _scoreForTier(
      tier: tier,
      coreProfile: coreProfileRaw,
      availability: availabilityRaw,
      communication: communicationRaw,
      squadIntent: squadIntentRaw,
      archetypeFit: archetypeFitRaw,
      reputation: reputationRaw,
      relationship: relationshipRaw,
      progression: progressionRaw,
      mapAndEventFit: mapAndEventFitRaw,
      blueprintComplementarity: blueprintComplementarity,
      competitionPenalty: competitionPenalty,
      incompleteProfilePenalty: incompleteProfilePenalty,
    );
    final score = exclusions.isEmpty
        ? _cap(scoreBase, 0, 100)
        : _cap(scoreBase - config.incompatiblePlatformPenalty, 0, 45);
    final confidence = _confidence(
      dataCompleteness: dataCompleteness,
      staleProfile: staleProfile,
      rawReputationScore: rawReputationScore,
      exclusions: exclusions,
      tier: tier,
    );
    final rankScore = _rankScore(
      score: score,
      confidence: confidence,
      other: other,
      exclusions: exclusions,
      staleProfile: staleProfile,
    );

    return ArcMatchCompatibilityResult(
      score: score,
      reasons: _buildReasons(
        me,
        other,
        normalizedMeSignals,
        normalizedOtherSignals,
      ),
      tier: tier,
      confidence: confidence,
      breakdown: breakdown,
      publicTags: _publicTags(
        me: me,
        other: other,
        meSignals: normalizedMeSignals,
        otherSignals: normalizedOtherSignals,
        tier: tier,
        rawReputationScore: rawReputationScore,
      ),
      exclusionReasons: exclusions,
      ranking: ArcMatchRankingMetadata(
        rankScore: rankScore,
        dataCompleteness: dataCompleteness,
        staleProfile: staleProfile,
        tieBreaker: _tieBreaker(other),
      ),
    );
  }

  List<String> _buildReasons(
    ArcMatchRiderProfile me,
    ArcMatchRiderProfile other,
    ArcMatchObjectiveSignals meSignals,
    ArcMatchObjectiveSignals otherSignals,
  ) {
    final reasons = <String>[];

    void addShared(String label, List<String> mine, List<String> theirs) {
      final overlap = mine
          .where((item) => theirs.contains(item))
          .toList(growable: false);
      if (overlap.isNotEmpty) {
        reasons.add('$label: ${overlap.take(2).join(', ')}');
      }
    }

    addShared('Shared archetypes', me.archetypes, other.archetypes);
    addShared('Shared goals', me.goals, other.goals);
    if (me.sessionIntent == other.sessionIntent &&
        me.sessionIntent != 'Flexible') {
      reasons.add('Same session intent: ${me.sessionIntent}');
    }
    if (me.currentPriority == other.currentPriority &&
        me.currentPriority != 'Balanced progression') {
      reasons.add('Same priority: ${me.currentPriority}');
    }
    addShared('Shared playstyle', me.playstyles, other.playstyles);
    addShared('Shared squad vibe', me.squadPreferences, other.squadPreferences);
    addShared('Shared comms', me.comms, other.comms);
    addShared('Shared maps', me.preferredMaps, other.preferredMaps);
    if (me.platform.isNotEmpty && me.platform == other.platform) {
      reasons.add('Same platform');
    }
    if (me.crossplayEnabled && other.crossplayEnabled) {
      reasons.add('Crossplay compatible');
    }
    if (me.region.isNotEmpty && me.region == other.region) {
      reasons.add('Same region');
    }
    if (_serverCompatible(me.serverPreference, other.serverPreference)) {
      reasons.add('Server compatible');
    }
    if (other.lookingNow) reasons.add('Looking now');
    if (_canHelp(meSignals, otherSignals).isNotEmpty) {
      reasons.add('Blueprint helper potential');
    }
    if (_canHelp(otherSignals, meSignals).isNotEmpty) {
      reasons.add('Can help your blueprint targets');
    }
    if (_sharedNormalized(meSignals.questIds, otherSignals.questIds) > 0) {
      reasons.add('Quest alignment');
    }
    if (_sharedNormalized(meSignals.trialIds, otherSignals.trialIds) > 0) {
      reasons.add('Trials alignment');
    }
    return reasons.take(4).toList(growable: false);
  }

  int _scoreForTier({
    required ArcMatchIntelligenceTier tier,
    required int coreProfile,
    required int availability,
    required int communication,
    required int squadIntent,
    required int archetypeFit,
    required int reputation,
    required int relationship,
    required int progression,
    required int mapAndEventFit,
    required int blueprintComplementarity,
    required int competitionPenalty,
    required int incompleteProfilePenalty,
  }) {
    final basic = _weighted(
      rawScores: <int>[coreProfile, availability, reputation],
      weights: <int>[46, 24, 30],
    );
    if (tier == ArcMatchIntelligenceTier.basic) {
      return _cap(basic - incompleteProfilePenalty, 0, 100);
    }

    final enhanced = _weighted(
      rawScores: <int>[
        coreProfile,
        availability,
        communication,
        squadIntent,
        archetypeFit,
        reputation,
        if (relationship > 0) relationship,
      ],
      weights: <int>[30, 18, 14, 12, 17, 9, if (relationship > 0) 5],
    );
    final enhancedScore = _max(basic, enhanced + (relationship > 0 ? 4 : 0));
    if (tier == ArcMatchIntelligenceTier.enhanced) {
      return _cap(enhancedScore - incompleteProfilePenalty, 0, 100);
    }

    final advancedBoost =
        (progression * 0.14).round() +
        (mapAndEventFit * 0.08).round() +
        blueprintComplementarity -
        competitionPenalty;
    return _cap(
      enhancedScore + advancedBoost - incompleteProfilePenalty,
      0,
      100,
    );
  }

  int _weighted({required List<int> rawScores, required List<int> weights}) {
    var totalWeight = 0;
    var weighted = 0;
    for (var index = 0; index < rawScores.length; index += 1) {
      final weight = weights[index];
      totalWeight += weight;
      weighted += _cap(rawScores[index], 0, 100) * weight;
    }
    if (totalWeight <= 0) return 0;
    return (weighted / totalWeight).round();
  }

  ArcMatchObjectiveSignals _profileAdjustedSignals(
    ArcMatchRiderProfile profile,
    ArcMatchObjectiveSignals signals,
  ) {
    return signals.copyWith(
      availabilityDayKeys: signals.availabilityDayKeys.isEmpty
          ? profile.availabilityDayKeys
          : signals.availabilityDayKeys,
      timezone: signals.timezone.trim().isEmpty
          ? profile.timezone
          : signals.timezone,
      lookingNow: signals.lookingNow || profile.lookingNow,
    );
  }

  List<String> _exclusions({
    required ArcMatchRiderProfile me,
    required ArcMatchRiderProfile other,
    required ArcMatchObjectiveSignals otherSignals,
    required Set<String> blockedUserIds,
  }) {
    final exclusions = <String>[];
    if (blockedUserIds.contains(other.uid)) exclusions.add('Blocked by you');
    if (!other.visibleInSearch) exclusions.add('Hidden from search');
    if (_platformIncompatible(me, other)) {
      exclusions.add('Incompatible platform preferences');
    }
    if (otherSignals.betrayalFlags >= config.unsafeBetrayalThreshold ||
        _rawReputationScore(otherSignals) <= config.unsafeReputationFloor) {
      exclusions.add('Reputation safety threshold');
    }
    return exclusions;
  }

  int _coreProfileScore(ArcMatchRiderProfile me, ArcMatchRiderProfile other) {
    var score = 0;
    score += _cap(_sharedCount(me.playstyles, other.playstyles), 0, 2) * 25;
    score += _cap(_sharedCount(me.goals, other.goals), 0, 2) * 20;
    if (me.platform.isNotEmpty && me.platform == other.platform) score += 15;
    if (me.crossplayEnabled && other.crossplayEnabled) score += 8;
    if (me.region.isNotEmpty && me.region == other.region) score += 12;
    if (_serverCompatible(me.serverPreference, other.serverPreference)) {
      score += 15;
    }
    return _cap(score, 0, 100);
  }

  int _availabilityRawScore(
    ArcMatchObjectiveSignals me,
    ArcMatchObjectiveSignals other,
  ) {
    var score = 0;
    if (me.lookingNow && other.lookingNow && !other.away) score += 50;
    if (other.away) score -= 30;
    if (me.timezone.trim().isNotEmpty &&
        other.timezone.trim().isNotEmpty &&
        me.timezone.trim().toLowerCase() ==
            other.timezone.trim().toLowerCase()) {
      score += 26;
    }
    score +=
        _cap(
          _sharedNormalized(me.availabilityDayKeys, other.availabilityDayKeys),
          0,
          4,
        ) *
        12;
    return _cap(score, 0, 100);
  }

  int _communicationRawScore(
    ArcMatchRiderProfile me,
    ArcMatchRiderProfile other,
  ) {
    if (me.comms.isEmpty || other.comms.isEmpty) return 0;
    final shared = _sharedCount(me.comms, other.comms);
    if (shared > 0) return _cap(70 + (shared * 15), 0, 100);
    if (me.comms.contains('Flexible') || other.comms.contains('Flexible')) {
      return 55;
    }
    return 0;
  }

  int _squadIntentRawScore(
    ArcMatchRiderProfile me,
    ArcMatchRiderProfile other,
  ) {
    var score = _sharedCount(me.squadPreferences, other.squadPreferences) * 50;
    if (me.sessionIntent == other.sessionIntent &&
        me.sessionIntent != 'Flexible') {
      score += 40;
    }
    if (me.currentPriority == other.currentPriority &&
        me.currentPriority != 'Balanced progression') {
      score += 30;
    }
    return _cap(score, 0, 100);
  }

  int _archetypeRawScore(ArcMatchRiderProfile me, ArcMatchRiderProfile other) {
    var score = _sharedCount(me.archetypes, other.archetypes) * 60;
    if (ArcPlayerArchetypeCatalog.hasRatHunter(me.archetypes) &&
        ArcPlayerArchetypeCatalog.hasRatHunter(other.archetypes)) {
      score += 35;
    }
    if (_hasComplementaryArchetype(me.archetypes, other.archetypes)) {
      score += 25;
    }
    return _cap(score, 0, 100);
  }

  int _reputationRawScore(ArcMatchObjectiveSignals other) {
    var score = 70;
    score += _cap(other.completedTrades, 0, 10) * 3;
    score += _cap(other.reputationScore ~/ 10, 0, 25);
    score -= _cap(other.noShows, 0, 6) * 9;
    score -= _cap(other.betrayalFlags, 0, 4) * 24;
    return _cap(score, 0, 100);
  }

  int _rawReputationScore(ArcMatchObjectiveSignals other) {
    var score = 0;
    score += _cap(other.completedTrades, 0, 10) * 3;
    score += _cap(other.reputationScore ~/ 10, 0, 20);
    score -= _cap(other.noShows, 0, 8) * 5;
    score -= _cap(other.betrayalFlags, 0, 4) * 24;
    return score;
  }

  int _relationshipRawScore(ArcMatchObjectiveSignals other) {
    var score = 0;
    if (other.isFavouriteRider) score += 46;
    score += _cap(other.previousCompletedTrades, 0, 5) * 10;
    score += _cap(other.previousSquadSessions, 0, 5) * 10;
    if (other.previousBlueprintOffers > 0) score += 16;
    return _cap(score, 0, 100);
  }

  int _progressionRawScore(
    ArcMatchObjectiveSignals me,
    ArcMatchObjectiveSignals other,
  ) {
    var score = 0;
    score += _cap(_sharedNormalized(me.questIds, other.questIds), 0, 2) * 20;
    score +=
        _cap(_sharedNormalized(me.questChains, other.questChains), 0, 2) * 14;
    score += _cap(_sharedNormalized(me.trialIds, other.trialIds), 0, 2) * 18;
    score +=
        _cap(_sharedNormalized(me.benchGoalIds, other.benchGoalIds), 0, 2) * 12;
    score +=
        _cap(
          _sharedNormalized(
            me.favouriteLoadoutNeedIds,
            other.favouriteLoadoutNeedIds,
          ),
          0,
          2,
        ) *
        12;
    score +=
        _cap(
          _sharedNormalized(
            me.raidPlannerTargetIds,
            other.raidPlannerTargetIds,
          ),
          0,
          2,
        ) *
        10;
    score +=
        _cap(
          _sharedNormalized(me.tradePreferences, other.tradePreferences),
          0,
          2,
        ) *
        8;
    if (me.helperMentor && other.neededBlueprintIds.isNotEmpty) score += 12;
    if (other.helperMentor && me.neededBlueprintIds.isNotEmpty) score += 14;
    return _cap(score, 0, 100);
  }

  int _mapAndEventRawScore(
    ArcMatchRiderProfile me,
    ArcMatchRiderProfile other,
  ) {
    var score =
        _cap(_sharedCount(me.preferredMaps, other.preferredMaps), 0, 3) * 22;
    score +=
        _cap(_sharedCount(me.preferredModes, other.preferredModes), 0, 3) * 18;
    return _cap(score, 0, 100);
  }

  int _blueprintComplementarityScore(
    ArcMatchObjectiveSignals me,
    ArcMatchObjectiveSignals other,
  ) {
    final iHelpThem = _canHelp(me, other).length;
    final theyHelpMe = _canHelp(other, me).length;
    final iHaveActiveDuplicate = _activeDuplicateHelp(me, other);
    final theyHaveActiveDuplicate = _activeDuplicateHelp(other, me);
    var score = 0;

    score += iHelpThem * (iHaveActiveDuplicate ? 8 : 5);
    score += theyHelpMe * (theyHaveActiveDuplicate ? 10 : 6);
    if (iHelpThem > 0 && theyHelpMe > 0) score += 10;
    if (iHelpThem > 0 && me.giftFriendly) score += 3;
    if (theyHelpMe > 0 && other.giftFriendly) score += 4;
    if ((iHelpThem > 0 || theyHelpMe > 0) &&
        (me.tradeOnly || other.tradeOnly)) {
      score += 2;
    }
    return _cap(score, 0, config.blueprintComplementarityCap);
  }

  int _competitionPenalty(
    ArcMatchObjectiveSignals me,
    ArcMatchObjectiveSignals other,
  ) {
    final competing = _sharedNormalized(
      me.neededBlueprintIds,
      other.neededBlueprintIds,
    );
    if (competing <= 0 ||
        _canHelp(me, other).isNotEmpty ||
        _canHelp(other, me).isNotEmpty) {
      return 0;
    }
    return _cap(competing * 5, 0, config.competitionPenaltyCap);
  }

  int _dataCompleteness(ArcMatchRiderProfile me, ArcMatchRiderProfile other) {
    final score = (_profileCompleteness(me) + _profileCompleteness(other)) / 2;
    return _cap(score.round(), 0, 100);
  }

  int _profileCompleteness(ArcMatchRiderProfile profile) {
    var score = 0;
    if (profile.platform.trim().isNotEmpty) score += 12;
    if (profile.region.trim().isNotEmpty) score += 12;
    if (profile.serverPreference.trim().isNotEmpty) score += 8;
    if (profile.archetypes.isNotEmpty) score += 12;
    if (profile.playstyles.isNotEmpty) score += 12;
    if (profile.goals.isNotEmpty) score += 10;
    if (profile.comms.isNotEmpty) score += 10;
    if (profile.squadPreferences.isNotEmpty) score += 10;
    if (profile.sessionIntent != 'Flexible') score += 7;
    if (profile.currentPriority != 'Balanced progression') score += 7;
    return _cap(score, 0, 100);
  }

  bool _isStale(ArcMatchRiderProfile other, DateTime now) {
    final updatedAt = other.updatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt).inDays > config.staleProfileDays;
  }

  ArcMatchConfidenceLevel _confidence({
    required int dataCompleteness,
    required bool staleProfile,
    required int rawReputationScore,
    required List<String> exclusions,
    required ArcMatchIntelligenceTier tier,
  }) {
    var confidence =
        config.minimumConfidence + (dataCompleteness * 0.55).round();
    if (tier == ArcMatchIntelligenceTier.enhanced) confidence += 8;
    if (tier == ArcMatchIntelligenceTier.advanced) confidence += 12;
    if (staleProfile) confidence -= 18;
    if (rawReputationScore < 0) confidence -= 12;
    if (exclusions.isNotEmpty) confidence -= 28;

    if (confidence >= 74) return ArcMatchConfidenceLevel.high;
    if (confidence >= 48) return ArcMatchConfidenceLevel.medium;
    return ArcMatchConfidenceLevel.low;
  }

  int _rankScore({
    required int score,
    required ArcMatchConfidenceLevel confidence,
    required ArcMatchRiderProfile other,
    required List<String> exclusions,
    required bool staleProfile,
  }) {
    if (exclusions.isNotEmpty) return -1000;
    var rank = score;
    if (confidence == ArcMatchConfidenceLevel.high) rank += 4;
    if (confidence == ArcMatchConfidenceLevel.low) rank -= 8;
    if (other.lookingNow) rank += 3;
    if (staleProfile) rank -= 6;
    return _cap(rank, -1000, 120);
  }

  List<String> _publicTags({
    required ArcMatchRiderProfile me,
    required ArcMatchRiderProfile other,
    required ArcMatchObjectiveSignals meSignals,
    required ArcMatchObjectiveSignals otherSignals,
    required ArcMatchIntelligenceTier tier,
    required int rawReputationScore,
  }) {
    final tags = <String>[];
    if (_availabilityRawScore(meSignals, otherSignals) >= 22) {
      tags.add('Similar schedule');
    }
    if (_sharedCount(me.playstyles, other.playstyles) > 0 ||
        _sharedCount(me.goals, other.goals) > 0) {
      tags.add('Compatible play style');
    }
    if (me.crossplayEnabled && other.crossplayEnabled) {
      tags.add('Crossplay ready');
    }
    if (rawReputationScore >= 15 || otherSignals.completedTrades > 0) {
      tags.add('Trusted activity');
    }
    if (tier.index >= ArcMatchIntelligenceTier.enhanced.index) {
      if (_communicationRawScore(me, other) >= 28) {
        tags.add('Communication fit');
      }
      if (_squadIntentRawScore(me, other) >= 32) {
        tags.add('Good squad balance');
      }
      if (otherSignals.isFavouriteRider) tags.add('Favourite Raider');
    }
    if (tier == ArcMatchIntelligenceTier.advanced &&
        (_progressionRawScore(meSignals, otherSignals) > 0 ||
            _blueprintComplementarityScore(meSignals, otherSignals) > 0)) {
      tags.add('Progression fit');
    }
    return tags.take(4).toList(growable: false);
  }

  Set<String> _canHelp(
    ArcMatchObjectiveSignals helper,
    ArcMatchObjectiveSignals seeker,
  ) {
    final helperOwned = helper.normalizedOwnedBlueprintIds();
    final seekerNeeds = seeker.normalizedNeededBlueprintIds();
    return helperOwned.intersection(seekerNeeds);
  }

  bool _activeDuplicateHelp(
    ArcMatchObjectiveSignals helper,
    ArcMatchObjectiveSignals seeker,
  ) {
    final active = helper.normalizedAvailableBlueprintIds();
    final seekerNeeds = seeker.normalizedNeededBlueprintIds();
    return active.intersection(seekerNeeds).isNotEmpty;
  }

  bool _hasComplementaryArchetype(List<String> left, List<String> right) {
    final normalizedLeft = left.map((value) => value.toLowerCase()).toSet();
    final normalizedRight = right.map((value) => value.toLowerCase()).toSet();
    final leftSupport = normalizedLeft.any(
      (value) => value.contains('support') || value.contains('trader'),
    );
    final rightProgression = normalizedRight.any(
      (value) => value.contains('quest') || value.contains('blueprint'),
    );
    final rightSupport = normalizedRight.any(
      (value) => value.contains('support') || value.contains('trader'),
    );
    final leftProgression = normalizedLeft.any(
      (value) => value.contains('quest') || value.contains('blueprint'),
    );
    return (leftSupport && rightProgression) ||
        (rightSupport && leftProgression);
  }

  bool _serverCompatible(String left, String right) {
    return left.isNotEmpty &&
        right.isNotEmpty &&
        (left == 'Automatic' || right == 'Automatic' || left == right);
  }

  bool _platformIncompatible(
    ArcMatchRiderProfile me,
    ArcMatchRiderProfile other,
  ) {
    return me.platform.trim().isNotEmpty &&
        other.platform.trim().isNotEmpty &&
        me.platform != other.platform &&
        (!me.crossplayEnabled || !other.crossplayEnabled);
  }

  int _sharedCount(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.where((item) => b.contains(item)).length;
  }

  int _sharedNormalized(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final left = ArcMatchObjectiveSignals.normalizeList(a).toSet();
    final right = ArcMatchObjectiveSignals.normalizeList(b).toSet();
    return left.intersection(right).length;
  }

  int _scaled(int raw, int weight) {
    if (weight <= 0 || raw <= 0) return 0;
    return ((_cap(raw, 0, 100) * weight) / 100).round();
  }

  String _tieBreaker(ArcMatchRiderProfile other) {
    return '${other.title.toLowerCase()}|${other.uid}';
  }

  int _cap(int value, int minimum, int maximum) {
    return value.clamp(minimum, maximum).toInt();
  }

  int _max(int left, int right) {
    return left >= right ? left : right;
  }
}
