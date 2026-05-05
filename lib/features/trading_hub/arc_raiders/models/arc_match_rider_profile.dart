import 'package:cloud_firestore/cloud_firestore.dart';

class ArcMatchRiderProfile {
  const ArcMatchRiderProfile({
    required this.uid,
    required this.uagId,
    required this.displayName,
    required this.region,
    required this.platform,
    required this.serverPreference,
    required this.crossplayEnabled,
    required this.playstyles,
    required this.preferredMaps,
    required this.preferredModes,
    required this.goals,
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
  final List<String> playstyles;
  final List<String> preferredMaps;
  final List<String> preferredModes;
  final List<String> goals;
  final List<String> comms;
  final List<String> squadPreferences;
  final bool lookingNow;
  final bool visibleInSearch;
  final String notes;
  final DateTime? updatedAt;

  String get title => displayName.isNotEmpty ? displayName : (uagId.isNotEmpty ? uagId : 'Unknown Raider');

  ArcMatchRiderProfile copyWith({
    String? uid,
    String? uagId,
    String? displayName,
    String? region,
    String? platform,
    String? serverPreference,
    bool? crossplayEnabled,
    List<String>? playstyles,
    List<String>? preferredMaps,
    List<String>? preferredModes,
    List<String>? goals,
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
      playstyles: playstyles ?? this.playstyles,
      preferredMaps: preferredMaps ?? this.preferredMaps,
      preferredModes: preferredModes ?? this.preferredModes,
      goals: goals ?? this.goals,
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
      'playstyles': playstyles,
      'preferredMaps': preferredMaps,
      'preferredModes': preferredModes,
      'goals': goals,
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
      playstyles: const [],
      preferredMaps: const [],
      preferredModes: const [],
      goals: const [],
      comms: const [],
      squadPreferences: const [],
      lookingNow: true,
      visibleInSearch: true,
      notes: '',
      updatedAt: null,
    );
  }

  factory ArcMatchRiderProfile.fromMap(Map<String, dynamic> map, String fallbackUid) {
    DateTime? updatedAt;
    final rawUpdatedAt = map['updatedAt'];
    if (rawUpdatedAt is Timestamp) updatedAt = rawUpdatedAt.toDate();

    List<String> readList(String key) {
      final raw = map[key];
      if (raw is Iterable) {
        return raw.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
      }
      return const [];
    }

    return ArcMatchRiderProfile(
      uid: (map['uid'] as String?)?.trim().isNotEmpty == true ? (map['uid'] as String).trim() : fallbackUid,
      uagId: (map['uagId'] as String? ?? '').trim(),
      displayName: (map['displayName'] as String? ?? '').trim(),
      region: (map['region'] as String? ?? '').trim(),
      platform: (map['platform'] as String? ?? '').trim(),
      serverPreference: (map['serverPreference'] as String? ?? 'Automatic').trim(),
      crossplayEnabled: map['crossplayEnabled'] != false,
      playstyles: readList('playstyles'),
      preferredMaps: readList('preferredMaps'),
      preferredModes: readList('preferredModes'),
      goals: readList('goals'),
      comms: readList('comms'),
      squadPreferences: readList('squadPreferences'),
      lookingNow: map['lookingNow'] == true,
      visibleInSearch: map['visibleInSearch'] != false,
      notes: (map['notes'] as String? ?? '').trim(),
      updatedAt: updatedAt,
    );
  }
}
