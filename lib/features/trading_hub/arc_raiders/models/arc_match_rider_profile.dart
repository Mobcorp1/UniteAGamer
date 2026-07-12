import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_session_catalog.dart';

class ArcMatchRiderProfile {
  const ArcMatchRiderProfile({
    required this.uid,
    required this.uagId,
    required this.displayName,
    required this.region,
    required this.platform,
    required this.serverPreference,
    required this.crossplayEnabled,
    required this.archetypes,
    required this.playstyles,
    required this.preferredMaps,
    required this.preferredModes,
    required this.goals,
    this.sessionIntent = ArcPlayerSessionCatalog.defaultIntent,
    this.currentPriority = ArcPlayerSessionCatalog.defaultPriority,
    this.blueprintTargets = const <String>[],
    this.helperBlueprintIds = const <String>[],
    this.questFocusIds = const <String>[],
    this.questChainIds = const <String>[],
    this.trialFocusIds = const <String>[],
    this.benchGoalIds = const <String>[],
    this.favouriteLoadoutNeedIds = const <String>[],
    this.raidPlannerTargetIds = const <String>[],
    this.tradePreferences = const <String>[],
    this.availabilityDayKeys = const <String>[],
    this.timezone = '',
    this.giftFriendly = false,
    this.tradeOnly = false,
    this.helperMentor = false,
    this.reputationScore = 0,
    this.completedTrades = 0,
    this.noShows = 0,
    this.betrayalFlags = 0,
    required this.comms,
    required this.squadPreferences,
    required this.lookingNow,
    required this.visibleInSearch,
    required this.notes,
    required this.updatedAt,
  });

  final String uid;
  final String uagId;
  final String displayName;
  final String region;
  final String platform;
  final String serverPreference;
  final bool crossplayEnabled;
  final List<String> archetypes;
  final List<String> playstyles;
  final List<String> preferredMaps;
  final List<String> preferredModes;
  final List<String> goals;
  final String sessionIntent;
  final String currentPriority;
  final List<String> blueprintTargets;
  final List<String> helperBlueprintIds;
  final List<String> questFocusIds;
  final List<String> questChainIds;
  final List<String> trialFocusIds;
  final List<String> benchGoalIds;
  final List<String> favouriteLoadoutNeedIds;
  final List<String> raidPlannerTargetIds;
  final List<String> tradePreferences;
  final List<String> availabilityDayKeys;
  final String timezone;
  final bool giftFriendly;
  final bool tradeOnly;
  final bool helperMentor;
  final int reputationScore;
  final int completedTrades;
  final int noShows;
  final int betrayalFlags;
  final List<String> comms;
  final List<String> squadPreferences;
  final bool lookingNow;
  final bool visibleInSearch;
  final String notes;
  final DateTime? updatedAt;

  String get title => displayName.isNotEmpty
      ? displayName
      : (uagId.isNotEmpty ? uagId : 'Unknown Raider');

  ArcMatchRiderProfile copyWith({
    String? uid,
    String? uagId,
    String? displayName,
    String? region,
    String? platform,
    String? serverPreference,
    bool? crossplayEnabled,
    List<String>? archetypes,
    List<String>? playstyles,
    List<String>? preferredMaps,
    List<String>? preferredModes,
    List<String>? goals,
    String? sessionIntent,
    String? currentPriority,
    List<String>? blueprintTargets,
    List<String>? helperBlueprintIds,
    List<String>? questFocusIds,
    List<String>? questChainIds,
    List<String>? trialFocusIds,
    List<String>? benchGoalIds,
    List<String>? favouriteLoadoutNeedIds,
    List<String>? raidPlannerTargetIds,
    List<String>? tradePreferences,
    List<String>? availabilityDayKeys,
    String? timezone,
    bool? giftFriendly,
    bool? tradeOnly,
    bool? helperMentor,
    int? reputationScore,
    int? completedTrades,
    int? noShows,
    int? betrayalFlags,
    List<String>? comms,
    List<String>? squadPreferences,
    bool? lookingNow,
    bool? visibleInSearch,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ArcMatchRiderProfile(
      uid: uid ?? this.uid,
      uagId: uagId ?? this.uagId,
      displayName: displayName ?? this.displayName,
      region: region ?? this.region,
      platform: platform ?? this.platform,
      serverPreference: serverPreference ?? this.serverPreference,
      crossplayEnabled: crossplayEnabled ?? this.crossplayEnabled,
      archetypes: archetypes ?? this.archetypes,
      playstyles: playstyles ?? this.playstyles,
      preferredMaps: preferredMaps ?? this.preferredMaps,
      preferredModes: preferredModes ?? this.preferredModes,
      goals: goals ?? this.goals,
      sessionIntent: sessionIntent ?? this.sessionIntent,
      currentPriority: currentPriority ?? this.currentPriority,
      blueprintTargets: blueprintTargets ?? this.blueprintTargets,
      helperBlueprintIds: helperBlueprintIds ?? this.helperBlueprintIds,
      questFocusIds: questFocusIds ?? this.questFocusIds,
      questChainIds: questChainIds ?? this.questChainIds,
      trialFocusIds: trialFocusIds ?? this.trialFocusIds,
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
      reputationScore: reputationScore ?? this.reputationScore,
      completedTrades: completedTrades ?? this.completedTrades,
      noShows: noShows ?? this.noShows,
      betrayalFlags: betrayalFlags ?? this.betrayalFlags,
      comms: comms ?? this.comms,
      squadPreferences: squadPreferences ?? this.squadPreferences,
      lookingNow: lookingNow ?? this.lookingNow,
      visibleInSearch: visibleInSearch ?? this.visibleInSearch,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'uagId': uagId,
      'displayName': displayName,
      'region': region,
      'platform': platform,
      'serverPreference': serverPreference,
      'crossplayEnabled': crossplayEnabled,
      'archetypes': ArcPlayerArchetypeCatalog.normalizeLabels(archetypes),
      'playstyles': playstyles,
      'preferredMaps': preferredMaps,
      'preferredModes': preferredModes,
      'goals': goals,
      'sessionIntent': ArcPlayerSessionCatalog.normalizeIntent(sessionIntent),
      'currentPriority': ArcPlayerSessionCatalog.normalizePriority(
        currentPriority,
      ),
      'blueprintTargets': blueprintTargets,
      'helperBlueprintIds': helperBlueprintIds,
      'questFocusIds': questFocusIds,
      'questChainIds': questChainIds,
      'trialFocusIds': trialFocusIds,
      'benchGoalIds': benchGoalIds,
      'favouriteLoadoutNeedIds': favouriteLoadoutNeedIds,
      'raidPlannerTargetIds': raidPlannerTargetIds,
      'tradePreferences': tradePreferences,
      'availabilityDayKeys': availabilityDayKeys,
      'timezone': timezone,
      'giftFriendly': giftFriendly,
      'tradeOnly': tradeOnly,
      'helperMentor': helperMentor,
      'reputationScore': reputationScore,
      'completedTrades': completedTrades,
      'noShows': noShows,
      'betrayalFlags': betrayalFlags,
      'comms': comms,
      'squadPreferences': squadPreferences,
      'lookingNow': lookingNow,
      'visibleInSearch': visibleInSearch,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ArcMatchRiderProfile.empty(String uid) {
    return ArcMatchRiderProfile(
      uid: uid,
      uagId: '',
      displayName: '',
      region: '',
      platform: '',
      serverPreference: 'Automatic',
      crossplayEnabled: true,
      archetypes: const [],
      playstyles: const [],
      preferredMaps: const [],
      preferredModes: const [],
      goals: const [],
      sessionIntent: ArcPlayerSessionCatalog.defaultIntent,
      currentPriority: ArcPlayerSessionCatalog.defaultPriority,
      blueprintTargets: const [],
      helperBlueprintIds: const [],
      questFocusIds: const [],
      questChainIds: const [],
      trialFocusIds: const [],
      benchGoalIds: const [],
      favouriteLoadoutNeedIds: const [],
      raidPlannerTargetIds: const [],
      tradePreferences: const [],
      availabilityDayKeys: const [],
      timezone: '',
      giftFriendly: false,
      tradeOnly: false,
      helperMentor: false,
      reputationScore: 0,
      completedTrades: 0,
      noShows: 0,
      betrayalFlags: 0,
      comms: const [],
      squadPreferences: const [],
      lookingNow: true,
      visibleInSearch: true,
      notes: '',
      updatedAt: null,
    );
  }

  factory ArcMatchRiderProfile.fromMap(
    Map<String, dynamic> map,
    String fallbackUid,
  ) {
    DateTime? updatedAt;
    final rawUpdatedAt = map['updatedAt'];
    if (rawUpdatedAt is Timestamp) updatedAt = rawUpdatedAt.toDate();

    List<String> readList(String key) {
      final raw = map[key];
      if (raw is Iterable) {
        return raw
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return const [];
    }

    int readInt(String key) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ArcMatchRiderProfile(
      uid: (map['uid'] as String?)?.trim().isNotEmpty == true
          ? (map['uid'] as String).trim()
          : fallbackUid,
      uagId: (map['uagId'] as String? ?? '').trim(),
      displayName: (map['displayName'] as String? ?? '').trim(),
      region: (map['region'] as String? ?? '').trim(),
      platform: (map['platform'] as String? ?? '').trim(),
      serverPreference: (map['serverPreference'] as String? ?? 'Automatic')
          .trim(),
      crossplayEnabled: map['crossplayEnabled'] != false,
      archetypes: ArcPlayerArchetypeCatalog.normalizeLabels(
        readList('archetypes'),
      ),
      playstyles: readList('playstyles'),
      preferredMaps: readList('preferredMaps'),
      preferredModes: readList('preferredModes'),
      goals: readList('goals'),
      sessionIntent: ArcPlayerSessionCatalog.normalizeIntent(
        map['sessionIntent'] as String?,
      ),
      currentPriority: ArcPlayerSessionCatalog.normalizePriority(
        map['currentPriority'] as String?,
      ),
      blueprintTargets: readList('blueprintTargets'),
      helperBlueprintIds: readList('helperBlueprintIds'),
      questFocusIds: readList('questFocusIds'),
      questChainIds: readList('questChainIds'),
      trialFocusIds: readList('trialFocusIds'),
      benchGoalIds: readList('benchGoalIds'),
      favouriteLoadoutNeedIds: readList('favouriteLoadoutNeedIds'),
      raidPlannerTargetIds: readList('raidPlannerTargetIds'),
      tradePreferences: readList('tradePreferences'),
      availabilityDayKeys: readList('availabilityDayKeys'),
      timezone: (map['timezone'] as String? ?? '').trim(),
      giftFriendly: map['giftFriendly'] == true,
      tradeOnly: map['tradeOnly'] == true,
      helperMentor: map['helperMentor'] == true,
      reputationScore: readInt('reputationScore'),
      completedTrades: readInt('completedTrades'),
      noShows: readInt('noShows'),
      betrayalFlags: readInt('betrayalFlags'),
      comms: readList('comms'),
      squadPreferences: readList('squadPreferences'),
      lookingNow: map['lookingNow'] == true,
      visibleInSearch: map['visibleInSearch'] != false,
      notes: (map['notes'] as String? ?? '').trim(),
      updatedAt: updatedAt,
    );
  }
}
