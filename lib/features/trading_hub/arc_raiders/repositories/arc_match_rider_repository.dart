import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/arc_match_rider_invite.dart';
import '../models/arc_match_rider_profile.dart';

class ArcMatchCandidate {
  const ArcMatchCandidate({
    required this.profile,
    required this.score,
    required this.reasons,
  });

  final ArcMatchRiderProfile profile;
  final int score;
  final List<String> reasons;
}

class ArcMatchRiderRepository {
  ArcMatchRiderRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('arc_match_rider_profiles');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('arc_match_rider_invites');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('trading_notifications');

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

    return ArcMatchRiderProfile.empty(uid).copyWith(
      displayName: fallbackName,
      uagId: fallbackUag,
      region: fallbackRegion,
      platform: fallbackPlatform,
      serverPreference: fallbackServerPreference.isEmpty
          ? 'Automatic'
          : fallbackServerPreference,
      crossplayEnabled: fallbackCrossplay,
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
      for (final doc in snapshot.docs) {
        if (doc.id == uid) continue;
        final profile = ArcMatchRiderProfile.fromMap(doc.data(), doc.id);
        final score = _score(currentProfile, profile);
        final reasons = _buildReasons(currentProfile, profile);
        matches.add(
          ArcMatchCandidate(profile: profile, score: score, reasons: reasons),
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
  }

  int _score(ArcMatchRiderProfile me, ArcMatchRiderProfile other) {
    var score = 0;
    score += _sharedCount(me.playstyles, other.playstyles) * 24;
    score += _sharedCount(me.goals, other.goals) * 18;
    score += _sharedCount(me.squadPreferences, other.squadPreferences) * 16;
    score += _sharedCount(me.comms, other.comms) * 12;
    score += _sharedCount(me.preferredMaps, other.preferredMaps) * 10;
    score += _sharedCount(me.preferredModes, other.preferredModes) * 10;
    if (me.platform.isNotEmpty && me.platform == other.platform) score += 14;
    if (me.crossplayEnabled && other.crossplayEnabled) score += 6;
    if (me.region.isNotEmpty && me.region == other.region) score += 10;
    if (me.serverPreference.isNotEmpty &&
        other.serverPreference.isNotEmpty &&
        (me.serverPreference == 'Automatic' ||
            other.serverPreference == 'Automatic' ||
            me.serverPreference == other.serverPreference)) {
      score += 12;
    }
    if (other.lookingNow) score += 8;
    return score;
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
      if (overlap.isNotEmpty)
        reasons.add('$label: ${overlap.take(2).join(', ')}');
    }

    addShared('Shared goals', me.goals, other.goals);
    addShared('Shared playstyle', me.playstyles, other.playstyles);
    addShared('Shared squad vibe', me.squadPreferences, other.squadPreferences);
    addShared('Shared comms', me.comms, other.comms);
    addShared('Shared maps', me.preferredMaps, other.preferredMaps);
    if (me.platform.isNotEmpty && me.platform == other.platform)
      reasons.add('Same platform');
    if (me.crossplayEnabled && other.crossplayEnabled)
      reasons.add('Crossplay compatible');
    if (me.region.isNotEmpty && me.region == other.region)
      reasons.add('Same region');
    if (me.serverPreference.isNotEmpty &&
        other.serverPreference.isNotEmpty &&
        (me.serverPreference == 'Automatic' ||
            other.serverPreference == 'Automatic' ||
            me.serverPreference == other.serverPreference)) {
      reasons.add('Server compatible');
    }
    if (other.lookingNow) reasons.add('Looking now');
    return reasons.take(4).toList(growable: false);
  }

  int _sharedCount(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.where((item) => b.contains(item)).length;
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
