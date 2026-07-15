import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/arc_match_compatibility_engine.dart';
import '../data/arc_player_archetype_catalog.dart';
import '../data/arc_player_session_catalog.dart';
import '../models/arc_favourite_rider.dart';
import '../models/arc_match_objective_signals.dart';
import '../models/arc_match_rider_invite.dart';
import '../models/arc_match_rider_profile.dart';
import 'arc_operations_repository.dart';

class ArcMatchCandidate {
  const ArcMatchCandidate({
    required this.profile,
    required this.score,
    required this.reasons,
  });

  final ArcMatchRiderProfile profile;
  final int score;
  final List<String> reasons;

  String get percentageLabel => '$score% Match';
  String get publicMatchLabel => ArcMatchCompatibilityEngine.matchLabel(score);
  String get publicExplanation =>
      ArcMatchCompatibilityEngine.protectedExplanation;
}

class ArcMatchRiderRepository {
  ArcMatchRiderRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ArcMatchCompatibilityEngine _compatibilityEngine =
      const ArcMatchCompatibilityEngine();

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('arc_match_rider_profiles');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('arc_match_rider_invites');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('trading_notifications');
  CollectionReference<Map<String, dynamic>> get _favouriteRiders =>
      _firestore.collection('arc_favourite_riders');

  DocumentReference<Map<String, dynamic>> _userProfileDoc(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('trading_activity')
          .doc('profile');

  Future<ArcMatchRiderProfile> loadMyProfile() async {
    final uid = currentUid;
    if (uid == null) throw StateError('No signed-in user found.');

    final publicSnap = await _profiles.doc(uid).get();
    if (publicSnap.exists) {
      return ArcMatchRiderProfile.fromMap(publicSnap.data() ?? const {}, uid);
    }

    final userSnap = await _userProfileDoc(uid).get();
    final userData = userSnap.data() ?? const <String, dynamic>{};
    final fallbackName =
        (userData['uagName'] as String? ??
                userData['displayName'] as String? ??
                '')
            .trim();
    final fallbackUag =
        (userData['uagId'] as String? ?? userData['gamerTag'] as String? ?? '')
            .trim();
    final fallbackRegion = (userData['region'] as String? ?? '').trim();
    final fallbackPlatform = (userData['platform'] as String? ?? '').trim();
    final fallbackServerPreference =
        (userData['serverPreference'] as String? ?? 'Automatic').trim();
    final fallbackCrossplay = userData['crossplayEnabled'] is bool
        ? userData['crossplayEnabled'] as bool
        : userData['crossPlatformOk'] != false;
    final fallbackArchetypes = ArcPlayerArchetypeCatalog.normalizeLabels(
      _readStringList(userData['archetypes']),
    );
    final fallbackPlaystyles = _readStringList(
      userData['playStyles'],
      _readStringList(userData['playStyle']),
    );
    final fallbackComms = _communicationToMatchComms(
      (userData['communicationStyle'] as String? ?? '').trim(),
    );
    final fallbackSquad = (userData['squadIntent'] as String? ?? '').trim();
    final fallbackSessionIntent = ArcPlayerSessionCatalog.normalizeIntent(
      userData['sessionIntent'] as String? ?? fallbackSquad,
    );
    final fallbackCurrentPriority = ArcPlayerSessionCatalog.normalizePriority(
      userData['currentPriority'] as String?,
    );
    final fallbackTradePreferences = _readStringList(
      userData['tradePreferences'],
    );

    return ArcMatchRiderProfile.empty(uid).copyWith(
      displayName: fallbackName,
      uagId: fallbackUag,
      region: fallbackRegion,
      platform: fallbackPlatform,
      serverPreference: fallbackServerPreference.isEmpty
          ? 'Automatic'
          : fallbackServerPreference,
      crossplayEnabled: fallbackCrossplay,
      archetypes: fallbackArchetypes,
      playstyles: fallbackPlaystyles,
      comms: fallbackComms,
      squadPreferences: fallbackSquad.isEmpty
          ? const <String>[]
          : <String>[fallbackSquad],
      sessionIntent: fallbackSessionIntent,
      currentPriority: fallbackCurrentPriority,
      blueprintTargets: _readStringList(userData['blueprintTargets']),
      helperBlueprintIds: _readStringList(userData['helperBlueprintIds']),
      questFocusIds: _readStringList(userData['questFocusIds']),
      questChainIds: _readStringList(userData['questChainIds']),
      trialFocusIds: _readStringList(userData['trialFocusIds']),
      benchGoalIds: _readStringList(userData['benchGoalIds']),
      favouriteLoadoutNeedIds: _readStringList(
        userData['favouriteLoadoutNeedIds'],
      ),
      raidPlannerTargetIds: _readStringList(userData['raidPlannerTargetIds']),
      tradePreferences: fallbackTradePreferences,
      availabilityDayKeys: _readStringList(userData['availabilityDayKeys']),
      timezone: (userData['timezone'] as String? ?? '').trim(),
      giftFriendly: userData['giftFriendly'] == true,
      tradeOnly: userData['tradeOnly'] == true,
      helperMentor: userData['helperMentor'] == true,
      reputationScore: _readInt(userData['reputationScore']),
      completedTrades: _readInt(userData['completedTrades']),
      noShows: _readInt(userData['noShows']),
      betrayalFlags: _readInt(userData['betrayalFlags']),
    );
  }

  Future<void> saveMyProfile(ArcMatchRiderProfile profile) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No signed-in user found.');

    final normalized = profile.copyWith(uid: uid);
    await _profiles.doc(uid).set(normalized.toMap(), SetOptions(merge: true));
  }

  Stream<List<ArcMatchCandidate>> watchCandidates(
    ArcMatchRiderProfile currentProfile,
  ) {
    final uid = currentUid;
    if (uid == null) return const Stream<List<ArcMatchCandidate>>.empty();

    return _profiles.where('visibleInSearch', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final matches = <ArcMatchCandidate>[];
      final currentSignals = _objectiveSignalsFromProfile(currentProfile);
      for (final doc in snapshot.docs) {
        if (doc.id == uid) continue;
        final profile = ArcMatchRiderProfile.fromMap(doc.data(), doc.id);
        final result = _compatibilityEngine.score(
          me: currentProfile,
          other: profile,
          meSignals: currentSignals,
          otherSignals: _objectiveSignalsFromProfile(profile),
        );
        matches.add(
          ArcMatchCandidate(
            profile: profile,
            score: result.score,
            reasons: result.reasons,
          ),
        );
      }

      matches.sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        if (a.profile.lookingNow != b.profile.lookingNow) {
          return a.profile.lookingNow ? -1 : 1;
        }
        return a.profile.title.toLowerCase().compareTo(
          b.profile.title.toLowerCase(),
        );
      });
      return matches;
    });
  }

  Stream<Set<String>> watchFavouriteRiderIds() {
    final uid = currentUid;
    if (uid == null) return Stream.value(<String>{});
    return _favouriteRiders
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcFavouriteRider.fromMap(doc.data()).riderUid)
              .where((riderUid) => riderUid.trim().isNotEmpty)
              .toSet(),
        );
  }

  Future<void> setFavouriteRider({
    required String riderUid,
    required bool favourite,
    String privateNote = '',
    List<String> tags = const <String>[],
    ArcFavouriteNotificationPreference notificationPreference =
        ArcFavouriteNotificationPreference.duringAvailabilityOnly,
  }) async {
    final uid = currentUid;
    final normalizedRiderUid = riderUid.trim();
    if (uid == null ||
        normalizedRiderUid.isEmpty ||
        uid == normalizedRiderUid) {
      return;
    }

    final docId = ArcFavouriteRider.idFor(uid, normalizedRiderUid);
    final ref = _favouriteRiders.doc(docId);
    if (!favourite) {
      await ref.delete();
      return;
    }

    final now = DateTime.now();
    final existing = await ref.get();
    final previous = existing.exists
        ? ArcFavouriteRider.fromMap(existing.data() ?? const {})
        : null;
    final model = ArcFavouriteRider(
      id: docId,
      ownerUid: uid,
      riderUid: normalizedRiderUid,
      privateNote: privateNote.trim().isEmpty
          ? previous?.privateNote ?? ''
          : privateNote.trim(),
      tags: tags.isEmpty ? previous?.tags ?? const <String>[] : tags,
      notificationPreference: notificationPreference,
      completedTrades: previous?.completedTrades ?? 0,
      squadSessions: previous?.squadSessions ?? 0,
      previousBlueprintOffer: previous?.previousBlueprintOffer ?? false,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.set(model.toMap(), SetOptions(merge: true));
  }

  Stream<List<ArcMatchRiderInvite>> watchIncomingInvites() {
    final uid = currentUid;
    if (uid == null) return const Stream<List<ArcMatchRiderInvite>>.empty();
    return _invites
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcMatchRiderInvite.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Stream<List<ArcMatchRiderInvite>> watchOutgoingInvites() {
    final uid = currentUid;
    if (uid == null) return const Stream<List<ArcMatchRiderInvite>>.empty();
    return _invites
        .where('senderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcMatchRiderInvite.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> sendInvite({
    required ArcMatchRiderProfile sender,
    required ArcMatchRiderProfile recipient,
    required String note,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No signed-in user found.');
    if (uid == recipient.uid) throw StateError('You cannot invite yourself.');

    final inviteRef = _invites.doc('${uid}_${recipient.uid}');
    final existingInvite = await inviteRef.get();
    if (existingInvite.exists) {
      final existingStatus = (existingInvite.data()?['status'] as String? ?? '')
          .trim();
      if (existingStatus == 'pending') {
        throw StateError('You already have a pending invite with this raider.');
      }
    }

    final notificationRef = _notifications.doc();
    final batch = _firestore.batch();

    batch.set(inviteRef, {
      'id': inviteRef.id,
      'senderUid': uid,
      'senderName': sender.title,
      'recipientUid': recipient.uid,
      'recipientName': recipient.title,
      'status': 'pending',
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(notificationRef, {
      'id': notificationRef.id,
      'targetUid': recipient.uid,
      'actorUid': uid,
      'title': 'New Match-a-Raider request',
      'body': '${sender.title} wants to squad up for ARC Raiders.',
      'type': 'match_invite',
      'listingId': null,
      'offerId': null,
      'sessionId': null,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> respondToInvite(
    ArcMatchRiderInvite invite,
    String newStatus,
  ) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No signed-in user found.');
    if (!['accepted', 'declined', 'cancelled'].contains(newStatus)) {
      throw StateError('Unsupported invite status.');
    }

    await _invites.doc(invite.id).set({
      'id': invite.id,
      'senderUid': invite.senderUid,
      'senderName': invite.senderName,
      'recipientUid': invite.recipientUid,
      'recipientName': invite.recipientName,
      'status': newStatus,
      'note': invite.note,
      'createdAt': invite.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(invite.createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));

    final targetUid = newStatus == 'cancelled'
        ? invite.recipientUid
        : invite.senderUid;
    final actorUid = uid;
    final actorName = uid == invite.senderUid
        ? invite.senderName
        : invite.recipientName;
    final notificationRef = _notifications.doc();
    await notificationRef.set({
      'id': notificationRef.id,
      'targetUid': targetUid,
      'actorUid': actorUid,
      'title': 'Match-a-Raider update',
      'body': '$actorName ${_statusMessage(newStatus)}.',
      'type': 'match_invite_update',
      'listingId': null,
      'offerId': null,
      'sessionId': null,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (newStatus == 'accepted') {
      await ArcOperationsRepository(
        firestore: _firestore,
        auth: _auth,
      ).recordMatchmakingCompleted(matchId: invite.id);
    }
  }

  List<String> _readStringList(
    dynamic value, [
    List<String> fallback = const <String>[],
  ]) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return <String>[value.trim()];
    }
    return fallback;
  }

  List<String> _communicationToMatchComms(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('mic') || normalized.contains('voice')) {
      return const <String>['Voice'];
    }
    if (normalized.contains('ping')) return const <String>['Pings'];
    if (normalized.contains('quiet') || normalized.contains('low')) {
      return const <String>['Quiet'];
    }
    if (normalized.contains('chat')) return const <String>['Text/chat'];
    if (normalized.contains('flex')) return const <String>['Flexible'];
    return const <String>[];
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  ArcMatchObjectiveSignals _objectiveSignalsFromProfile(
    ArcMatchRiderProfile profile,
  ) {
    return ArcMatchObjectiveSignals(
      ownedBlueprintIds: profile.helperBlueprintIds,
      availableBlueprintIds: const <String>[],
      neededBlueprintIds: profile.blueprintTargets,
      blueprintHuntIds: profile.raidPlannerTargetIds,
      questIds: profile.questFocusIds,
      questChains: profile.questChainIds,
      trialIds: profile.trialFocusIds,
      benchGoalIds: profile.benchGoalIds,
      favouriteLoadoutNeedIds: profile.favouriteLoadoutNeedIds,
      raidPlannerTargetIds: profile.raidPlannerTargetIds,
      tradePreferences: profile.tradePreferences,
      availabilityDayKeys: profile.availabilityDayKeys,
      timezone: profile.timezone,
      giftFriendly: profile.giftFriendly,
      tradeOnly: profile.tradeOnly,
      helperMentor: profile.helperMentor,
      lookingNow: profile.lookingNow,
      reputationScore: profile.reputationScore,
      completedTrades: profile.completedTrades,
      noShows: profile.noShows,
      betrayalFlags: profile.betrayalFlags,
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'accepted':
        return 'accepted your squad-up request';
      case 'declined':
        return 'declined your squad-up request';
      case 'cancelled':
        return 'cancelled the squad-up request';
      default:
        return 'updated the squad-up request';
    }
  }
}
