import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_state.dart';

class PlayLikeAProRepository {
  PlayLikeAProRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No signed-in user available for Play Like a Pro.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(_uid)
      .collection('trading_activity')
      .doc(PlayLikeAProState.docId);

  Stream<PlayLikeAProState> watchState() {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || data.isEmpty) return PlayLikeAProState.initial();
      return PlayLikeAProState.fromMap(Map<String, dynamic>.from(data));
    });
  }

  Future<void> ensureDocExists() async {
    final snapshot = await _doc.get();
    if (snapshot.exists) return;
    final state = PlayLikeAProState.initial().copyWith(
      updatedAt: DateTime.now(),
    );
    await _doc.set(state.toMap(), SetOptions(merge: true));
  }

  Future<void> savePreferences({
    required String preferredGame,
    required int preferredSessionMinutes,
    required PlayLikeAProResetStyle preferredResetStyle,
    required String musicTrigger,
  }) async {
    final now = DateTime.now();
    await _doc.set({
      'preferredGame': preferredGame.trim(),
      'preferredSessionMinutes': preferredSessionMinutes,
      'preferredResetStyle': preferredResetStyle.name,
      'musicTrigger': musicTrigger.trim(),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> savePreGame({
    required PlayLikeAProGoal goal,
    required int energy,
    required int focus,
    required int calm,
    required int confidence,
    required int tiltRisk,
    required String notes,
  }) async {
    final now = DateTime.now();
    await _doc.set({
      'preGoal': goal.name,
      'preEnergy': energy,
      'preFocus': focus,
      'preCalm': calm,
      'preConfidence': confidence,
      'preTiltRisk': tiltRisk,
      'preNotes': notes.trim(),
      'preUpdatedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> saveMidSession({
    required int tiltLevel,
    required int fatigue,
    required int frustration,
    required int focusDrop,
    required bool needsBreak,
    required String notes,
  }) async {
    final now = DateTime.now();
    await _doc.set({
      'midTiltLevel': tiltLevel,
      'midFatigue': fatigue,
      'midFrustration': frustration,
      'midFocusDrop': focusDrop,
      'midNeedsBreak': needsBreak,
      'midNotes': notes.trim(),
      'midUpdatedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> savePostSession({
    required PlayLikeAProState currentState,
    required int performance,
    required int enjoyment,
    required int discipline,
    required int tiltControl,
    required String notes,
  }) async {
    final now = DateTime.now();
    final nextHistory =
        List<PlayLikeAProHistoryEntry>.from(currentState.history)..insert(
          0,
          PlayLikeAProHistoryEntry(
            createdAt: now,
            goal: currentState.preGoal,
            energy: currentState.preEnergy,
            focus: currentState.preFocus,
            calm: currentState.preCalm,
            confidence: currentState.preConfidence,
            tiltRisk: currentState.preTiltRisk,
            tiltLevel: currentState.midTiltLevel,
            fatigue: currentState.midFatigue,
            frustration: currentState.midFrustration,
            performance: performance,
            enjoyment: enjoyment,
            discipline: discipline,
            tiltControl: tiltControl,
            notes: notes.trim(),
          ),
        );

    if (nextHistory.length > 12) {
      nextHistory.removeRange(12, nextHistory.length);
    }

    await _doc.set({
      'postPerformance': performance,
      'postEnjoyment': enjoyment,
      'postDiscipline': discipline,
      'postTiltControl': tiltControl,
      'postNotes': notes.trim(),
      'postUpdatedAt': Timestamp.fromDate(now),
      'history': nextHistory
          .map((entry) => entry.toMap())
          .toList(growable: false),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }
}
