import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/notifications/data/uag_notification_delivery_engine.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';

class UagNotificationRepository {
  UagNotificationRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UagNotificationDeliveryEngine _deliveryEngine =
      const UagNotificationDeliveryEngine();

  String? get currentUid => _auth.currentUser?.uid;

  Stream<String?> _watchCurrentUid() =>
      _auth.authStateChanges().map((user) => user?.uid).distinct();

  CollectionReference<Map<String, dynamic>> _deviceCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_devices');
  }

  DocumentReference<Map<String, dynamic>> _preferencesDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences')
        .doc('current');
  }

  CollectionReference<Map<String, dynamic>> get _broadcasts =>
      _firestore.collection('notification_broadcasts');

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _firestore.collection('uag_notification_schedules');

  Stream<UagNotificationPreferences> watchPreferences() {
    return _watchCurrentUid().asyncExpand((uid) {
      if (uid == null) {
        return Stream.value(UagNotificationPreferences.defaults);
      }

      return _preferencesDoc(uid).snapshots().map(
        (snapshot) => UagNotificationPreferences.fromMap(snapshot.data()),
      );
    });
  }

  Future<UagNotificationPreferences> loadPreferences({String? uid}) async {
    final effectiveUid = uid ?? currentUid;
    if (effectiveUid == null) return UagNotificationPreferences.defaults;
    final snapshot = await _preferencesDoc(effectiveUid).get();
    return UagNotificationPreferences.fromMap(snapshot.data());
  }

  Future<void> savePreferences(UagNotificationPreferences preferences) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before saving preferences.');
    await _preferencesDoc(uid).set({
      ...preferences.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveDeviceRegistration(UagNotificationDevice device) async {
    final uid = currentUid;
    if (uid == null) return;
    if (uid != device.userId || device.token.trim().isEmpty) return;

    final devices = _deviceCollection(uid);
    final duplicateTokens = await devices
        .where('token', isEqualTo: device.token)
        .get();

    final batch = _firestore.batch();
    for (final doc in duplicateTokens.docs) {
      if (doc.id == device.deviceId) continue;
      batch.set(doc.reference, {
        'enabled': false,
        'tokenValid': false,
        'replacedByDeviceId': device.deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    batch.set(devices.doc(device.deviceId), {
      ...device.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_preferencesDoc(uid), {
      ...device.preferences.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep the legacy trading push trigger alive until all server code reads
    // notification_devices directly.
    batch.set(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_tokens')
          .doc(device.token),
      {
        'token': device.token,
        'platform': device.platform,
        'deviceId': device.deviceId,
        'enabled': device.enabled,
        'permissionStatus': device.permissionStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> disableDevice({
    required String uid,
    required String deviceId,
    String token = '',
  }) async {
    if (uid.trim().isEmpty || deviceId.trim().isEmpty) return;

    final batch = _firestore.batch();
    batch.set(_deviceCollection(uid).doc(deviceId), {
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'signedOutAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (token.trim().isNotEmpty) {
      batch.set(
        _firestore
            .collection('users')
            .doc(uid)
            .collection('notification_tokens')
            .doc(token.trim()),
        {
          'enabled': false,
          'updatedAt': FieldValue.serverTimestamp(),
          'signedOutAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Stream<List<UagNotificationDevice>> watchMyDevices() {
    return _watchCurrentUid().asyncExpand((uid) {
      if (uid == null) return Stream.value(const <UagNotificationDevice>[]);
      return _deviceCollection(uid)
          .orderBy('lastSeenAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UagNotificationDevice.fromMap(doc.data()))
                .toList(growable: false),
          );
    });
  }

  Future<UagNotificationAudienceEstimate> estimateAudience({
    required UagNotificationPayload payload,
    String specificTargetUid = '',
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('notification_devices')
        .where('enabled', isEqualTo: true)
        .limit(500);

    if (payload.audience == UagNotificationAudience.android) {
      query = query.where('platform', isEqualTo: 'android');
    }
    if (payload.audience == UagNotificationAudience.web) {
      query = query.where('platform', isEqualTo: 'web');
    }
    if (payload.audience == UagNotificationAudience.specificUser &&
        specificTargetUid.trim().isNotEmpty) {
      query = query.where('userId', isEqualTo: specificTargetUid.trim());
    }

    final snapshot = await query.get();
    final devices = snapshot.docs
        .map((doc) => UagNotificationDevice.fromMap(doc.data()))
        .toList(growable: false);
    final eligible = _deliveryEngine.eligibleDevices(
      payload: payload,
      devices: devices,
      specificTargetUid: specificTargetUid,
    );

    return UagNotificationAudienceEstimate(
      eligibleDevices: eligible.length,
      eligibleUsers: eligible.map((device) => device.userId).toSet().length,
      limited: snapshot.docs.length >= 500,
    );
  }

  Future<String> createBroadcastRequest({
    required UagNotificationPayload payload,
    required bool sendPush,
    required bool createInApp,
    required bool testMode,
    String specificTargetUid = '',
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before creating a broadcast.');
    final doc = _broadcasts.doc();
    final request = UagNotificationBroadcastRequest(
      id: doc.id,
      payload: UagNotificationPayload(
        id: doc.id,
        type: payload.type,
        title: payload.title,
        body: payload.body,
        imageUrl: payload.imageUrl,
        deepLink: payload.deepLink,
        route: payload.route,
        entityId: payload.entityId,
        audience: payload.audience,
        expiresAt: payload.expiresAt,
        senderUid: uid,
        priority: payload.priority,
        deliveryChannels: payload.deliveryChannels,
        metadata: payload.metadata,
      ),
      sendPush: sendPush,
      createInApp: createInApp,
      testMode: testMode,
      status: 'queued',
      targetUid: specificTargetUid.trim(),
      clientRequestId: '${uid}_${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    await doc.set({
      ...request.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> createDirectInAppTestNotification({
    required UagNotificationPayload payload,
    String targetUid = '',
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before creating a test notification.');
    }

    final resolvedTargetUid = targetUid.trim().isEmpty ? uid : targetUid.trim();
    final route = payload.route.trim().isNotEmpty
        ? payload.route.trim()
        : payload.deepLink.trim();
    final doc = _firestore.collection('trading_notifications').doc();

    await doc.set({
      'id': doc.id,
      'targetUid': resolvedTargetUid,
      'actorUid': uid,
      'title': payload.title,
      'body': payload.body,
      'type': payload.type.wireName,
      'listingId': '',
      'offerId': '',
      'sessionId': '',
      'watchId': '',
      'queueId': '',
      'preparationId': '',
      'opportunityId': '',
      'route': route,
      'deepLink': payload.deepLink,
      'imageUrl': payload.imageUrl,
      'entityId': payload.entityId,
      'audience': UagNotificationAudience.specificUser.wireName,
      'priority': payload.priority.wireName,
      'deliveryChannels': [UagNotificationDeliveryChannel.inApp.wireName],
      'source': 'admin_direct_inbox_test',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<bool> canReadDirectInAppNotification(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return false;
    final snapshot = await _firestore
        .collection('trading_notifications')
        .doc(id)
        .get();
    return snapshot.exists;
  }

  Future<void> createSchedule(UagScheduledNotification schedule) async {
    await _schedules.doc(schedule.id).set({
      ...schedule.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
