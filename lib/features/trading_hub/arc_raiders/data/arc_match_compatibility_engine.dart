import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_objective_signals.dart';

class ArcMatchCompatibilityResult {
  const ArcMatchCompatibilityResult({
    required this.score,
    required this.reasons,
  });

  final int score;
  final List<String> reasons;

  String get percentageLabel => '$score% Match';
  String get publicLabel => ArcMatchCompatibilityEngine.matchLabel(score);
  String get publicExplanation =>
      ArcMatchCompatibilityEngine.protectedExplanation;
}

class ArcMatchCompatibilityEngine {
  const ArcMatchCompatibilityEngine();

  static const protectedExplanation = 'Based on your profiles.';

  static String matchLabel(int score) {
    if (score >= 95) return 'Perfect Match';
    if (score >= 85) return 'Excellent Match';
    if (score >= 70) return 'Strong Match';
    if (score >= 55) return 'Good Match';
    return 'Possible Match';
  }

  ArcMatchCompatibilityResult score({
    required ArcMatchRiderProfile me,
    required ArcMatchRiderProfile other,
    ArcMatchObjectiveSignals meSignals = ArcMatchObjectiveSignals.empty,
    ArcMatchObjectiveSignals otherSignals = ArcMatchObjectiveSignals.empty,
  }) {
    var score = 0;
    score += _sharedCount(me.archetypes, other.archetypes) * 26;
    score += _sharedCount(me.playstyles, other.playstyles) * 20;
    score += _sharedCount(me.goals, other.goals) * 18;
    if (me.sessionIntent == other.sessionIntent &&
        me.sessionIntent != 'Flexible') {
      score += 20;
    }
    if (me.currentPriority == other.currentPriority &&
        me.currentPriority != 'Balanced progression') {
      score += 16;
    }
    score += _sharedCount(me.squadPreferences, other.squadPreferences) * 16;
    score += _sharedCount(me.comms, other.comms) * 12;
    score += _sharedCount(me.preferredMaps, other.preferredMaps) * 10;
    score += _sharedCount(me.preferredModes, other.preferredModes) * 10;

    if (ArcPlayerArchetypeCatalog.hasRatHunter(me.archetypes) &&
        ArcPlayerArchetypeCatalog.hasRatHunter(other.archetypes)) {
      score += 14;
    }
    if (me.platform.isNotEmpty && me.platform == other.platform) score += 14;
    if (me.crossplayEnabled && other.crossplayEnabled) score += 6;
    if (me.region.isNotEmpty && me.region == other.region) score += 10;
    if (_serverCompatible(me.serverPreference, other.serverPreference)) {
      score += 12;
    }
    if (other.lookingNow) score += 8;
    score += _objectiveScore(meSignals, otherSignals);
    score += _availabilityScore(meSignals, otherSignals);
    score += _reputationScore(otherSignals);

    return ArcMatchCompatibilityResult(
      score: score.clamp(0, 100),
      reasons: _buildReasons(me, other, meSignals, otherSignals),
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

  int _objectiveScore(
    ArcMatchObjectiveSignals me,
    ArcMatchObjectiveSignals other,
  ) {
    var score = 0;
    final iHelpThem = _canHelp(me, other);
    final theyHelpMe = _canHelp(other, me);
    final iHaveActiveDuplicate = _activeDuplicateHelp(me, other);
    final theyHaveActiveDuplicate = _activeDuplicateHelp(other, me);

    score += iHelpThem.length * (iHaveActiveDuplicate ? 14 : 8);
    score += theyHelpMe.length * (theyHaveActiveDuplicate ? 18 : 10);
    if (iHelpThem.isNotEmpty && theyHelpMe.isNotEmpty) score += 20;
    if (iHelpThem.isNotEmpty && me.giftFriendly) score += 6;
    if (theyHelpMe.isNotEmpty && other.giftFriendly) score += 8;
    if ((iHelpThem.isNotEmpty || theyHelpMe.isNotEmpty) &&
        (me.tradeOnly || other.tradeOnly)) {
      score += 3;
    }

    score += _sharedNormalized(me.questIds, other.questIds) * 12;
    score += _sharedNormalized(me.questChains, other.questChains) * 8;
    score += _sharedNormalized(me.trialIds, other.trialIds) * 12;
    score += _sharedNormalized(me.benchGoalIds, other.benchGoalIds) * 8;
    score +=
        _sharedNormalized(
          me.favouriteLoadoutNeedIds,
          other.favouriteLoadoutNeedIds,
        ) *
        8;
    score +=
        _sharedNormalized(me.raidPlannerTargetIds, other.raidPlannerTargetIds) *
        7;
    score += _sharedNormalized(me.tradePreferences, other.tradePreferences) * 5;

    final competingBlueprintHunts = _sharedNormalized(
      me.neededBlueprintIds,
      other.neededBlueprintIds,
    );
    if (competingBlueprintHunts > 0 &&
        iHelpThem.isEmpty &&
        theyHelpMe.isEmpty) {
      score += competingBlueprintHunts.clamp(0, 2) * 2;
    }

    if (me.helperMentor && other.neededBlueprintIds.isNotEmpty) score += 6;
    if (other.helperMentor && me.neededBlueprintIds.isNotEmpty) score += 8;
    if (other.isFavouriteRider) score += 10;
    if (other.previousCompletedTrades > 0) score += 5;
    if (other.previousSquadSessions > 0) score += 4;
    if (other.previousBlueprintOffers > 0) score += 4;

    return score;
  }

  int _availabilityScore(
    ArcMatchObjectiveSignals me,
    ArcMatchObjectiveSignals other,
  ) {
    var score = 0;
    if (me.lookingNow && other.lookingNow && !other.away) score += 8;
    if (other.away) score -= 12;
    if (me.timezone.trim().isNotEmpty &&
        other.timezone.trim().isNotEmpty &&
        me.timezone.trim().toLowerCase() ==
            other.timezone.trim().toLowerCase()) {
      score += 4;
    }
    score +=
        _sharedNormalized(me.availabilityDayKeys, other.availabilityDayKeys) *
        3;
    return score;
  }

  int _reputationScore(ArcMatchObjectiveSignals other) {
    var score = 0;
    score += other.completedTrades.clamp(0, 10);
    score += (other.reputationScore ~/ 20).clamp(0, 8);
    score -= other.noShows.clamp(0, 6) * 2;
    score -= other.betrayalFlags.clamp(0, 3) * 8;
    return score;
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

  bool _serverCompatible(String left, String right) {
    return left.isNotEmpty &&
        right.isNotEmpty &&
        (left == 'Automatic' || right == 'Automatic' || left == right);
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
}
