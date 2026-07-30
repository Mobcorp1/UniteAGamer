import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

class ArcUserPersonalisationRepository {
  ArcUserPersonalisationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const collectionName = 'personalisation';
  static const documentId = 'profile';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static String profilePath(String uid) =>
      'users/$uid/$collectionName/$documentId';

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return _userRef(uid).collection(collectionName).doc(documentId);
  }

  Stream<ArcUserPersonalisationProfile> watchProfile() {
    return _auth
        .authStateChanges()
        .map((user) => user?.uid)
        .distinct()
        .asyncExpand((uid) {
          if (uid == null || uid.isEmpty) {
            return Stream<ArcUserPersonalisationProfile>.value(
              ArcUserPersonalisationProfile.defaults,
            );
          }
          return _profileRef(uid).snapshots().map((snapshot) {
            final data = snapshot.data();
            if (!snapshot.exists || data == null) {
              return ArcUserPersonalisationProfile.defaults;
            }
            return ArcUserPersonalisationProfile.fromMap(data);
          });
        })
        .handleError((Object error, StackTrace stackTrace) {
          debugPrint('Personalisation stream failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  }

  Future<ArcUserPersonalisationProfile> loadProfile({
    bool migrateIfNeeded = true,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return ArcUserPersonalisationProfile.defaults;
    }
    if (migrateIfNeeded) {
      return migrateLegacyIfNeeded();
    }
    final snapshot = await _profileRef(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return ArcUserPersonalisationProfile.defaults;
    }
    return ArcUserPersonalisationProfile.fromMap(data);
  }

  Future<void> saveProfile(ArcUserPersonalisationProfile profile) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    await _profileRef(uid).set({
      ...profile
          .copyWith(
            schemaVersion: ArcUserPersonalisationProfile.currentSchemaVersion,
          )
          .toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markComplete(ArcUserPersonalisationProfile profile) async {
    final completed = profile.copyWith(
      schemaVersion: ArcUserPersonalisationProfile.currentSchemaVersion,
      completed: true,
      completedAt: DateTime.now(),
      source: profile.source.trim().isEmpty
          ? 'personalisation_preferences'
          : profile.source,
    );
    await saveProfile(completed);
  }

  Future<ArcUserPersonalisationProfile> migrateLegacyIfNeeded() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return ArcUserPersonalisationProfile.defaults;
    }

    final profileRef = _profileRef(uid);
    try {
      final current = await profileRef.get();
      final data = current.data();
      if (current.exists && data != null) {
        final profile = ArcUserPersonalisationProfile.fromMap(data);
        if (profile.isCurrentSchema) return profile;
      }

      final userSnapshot = await _userRef(uid).get();
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final migrated = ArcUserPersonalisationProfile.inferFromLegacy(
        userData: userData,
        hasBlueprintData: await _hasAny(
          _userRef(uid).collection('arc_blueprints'),
        ),
        hasTradeEvidence: await _hasAny(
          _userRef(uid).collection('trading_activity'),
        ),
        hasScrappyData: await _hasAny(
          _userRef(uid).collection('arc_scrappy_states'),
        ),
        hasProgressionData:
            await _hasAny(_userRef(uid).collection('arc_quest_progress')) ||
            await _hasAny(_userRef(uid).collection('arc_bench_progress')),
        hasLoadout: await _hasAny(
          _userRef(uid).collection('arc_saved_loadouts'),
        ),
      );

      await profileRef.set({
        ...migrated.toMap(),
        'schemaVersion': ArcUserPersonalisationProfile.currentSchemaVersion,
        'migrationSource': 'users/$uid legacy profile and tracker evidence',
        'migratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return migrated.copyWith(
        schemaVersion: ArcUserPersonalisationProfile.currentSchemaVersion,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Personalisation migration skipped safely: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);
      return ArcUserPersonalisationProfile.defaults;
    } catch (error, stackTrace) {
      debugPrint('Personalisation migration skipped safely: $error');
      debugPrintStack(stackTrace: stackTrace);
      return ArcUserPersonalisationProfile.defaults;
    }
  }

  Future<bool> _hasAny(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
