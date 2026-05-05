import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayLikeAProGoal {
  rankedPush,
  blueprintFarm,
  resourceRun,
  chillLoot,
  questsTrials,
  teamChemistry,
}

enum PlayLikeAProResetStyle {
  breathing,
  hydrate,
  music,
  shortBreak,
  lowerPressure,
}

class PlayLikeAProHistoryEntry {
  const PlayLikeAProHistoryEntry({
    required this.createdAt,
    required this.goal,
    required this.energy,
    required this.focus,
    required this.calm,
    required this.confidence,
    required this.tiltRisk,
    required this.tiltLevel,
    required this.fatigue,
    required this.frustration,
    required this.performance,
    required this.enjoyment,
    required this.discipline,
    required this.tiltControl,
    required this.notes,
  });

  final DateTime createdAt;
  final PlayLikeAProGoal goal;
  final int energy;
  final int focus;
  final int calm;
  final int confidence;
  final int tiltRisk;
  final int tiltLevel;
  final int fatigue;
  final int frustration;
  final int performance;
  final int enjoyment;
  final int discipline;
  final int tiltControl;
  final String notes;

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'goal': goal.name,
      'energy': energy,
      'focus': focus,
      'calm': calm,
      'confidence': confidence,
      'tiltRisk': tiltRisk,
      'tiltLevel': tiltLevel,
      'fatigue': fatigue,
      'frustration': frustration,
      'performance': performance,
      'enjoyment': enjoyment,
      'discipline': discipline,
      'tiltControl': tiltControl,
      'notes': notes,
    };
  }

  factory PlayLikeAProHistoryEntry.fromMap(Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return PlayLikeAProHistoryEntry(
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      goal: PlayLikeAProGoal.values.firstWhere(
        (value) => value.name == map['goal'],
        orElse: () => PlayLikeAProGoal.blueprintFarm,
      ),
      energy: (map['energy'] as num?)?.toInt() ?? 3,
      focus: (map['focus'] as num?)?.toInt() ?? 3,
      calm: (map['calm'] as num?)?.toInt() ?? 3,
      confidence: (map['confidence'] as num?)?.toInt() ?? 3,
      tiltRisk: (map['tiltRisk'] as num?)?.toInt() ?? 3,
      tiltLevel: (map['tiltLevel'] as num?)?.toInt() ?? 3,
      fatigue: (map['fatigue'] as num?)?.toInt() ?? 3,
      frustration: (map['frustration'] as num?)?.toInt() ?? 3,
      performance: (map['performance'] as num?)?.toInt() ?? 3,
      enjoyment: (map['enjoyment'] as num?)?.toInt() ?? 3,
      discipline: (map['discipline'] as num?)?.toInt() ?? 3,
      tiltControl: (map['tiltControl'] as num?)?.toInt() ?? 3,
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

class PlayLikeAProState {
  const PlayLikeAProState({
    required this.preferredGame,
    required this.preferredSessionMinutes,
    required this.preferredResetStyle,
    required this.musicTrigger,
    required this.preGoal,
    required this.preEnergy,
    required this.preFocus,
    required this.preCalm,
    required this.preConfidence,
    required this.preTiltRisk,
    required this.preNotes,
    required this.preUpdatedAt,
    required this.midTiltLevel,
    required this.midFatigue,
    required this.midFrustration,
    required this.midFocusDrop,
    required this.midNeedsBreak,
    required this.midNotes,
    required this.midUpdatedAt,
    required this.postPerformance,
    required this.postEnjoyment,
    required this.postDiscipline,
    required this.postTiltControl,
    required this.postNotes,
    required this.postUpdatedAt,
    required this.history,
    required this.updatedAt,
  });

  final String preferredGame;
  final int preferredSessionMinutes;
  final PlayLikeAProResetStyle preferredResetStyle;
  final String musicTrigger;

  final PlayLikeAProGoal preGoal;
  final int preEnergy;
  final int preFocus;
  final int preCalm;
  final int preConfidence;
  final int preTiltRisk;
  final String preNotes;
  final DateTime? preUpdatedAt;

  final int midTiltLevel;
  final int midFatigue;
  final int midFrustration;
  final int midFocusDrop;
  final bool midNeedsBreak;
  final String midNotes;
  final DateTime? midUpdatedAt;

  final int postPerformance;
  final int postEnjoyment;
  final int postDiscipline;
  final int postTiltControl;
  final String postNotes;
  final DateTime? postUpdatedAt;

  final List<PlayLikeAProHistoryEntry> history;
  final DateTime? updatedAt;

  static const String docId = 'play_like_a_pro';

  factory PlayLikeAProState.initial() {
    return PlayLikeAProState(
      preferredGame: 'ARC Raiders',
      preferredSessionMinutes: 90,
      preferredResetStyle: PlayLikeAProResetStyle.hydrate,
      musicTrigger: '',
      preGoal: PlayLikeAProGoal.blueprintFarm,
      preEnergy: 3,
      preFocus: 3,
      preCalm: 3,
      preConfidence: 3,
      preTiltRisk: 3,
      preNotes: '',
      preUpdatedAt: null,
      midTiltLevel: 3,
      midFatigue: 3,
      midFrustration: 3,
      midFocusDrop: 3,
      midNeedsBreak: false,
      midNotes: '',
      midUpdatedAt: null,
      postPerformance: 3,
      postEnjoyment: 3,
      postDiscipline: 3,
      postTiltControl: 3,
      postNotes: '',
      postUpdatedAt: null,
      history: const <PlayLikeAProHistoryEntry>[],
      updatedAt: null,
    );
  }

  PlayLikeAProState copyWith({
    String? preferredGame,
    int? preferredSessionMinutes,
    PlayLikeAProResetStyle? preferredResetStyle,
    String? musicTrigger,
    PlayLikeAProGoal? preGoal,
    int? preEnergy,
    int? preFocus,
    int? preCalm,
    int? preConfidence,
    int? preTiltRisk,
    String? preNotes,
    DateTime? preUpdatedAt,
    int? midTiltLevel,
    int? midFatigue,
    int? midFrustration,
    int? midFocusDrop,
    bool? midNeedsBreak,
    String? midNotes,
    DateTime? midUpdatedAt,
    int? postPerformance,
    int? postEnjoyment,
    int? postDiscipline,
    int? postTiltControl,
    String? postNotes,
    DateTime? postUpdatedAt,
    List<PlayLikeAProHistoryEntry>? history,
    DateTime? updatedAt,
  }) {
    return PlayLikeAProState(
      preferredGame: preferredGame ?? this.preferredGame,
      preferredSessionMinutes:
          preferredSessionMinutes ?? this.preferredSessionMinutes,
      preferredResetStyle: preferredResetStyle ?? this.preferredResetStyle,
      musicTrigger: musicTrigger ?? this.musicTrigger,
      preGoal: preGoal ?? this.preGoal,
      preEnergy: preEnergy ?? this.preEnergy,
      preFocus: preFocus ?? this.preFocus,
      preCalm: preCalm ?? this.preCalm,
      preConfidence: preConfidence ?? this.preConfidence,
      preTiltRisk: preTiltRisk ?? this.preTiltRisk,
      preNotes: preNotes ?? this.preNotes,
      preUpdatedAt: preUpdatedAt ?? this.preUpdatedAt,
      midTiltLevel: midTiltLevel ?? this.midTiltLevel,
      midFatigue: midFatigue ?? this.midFatigue,
      midFrustration: midFrustration ?? this.midFrustration,
      midFocusDrop: midFocusDrop ?? this.midFocusDrop,
      midNeedsBreak: midNeedsBreak ?? this.midNeedsBreak,
      midNotes: midNotes ?? this.midNotes,
      midUpdatedAt: midUpdatedAt ?? this.midUpdatedAt,
      postPerformance: postPerformance ?? this.postPerformance,
      postEnjoyment: postEnjoyment ?? this.postEnjoyment,
      postDiscipline: postDiscipline ?? this.postDiscipline,
      postTiltControl: postTiltControl ?? this.postTiltControl,
      postNotes: postNotes ?? this.postNotes,
      postUpdatedAt: postUpdatedAt ?? this.postUpdatedAt,
      history: history ?? this.history,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredGame': preferredGame,
      'preferredSessionMinutes': preferredSessionMinutes,
      'preferredResetStyle': preferredResetStyle.name,
      'musicTrigger': musicTrigger,
      'preGoal': preGoal.name,
      'preEnergy': preEnergy,
      'preFocus': preFocus,
      'preCalm': preCalm,
      'preConfidence': preConfidence,
      'preTiltRisk': preTiltRisk,
      'preNotes': preNotes,
      'preUpdatedAt':
          preUpdatedAt == null ? null : Timestamp.fromDate(preUpdatedAt!),
      'midTiltLevel': midTiltLevel,
      'midFatigue': midFatigue,
      'midFrustration': midFrustration,
      'midFocusDrop': midFocusDrop,
      'midNeedsBreak': midNeedsBreak,
      'midNotes': midNotes,
      'midUpdatedAt':
          midUpdatedAt == null ? null : Timestamp.fromDate(midUpdatedAt!),
      'postPerformance': postPerformance,
      'postEnjoyment': postEnjoyment,
      'postDiscipline': postDiscipline,
      'postTiltControl': postTiltControl,
      'postNotes': postNotes,
      'postUpdatedAt':
          postUpdatedAt == null ? null : Timestamp.fromDate(postUpdatedAt!),
      'history': history.map((entry) => entry.toMap()).toList(growable: false),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory PlayLikeAProState.fromMap(Map<String, dynamic> map) {
    final history = (map['history'] as List?)
            ?.map((entry) => entry is Map<String, dynamic>
                ? PlayLikeAProHistoryEntry.fromMap(entry)
                : entry is Map
                    ? PlayLikeAProHistoryEntry.fromMap(
                        entry.map((key, value) => MapEntry(key.toString(), value)),
                      )
                    : null)
            .whereType<PlayLikeAProHistoryEntry>()
            .toList(growable: false) ??
        const <PlayLikeAProHistoryEntry>[];

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return PlayLikeAProState(
      preferredGame: (map['preferredGame'] as String?) ?? 'ARC Raiders',
      preferredSessionMinutes:
          (map['preferredSessionMinutes'] as num?)?.toInt() ?? 90,
      preferredResetStyle: PlayLikeAProResetStyle.values.firstWhere(
        (value) => value.name == map['preferredResetStyle'],
        orElse: () => PlayLikeAProResetStyle.hydrate,
      ),
      musicTrigger: (map['musicTrigger'] as String?) ?? '',
      preGoal: PlayLikeAProGoal.values.firstWhere(
        (value) => value.name == map['preGoal'],
        orElse: () => PlayLikeAProGoal.blueprintFarm,
      ),
      preEnergy: (map['preEnergy'] as num?)?.toInt() ?? 3,
      preFocus: (map['preFocus'] as num?)?.toInt() ?? 3,
      preCalm: (map['preCalm'] as num?)?.toInt() ?? 3,
      preConfidence: (map['preConfidence'] as num?)?.toInt() ?? 3,
      preTiltRisk: (map['preTiltRisk'] as num?)?.toInt() ?? 3,
      preNotes: (map['preNotes'] as String?) ?? '',
      preUpdatedAt: parseDate(map['preUpdatedAt']),
      midTiltLevel: (map['midTiltLevel'] as num?)?.toInt() ?? 3,
      midFatigue: (map['midFatigue'] as num?)?.toInt() ?? 3,
      midFrustration: (map['midFrustration'] as num?)?.toInt() ?? 3,
      midFocusDrop: (map['midFocusDrop'] as num?)?.toInt() ?? 3,
      midNeedsBreak: (map['midNeedsBreak'] as bool?) ?? false,
      midNotes: (map['midNotes'] as String?) ?? '',
      midUpdatedAt: parseDate(map['midUpdatedAt']),
      postPerformance: (map['postPerformance'] as num?)?.toInt() ?? 3,
      postEnjoyment: (map['postEnjoyment'] as num?)?.toInt() ?? 3,
      postDiscipline: (map['postDiscipline'] as num?)?.toInt() ?? 3,
      postTiltControl: (map['postTiltControl'] as num?)?.toInt() ?? 3,
      postNotes: (map['postNotes'] as String?) ?? '',
      postUpdatedAt: parseDate(map['postUpdatedAt']),
      history: history,
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
