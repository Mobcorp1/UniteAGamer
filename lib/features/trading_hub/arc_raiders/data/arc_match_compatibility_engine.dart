import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';

class ArcMatchCompatibilityResult {
  const ArcMatchCompatibilityResult({
    required this.score,
    required this.reasons,
  });

  final int score;
  final List<String> reasons;
}

class ArcMatchCompatibilityEngine {
  const ArcMatchCompatibilityEngine();

  ArcMatchCompatibilityResult score({
    required ArcMatchRiderProfile me,
    required ArcMatchRiderProfile other,
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

    return ArcMatchCompatibilityResult(
      score: score.clamp(0, 100),
      reasons: _buildReasons(me, other),
    );
  }

  List<String> _buildReasons(
    ArcMatchRiderProfile me,
    ArcMatchRiderProfile other,
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
    return reasons.take(4).toList(growable: false);
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
}
