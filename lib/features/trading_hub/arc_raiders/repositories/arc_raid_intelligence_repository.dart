import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcRaidIntelligenceRepository {
  ArcRaidIntelligenceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _routes(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('arc_raid_routes');
  }

  Future<ArcRaidRoutePlan?> loadActiveRoute() async {
    final uid = _uid;
    if (uid == null) return null;
    final snapshot = await _routes(uid).doc('active').get();
    final data = snapshot.data();
    if (data == null || data['routeState'] == 'archived') return null;
    return _routeFromMap(data);
  }

  Future<void> saveActiveRoute(ArcRaidRoutePlan route) async {
    final uid = _uid;
    if (uid == null) return;
    await _routes(uid).doc('active').set({
      ..._routeToMap(route),
      'routeState': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveRoute(ArcRaidRoutePlan route) async {
    final uid = _uid;
    if (uid == null) return;
    await _routes(uid).doc(route.id).set({
      ..._routeToMap(route),
      'routeState': 'saved',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> archiveActiveRoute() async {
    final uid = _uid;
    if (uid == null) return;
    await _routes(uid).doc('active').set({
      'routeState': 'archived',
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _routeToMap(ArcRaidRoutePlan route) {
    return {
      'id': route.id,
      'mapId': route.mapId,
      'mapName': route.mapName,
      'squadMode': route.squadMode.name,
      'routeStyle': route.routeStyle.name,
      'raidStage': route.raidStage,
      'objectivePriority': route.objectivePriority.name,
      'usesRaiderHatch': route.usesRaiderHatch,
      'hatchKeyConfirmed': route.hatchKeyConfirmed,
      'score': route.score,
      'summary': route.summary,
      'approximate': route.approximate,
      'spawn': _stopToMap(route.spawn),
      'extraction': _stopToMap(route.extraction),
      'stops': route.stops.map(_stopToMap).toList(growable: false),
      'participants': route.participants
          .map(
            (participant) => {
              'uid': participant.uid,
              'displayName': participant.displayName,
              'objectiveSharing': participant.objectiveSharing.name,
            },
          )
          .toList(growable: false),
      'createdAt': route.createdAt == null
          ? null
          : Timestamp.fromDate(route.createdAt!),
      'clientUpdatedAt': route.updatedAt == null
          ? null
          : Timestamp.fromDate(route.updatedAt!),
    };
  }

  Map<String, dynamic> _stopToMap(ArcRaidRouteStop stop) {
    return {
      'id': stop.id,
      'label': stop.label,
      'order': stop.order,
      'clusterId': stop.clusterId,
      'markerId': stop.markerId,
      'blueprintIds': stop.blueprintIds,
      'state': stop.state.name,
      'reason': stop.reason,
      'point': stop.point.toMap(),
    };
  }

  ArcRaidRoutePlan _routeFromMap(Map<String, dynamic> map) {
    final stopsData = (map['stops'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => _stopFromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final participantsData =
        (map['participants'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
    return ArcRaidRoutePlan(
      id: _string(map['id'], 'active'),
      mapId: _string(map['mapId'], 'blue_gate'),
      mapName: _string(map['mapName'], 'The Blue Gate'),
      squadMode: _squadMode(map['squadMode']),
      routeStyle: _routeStyle(map['routeStyle']),
      raidStage: _string(map['raidStage'], 'Full'),
      objectivePriority: _objectivePriority(map['objectivePriority']),
      spawn: _stopFromMap(
        Map<String, dynamic>.from(map['spawn'] as Map? ?? const {}),
      ),
      extraction: _stopFromMap(
        Map<String, dynamic>.from(map['extraction'] as Map? ?? const {}),
      ),
      stops: stopsData,
      usesRaiderHatch: map['usesRaiderHatch'] == true,
      hatchKeyConfirmed: map['hatchKeyConfirmed'] == true,
      participants: participantsData
          .map(_participantFromMap)
          .toList(growable: false),
      score: (map['score'] as num?)?.round() ?? 0,
      summary: _string(map['summary'], ''),
      approximate: map['approximate'] != false,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['clientUpdatedAt']) ?? _date(map['updatedAt']),
    );
  }

  ArcRaidRouteStop _stopFromMap(Map<String, dynamic> map) {
    return ArcRaidRouteStop(
      id: _string(map['id'], 'route_stop'),
      label: _string(map['label'], 'Route Stop'),
      point: ArcNormalizedPoint.fromMap(
        Map<String, dynamic>.from(map['point'] as Map? ?? const {}),
      ),
      order: (map['order'] as num?)?.round() ?? 0,
      clusterId: _nullableString(map['clusterId']),
      markerId: _nullableString(map['markerId']),
      blueprintIds: (map['blueprintIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      state: _routeStopState(map['state']),
      reason: _string(map['reason'], ''),
    );
  }

  ArcRaidRouteParticipant _participantFromMap(Map<String, dynamic> map) {
    return ArcRaidRouteParticipant(
      uid: _string(map['uid'], ''),
      displayName: _string(map['displayName'], 'Squadmate'),
      objectiveSharing: _objectiveSharing(map['objectiveSharing']),
    );
  }

  static String _string(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static ArcRaidSquadMode _squadMode(Object? value) {
    return ArcRaidSquadMode.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => ArcRaidSquadMode.solo,
    );
  }

  static ArcRaidRouteStyle _routeStyle(Object? value) {
    return ArcRaidRouteStyle.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => ArcRaidRouteStyle.balanced,
    );
  }

  static ArcRaidObjectivePriority _objectivePriority(Object? value) {
    return ArcRaidObjectivePriority.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => ArcRaidObjectivePriority.myNeedsFirst,
    );
  }

  static ArcRaidRouteStopState _routeStopState(Object? value) {
    return ArcRaidRouteStopState.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => ArcRaidRouteStopState.planned,
    );
  }

  static ArcRaidObjectiveSharing _objectiveSharing(Object? value) {
    return ArcRaidObjectiveSharing.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => ArcRaidObjectiveSharing.keepPrivate,
    );
  }
}
