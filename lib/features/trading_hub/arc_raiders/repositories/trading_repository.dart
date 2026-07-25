import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_watch.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_favourite_rider.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_listing_queue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_bundle_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_network_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_cosmetic_identity.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/trading_push_service.dart';

import 'arc_operations_repository.dart';

class TradingRepository {
  TradingRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Map<String, Stream<TradingCosmeticIdentity>> _cosmeticIdentityStreams =
      <String, Stream<TradingCosmeticIdentity>>{};

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _tradingProfileDoc(String uid) {
    return _userDoc(uid).collection('trading_activity').doc('profile');
  }

  DocumentReference<Map<String, dynamic>> _equippedCosmeticsDoc(String uid) =>
      _firestore.collection('arc_equipped_cosmetics').doc(uid);

  CollectionReference<Map<String, dynamic>> _rewardInventoryCollection(
    String uid,
  ) => _firestore
      .collection('arc_rewards_inventory')
      .doc(uid)
      .collection('items');

  CollectionReference<Map<String, dynamic>> _blueprintStatesCollection(
    String uid,
  ) => _userDoc(uid).collection('arc_blueprints');

  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _firestore.collection('trading_sessions');

  CollectionReference<Map<String, dynamic>> get _listingsCollection =>
      _firestore.collection('trading_listings');

  CollectionReference<Map<String, dynamic>> get _offersCollection =>
      _firestore.collection('trading_offers');

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('trading_notifications');

  CollectionReference<Map<String, dynamic>> get _tradePreparationsCollection =>
      _firestore.collection('arc_trade_preparations');

  CollectionReference<Map<String, dynamic>> get _favouriteRidersCollection =>
      _firestore.collection('arc_favourite_riders');

  CollectionReference<Map<String, dynamic>> get _blueprintWatchesCollection =>
      _firestore.collection('arc_blueprint_watches');

  CollectionReference<Map<String, dynamic>> get _tradePreferencesCollection =>
      _firestore.collection('arc_trade_offer_preferences');

  CollectionReference<Map<String, dynamic>> get _listingQueueCollection =>
      _firestore.collection('arc_trade_listing_queue');

  String _firstNonEmptyString(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  ArcRewardInventoryItem? _findCosmeticItem({
    required List<ArcRewardInventoryItem> inventory,
    required String? rewardId,
    required ArcOperationRewardType type,
  }) {
    if (rewardId == null || rewardId.isEmpty) return null;
    for (final item in inventory) {
      if (item.rewardId == rewardId && item.type == type) return item;
    }
    return null;
  }

  Future<TradingCosmeticIdentity> _loadTraderCosmeticIdentity({
    required String uid,
    required Map<String, dynamic>? profileData,
  }) async {
    final inventorySnapshot = await _rewardInventoryCollection(uid).get();
    final legacyEquippedSnapshot = await _equippedCosmeticsDoc(uid).get();
    final equippedData = <String, dynamic>{
      ...?legacyEquippedSnapshot.data(),
      ...?profileData,
    };
    final equipped = ArcEquippedCosmetics.fromMap(equippedData);

    final inventory = inventorySnapshot.docs
        .map((doc) => ArcRewardInventoryItem.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    return TradingCosmeticIdentity(
      uid: uid,
      displayName: _firstNonEmptyString([
        profileData?['displayName'],
        profileData?['uagName'],
        profileData?['gamerTag'],
      ]),
      gamerTag: _firstNonEmptyString([
        profileData?['gamerTag'],
        profileData?['uagId'],
      ]),
      preferredPlatform: _firstNonEmptyString([
        profileData?['preferredPlatform'],
        profileData?['platform'],
      ]),
      equippedCosmetics: equipped,
      badge: _findCosmeticItem(
        inventory: inventory,
        rewardId: equipped.badgeId,
        type: ArcOperationRewardType.badge,
      ),
      title: _findCosmeticItem(
        inventory: inventory,
        rewardId: equipped.titleId,
        type: ArcOperationRewardType.title,
      ),
      profileFrame: _findCosmeticItem(
        inventory: inventory,
        rewardId: equipped.profileFrameId,
        type: ArcOperationRewardType.profileFrame,
      ),
      profileBanner: _findCosmeticItem(
        inventory: inventory,
        rewardId: equipped.profileBannerId,
        type: ArcOperationRewardType.profileBanner,
      ),
    );
  }

  Stream<TradingCosmeticIdentity> watchTraderCosmeticIdentity(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream.value(TradingCosmeticIdentity.empty);
    }

    return _cosmeticIdentityStreams.putIfAbsent(normalizedUid, () {
      return _tradingProfileDoc(normalizedUid)
          .snapshots()
          .asyncMap(
            (snapshot) => _loadTraderCosmeticIdentity(
              uid: normalizedUid,
              profileData: snapshot.data(),
            ),
          )
          .asBroadcastStream();
    });
  }

  String _blueprintNameFromId(String blueprintId) {
    final match = ArcBlueprintSeedData.blueprints.where(
      (blueprint) => blueprint.id == blueprintId,
    );
    if (match.isEmpty) return blueprintId;
    return match.first.name;
  }

  String _blueprintIdFromName(String blueprintName) {
    final normalized = _normalizeBlueprintText(blueprintName);
    final match = ArcBlueprintSeedData.blueprints.where(
      (blueprint) =>
          _normalizeBlueprintText(blueprint.name) == normalized ||
          _normalizeBlueprintText(blueprint.id) == normalized,
    );
    if (match.isEmpty) return normalized;
    return match.first.id;
  }

  String _normalizeBlueprintText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  TradingSessionStatus _deriveSessionStatus(TradingSession session) {
    if (session.traderOneMarkedBetrayal || session.traderTwoMarkedBetrayal) {
      return TradingSessionStatus.betrayal;
    }
    if (session.traderOneMarkedNoShow || session.traderTwoMarkedNoShow) {
      return TradingSessionStatus.noShow;
    }
    if (session.traderOneMarkedComplete && session.traderTwoMarkedComplete) {
      return TradingSessionStatus.completed;
    }
    if (session.traderOneReady && session.traderTwoReady) {
      return TradingSessionStatus.ready;
    }
    if (session.selectedBooking != null || session.scheduledAt != null) {
      return TradingSessionStatus.scheduled;
    }
    return TradingSessionStatus.pending;
  }

  String _sessionStatusValue(TradingSessionStatus status) {
    return status == TradingSessionStatus.noShow ? 'no_show' : status.name;
  }

  String _otherTraderUid(TradingSession session, String uid) {
    if (uid == session.traderOneUid) return session.traderTwoUid;
    if (uid == session.traderTwoUid) return session.traderOneUid;
    throw Exception('You are not part of this trade session.');
  }

  void _ensureSessionParticipant(TradingSession session, String? uid) {
    if (uid == null) throw Exception('You must be signed in.');
    if (uid != session.traderOneUid && uid != session.traderTwoUid) {
      throw Exception('You are not part of this trade session.');
    }
  }

  void _ensureNonNegativeBundles({
    required int smallBundles,
    required int mediumBundles,
    required int largeBundles,
  }) {
    if (smallBundles < 0 || mediumBundles < 0 || largeBundles < 0) {
      throw Exception('Bundle quantities cannot be negative.');
    }
  }

  List<String> _normalisedUniqueTextItems(Iterable<String> values) {
    final seen = <String>{};
    final output = <String>[];
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase().replaceAll(RegExp(r'\\s+'), ' ');
      if (seen.add(key)) output.add(value);
    }
    return output;
  }

  void _ensureListingInputSafe({
    required String offeredItem,
    required String wantedText,
    required TradingListingType listingType,
    required bool wantsNothing,
    required int smallBundles,
    required int mediumBundles,
    required int largeBundles,
    required List<String> offeredBlueprintNames,
    required List<String> offeredAssetNames,
    required List<String> offeredTradeItemIds,
    required List<String> wantedBlueprintNames,
    required List<String> wantedAssetNames,
    required List<String> wantedTradeItemIds,
  }) {
    _ensureNonNegativeBundles(
      smallBundles: smallBundles,
      mediumBundles: mediumBundles,
      largeBundles: largeBundles,
    );

    final offeredCount = _normalisedUniqueTextItems([
      offeredItem,
      ...offeredBlueprintNames,
      ...offeredAssetNames,
      ...offeredTradeItemIds,
    ]).length;

    if (offeredCount == 0 &&
        smallBundles == 0 &&
        mediumBundles == 0 &&
        largeBundles == 0) {
      throw Exception(
        'Add at least one item, blueprint or seed bundle before listing.',
      );
    }

    if (!wantsNothing && listingType == TradingListingType.specificWant) {
      final wantedCount = _normalisedUniqueTextItems([
        wantedText,
        ...wantedBlueprintNames,
        ...wantedAssetNames,
        ...wantedTradeItemIds,
      ]).length;
      if (wantedCount == 0) {
        throw Exception(
          'Add what you want back, or switch to open offers/free giveaway.',
        );
      }
    }
  }

  void _ensureListingCanReceiveOffer(TradingListing listing, String senderUid) {
    if (listing.id.trim().isEmpty) {
      throw Exception('This listing cannot receive offers yet.');
    }
    if (listing.ownerUid == senderUid) {
      throw Exception('You cannot make an offer on your own listing.');
    }
    if (!listing.active) {
      throw Exception('This listing is no longer active.');
    }
    if (listing.expiresAt.isBefore(DateTime.now())) {
      throw Exception('This listing has expired.');
    }
  }

  void _ensureOfferInputSafe({
    required TradingListing listing,
    required String senderUid,
    required String offeredBlueprintText,
    required int smallBundles,
    required int mediumBundles,
    required int largeBundles,
    required bool includesResources,
    required String resourcesText,
    required List<String> offeredTradeItemIds,
    required bool isGiveawayClaim,
  }) {
    _ensureListingCanReceiveOffer(listing, senderUid);
    _ensureNonNegativeBundles(
      smallBundles: smallBundles,
      mediumBundles: mediumBundles,
      largeBundles: largeBundles,
    );

    if (isGiveawayClaim || listing.wantsNothing) return;

    final seedTotal =
        (smallBundles * 10) + (mediumBundles * 50) + (largeBundles * 100);
    final hasBlueprintText = offeredBlueprintText.trim().isNotEmpty;
    final hasResources = includesResources && resourcesText.trim().isNotEmpty;
    final hasTradeItems = offeredTradeItemIds.any(
      (item) => item.trim().isNotEmpty,
    );

    if (!hasBlueprintText &&
        !hasResources &&
        !hasTradeItems &&
        seedTotal == 0) {
      throw Exception(
        'Add at least one blueprint, resource or seed bundle before sending an offer.',
      );
    }
  }

  Future<void> _ensureNoDuplicatePendingOffer({
    required String senderUid,
    required String listingId,
  }) async {
    final duplicate = await _offersCollection
        .where('senderUid', isEqualTo: senderUid)
        .where('listingId', isEqualTo: listingId)
        .where('status', isEqualTo: TradingOfferStatus.pending.name)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('You already have a pending offer on this listing.');
    }
  }

  Future<void> _ensureListingOfferCapacity(TradingListing listing) async {
    final maxOffers = listing.maxActiveOffers.clamp(1, 25).toInt();
    final pending = await _offersCollection
        .where('listingId', isEqualTo: listing.id)
        .where('status', isEqualTo: TradingOfferStatus.pending.name)
        .limit(maxOffers)
        .get();
    if (pending.docs.length >= maxOffers) {
      throw Exception(
        'This trader is already reviewing the maximum active offers for this listing.',
      );
    }
  }

  Future<void> _ensureNoSessionAlreadyExistsForOffer(String offerId) async {
    final existing = await _sessionsCollection
        .where('offerId', isEqualTo: offerId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('A trade session already exists for this offer.');
    }
  }

  void _ensureSessionCanBeUpdated(TradingSession session) {
    if (session.status == TradingSessionStatus.completed ||
        session.status == TradingSessionStatus.cancelled ||
        session.status == TradingSessionStatus.betrayal ||
        session.status == TradingSessionStatus.noShow) {
      throw Exception('This trade session is already closed.');
    }
  }

  Map<String, dynamic>? _buildNotificationPayload({
    required String targetUid,
    required TradingNotificationType type,
    required String title,
    required String body,
    String listingId = '',
    String offerId = '',
    String sessionId = '',
    String watchId = '',
    String queueId = '',
    String preparationId = '',
    String opportunityId = '',
    DateTime? now,
    bool allowSelfNotification = false,
  }) {
    final actorUid = currentUid;
    if (actorUid == null ||
        targetUid.isEmpty ||
        (!allowSelfNotification && targetUid == actorUid)) {
      return null;
    }

    final ref = _notificationsCollection.doc();
    final createdAt = now ?? DateTime.now();
    final notification = TradingNotification(
      id: ref.id,
      targetUid: targetUid,
      actorUid: actorUid,
      title: title,
      body: body,
      type: type,
      listingId: listingId,
      offerId: offerId,
      sessionId: sessionId,
      watchId: watchId,
      queueId: queueId,
      preparationId: preparationId,
      opportunityId: opportunityId,
      read: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    return {'id': ref.id, 'data': notification.toMap()};
  }

  Future<void> _safeNotify({
    required String targetUid,
    required TradingNotificationType type,
    required String title,
    required String body,
    String listingId = '',
    String offerId = '',
    String sessionId = '',
    String watchId = '',
    String queueId = '',
    String preparationId = '',
    String opportunityId = '',
    bool allowSelfNotification = false,
  }) async {
    final payload = _buildNotificationPayload(
      targetUid: targetUid,
      type: type,
      title: title,
      body: body,
      listingId: listingId,
      offerId: offerId,
      sessionId: sessionId,
      watchId: watchId,
      queueId: queueId,
      preparationId: preparationId,
      opportunityId: opportunityId,
      allowSelfNotification: allowSelfNotification,
    );
    if (payload == null) return;

    try {
      await _notificationsCollection
          .doc(payload['id'] as String)
          .set(payload['data'] as Map<String, dynamic>);
    } catch (_) {
      // Best effort only. Notifications must never break the core trading flow.
    }
  }

  Future<Map<String, dynamic>> _loadUserProfileSource(String uid) async {
    final userSnap = await _userDoc(uid).get();
    final userData = userSnap.data() ?? <String, dynamic>{};

    final basicProfile = _safeMap(userData['basicProfile']);
    final traderProfile = _safeMap(userData['traderProfile']);

    final displayName = _firstNonEmptyString([
      userData['displayName'],
      basicProfile['displayName'],
      userData['name'],
    ], fallback: 'New Trader');

    final region = _firstNonEmptyString([
      traderProfile['region'],
      basicProfile['country'],
    ], fallback: 'Flexible');

    final profileImageUrl = _firstNonEmptyString([
      userData['photoURL'],
      basicProfile['photoURL'],
    ], fallback: '');

    final gamerTag = _firstNonEmptyString([
      traderProfile['gamerTag'],
      basicProfile['gamertag'],
    ], fallback: '');

    final preferredPlatform = _firstNonEmptyString([
      traderProfile['preferredPlatform'],
      basicProfile['platform'],
    ], fallback: '');

    return {
      'displayName': displayName,
      'region': region,
      'profileImageUrl': profileImageUrl,
      'gamerTag': gamerTag,
      'preferredPlatform': preferredPlatform,
    };
  }

  Future<void> ensureTradingProfileExists() async {
    final uid = currentUid;
    if (uid == null) return;

    final profileDoc = _tradingProfileDoc(uid);
    final existing = await profileDoc.get();

    if (existing.exists) return;

    final source = await _loadUserProfileSource(uid);

    final profile = TradingProfile.empty(uid).copyWith(
      displayName: source['displayName'] as String? ?? 'New Trader',
      region: source['region'] as String? ?? 'Flexible',
      profileImageUrl: source['profileImageUrl'] as String? ?? '',
      gamerTag: source['gamerTag'] as String? ?? '',
      preferredPlatform: source['preferredPlatform'] as String? ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await profileDoc.set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> syncTradingProfileFromUserProfile() async {
    final uid = currentUid;
    if (uid == null) return;

    await ensureTradingProfileExists();
    final source = await _loadUserProfileSource(uid);

    await _tradingProfileDoc(uid).set({
      'uid': uid,
      'displayName': source['displayName'] ?? 'New Trader',
      'region': source['region'] ?? 'Flexible',
      'profileImageUrl': source['profileImageUrl'] ?? '',
      'gamerTag': source['gamerTag'] ?? '',
      'preferredPlatform': source['preferredPlatform'] ?? '',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Stream<TradingProfile> watchTradingProfile() {
    final uid = currentUid;
    if (uid == null) return Stream.value(TradingProfile.empty(''));

    return _tradingProfileDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return TradingProfile.empty(uid);
      return TradingProfile.fromMap(snapshot.data() ?? <String, dynamic>{});
    });
  }

  Stream<Set<String>> watchFavouriteRiderIds() {
    final uid = currentUid;
    if (uid == null) return Stream.value(<String>{});
    return _favouriteRidersCollection
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
  }) async {
    final uid = currentUid;
    final normalizedRiderUid = riderUid.trim();
    if (uid == null ||
        normalizedRiderUid.isEmpty ||
        uid == normalizedRiderUid) {
      return;
    }

    final docId = ArcFavouriteRider.idFor(uid, normalizedRiderUid);
    final ref = _favouriteRidersCollection.doc(docId);
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
      completedTrades: previous?.completedTrades ?? 0,
      squadSessions: previous?.squadSessions ?? 0,
      previousBlueprintOffer: previous?.previousBlueprintOffer ?? false,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.set(model.toMap(), SetOptions(merge: true));
  }

  Stream<ArcTradePreferences> watchTradePreferences() {
    final uid = currentUid;
    if (uid == null) return Stream.value(ArcTradePreferences.empty(''));
    return _tradePreferencesCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return ArcTradePreferences.empty(uid);
      return ArcTradePreferences.fromMap(snapshot.data() ?? const {});
    });
  }

  Future<void> saveTradePreferences(ArcTradePreferences preferences) async {
    final uid = currentUid;
    if (uid == null) return;
    final now = DateTime.now();
    await _tradePreferencesCollection.doc(uid).set({
      ...preferences.toMap(),
      'ownerUid': uid,
      'createdAt': preferences.createdAt == null
          ? Timestamp.fromDate(now)
          : Timestamp.fromDate(preferences.createdAt!),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Stream<List<ArcBlueprintWatch>> watchBlueprintWatches() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const <ArcBlueprintWatch>[]);
    return _blueprintWatchesCollection
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final watches = snapshot.docs
              .map((doc) => ArcBlueprintWatch.fromMap(doc.data()))
              .toList(growable: false);
          return watches..sort((a, b) {
            final aDate =
                a.updatedAt ??
                a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.updatedAt ??
                b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
        });
  }

  Future<void> saveBlueprintWatch(ArcBlueprintWatch watch) async {
    final uid = currentUid;
    if (uid == null) return;
    final ref = watch.id.trim().isEmpty
        ? _blueprintWatchesCollection.doc()
        : _blueprintWatchesCollection.doc(watch.id);
    final now = DateTime.now();
    await ref.set({
      ...watch.toMap(),
      'id': ref.id,
      'ownerUid': uid,
      'createdAt': watch.createdAt == null
          ? Timestamp.fromDate(now)
          : Timestamp.fromDate(watch.createdAt!),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<ArcBlueprintWatch> createOrReactivateBlueprintWatch({
    required String blueprintId,
    required String blueprintDisplayName,
    ArcBlueprintWatchType type = ArcBlueprintWatchType.blueprint,
    String objectiveId = '',
    String linkedListingId = '',
    String linkedOpportunityId = '',
    List<String> preferredAcquisitionMethods = const <String>[],
    int minimumMatchScore = 60,
    bool favouriteRidersOnly = false,
    bool notificationsEnabled = true,
    ArcBlueprintWatchNotificationPreference notificationPreference =
        ArcBlueprintWatchNotificationPreference.duringAvailabilityOnly,
  }) async {
    final uid = currentUid;
    if (uid == null || blueprintId.trim().isEmpty) {
      throw Exception('You must be signed in to watch a blueprint.');
    }

    final normalizedBlueprintId = blueprintId.trim();
    final watchId = ArcBlueprintWatch.idFor(
      ownerUid: uid,
      blueprintId: normalizedBlueprintId,
      type: type,
      objectiveId: objectiveId,
    );
    final ref = _blueprintWatchesCollection.doc(watchId);
    final now = DateTime.now();
    final existing = await ref.get();
    final previous = existing.exists
        ? ArcBlueprintWatch.fromMap(existing.data() ?? const {})
        : null;

    final watch =
        (previous ??
                ArcBlueprintWatch(
                  id: watchId,
                  ownerUid: uid,
                  type: type,
                  blueprintId: normalizedBlueprintId,
                  createdAt: now,
                ))
            .copyWith(
              id: watchId,
              ownerUid: uid,
              type: type,
              blueprintId: normalizedBlueprintId,
              blueprintDisplayName: blueprintDisplayName.trim().isEmpty
                  ? _blueprintNameFromId(normalizedBlueprintId)
                  : blueprintDisplayName.trim(),
              objectiveId: objectiveId.trim(),
              preferredAcquisitionMethods: preferredAcquisitionMethods,
              minimumMatchScore: minimumMatchScore,
              favouriteRidersOnly: favouriteRidersOnly,
              notificationsEnabled: notificationsEnabled,
              notificationPreference: notificationsEnabled
                  ? notificationPreference
                  : ArcBlueprintWatchNotificationPreference.muted,
              active: true,
              linkedListingId: linkedListingId.trim(),
              linkedOpportunityId: linkedOpportunityId.trim(),
              lastMatchedAt:
                  linkedListingId.trim().isEmpty &&
                      linkedOpportunityId.trim().isEmpty
                  ? previous?.lastMatchedAt
                  : now,
              createdAt: previous?.createdAt ?? now,
              updatedAt: now,
            );

    await ref.set(watch.toMap(), SetOptions(merge: true));
    return watch;
  }

  Future<void> pauseBlueprintWatch(String watchId) async {
    await _updateBlueprintWatchState(watchId: watchId, active: false);
  }

  Future<void> resumeBlueprintWatch(String watchId) async {
    await _updateBlueprintWatchState(watchId: watchId, active: true);
  }

  Future<void> removeBlueprintWatch(String watchId) async {
    final uid = currentUid;
    if (uid == null || watchId.trim().isEmpty) return;
    final ref = _blueprintWatchesCollection.doc(watchId.trim());
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final watch = ArcBlueprintWatch.fromMap(snapshot.data() ?? const {});
    if (watch.ownerUid != uid) {
      throw Exception('You can only remove your own blueprint watches.');
    }
    await ref.delete();
  }

  Future<void> _updateBlueprintWatchState({
    required String watchId,
    required bool active,
  }) async {
    final uid = currentUid;
    if (uid == null || watchId.trim().isEmpty) return;
    final ref = _blueprintWatchesCollection.doc(watchId.trim());
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final watch = ArcBlueprintWatch.fromMap(snapshot.data() ?? const {});
    if (watch.ownerUid != uid) {
      throw Exception('You can only update your own blueprint watches.');
    }
    await ref.set({
      'active': active,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> enqueueDuplicateRelease(
    ArcTradeListingQueueItem queueItem,
  ) async {
    final uid = currentUid;
    if (uid == null) return;
    final ref = queueItem.id.trim().isEmpty
        ? _listingQueueCollection.doc()
        : _listingQueueCollection.doc(queueItem.id);
    final now = DateTime.now();
    await ref.set({
      ...queueItem.toMap(),
      'id': ref.id,
      'ownerUid': uid,
      'createdAt': queueItem.createdAt == null
          ? Timestamp.fromDate(now)
          : Timestamp.fromDate(queueItem.createdAt!),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Stream<List<ArcTradeListingQueueItem>> watchListingQueues() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <ArcTradeListingQueueItem>[]);
    }

    return _listingQueueCollection
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final queues = snapshot.docs
              .map((doc) => ArcTradeListingQueueItem.fromMap(doc.data()))
              .toList(growable: false);
          return queues..sort((a, b) {
            final aDate =
                a.updatedAt ??
                a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.updatedAt ??
                b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
        });
  }

  Future<void> pauseListingQueue(String queueId) async {
    await _updateListingQueueStatus(
      queueId: queueId,
      status: ArcTradeListingQueueStatus.paused,
      clearBlockedReason: true,
    );
  }

  Future<void> resumeListingQueue(String queueId) async {
    await _updateListingQueueStatus(
      queueId: queueId,
      status: ArcTradeListingQueueStatus.active,
      clearBlockedReason: true,
    );
  }

  Future<void> cancelListingQueue(String queueId) async {
    await _updateListingQueueStatus(
      queueId: queueId,
      status: ArcTradeListingQueueStatus.cancelled,
      clearBlockedReason: true,
      cancelledAt: DateTime.now(),
    );
  }

  Future<void> _updateListingQueueStatus({
    required String queueId,
    required ArcTradeListingQueueStatus status,
    bool clearBlockedReason = false,
    DateTime? cancelledAt,
  }) async {
    final uid = currentUid;
    if (uid == null || queueId.trim().isEmpty) return;
    final ref = _listingQueueCollection.doc(queueId.trim());
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final queue = ArcTradeListingQueueItem.fromMap(snapshot.data() ?? const {});
    if (queue.ownerUid != uid) {
      throw Exception('You can only update your own listing queues.');
    }

    await ref.set({
      'status': status.name,
      if (clearBlockedReason) 'blockedReason': '',
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<TradingListing?> releaseNextQueuedListing(String queueId) async {
    final uid = currentUid;
    if (uid == null || queueId.trim().isEmpty) {
      throw Exception('You must be signed in to release a queued listing.');
    }

    final queueRef = _listingQueueCollection.doc(queueId.trim());
    final newListingRef = _listingsCollection.doc();
    late TradingListing? releasedListing;
    String? blockedReason;

    await _firestore.runTransaction((transaction) async {
      final queueSnapshot = await transaction.get(queueRef);
      if (!queueSnapshot.exists) {
        throw Exception('This listing queue no longer exists.');
      }
      final queue = ArcTradeListingQueueItem.fromMap(
        queueSnapshot.data() ?? <String, dynamic>{},
      );
      if (queue.ownerUid != uid) {
        throw Exception('You can only release your own listing queues.');
      }
      if (queue.isPaused) {
        blockedReason = 'Queue is paused.';
        transaction.set(queueRef, {
          'blockedReason': blockedReason,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
        releasedListing = null;
        return;
      }
      if (queue.isTerminal || !queue.hasRemaining) {
        blockedReason = 'No queued duplicate remains.';
        transaction.set(queueRef, {
          'status': ArcTradeListingQueueStatus.completed.name,
          'blockedReason': blockedReason,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
        releasedListing = null;
        return;
      }

      final activeListingId = queue.activeListingId.trim().isEmpty
          ? queue.sourceListingId
          : queue.activeListingId.trim();
      if (activeListingId.isNotEmpty) {
        final activeSnapshot = await transaction.get(
          _listingsCollection.doc(activeListingId),
        );
        if (activeSnapshot.exists) {
          final activeListing = TradingListing.fromMap(
            activeSnapshot.data() ?? <String, dynamic>{},
          );
          if (activeListing.active &&
              activeListing.expiresAt.isAfter(DateTime.now())) {
            blockedReason = 'A queue-linked listing is still active.';
            transaction.set(queueRef, {
              'blockedReason': blockedReason,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            }, SetOptions(merge: true));
            releasedListing = null;
            return;
          }
        }
      }

      final stateSnapshot = await transaction.get(
        _blueprintStatesCollection(uid).doc(queue.blueprintId),
      );
      final state = stateSnapshot.exists
          ? ArcBlueprintState.fromMap(
              stateSnapshot.data() ?? <String, dynamic>{},
            )
          : ArcBlueprintState.empty(queue.blueprintId);
      if (state.dupesOwned < queue.releasedQuantity + 1) {
        blockedReason = 'Duplicate ownership no longer supports this queue.';
        transaction.set(queueRef, {
          'status': ArcTradeListingQueueStatus.blocked.name,
          'blockedReason': blockedReason,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
        releasedListing = null;
        return;
      }

      final sourceSnapshot = await transaction.get(
        _listingsCollection.doc(queue.sourceListingId),
      );
      if (!sourceSnapshot.exists) {
        blockedReason = 'Source listing is missing.';
        transaction.set(queueRef, {
          'status': ArcTradeListingQueueStatus.blocked.name,
          'blockedReason': blockedReason,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
        releasedListing = null;
        return;
      }

      final now = DateTime.now();
      final source = TradingListing.fromMap(
        sourceSnapshot.data() ?? <String, dynamic>{},
      );
      final sourceCreatedAt = source.createdAt ?? now;
      final sourceDuration = source.expiresAt.isAfter(sourceCreatedAt)
          ? source.expiresAt.difference(sourceCreatedAt)
          : const Duration(hours: 72);
      final releaseNumber = queue.releasedQuantity + 1;
      final next = source.copyWith(
        id: newListingRef.id,
        title: '${source.title} #${releaseNumber + 1}',
        active: true,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(sourceDuration),
        queueId: queue.id,
        queueSourceListingId: queue.sourceListingId,
        queueReleaseNumber: releaseNumber,
      );
      final remainingAfterRelease = queue.remainingQuantity - 1;
      final nextStatus = remainingAfterRelease <= 0
          ? ArcTradeListingQueueStatus.completed
          : ArcTradeListingQueueStatus.active;
      final nextQueue = queue.copyWith(
        status: nextStatus,
        activeListingId: next.id,
        lastReleasedListingId: next.id,
        releasedQuantity: releaseNumber,
        lastReleasedAt: now,
        completedAt: nextStatus == ArcTradeListingQueueStatus.completed
            ? now
            : queue.completedAt,
        updatedAt: now,
        clearBlockedReason: true,
        clearReleaseAt: true,
      );

      transaction.set(newListingRef, next.toMap());
      transaction.set(queueRef, nextQueue.toMap(), SetOptions(merge: true));
      releasedListing = next;
    });

    if (releasedListing != null) {
      await _safeNotify(
        targetUid: uid,
        type: TradingNotificationType.queuedListingReleased,
        title: 'Queued listing released',
        body: '${releasedListing!.offeredSummary} is live from your queue.',
        listingId: releasedListing!.id,
        queueId: queueId.trim(),
        allowSelfNotification: true,
      );
    } else if (blockedReason != null && blockedReason!.isNotEmpty) {
      await _safeNotify(
        targetUid: uid,
        type: TradingNotificationType.queuedListingBlocked,
        title: 'Listing queue needs attention',
        body: blockedReason!,
        queueId: queueId.trim(),
        allowSelfNotification: true,
      );
    }

    return releasedListing;
  }

  Future<TradingProfile> getTradingProfile() async {
    final uid = currentUid;
    if (uid == null) return TradingProfile.empty('');

    await ensureTradingProfileExists();
    final snap = await _tradingProfileDoc(uid).get();

    if (!snap.exists) return TradingProfile.empty(uid);
    return TradingProfile.fromMap(snap.data() ?? <String, dynamic>{});
  }

  Future<String> getPreferredEmbarkIdForSession(TradingSession session) async {
    final uid = currentUid;
    _ensureSessionParticipant(session, uid);

    final profile = await getTradingProfile();
    if (profile.embarkId.trim().isNotEmpty) return profile.embarkId.trim();

    return uid == session.traderOneUid
        ? session.traderOneEmbarkId.trim()
        : session.traderTwoEmbarkId.trim();
  }

  Future<void> saveEmbarkId(String embarkId) async {
    final uid = currentUid;
    if (uid == null) return;

    await ensureTradingProfileExists();

    await _tradingProfileDoc(uid).set({
      'uid': uid,
      'embarkId': embarkId.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, ArcBlueprintState>> watchBlueprintStates() {
    final uid = currentUid;

    if (uid == null) {
      return Stream.value(const <String, ArcBlueprintState>{});
    }

    return _blueprintStatesCollection(uid).snapshots().map((snapshot) {
      final states = <String, ArcBlueprintState>{};

      for (final doc in snapshot.docs) {
        final rawData = doc.data();
        final data = <String, dynamic>{
          ...rawData,
          'blueprintId':
              (rawData['blueprintId'] as String?)?.trim().isNotEmpty == true
              ? rawData['blueprintId']
              : doc.id,
        };

        final state = ArcBlueprintState.fromMap(data);
        final blueprintId = state.blueprintId.trim().isNotEmpty
            ? state.blueprintId.trim()
            : doc.id;

        states[blueprintId] = state.copyWith(blueprintId: blueprintId);
      }

      return states;
    });
  }

  Future<List<String>> getMatchingDuplicateBlueprintNames(
    TradingListing listing,
  ) async {
    final uid = currentUid;
    if (uid == null) return const <String>[];

    final snapshot = await _blueprintStatesCollection(uid).get();
    if (snapshot.docs.isEmpty) return const <String>[];

    final wantedNames = <String>{
      for (final name in listing.wantedBlueprintNames)
        if (name.trim().isNotEmpty) name.trim().toLowerCase(),
    };

    if (listing.wantedText.trim().isNotEmpty) {
      wantedNames.add(listing.wantedText.trim().toLowerCase());
    }

    final matches = <String>[];
    for (final doc in snapshot.docs) {
      final state = ArcBlueprintState.fromMap(doc.data());
      if (!state.hasDuplicates) continue;
      final blueprintName = _blueprintNameFromId(state.blueprintId).trim();
      if (wantedNames.contains(blueprintName.toLowerCase())) {
        matches.add(blueprintName);
      }
    }

    matches.sort();
    return matches;
  }

  Stream<List<TradingNotification>> watchNotifications() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const <TradingNotification>[]);

    return _notificationsCollection
        .where('targetUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TradingNotification.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).set({
      'read': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> markAllNotificationsRead() async {
    final uid = currentUid;
    if (uid == null) return;
    final unread = await _notificationsCollection
        .where('targetUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    for (final doc in unread.docs) {
      batch.set(doc.reference, {
        'read': true,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }

  Stream<List<ArcTradePreparation>> watchTradePreparations() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <ArcTradePreparation>[]);
    }

    return _tradePreparationsCollection
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcTradePreparation.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> saveTradePreparation(ArcTradePreparation preparation) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('You must be signed in to watch a trade.');
    }
    if (preparation.userId != uid) {
      throw Exception('You can only watch trades for your own account.');
    }

    await _tradePreparationsCollection
        .doc(preparation.id)
        .set(preparation.toMap(), SetOptions(merge: true));
  }

  Future<int> _activeListingCountForBlueprint({
    required String ownerUid,
    required String blueprintId,
  }) async {
    final normalizedBlueprintId = _normalizeBlueprintText(blueprintId);
    if (ownerUid.trim().isEmpty || normalizedBlueprintId.isEmpty) return 0;

    final snapshot = await _listingsCollection
        .where('ownerUid', isEqualTo: ownerUid)
        .get();
    final now = DateTime.now();
    return snapshot.docs
        .map((doc) => TradingListing.fromMap(doc.data()))
        .where((listing) => listing.active && listing.expiresAt.isAfter(now))
        .where(
          (listing) => listing.offeredBlueprintNames.any(
            (name) => _blueprintIdFromName(name) == normalizedBlueprintId,
          ),
        )
        .length;
  }

  Future<void> updateTradePreparationReadiness(
    ArcTradePreparation preparation,
  ) async {
    final uid = currentUid;
    if (uid == null || preparation.userId != uid) return;

    await _tradePreparationsCollection.doc(preparation.id).set({
      'ownedItems': preparation.ownedItems
          .map((item) => item.toMap())
          .toList(growable: false),
      'remainingItems': preparation.remainingItems
          .map((item) => item.toMap())
          .toList(growable: false),
      'status': preparation.status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> updateTradePreparationStatus({
    required String preparationId,
    required ArcTradePreparationStatus status,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('You must be signed in to update a trade watch.');
    }

    await _tradePreparationsCollection.doc(preparationId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<TradingSession?> getSessionForOffer(String offerId) async {
    final snapshot = await _sessionsCollection
        .where('offerId', isEqualTo: offerId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return TradingSession.fromMap(snapshot.docs.first.data());
  }

  String buildSessionInviteText(TradingSession session) {
    final effectiveScheduled = session.selectedBooking ?? session.scheduledAt;
    final when = effectiveScheduled == null
        ? 'Time still to be confirmed'
        : '${effectiveScheduled.day.toString().padLeft(2, '0')}/'
              '${effectiveScheduled.month.toString().padLeft(2, '0')}/'
              '${effectiveScheduled.year} '
              '${effectiveScheduled.hour.toString().padLeft(2, '0')}:'
              '${effectiveScheduled.minute.toString().padLeft(2, '0')}';

    return 'ARC Raiders trade invite\n\n'
        'Traders: ${session.traderOneName} â†” ${session.traderTwoName}\n'
        'When: $when (${session.timezone})\n'
        'Protocol: ${session.protocolLabel}\n'
        'Session ID: ${session.id}\n'
        'Listing ID: ${session.listingId}\n\n'
        'Before starting:\n'
        '- share Embark IDs\n'
        '- confirm first drop\n'
        '- mark ready in the app\n';
  }

  Future<TradingListing> createListing({
    required String offeredItem,
    required String wantedText,
    required TradingListingType listingType,
    required String playWindow,
    required int smallBundles,
    required int mediumBundles,
    required int largeBundles,
    required bool acceptsBlueprints,
    required bool acceptsSeeds,
    required bool acceptsResources,
    required bool seriousOffersOnly,
    required String notes,
    required Duration expiryDuration,
    List<String> offeredBlueprintNames = const <String>[],
    List<String> wantedBlueprintNames = const <String>[],
    List<String> offeredAssetNames = const <String>[],
    List<String> wantedAssetNames = const <String>[],
    List<String> offeredTradeItemIds = const <String>[],
    List<String> wantedTradeItemIds = const <String>[],
    List<String> offeredTradeItemNames = const <String>[],
    List<String> wantedTradeItemNames = const <String>[],
    bool wantsNothing = false,
    bool tradeAsBundle = true,
    bool allowPartialOffers = false,
    List<ArcTradeBundleTemplate> acceptedBundles =
        const <ArcTradeBundleTemplate>[],
    bool allowCustomBundleOffers = false,
    TradingListingMode listingMode = TradingListingMode.availableNow,
    String scheduledWindow = '',
    String sellerTimezone = '',
    ArcDuplicateReleasePolicy duplicateReleasePolicy =
        ArcDuplicateReleasePolicy.askBeforeRelisting,
    bool favouriteRidersFirst = false,
    bool fixedReturn = false,
    bool bestSuitableOffer = false,
    int maxActiveOffers = 5,
    bool duplicateQueueEnabled = false,
    String duplicateQueueBlueprintId = '',
    String duplicateQueueBlueprintName = '',
    int duplicateQueueQuantity = 0,
  }) async {
    final uid = currentUid;
    if (uid == null) return TradingListing.empty();

    final bundleErrors = const ArcTradeBundleEngine().validateTemplates(
      acceptedBundles,
    );
    if (bundleErrors.isNotEmpty) {
      throw Exception(bundleErrors.join(' '));
    }

    _ensureListingInputSafe(
      offeredItem: offeredItem,
      wantedText: wantedText,
      listingType: listingType,
      wantsNothing: wantsNothing,
      smallBundles: smallBundles,
      mediumBundles: mediumBundles,
      largeBundles: largeBundles,
      offeredBlueprintNames: offeredBlueprintNames,
      offeredAssetNames: offeredAssetNames,
      offeredTradeItemIds: offeredTradeItemIds,
      wantedBlueprintNames: wantedBlueprintNames,
      wantedAssetNames: wantedAssetNames,
      wantedTradeItemIds: wantedTradeItemIds,
    );

    await ensureTradingProfileExists();
    final profile = await getTradingProfile();

    final listingRef = _listingsCollection.doc();
    final now = DateTime.now();
    final normalizedQueueBlueprintId = duplicateQueueBlueprintId.trim().isEmpty
        ? offeredBlueprintNames.isEmpty
              ? ''
              : _blueprintIdFromName(offeredBlueprintNames.first)
        : duplicateQueueBlueprintId.trim();
    final normalizedQueueBlueprintName =
        duplicateQueueBlueprintName.trim().isEmpty
        ? normalizedQueueBlueprintId.isEmpty
              ? ''
              : _blueprintNameFromId(normalizedQueueBlueprintId)
        : duplicateQueueBlueprintName.trim();
    final safeQueueQuantity = duplicateQueueEnabled
        ? duplicateQueueQuantity.clamp(0, 99).toInt()
        : 0;
    final queueId =
        safeQueueQuantity > 0 && normalizedQueueBlueprintId.isNotEmpty
        ? ArcTradeListingQueueItem.idFor(
            ownerUid: uid,
            sourceListingId: listingRef.id,
          )
        : '';

    final seedTotal =
        (smallBundles * 10) + (mediumBundles * 50) + (largeBundles * 100);

    final title = wantsNothing
        ? '$offeredItem - Free Giveaway'
        : listingType == TradingListingType.openToOffers
        ? '$offeredItem - Open Offer'
        : '$offeredItem for $wantedText';

    final listing = TradingListing(
      id: listingRef.id,
      ownerUid: uid,
      traderName: profile.displayName,
      gamerTag: profile.gamerTag,
      preferredPlatform: profile.preferredPlatform,
      title: title,
      offeredItem: offeredItem.trim(),
      wantedText: wantedText.trim(),
      offeredBlueprintNames: offeredBlueprintNames,
      wantedBlueprintNames: wantedBlueprintNames,
      offeredAssetNames: offeredAssetNames,
      wantedAssetNames: wantedAssetNames,
      offeredTradeItemIds: offeredTradeItemIds,
      wantedTradeItemIds: wantedTradeItemIds,
      offeredTradeItemNames: offeredTradeItemNames.isNotEmpty
          ? offeredTradeItemNames
          : offeredAssetNames,
      wantedTradeItemNames: wantedTradeItemNames.isNotEmpty
          ? wantedTradeItemNames
          : wantedAssetNames,
      wantsNothing: wantsNothing,
      listingType: wantsNothing ? TradingListingType.openToOffers : listingType,
      riskLevel: profile.riskLevel,
      completedTrades: profile.completedTrades,
      noShows: profile.noShows,
      betrayalFlags: profile.betrayalFlags,
      region: profile.region,
      playWindow: playWindow,
      smallBundles: smallBundles,
      mediumBundles: mediumBundles,
      largeBundles: largeBundles,
      seedTotalOffered: seedTotal,
      acceptsBlueprints: acceptsBlueprints,
      acceptsSeeds: acceptsSeeds,
      acceptsResources: acceptsResources,
      seriousOffersOnly: seriousOffersOnly,
      tradeAsBundle: tradeAsBundle,
      allowPartialOffers: allowPartialOffers,
      acceptedBundles: acceptedBundles,
      allowCustomBundleOffers: allowCustomBundleOffers,
      listingMode: wantsNothing ? TradingListingMode.gift : listingMode,
      scheduledWindow: scheduledWindow.trim(),
      sellerTimezone: sellerTimezone.trim(),
      duplicateReleasePolicy: duplicateReleasePolicy,
      favouriteRidersFirst:
          favouriteRidersFirst ||
          listingMode == TradingListingMode.favouriteRidersFirst,
      fixedReturn: fixedReturn || listingMode == TradingListingMode.fixedReturn,
      bestSuitableOffer:
          bestSuitableOffer ||
          listingMode == TradingListingMode.bestSuitableOffer,
      maxActiveOffers: maxActiveOffers.clamp(1, 25).toInt(),
      queueId: queueId,
      queueSourceListingId: queueId.isEmpty ? '' : listingRef.id,
      queueReleaseNumber: 0,
      expiresAt: now.add(expiryDuration),
      notes: notes.trim(),
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    if (safeQueueQuantity <= 0) {
      await listingRef.set(listing.toMap());
      await _recordListingCreated(listing.id);
      return listing;
    }

    final blueprintStateSnapshot = await _blueprintStatesCollection(
      uid,
    ).doc(normalizedQueueBlueprintId).get();
    final blueprintState = blueprintStateSnapshot.exists
        ? ArcBlueprintState.fromMap(
            blueprintStateSnapshot.data() ?? <String, dynamic>{},
          )
        : ArcBlueprintState.empty(normalizedQueueBlueprintId);
    final activeSameBlueprintCount = await _activeListingCountForBlueprint(
      ownerUid: uid,
      blueprintId: normalizedQueueBlueprintId,
    );
    final maxFutureQueue =
        blueprintState.dupesOwned - activeSameBlueprintCount - 1;
    if (maxFutureQueue < safeQueueQuantity) {
      throw Exception(
        'Queued release quantity exceeds duplicate availability for $normalizedQueueBlueprintName.',
      );
    }

    final queue = ArcTradeListingQueueItem.createForListing(
      id: queueId,
      ownerUid: uid,
      blueprintId: normalizedQueueBlueprintId,
      blueprintName: normalizedQueueBlueprintName,
      sourceListingId: listingRef.id,
      releasePolicy: duplicateReleasePolicy,
      queuedQuantity: safeQueueQuantity,
      now: now,
    );

    final batch = _firestore.batch();
    batch.set(listingRef, listing.toMap());
    batch.set(_listingQueueCollection.doc(queue.id), queue.toMap());
    await batch.commit();
    await _recordListingCreated(listing.id);
    return listing;
  }

  Stream<List<TradingListing>> watchActiveListings() {
    return _listingsCollection
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          return snapshot.docs
              .map((doc) => TradingListing.fromMap(doc.data()))
              .where((listing) => listing.expiresAt.isAfter(now))
              .toList(growable: false);
        });
  }

  Stream<List<TradingListing>> watchMyListings() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <TradingListing>[]);
    }

    return _listingsCollection
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TradingListing.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> closeListing(String listingId) async {
    await _listingsCollection.doc(listingId).set({
      'active': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> reopenListing(String listingId) async {
    await _listingsCollection.doc(listingId).set({
      'active': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> deleteListing(String listingId) async {
    await _listingsCollection.doc(listingId).delete();
  }

  Future<void> requestCollectionView(TradingListing listing) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');
    if (listing.ownerUid == uid) {
      throw Exception('You cannot request your own collection view.');
    }

    await ensureTradingProfileExists();
    final profile = await getTradingProfile();
    await _safeNotify(
      targetUid: listing.ownerUid,
      type: TradingNotificationType.collectionRequest,
      title: 'Tailored offer request',
      body:
          '${profile.displayName} asked to compare dupes and missing blueprints so they can build a tailored offer for ${listing.offeredItem}.',
      listingId: listing.id,
    );
  }

  Future<TradingListing?> getListingById(String listingId) async {
    final snap = await _listingsCollection.doc(listingId).get();
    if (!snap.exists) return null;
    return TradingListing.fromMap(snap.data()!);
  }

  Future<void> createOffer({
    required TradingListing listing,
    required String offeredBlueprintText,
    required int smallBundles,
    required int mediumBundles,
    required int largeBundles,
    required bool includesResources,
    required String resourcesText,
    required String note,
    List<String> offeredTradeItemIds = const <String>[],
    List<String> offeredTradeItemNames = const <String>[],
    ArcExactTradeBundleOffer? exactBundleOffer,
    bool isGiveawayClaim = false,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    if (exactBundleOffer != null) {
      final templateMatches = listing.acceptedBundles.where(
        (bundle) => bundle.id == exactBundleOffer.templateId && bundle.active,
      );
      if (templateMatches.isEmpty) {
        throw Exception('The selected accepted bundle is no longer available.');
      }
      final result = const ArcTradeBundleEngine().compare(
        template: templateMatches.first,
        offer: exactBundleOffer,
      );
      if (!result.isExact && !listing.allowCustomBundleOffers) {
        final details = <String>[
          ...result.missing.map((item) => 'Missing $item'),
          ...result.incorrect,
          ...result.unexpected.map((item) => 'Unexpected $item'),
        ];
        throw Exception(
          'Offer does not match the selected bundle. ${details.join('; ')}',
        );
      }
    }

    _ensureOfferInputSafe(
      listing: listing,
      senderUid: uid,
      offeredBlueprintText: offeredBlueprintText,
      smallBundles: smallBundles,
      mediumBundles: mediumBundles,
      largeBundles: largeBundles,
      includesResources: includesResources,
      resourcesText: resourcesText,
      offeredTradeItemIds: exactBundleOffer == null
          ? offeredTradeItemIds
          : exactBundleOffer.components
                .map((component) => component.itemId)
                .toList(growable: false),
      isGiveawayClaim: isGiveawayClaim,
    );
    await _ensureNoDuplicatePendingOffer(senderUid: uid, listingId: listing.id);
    await _ensureListingOfferCapacity(listing);

    await ensureTradingProfileExists();
    final profile = await getTradingProfile();

    final offerRef = _offersCollection.doc();
    final now = DateTime.now();
    final seedTotal =
        (smallBundles * 10) + (mediumBundles * 50) + (largeBundles * 100);
    final structuredOfferItemIds = exactBundleOffer?.components
        .map((component) => component.itemId)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final structuredOfferItemNames = exactBundleOffer?.components
        .map((component) => component.itemName)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    final offer = TradingOffer(
      id: offerRef.id,
      listingId: listing.id,
      senderUid: uid,
      receiverUid: listing.ownerUid,
      senderName: profile.displayName,
      senderGamerTag: profile.gamerTag,
      senderPlatform: profile.preferredPlatform,
      offeredBlueprintText: offeredBlueprintText.trim(),
      smallBundles: smallBundles,
      mediumBundles: mediumBundles,
      largeBundles: largeBundles,
      seedTotal: seedTotal,
      includesResources: includesResources,
      resourcesText: resourcesText.trim(),
      offeredTradeItemIds: structuredOfferItemIds?.isNotEmpty ?? false
          ? structuredOfferItemIds!
          : offeredTradeItemIds,
      offeredTradeItemNames: structuredOfferItemNames?.isNotEmpty ?? false
          ? structuredOfferItemNames!
          : offeredTradeItemNames,
      isGiveawayClaim: isGiveawayClaim || listing.wantsNothing,
      exactBundleOffer: exactBundleOffer,
      note: note.trim(),
      status: TradingOfferStatus.pending,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(hours: 72)),
    );

    await offerRef.set(offer.toMap());

    await _safeNotify(
      targetUid: listing.ownerUid,
      type: TradingNotificationType.offerReceived,
      title: listing.wantsNothing
          ? 'Giveaway claim received'
          : 'New offer received',
      body: listing.wantsNothing
          ? '${profile.displayName} claimed your giveaway for ${listing.offeredItem}.'
          : '${profile.displayName} sent an offer for ${listing.offeredItem}.',
      listingId: listing.id,
      offerId: offer.id,
    );
  }

  Future<void> acceptOffer(TradingOffer offer) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('You must be signed in to accept an offer.');
    }
    if (offer.receiverUid != uid) {
      throw Exception('Only the receiving trader can accept this offer.');
    }
    if (offer.status != TradingOfferStatus.pending) {
      throw Exception('Only pending offers can be accepted.');
    }
    if (offer.isExpiredAt(DateTime.now())) {
      throw Exception('This offer has expired.');
    }

    final listingSnap = await _listingsCollection.doc(offer.listingId).get();
    if (!listingSnap.exists) {
      throw Exception('The listing linked to this offer no longer exists.');
    }

    final listing = TradingListing.fromMap(listingSnap.data()!);
    if (listing.ownerUid != uid) {
      throw Exception('Only the listing owner can accept this offer.');
    }
    if (!listing.active) {
      throw Exception('This listing is no longer active.');
    }
    if (listing.expiresAt.isBefore(DateTime.now())) {
      throw Exception('This listing has expired.');
    }
    await _ensureNoSessionAlreadyExistsForOffer(offer.id);

    Future<String> loadEmbarkId(String traderUid) async {
      try {
        final snap = await _tradingProfileDoc(traderUid).get();
        final data = snap.data() ?? <String, dynamic>{};
        final value = data['embarkId'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      } catch (_) {
        // Embark ID hydration is best effort and must not block accepting a trade.
      }
      return '';
    }

    final now = DateTime.now();
    final traderOneEmbarkId = await loadEmbarkId(listing.ownerUid);
    final traderTwoEmbarkId = await loadEmbarkId(offer.senderUid);

    final sessionRef = _sessionsCollection.doc();
    final session = TradingSession(
      id: sessionRef.id,
      listingId: offer.listingId,
      offerId: offer.id,
      traderOneUid: listing.ownerUid,
      traderTwoUid: offer.senderUid,
      traderOneName: listing.traderName,
      traderTwoName: offer.senderName,
      scheduledAt: null,
      timezone: 'Europe/London',
      protocolType: TradingProtocolType.sequentialSafePocketSwap,
      status: TradingSessionStatus.pending,
      traderOneEmbarkId: traderOneEmbarkId,
      traderTwoEmbarkId: traderTwoEmbarkId,
      traderOneSharedEmbarkId: traderOneEmbarkId.isNotEmpty,
      traderTwoSharedEmbarkId: traderTwoEmbarkId.isNotEmpty,
      traderOneReady: false,
      traderTwoReady: false,
      dropOrderAssigned: false,
      firstDropUid: '',
      traderOneMarkedComplete: false,
      traderTwoMarkedComplete: false,
      traderOneMarkedNoShow: false,
      traderTwoMarkedNoShow: false,
      traderOneMarkedBetrayal: false,
      traderTwoMarkedBetrayal: false,
      bookingOptions: const [],
      selectedBooking: null,
      bookingProposedByUid: '',
      bookingProposedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();

    batch.update(_offersCollection.doc(offer.id), {
      'status': TradingOfferStatus.accepted.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    batch.set(_listingsCollection.doc(offer.listingId), {
      'active': false,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(sessionRef, session.toMap());

    await batch.commit();

    try {
      final pendingOffers = await _offersCollection
          .where('listingId', isEqualTo: offer.listingId)
          .where('status', isEqualTo: TradingOfferStatus.pending.name)
          .get();

      for (final pendingDoc in pendingOffers.docs) {
        if (pendingDoc.id == offer.id) continue;
        try {
          await pendingDoc.reference.update({
            'status': TradingOfferStatus.declined.name,
            'updatedAt': Timestamp.fromDate(now),
          });
        } catch (_) {
          // Best effort only.
        }
      }
    } catch (_) {
      // Best effort only.
    }

    await _safeNotify(
      targetUid: offer.senderUid,
      type: TradingNotificationType.offerAccepted,
      title: 'Offer accepted',
      body:
          '${listing.traderName} accepted your offer and created a trade session. Open the Session Planner to confirm a time.',
      listingId: offer.listingId,
      offerId: offer.id,
      sessionId: session.id,
    );

    await _safeNotify(
      targetUid: listing.ownerUid,
      type: TradingNotificationType.sessionCreated,
      title: 'Trade session created',
      body:
          'Your accepted trade is now live in the Session Planner. Book a time, confirm Embark IDs, and send the in-game friend request.',
      listingId: offer.listingId,
      offerId: offer.id,
      sessionId: session.id,
    );
  }

  Future<void> declineOffer(TradingOffer offer) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('You must be signed in to decline this offer.');
    }
    if (offer.receiverUid != uid) {
      throw Exception('Only the receiving trader can decline this offer.');
    }
    if (offer.status != TradingOfferStatus.pending) {
      throw Exception('Only pending offers can be declined.');
    }

    final now = DateTime.now();

    await _offersCollection.doc(offer.id).update({
      'status': TradingOfferStatus.declined.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await _safeNotify(
      targetUid: offer.senderUid,
      type: TradingNotificationType.offerDeclined,
      title: 'Offer declined',
      body:
          '${offer.receiverUid == uid ? 'The listing owner' : 'A trader'} declined your offer.',
      listingId: offer.listingId,
      offerId: offer.id,
    );
  }

  Future<void> declineAllPendingOffersForListing(String listingId) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('You must be signed in to decline offers.');
    }

    final pendingOffers = await _offersCollection
        .where('listingId', isEqualTo: listingId)
        .where('receiverUid', isEqualTo: uid)
        .where('status', isEqualTo: TradingOfferStatus.pending.name)
        .get();

    if (pendingOffers.docs.isEmpty) return;

    final now = DateTime.now();
    final batch = _firestore.batch();
    for (final doc in pendingOffers.docs) {
      batch.update(doc.reference, {
        'status': TradingOfferStatus.declined.name,
        'updatedAt': Timestamp.fromDate(now),
      });
    }
    await batch.commit();

    for (final doc in pendingOffers.docs) {
      final offer = TradingOffer.fromMap(doc.data());
      await _safeNotify(
        targetUid: offer.senderUid,
        type: TradingNotificationType.offerDeclined,
        title: 'Offer declined',
        body: 'The listing owner declined pending offers for this listing.',
        listingId: offer.listingId,
        offerId: offer.id,
      );
    }
  }

  Future<void> cancelOffer(TradingOffer offer) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('You must be signed in to cancel this offer.');
    }
    if (offer.senderUid != uid) {
      throw Exception('Only the sending trader can cancel this offer.');
    }
    if (offer.status != TradingOfferStatus.pending) {
      throw Exception('Only pending offers can be cancelled.');
    }

    final now = DateTime.now();

    await _offersCollection.doc(offer.id).update({
      'status': TradingOfferStatus.cancelled.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await _safeNotify(
      targetUid: offer.receiverUid,
      type: TradingNotificationType.offerCancelled,
      title: 'Offer cancelled',
      body: '${offer.senderName} cancelled a pending offer.',
      listingId: offer.listingId,
      offerId: offer.id,
    );
  }

  Stream<List<TradingOffer>> watchMyOffers() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <TradingOffer>[]);
    }

    final senderQuery = _offersCollection
        .where('senderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    final receiverQuery = _offersCollection
        .where('receiverUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    late StreamController<List<TradingOffer>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? senderSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? receiverSub;

    QuerySnapshot<Map<String, dynamic>>? senderLatest;
    QuerySnapshot<Map<String, dynamic>>? receiverLatest;

    List<TradingOffer> buildCombined() {
      final combined = <String, TradingOffer>{};

      for (final doc in senderLatest?.docs ?? const []) {
        combined[doc.id] = TradingOffer.fromMap(doc.data());
      }
      for (final doc in receiverLatest?.docs ?? const []) {
        combined[doc.id] = TradingOffer.fromMap(doc.data());
      }

      final offers = combined.values.toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return offers;
    }

    void emitIfReady() {
      if (senderLatest == null ||
          receiverLatest == null ||
          controller.isClosed) {
        return;
      }
      controller.add(buildCombined());
    }

    controller = StreamController<List<TradingOffer>>.broadcast(
      onListen: () {
        senderSub = senderQuery.snapshots().listen((snapshot) {
          senderLatest = snapshot;
          emitIfReady();
        }, onError: controller.addError);
        receiverSub = receiverQuery.snapshots().listen((snapshot) {
          receiverLatest = snapshot;
          emitIfReady();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await senderSub?.cancel();
        await receiverSub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<List<TradingSession>> watchMySessions() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <TradingSession>[]);
    }

    final traderOneQuery = _sessionsCollection
        .where('traderOneUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    final traderTwoQuery = _sessionsCollection
        .where('traderTwoUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    late StreamController<List<TradingSession>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? traderOneSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? traderTwoSub;

    QuerySnapshot<Map<String, dynamic>>? traderOneLatest;
    QuerySnapshot<Map<String, dynamic>>? traderTwoLatest;

    List<TradingSession> buildCombined() {
      final combined = <String, TradingSession>{};

      for (final doc in traderOneLatest?.docs ?? const []) {
        combined[doc.id] = TradingSession.fromMap(doc.data());
      }
      for (final doc in traderTwoLatest?.docs ?? const []) {
        combined[doc.id] = TradingSession.fromMap(doc.data());
      }

      final sessions = combined.values.toList()
        ..sort((a, b) {
          final aDate =
              a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return sessions;
    }

    void emitIfReady() {
      if (traderOneLatest == null ||
          traderTwoLatest == null ||
          controller.isClosed) {
        return;
      }
      controller.add(buildCombined());
    }

    controller = StreamController<List<TradingSession>>.broadcast(
      onListen: () {
        traderOneSub = traderOneQuery.snapshots().listen((snapshot) {
          traderOneLatest = snapshot;
          emitIfReady();
        }, onError: controller.addError);
        traderTwoSub = traderTwoQuery.snapshots().listen((snapshot) {
          traderTwoLatest = snapshot;
          emitIfReady();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await traderOneSub?.cancel();
        await traderTwoSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> submitBookingOptions({
    required TradingSession session,
    required List<TradingBookingOption> bookingOptions,
    String timezone = 'Europe/London',
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');
    if (uid != session.traderOneUid && uid != session.traderTwoUid) {
      throw Exception('You are not part of this trade session.');
    }
    if (bookingOptions.length != 3) {
      throw Exception('Provide exactly 3 booking days.');
    }
    for (final option in bookingOptions) {
      if (option.times.length != 3) {
        throw Exception(
          'Each booking day must contain exactly 3 time options.',
        );
      }
    }

    final normalizedDays = bookingOptions
        .map(
          (option) =>
              DateTime(option.day.year, option.day.month, option.day.day),
        )
        .toSet();
    if (normalizedDays.length != 3) {
      throw Exception('Each booking option day must be unique.');
    }

    final now = DateTime.now();
    final targetUid = _otherTraderUid(session, uid);

    final batch = _firestore.batch();
    batch.update(_sessionsCollection.doc(session.id), {
      'bookingOptions': bookingOptions.map((option) => option.toMap()).toList(),
      'selectedBooking': null,
      'scheduledAt': null,
      'bookingProposedByUid': uid,
      'bookingProposedAt': Timestamp.fromDate(now),
      'timezone': timezone,
      'status': TradingSessionStatus.pending.name,
      'traderOneReady': false,
      'traderTwoReady': false,
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();

    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionUpdated,
      title: 'Trade times proposed',
      body: 'Your trading partner proposed 9 booking options for the session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> selectBookingOption({
    required TradingSession session,
    required DateTime selected,
  }) async {
    final uid = currentUid;
    _ensureSessionParticipant(session, uid);
    _ensureSessionCanBeUpdated(session);

    if (session.bookingProposedByUid.isNotEmpty &&
        session.bookingProposedByUid == uid) {
      throw Exception(
        'Wait for the other trader to choose one of your proposed slots.',
      );
    }

    final allowedTimes = session.bookingOptions
        .expand((option) => option.times)
        .map((value) => value.millisecondsSinceEpoch)
        .toSet();

    if (!allowedTimes.contains(selected.millisecondsSinceEpoch)) {
      throw Exception('That booking option is no longer available.');
    }

    Future<String> loadEmbarkId(String traderUid, String fallback) async {
      try {
        final snap = await _tradingProfileDoc(traderUid).get();
        final data = snap.data() ?? <String, dynamic>{};
        final value = data['embarkId'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      } catch (_) {
        // Best effort only.
      }
      return fallback.trim();
    }

    final targetUid = _otherTraderUid(session, uid!);
    final now = DateTime.now();

    final traderOneEmbarkId = await loadEmbarkId(
      session.traderOneUid,
      session.traderOneEmbarkId,
    );
    final traderTwoEmbarkId = await loadEmbarkId(
      session.traderTwoUid,
      session.traderTwoEmbarkId,
    );

    final updates = <String, dynamic>{
      'selectedBooking': Timestamp.fromDate(selected),
      'scheduledAt': Timestamp.fromDate(selected),
      'status': TradingSessionStatus.scheduled.name,
      'updatedAt': Timestamp.fromDate(now),
      'traderOneEmbarkId': traderOneEmbarkId,
      'traderTwoEmbarkId': traderTwoEmbarkId,
      'traderOneSharedEmbarkId': traderOneEmbarkId.isNotEmpty,
      'traderTwoSharedEmbarkId': traderTwoEmbarkId.isNotEmpty,
    };

    await _sessionsCollection.doc(session.id).update(updates);

    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionUpdated,
      title: 'Trade time confirmed',
      body:
          'A booking slot has been locked in. Saved Embark IDs have been added to the Session Planner where available. Send the in-game friend request before the trade.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );

    try {
      final otherTraderName = targetUid == session.traderOneUid
          ? session.traderOneName
          : session.traderTwoName;

      await TradingPushService.instance.scheduleTradeReminder(
        sessionId: session.id,
        scheduledAt: selected,
        otherTraderName: otherTraderName,
        listingId: session.listingId,
        offerId: session.offerId,
      );
    } catch (_) {
      // Never break the booking flow if reminder scheduling fails.
    }
  }

  Future<void> updateSessionSchedule({
    required TradingSession session,
    required DateTime scheduledAt,
    String timezone = 'Europe/London',
  }) async {
    await selectBookingOption(
      session: session.copyWith(
        bookingOptions: const <TradingBookingOption>[],
        selectedBooking: scheduledAt,
        scheduledAt: scheduledAt,
        timezone: timezone,
      ),
      selected: scheduledAt,
    );
  }

  Future<void> updateSessionProtocol({
    required TradingSession session,
    required TradingProtocolType protocol,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');
    if (uid != session.traderOneUid && uid != session.traderTwoUid) {
      throw Exception('You are not part of this trade session.');
    }

    await _sessionsCollection.doc(session.id).update({
      'protocolType': protocol.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> shareMyEmbarkId(TradingSession session, String embarkId) async {
    final uid = currentUid;
    _ensureSessionParticipant(session, uid);
    _ensureSessionCanBeUpdated(session);

    final trimmedEmbarkId = embarkId.trim();
    final now = DateTime.now();
    final updates = <String, dynamic>{'updatedAt': Timestamp.fromDate(now)};

    if (uid == session.traderOneUid) {
      updates['traderOneEmbarkId'] = trimmedEmbarkId;
      updates['traderOneSharedEmbarkId'] = trimmedEmbarkId.isNotEmpty;
    } else {
      updates['traderTwoEmbarkId'] = trimmedEmbarkId;
      updates['traderTwoSharedEmbarkId'] = trimmedEmbarkId.isNotEmpty;
    }

    await _sessionsCollection.doc(session.id).update(updates);

    if (trimmedEmbarkId.isNotEmpty) {
      try {
        final profile = await getTradingProfile();
        if (profile.embarkId.trim().isEmpty) {
          await saveEmbarkId(trimmedEmbarkId);
        }
      } catch (_) {
        // Best effort only. Session share should still succeed.
      }
    }

    await _safeNotify(
      targetUid: _otherTraderUid(session, uid!),
      type: TradingNotificationType.sessionUpdated,
      title: 'Embark ID shared',
      body:
          'Your trading partner shared their Embark ID for the active session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> setMyReadyState(TradingSession session, bool ready) async {
    final uid = currentUid;
    _ensureSessionParticipant(session, uid);
    _ensureSessionCanBeUpdated(session);

    final nextSession = uid == session.traderOneUid
        ? session.copyWith(traderOneReady: ready, updatedAt: DateTime.now())
        : session.copyWith(traderTwoReady: ready, updatedAt: DateTime.now());

    final now = DateTime.now();
    final targetUid = _otherTraderUid(session, uid!);

    final batch = _firestore.batch();
    batch.update(_sessionsCollection.doc(session.id), {
      if (uid == session.traderOneUid) 'traderOneReady': ready,
      if (uid == session.traderTwoUid) 'traderTwoReady': ready,
      'status': _sessionStatusValue(_deriveSessionStatus(nextSession)),
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();

    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionReady,
      title: ready ? 'Trader marked ready' : 'Trader un-readied',
      body: ready
          ? 'Your trading partner marked themselves ready for the swap.'
          : 'Your trading partner is no longer marked ready.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> assignFirstDrop({
    required TradingSession session,
    required String firstDropUid,
  }) async {
    final uid = currentUid;
    _ensureSessionParticipant(session, uid);
    _ensureSessionCanBeUpdated(session);
    if (firstDropUid != session.traderOneUid &&
        firstDropUid != session.traderTwoUid) {
      throw Exception('First drop must be one of the session traders.');
    }

    final now = DateTime.now();
    final chosenName = firstDropUid == session.traderOneUid
        ? session.traderOneName
        : session.traderTwoName;
    final targetUid = _otherTraderUid(session, uid!);

    final batch = _firestore.batch();
    batch.update(_sessionsCollection.doc(session.id), {
      'dropOrderAssigned': true,
      'firstDropUid': firstDropUid,
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();

    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionUpdated,
      title: 'First drop assigned',
      body:
          '$chosenName is set to make the first drop in the active trade session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> markMySessionOutcome({
    required TradingSession session,
    required TradingSessionStatus outcome,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');
    if (uid != session.traderOneUid && uid != session.traderTwoUid) {
      throw Exception('You are not part of this trade session.');
    }

    _ensureSessionCanBeUpdated(session);
    if (outcome != TradingSessionStatus.completed &&
        outcome != TradingSessionStatus.noShow &&
        outcome != TradingSessionStatus.betrayal) {
      throw Exception(
        'Choose completed, no-show or betrayal as the final session outcome.',
      );
    }

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (uid == session.traderOneUid) {
      updates['traderOneMarkedComplete'] =
          outcome == TradingSessionStatus.completed;
      updates['traderOneMarkedNoShow'] = outcome == TradingSessionStatus.noShow;
      updates['traderOneMarkedBetrayal'] =
          outcome == TradingSessionStatus.betrayal;
    } else {
      updates['traderTwoMarkedComplete'] =
          outcome == TradingSessionStatus.completed;
      updates['traderTwoMarkedNoShow'] = outcome == TradingSessionStatus.noShow;
      updates['traderTwoMarkedBetrayal'] =
          outcome == TradingSessionStatus.betrayal;
    }

    final merged = uid == session.traderOneUid
        ? session.copyWith(
            traderOneMarkedComplete: outcome == TradingSessionStatus.completed,
            traderOneMarkedNoShow: outcome == TradingSessionStatus.noShow,
            traderOneMarkedBetrayal: outcome == TradingSessionStatus.betrayal,
            updatedAt: DateTime.now(),
          )
        : session.copyWith(
            traderTwoMarkedComplete: outcome == TradingSessionStatus.completed,
            traderTwoMarkedNoShow: outcome == TradingSessionStatus.noShow,
            traderTwoMarkedBetrayal: outcome == TradingSessionStatus.betrayal,
            updatedAt: DateTime.now(),
          );

    final derivedStatus = _deriveSessionStatus(merged);
    updates['status'] = _sessionStatusValue(derivedStatus);

    final targetUid = _otherTraderUid(session, uid);

    final batch = _firestore.batch();
    batch.update(_sessionsCollection.doc(session.id), updates);
    await batch.commit();

    if (derivedStatus == TradingSessionStatus.completed) {
      await ArcOperationsRepository(
        firestore: _firestore,
        auth: _auth,
      ).recordTradeCompleted(sessionId: session.id);
    }

    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionOutcome,
      title: 'Trade session updated',
      body:
          'Your trading partner recorded a ${outcome.name} outcome for the session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> seedDemoSessionIfEmpty() async {
    return;
  }

  Future<void> _recordListingCreated(String listingId) async {
    await ArcOperationsRepository(
      firestore: _firestore,
      auth: _auth,
    ).recordListingCreated(listingId: listingId);
  }
}
