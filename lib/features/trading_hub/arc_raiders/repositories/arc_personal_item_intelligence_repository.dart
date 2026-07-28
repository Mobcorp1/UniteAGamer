import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_item_dependency_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart';

class ArcPersonalItemIntelligenceRepository {
  ArcPersonalItemIntelligenceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _activeDatasetVersionRef =>
      _firestore.collection('arc_item_dataset_versions').doc('active');

  CollectionReference<Map<String, dynamic>> _protections(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('arc_item_protections');

  Stream<ArcPersonalItemDataset> watchActiveDataset() {
    return _activeDatasetVersionRef.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || data['enabled'] == false) {
        return ArcPersonalItemDependencyCatalog.current;
      }
      final version = (data['version'] ?? '').toString().trim();
      final gameVersion = (data['gameVersion'] ?? '').toString().trim();
      if (version.isEmpty || gameVersion.isEmpty) {
        return ArcPersonalItemDependencyCatalog.current;
      }
      return ArcPersonalItemDataset(
        version: version,
        gameVersion: gameVersion,
        effectiveDateIso:
            (data['effectiveDateIso'] ?? data['effectiveDate'] ?? '')
                .toString()
                .trim(),
        published: data['published'] != false,
        previousVersionIds: _readStringList(data['previousVersionIds']),
        changedItemIds: _readStringList(data['changedItemIds']),
        forceRefreshAfterMajorUpdate:
            data['forceRefreshAfterMajorUpdate'] != false,
        sourceSummary: _readStringList(data['sourceSummary']),
        records: ArcPersonalItemDependencyCatalog.current.records,
      );
    });
  }

  Future<ArcPersonalItemDataset> loadActiveDataset() async {
    final snapshot = await _activeDatasetVersionRef.get();
    final data = snapshot.data();
    if (data == null || data['enabled'] == false) {
      return ArcPersonalItemDependencyCatalog.current;
    }
    final version = (data['version'] ?? '').toString().trim();
    final gameVersion = (data['gameVersion'] ?? '').toString().trim();
    if (version.isEmpty || gameVersion.isEmpty) {
      return ArcPersonalItemDependencyCatalog.current;
    }
    return ArcPersonalItemDataset(
      version: version,
      gameVersion: gameVersion,
      effectiveDateIso:
          (data['effectiveDateIso'] ?? data['effectiveDate'] ?? '')
              .toString()
              .trim(),
      published: data['published'] != false,
      previousVersionIds: _readStringList(data['previousVersionIds']),
      changedItemIds: _readStringList(data['changedItemIds']),
      forceRefreshAfterMajorUpdate:
          data['forceRefreshAfterMajorUpdate'] != false,
      sourceSummary: _readStringList(data['sourceSummary']),
      records: ArcPersonalItemDependencyCatalog.current.records,
    );
  }

  Stream<Map<String, ArcPersonalItemProtectionOverride>>
  watchMyProtectionOverrides() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <String, ArcPersonalItemProtectionOverride>{});
    }
    return _protections(uid).snapshots().map((snapshot) {
      return <String, ArcPersonalItemProtectionOverride>{
        for (final doc in snapshot.docs)
          doc.id: ArcPersonalItemProtectionOverride.fromMap(doc.data()),
      };
    });
  }

  Future<void> saveProtectionOverride(
    ArcPersonalItemProtectionOverride override,
  ) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before protecting an item.');
    if (override.userId != uid) {
      throw StateError('Cannot write item protections for another user.');
    }
    await _protections(uid).doc(_itemKey(override.itemId)).set({
      ...override.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearProtectionOverride(String itemId) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before editing protections.');
    await _protections(uid).doc(_itemKey(itemId)).delete();
  }

  Future<void> logRecommendation({
    required ArcPersonalItemRecommendationResult result,
    required String surface,
  }) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('arc_item_recommendation_logs')
        .add(<String, dynamic>{
          'uid': uid,
          'surface': surface,
          'query': result.query,
          'itemId': result.record?.id ?? '',
          'itemName': result.record?.name ?? '',
          'outcome': result.outcome.name,
          'primaryReason': result.primaryReason,
          'requiredQuantity': result.requiredQuantity,
          'ownedQuantity': result.ownedQuantity,
          'surplusQuantity': result.surplusQuantity,
          'confidence': result.confidence,
          'dataVersion': result.dataVersion,
          'dataFreshness': result.dataFreshness,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static String _itemKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! Iterable) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
