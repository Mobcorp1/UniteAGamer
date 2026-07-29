import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_world_intel_models.dart';

class ArcAdminMapEditorRepository {
  ArcAdminMapEditorRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _providedFirestore = firestore,
       _providedAuth = auth;

  static const _draftKeyPrefix = 'arc_admin_map_editor_drafts_v1';
  static const _importCacheKeyPrefix = 'arc_admin_map_import_cache_v1';
  static const collectionName = 'arc_admin_map_markers';
  static const blueprintReportCollectionName = 'arc_blueprint_drop_reports';
  static const communityIntelCollectionName = 'arc_community_intel_reports';
  static const coverageCollectionName = 'arc_map_marker_coverage_reports';

  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedAuth;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;

  String _draftKey(String mapId, ArcRaidMapLayer layer) =>
      '$_draftKeyPrefix:$mapId:${layer.name}';

  String _importCacheKey(String mapId, ArcRaidMapLayer layer) =>
      '$_importCacheKeyPrefix:$mapId:${layer.name}';

  Future<List<ArcAdminMapMarker>> loadDrafts(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('mapId', isEqualTo: mapId)
        .where('layer', isEqualTo: layer.name)
        .get();
    final firestoreMarkers = _markersFromSnapshot(snapshot);
    if (firestoreMarkers.isNotEmpty) return firestoreMarkers;
    return _loadLegacyLocalDrafts(mapId, layer);
  }

  Future<List<ArcAdminMapMarker>> _loadLegacyLocalDrafts(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_draftKey(mapId, layer));
    if (raw == null || raw.trim().isEmpty) return const <ArcAdminMapMarker>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <ArcAdminMapMarker>[];
    return decoded
        .whereType<Map>()
        .map(
          (value) =>
              ArcAdminMapMarker.fromMap(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }

  Future<void> saveDrafts(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {
    await saveDraftMarkers(mapId, layer, markers);
  }

  Future<ArcAdminMapEditorSaveResult> saveDraftMarkers(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin sign-in is required.');

    final savedAt = DateTime.now();
    final values = prepareDraftMarkersForSave(
      mapId: mapId,
      layer: layer,
      markers: markers,
      uid: uid,
      savedAt: savedAt,
    );
    if (values.isEmpty) {
      return ArcAdminMapEditorSaveResult(
        collectionPath: collectionName,
        savedCount: 0,
        savedAt: savedAt,
      );
    }

    final batch = _firestore.batch();
    for (final marker in values) {
      batch.set(
        _firestore.collection(collectionName).doc(marker.id),
        marker.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    await _saveLegacyLocalDrafts(mapId, layer, values);
    return ArcAdminMapEditorSaveResult(
      collectionPath: collectionName,
      savedCount: values.length,
      savedAt: savedAt,
    );
  }

  static List<ArcAdminMapMarker> prepareDraftMarkersForSave({
    required String mapId,
    required ArcRaidMapLayer layer,
    required Iterable<ArcAdminMapMarker> markers,
    required String uid,
    required DateTime savedAt,
  }) {
    return markers
        .where(
          (item) =>
              item.mapId == mapId &&
              item.layer == layer &&
              item.state != ArcAdminMapMarkerState.archived,
        )
        .map(
          (item) => item.copyWith(
            createdByUid: item.createdByUid ?? uid,
            updatedByUid: uid,
            createdAt: item.createdAt ?? savedAt,
            updatedAt: savedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _saveLegacyLocalDrafts(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final values = markers.map((item) => item.toJsonMap()).toList();
    await preferences.setString(_draftKey(mapId, layer), jsonEncode(values));
  }

  Future<void> clearDrafts(String mapId, ArcRaidMapLayer layer) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftKey(mapId, layer));
  }

  Future<List<ArcAdminMapMarker>> loadImportCache(
    String mapId,
    ArcRaidMapLayer layer,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_importCacheKey(mapId, layer));
    if (raw == null || raw.trim().isEmpty) return const <ArcAdminMapMarker>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <ArcAdminMapMarker>[];
    return decoded
        .whereType<Map>()
        .map(
          (value) =>
              ArcAdminMapMarker.fromMap(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }

  Future<void> saveImportCache(
    String mapId,
    ArcRaidMapLayer layer,
    Iterable<ArcAdminMapMarker> markers,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final values = markers
        .where(
          (item) =>
              item.mapId == mapId &&
              item.layer == layer &&
              item.sourceRecordId?.trim().isNotEmpty == true,
        )
        .map((item) => item.toJsonMap())
        .toList(growable: false);
    await preferences.setString(
      _importCacheKey(mapId, layer),
      jsonEncode(values),
    );
  }

  Stream<List<ArcAdminMapMarker>> watchPublished(
    String mapId,
    ArcRaidMapLayer layer,
  ) {
    return watchLiveMarkers(mapId, layer);
  }

  Stream<List<ArcAdminMapMarker>> watchLiveMarkers(
    String mapId,
    ArcRaidMapLayer layer,
  ) {
    final controller = StreamController<List<ArcAdminMapMarker>>();
    var published = const <ArcAdminMapMarker>[];
    var provisional = const <ArcAdminMapMarker>[];

    void emit() {
      final merged =
          <String, ArcAdminMapMarker>{
              for (final marker in published) marker.id: marker,
              for (final marker in provisional) marker.id: marker,
            }.values.toList(growable: false)
            ..sort((a, b) => a.name.compareTo(b.name));
      if (!controller.isClosed) controller.add(merged);
    }

    final publishedSubscription = _firestore
        .collection(collectionName)
        .where('mapId', isEqualTo: mapId)
        .where('layer', isEqualTo: layer.name)
        .where('state', isEqualTo: ArcAdminMapMarkerState.published.name)
        .snapshots()
        .listen((snapshot) {
          published = _markersFromSnapshot(
            snapshot,
          ).where((marker) => marker.isLive).toList(growable: false);
          emit();
        }, onError: controller.addError);
    final provisionalSubscription = _firestore
        .collection(collectionName)
        .where('mapId', isEqualTo: mapId)
        .where('layer', isEqualTo: layer.name)
        .where('provisionalVisible', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          provisional = _markersFromSnapshot(
            snapshot,
          ).where((marker) => marker.isLive).toList(growable: false);
          emit();
        }, onError: controller.addError);

    controller.onCancel = () async {
      await publishedSubscription.cancel();
      await provisionalSubscription.cancel();
    };
    return controller.stream;
  }

  static List<ArcAdminMapMarker> _markersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (doc) => ArcAdminMapMarker.fromMap(<String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList(growable: false);
  }

  Future<List<ArcBlueprintDropReport>> loadRecentDropReports({
    int limit = 500,
  }) async {
    final snapshot = await _firestore
        .collection(blueprintReportCollectionName)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(
          (doc) => ArcBlueprintDropReport.fromMap(<String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList(growable: false);
  }

  Future<List<ArcCommunityIntelReport>> loadCommunityReports({
    int limit = 500,
  }) async {
    final snapshot = await _firestore
        .collection(communityIntelCollectionName)
        .where('active', isEqualTo: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(
          (doc) => ArcCommunityIntelReport.fromMap(<String, dynamic>{
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList(growable: false);
  }

  Future<void> publish(ArcAdminMapMarker marker) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin sign-in is required.');

    final now = DateTime.now();
    final published = marker.copyWith(
      state: ArcAdminMapMarkerState.published,
      adminVerified: true,
      createdByUid: marker.createdByUid ?? uid,
      updatedByUid: uid,
      createdAt: marker.createdAt ?? now,
      updatedAt: now,
    );

    await _firestore
        .collection(collectionName)
        .doc(marker.id)
        .set(published.toMap(), SetOptions(merge: true));
  }

  Future<void> publishAll(Iterable<ArcAdminMapMarker> markers) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin sign-in is required.');

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final marker in markers) {
      final published = marker.copyWith(
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        createdByUid: marker.createdByUid ?? uid,
        updatedByUid: uid,
        createdAt: marker.createdAt ?? now,
        updatedAt: now,
      );
      batch.set(
        _firestore.collection(collectionName).doc(marker.id),
        published.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> archive(String markerId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin sign-in is required.');
    await _firestore
        .collection(collectionName)
        .doc(markerId)
        .set(<String, dynamic>{
          'state': ArcAdminMapMarkerState.archived.name,
          'updatedByUid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> archiveAll(Iterable<String> markerIds) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin sign-in is required.');
    final batch = _firestore.batch();
    for (final markerId in markerIds.where((id) => id.trim().isNotEmpty)) {
      batch.set(
        _firestore.collection(collectionName).doc(markerId),
        <String, dynamic>{
          'state': ArcAdminMapMarkerState.archived.name,
          'updatedByUid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> saveCoverageReport(ArcWorldIntelCoverageReport report) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Admin sign-in is required.');
    await _firestore
        .collection(coverageCollectionName)
        .doc(report.id)
        .set(<String, dynamic>{
          ...report.toMap(),
          'createdByUid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  String exportJson(Iterable<ArcAdminMapMarker> markers) {
    final values = markers.map((item) => item.toJsonMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(values);
  }
}

class ArcAdminMapEditorSaveResult {
  const ArcAdminMapEditorSaveResult({
    required this.collectionPath,
    required this.savedCount,
    required this.savedAt,
  });

  final String collectionPath;
  final int savedCount;
  final DateTime savedAt;
}
