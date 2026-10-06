import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_squad_raid_models.dart';

class ArcSquadRaidRepository {
  ArcSquadRaidRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('arc_squad_raid_sessions');

  Future<ArcSquadRaidSession> createSession({
    required String leaderLabel,
    required Map<String, String> peerLabels,
    ArcSquadRaidFairnessMode fairnessMode =
        ArcSquadRaidFairnessMode.balancedSquad,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('You must be signed in.');

    final peers = peerLabels.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.key != uid)
        .take(2)
        .toList(growable: false);
    if (peers.isEmpty) {
      throw StateError('Select at least one accepted Raider.');
    }

    final ref = _sessions.doc();
    final members = <String>[uid, ...peers.map((entry) => entry.key)];
    final labels = <String, String>{
      uid: leaderLabel.trim().isEmpty ? 'Squad Leader' : leaderLabel.trim(),
      for (final peer in peers)
        peer.key: peer.value.trim().isEmpty
            ? 'Squad Raider'
            : peer.value.trim(),
    };

    await ref.set(<String, dynamic>{
      'id': ref.id,
      'leaderUid': uid,
      'leaderLabel': labels[uid],
      'memberUids': members,
      'memberLabels': labels,
      'fairnessMode': fairnessMode.name,
      'status': 'active',
      'route': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ArcSquadRaidSession(
      id: ref.id,
      leaderUid: uid,
      leaderLabel: labels[uid]!,
      memberUids: members,
      memberLabels: labels,
      fairnessMode: fairnessMode,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Stream<List<ArcSquadRaidSession>> watchMySessions() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <ArcSquadRaidSession>[]);
    }

    return _sessions.where('memberUids', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final sessions =
          snapshot.docs
              .map(
                (doc) => ArcSquadRaidSession.fromMap(
                  doc.id,
                  doc.data(),
                  routePlan: _routeFromMap(doc.data()['route']),
                ),
              )
              .where((session) => session.active)
              .toList(growable: false)
            ..sort(
              (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  ),
            );
      return sessions;
    });
  }

  Stream<ArcSquadRaidBundle?> watchBundle(String sessionId) {
    if (sessionId.trim().isEmpty) {
      return Stream.value(null);
    }

    late StreamController<ArcSquadRaidBundle?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sessionSub;
    final projectionSubs =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final projections = <String, ArcSquadRaidProjection>{};
    ArcSquadRaidSession? latestSession;
    var disposed = false;

    void emit() {
      if (disposed || controller.isClosed) return;
      final session = latestSession;
      if (session == null) {
        controller.add(null);
        return;
      }
      controller.add(
        ArcSquadRaidBundle(
          session: session,
          projections: Map<String, ArcSquadRaidProjection>.unmodifiable(
            projections,
          ),
        ),
      );
    }

    Future<void> resetProjectionSubscriptions(List<String> memberUids) async {
      for (final subscription in projectionSubs.values) {
        await subscription.cancel();
      }
      projectionSubs.clear();
      projections.clear();

      for (final uid in memberUids) {
        final sub = _sessions
            .doc(sessionId)
            .collection('projections')
            .doc(uid)
            .snapshots()
            .listen((snapshot) {
              final data = snapshot.data();
              if (data == null) {
                projections.remove(uid);
              } else {
                projections[uid] = ArcSquadRaidProjection.fromMap(uid, data);
              }
              emit();
            }, onError: controller.addError);
        projectionSubs[uid] = sub;
      }
      emit();
    }

    controller = StreamController<ArcSquadRaidBundle?>(
      onListen: () {
        sessionSub = _sessions.doc(sessionId).snapshots().listen((snapshot) {
          final data = snapshot.data();
          if (data == null) {
            latestSession = null;
            emit();
            return;
          }

          final next = ArcSquadRaidSession.fromMap(
            snapshot.id,
            data,
            routePlan: _routeFromMap(data['route']),
          );
          final previousMembers = latestSession?.memberUids.join('|');
          latestSession = next;
          if (previousMembers != next.memberUids.join('|')) {
            unawaited(resetProjectionSubscriptions(next.memberUids));
          } else {
            emit();
          }
        }, onError: controller.addError);
      },
      onCancel: () async {
        disposed = true;
        await sessionSub?.cancel();
        for (final subscription in projectionSubs.values) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  Future<void> saveMyProjection({
    required String sessionId,
    required ArcSquadRaidProjection projection,
  }) async {
    final uid = currentUid;
    if (uid == null || uid != projection.ownerUid) {
      throw StateError('You can only publish your own squad objectives.');
    }
    await _sessions
        .doc(sessionId)
        .collection('projections')
        .doc(uid)
        .set(<String, dynamic>{
          'ownerUid': uid,
          'ownerLabel': projection.ownerLabel,
          'tier': projection.tier.name,
          'objectiveLimit': projection.objectiveLimit,
          'sharingMode': projection.sharing.name,
          'objectives': projection.objectives
              .map((objective) => objective.toMap())
              .toList(growable: false),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> saveSharedRoute({
    required ArcSquadRaidSession session,
    required ArcRaidRoutePlan route,
  }) async {
    final uid = currentUid;
    if (uid == null || !session.isLeader(uid)) {
      throw StateError('Only the squad leader can publish the shared route.');
    }
    await _sessions.doc(session.id).update(<String, dynamic>{
      'route': _routeToSharedMap(route),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeSession(ArcSquadRaidSession session) async {
    final uid = currentUid;
    if (uid == null || !session.isLeader(uid)) {
      throw StateError('Only the squad leader can close the squad plan.');
    }
    await _sessions.doc(session.id).update(<String, dynamic>{
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _routeToSharedMap(ArcRaidRoutePlan route) {
    Map<String, dynamic> stop(ArcRaidRouteStop value) {
      final isEndpoint =
          value.id == route.spawn.id || value.id == route.extraction.id;
      return <String, dynamic>{
        'id': value.id,
        'label': value.label,
        'order': value.order,
        'point': value.point.toMap(),
        'state': value.state.name,
        'reason': isEndpoint
            ? (value.id == route.spawn.id
                  ? 'Shared squad spawn.'
                  : 'Shared squad extraction.')
            : '${value.objectiveIds.length} squad objectives align at this stop.',
      };
    }

    return <String, dynamic>{
      'id': route.id,
      'mapId': route.mapId,
      'mapName': route.mapName,
      'squadMode': route.squadMode.name,
      'routeStyle': route.routeStyle.name,
      'raidStage': route.raidStage,
      'objectivePriority': route.objectivePriority.name,
      'timeBudgetMinutes': route.timeBudgetMinutes,
      'conditionLabel': route.conditionLabel,
      'usesRaiderHatch': route.usesRaiderHatch,
      'hatchKeyConfirmed': route.hatchKeyConfirmed,
      'score': route.score,
      'summary':
          'Shared squad route: ${route.stops.length} stops, about ${route.metrics.estimatedMinutes} min, then extraction.',
      'approximate': route.approximate,
      'spawn': stop(route.spawn),
      'extraction': stop(route.extraction),
      'stops': route.stops.map(stop).toList(growable: false),
      'metrics': <String, dynamic>{
        'totalDistance': route.metrics.totalDistance,
        'estimatedMinutes': route.metrics.estimatedMinutes,
        'opportunityCount': route.metrics.opportunityCount,
        'blueprintTargetCount': route.metrics.blueprintTargetCount,
        'objectiveTargetCount': route.metrics.objectiveTargetCount,
        'averageConfidence': route.metrics.averageConfidence,
        'efficiencyScore': route.metrics.efficiencyScore,
        'riskLabel': route.metrics.riskLabel,
      },
      'createdAt': route.createdAt == null
          ? null
          : Timestamp.fromDate(route.createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ArcRaidRoutePlan? _routeFromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    ArcRaidRouteStop readStop(dynamic value) {
      final data = value is Map
          ? Map<String, dynamic>.from(value)
          : const <String, dynamic>{};
      return ArcRaidRouteStop(
        id: data['id']?.toString().trim() ?? 'shared_stop',
        label: data['label']?.toString().trim() ?? 'Shared stop',
        point: ArcNormalizedPoint.fromMap(
          data['point'] is Map
              ? Map<String, dynamic>.from(data['point'] as Map)
              : const <String, dynamic>{},
        ),
        order: (data['order'] as num?)?.toInt() ?? 0,
        reason: data['reason']?.toString().trim() ?? 'Shared squad stop.',
        state: ArcRaidRouteStopState.values.firstWhere(
          (item) => item.name == data['state'],
          orElse: () => ArcRaidRouteStopState.planned,
        ),
      );
    }

    final stops = (map['stops'] as Iterable? ?? const <dynamic>[])
        .map(readStop)
        .toList(growable: false);
    final metricsRaw = map['metrics'] is Map
        ? Map<String, dynamic>.from(map['metrics'] as Map)
        : const <String, dynamic>{};

    return ArcRaidRoutePlan(
      id: map['id']?.toString().trim() ?? 'shared',
      mapId: map['mapId']?.toString().trim() ?? 'blue_gate',
      mapName: map['mapName']?.toString().trim() ?? 'The Blue Gate',
      squadMode: ArcRaidSquadMode.values.firstWhere(
        (item) => item.name == map['squadMode'],
        orElse: () => ArcRaidSquadMode.duo,
      ),
      routeStyle: ArcRaidRouteStyle.values.firstWhere(
        (item) => item.name == map['routeStyle'],
        orElse: () => ArcRaidRouteStyle.balanced,
      ),
      raidStage: map['raidStage']?.toString().trim() ?? 'Full',
      objectivePriority: ArcRaidObjectivePriority.values.firstWhere(
        (item) => item.name == map['objectivePriority'],
        orElse: () => ArcRaidObjectivePriority.balancedSquad,
      ),
      timeBudgetMinutes: (map['timeBudgetMinutes'] as num?)?.toInt(),
      conditionLabel: map['conditionLabel']?.toString().trim(),
      spawn: readStop(map['spawn']),
      extraction: readStop(map['extraction']),
      stops: stops,
      usesRaiderHatch: map['usesRaiderHatch'] == true,
      hatchKeyConfirmed: map['hatchKeyConfirmed'] == true,
      metrics: ArcRaidRouteMetrics(
        totalDistance: (metricsRaw['totalDistance'] as num?)?.toDouble() ?? 0,
        estimatedMinutes:
            (metricsRaw['estimatedMinutes'] as num?)?.toInt() ?? 0,
        opportunityCount:
            (metricsRaw['opportunityCount'] as num?)?.toInt() ?? 0,
        blueprintTargetCount:
            (metricsRaw['blueprintTargetCount'] as num?)?.toInt() ?? 0,
        objectiveTargetCount:
            (metricsRaw['objectiveTargetCount'] as num?)?.toInt() ?? 0,
        averageConfidence:
            (metricsRaw['averageConfidence'] as num?)?.toInt() ?? 0,
        efficiencyScore: (metricsRaw['efficiencyScore'] as num?)?.toInt() ?? 0,
        riskLabel: metricsRaw['riskLabel']?.toString().trim() ?? 'Shared route',
      ),
      score: (map['score'] as num?)?.toInt() ?? 0,
      summary: map['summary']?.toString().trim() ?? 'Shared squad route.',
      approximate: map['approximate'] != false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
