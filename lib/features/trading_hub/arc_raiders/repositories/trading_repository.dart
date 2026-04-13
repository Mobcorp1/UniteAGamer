import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_profile.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';

class TradingRepository {
  TradingRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _tradingProfileDoc(String uid) {
    return _userDoc(uid).collection('trading_activity').doc('profile');
  }

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

  String _blueprintNameFromId(String blueprintId) {
    final match = ArcBlueprintSeedData.blueprints.where(
      (blueprint) => blueprint.id == blueprintId,
    );
    if (match.isEmpty) return blueprintId;
    return match.first.name;
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
    if (session.scheduledAt != null) {
      return TradingSessionStatus.scheduled;
    }
    return TradingSessionStatus.pending;
  }

  String _sessionStatusValue(TradingSessionStatus status) {
    return status == TradingSessionStatus.noShow ? 'no_show' : status.name;
  }

  Future<void> _safeNotify({
    required String targetUid,
    required TradingNotificationType type,
    required String title,
    required String body,
    String listingId = '',
    String offerId = '',
    String sessionId = '',
  }) async {
    final actorUid = currentUid;
    if (actorUid == null || targetUid.isEmpty || targetUid == actorUid) return;

    try {
      final ref = _notificationsCollection.doc();
      final now = DateTime.now();
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
        read: false,
        createdAt: now,
        updatedAt: now,
      );
      await ref.set(notification.toMap());
    } catch (_) {
      // Notification failures should never block trading actions.
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

  Future<TradingProfile> getTradingProfile() async {
    final uid = currentUid;
    if (uid == null) return TradingProfile.empty('');

    await ensureTradingProfileExists();
    final snap = await _tradingProfileDoc(uid).get();

    if (!snap.exists) return TradingProfile.empty(uid);
    return TradingProfile.fromMap(snap.data() ?? <String, dynamic>{});
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
        .map((snapshot) => snapshot.docs
            .map((doc) => TradingNotification.fromMap(doc.data()))
            .toList(growable: false));
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).set({
      'read': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
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
    final when = session.scheduledAt == null
        ? 'Time still to be confirmed'
        : '${session.scheduledAt!.day.toString().padLeft(2, '0')}/'
            '${session.scheduledAt!.month.toString().padLeft(2, '0')}/'
            '${session.scheduledAt!.year} '
            '${session.scheduledAt!.hour.toString().padLeft(2, '0')}:'
            '${session.scheduledAt!.minute.toString().padLeft(2, '0')}';

    return 'ARC Raiders trade invite\n\n'
        'Traders: ${session.traderOneName} ↔ ${session.traderTwoName}\n'
        'When: $when (${session.timezone})\n'
        'Protocol: ${session.protocolLabel}\n'
        'Session ID: ${session.id}\n'
        'Listing ID: ${session.listingId}\n\n'
        'Before starting:\n'
        '- share Embark IDs\n'
        '- confirm first drop\n'
        '- mark ready in the app\n';
  }

  Future<void> createListing({
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
    bool tradeAsBundle = true,
    bool allowPartialOffers = false,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await ensureTradingProfileExists();
    final profile = await getTradingProfile();

    final listingRef = _listingsCollection.doc();
    final now = DateTime.now();

    final seedTotal =
        (smallBundles * 10) + (mediumBundles * 50) + (largeBundles * 100);

    final title = listingType == TradingListingType.openToOffers
        ? '$offeredItem • Open Offer'
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
      listingType: listingType,
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
      expiresAt: now.add(expiryDuration),
      notes: notes.trim(),
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    await listingRef.set(listing.toMap());
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
        .map((snapshot) => snapshot.docs
            .map((doc) => TradingListing.fromMap(doc.data()))
            .toList(growable: false));
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

  Future<void> createOffer({
    required TradingListing listing,
    required String offeredBlueprintText,
    required int smallBundles,
    required int mediumBundles,
    required int largeBundles,
    required bool includesResources,
    required String resourcesText,
    required String note,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await ensureTradingProfileExists();
    final profile = await getTradingProfile();

    final offerRef = _offersCollection.doc();
    final now = DateTime.now();
    final seedTotal =
        (smallBundles * 10) + (mediumBundles * 50) + (largeBundles * 100);

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
      note: note.trim(),
      status: TradingOfferStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await offerRef.set(offer.toMap());

    await _safeNotify(
      targetUid: listing.ownerUid,
      type: TradingNotificationType.offerReceived,
      title: 'New offer received',
      body: '${profile.displayName} sent an offer for ${listing.offeredItem}.',
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

    final listingSnap = await _listingsCollection.doc(offer.listingId).get();
    if (!listingSnap.exists) {
      throw Exception('The listing linked to this offer no longer exists.');
    }
    final listing = TradingListing.fromMap(listingSnap.data()!);
    if (listing.ownerUid != uid) {
      throw Exception('Only the listing owner can accept this offer.');
    }

    final now = DateTime.now();
    final pendingOffers = await _offersCollection
        .where('listingId', isEqualTo: offer.listingId)
        .where('status', isEqualTo: TradingOfferStatus.pending.name)
        .get();

    final sessionRef = _sessionsCollection.doc();
    final session = TradingSession(
      id: sessionRef.id,
      listingId: offer.listingId,
      offerId: offer.id,
      traderOneUid: listing.ownerUid,
      traderTwoUid: offer.senderUid,
      traderOneName: listing.traderName,
      traderTwoName: offer.senderName,
      scheduledAt: now.add(const Duration(days: 1)),
      timezone: 'Europe/London',
      protocolType: TradingProtocolType.sequentialSafePocketSwap,
      status: TradingSessionStatus.pending,
      traderOneEmbarkId: '',
      traderTwoEmbarkId: '',
      traderOneSharedEmbarkId: false,
      traderTwoSharedEmbarkId: false,
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
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();
    batch.update(_offersCollection.doc(offer.id), {
      'status': TradingOfferStatus.accepted.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    for (final pendingDoc in pendingOffers.docs) {
      if (pendingDoc.id == offer.id) continue;
      batch.update(pendingDoc.reference, {
        'status': TradingOfferStatus.declined.name,
        'updatedAt': Timestamp.fromDate(now),
      });
    }

    batch.set(_listingsCollection.doc(offer.listingId), {
      'active': false,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(sessionRef, session.toMap());
    await batch.commit();

    await _safeNotify(
      targetUid: offer.senderUid,
      type: TradingNotificationType.offerAccepted,
      title: 'Offer accepted',
      body: '${listing.traderName} accepted your offer and created a trade session.',
      listingId: offer.listingId,
      offerId: offer.id,
      sessionId: session.id,
    );
    await _safeNotify(
      targetUid: listing.ownerUid,
      type: TradingNotificationType.sessionCreated,
      title: 'Trade session created',
      body: 'Your accepted trade is now live. Book a time and share Embark IDs.',
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
      body: '${offer.receiverUid == uid ? 'The listing owner' : 'A trader'} declined your offer.',
      listingId: offer.listingId,
      offerId: offer.id,
    );
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

    return senderQuery.snapshots().asyncMap((senderSnap) async {
      final receiverSnap = await receiverQuery.get();
      final combined = <String, TradingOffer>{};

      for (final doc in senderSnap.docs) {
        combined[doc.id] = TradingOffer.fromMap(doc.data());
      }
      for (final doc in receiverSnap.docs) {
        combined[doc.id] = TradingOffer.fromMap(doc.data());
      }

      final offers = combined.values.toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return offers;
    });
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

    return traderOneQuery.snapshots().asyncMap((traderOneSnap) async {
      final traderTwoSnap = await traderTwoQuery.get();

      final combined = <String, TradingSession>{};

      for (final doc in traderOneSnap.docs) {
        combined[doc.id] = TradingSession.fromMap(doc.data());
      }
      for (final doc in traderTwoSnap.docs) {
        combined[doc.id] = TradingSession.fromMap(doc.data());
      }

      final sessions = combined.values.toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return sessions;
    });
  }

  Future<void> updateSessionSchedule({
    required TradingSession session,
    required DateTime scheduledAt,
    String timezone = 'Europe/London',
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');
    if (uid != session.traderOneUid && uid != session.traderTwoUid) {
      throw Exception('You are not part of this trade session.');
    }

    await _sessionsCollection.doc(session.id).update({
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'timezone': timezone,
      'status': TradingSessionStatus.scheduled.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final targetUid = uid == session.traderOneUid
        ? session.traderTwoUid
        : session.traderOneUid;
    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionUpdated,
      title: 'Trade time booked',
      body: 'A trade window was booked for your active ARC Raiders session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
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
    if (uid == null) throw Exception('You must be signed in.');

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (uid == session.traderOneUid) {
      updates['traderOneEmbarkId'] = embarkId.trim();
      updates['traderOneSharedEmbarkId'] = embarkId.trim().isNotEmpty;
    } else if (uid == session.traderTwoUid) {
      updates['traderTwoEmbarkId'] = embarkId.trim();
      updates['traderTwoSharedEmbarkId'] = embarkId.trim().isNotEmpty;
    } else {
      throw Exception('You are not part of this trade session.');
    }

    await _sessionsCollection.doc(session.id).update(updates);

    final targetUid = uid == session.traderOneUid
        ? session.traderTwoUid
        : session.traderOneUid;
    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionUpdated,
      title: 'Embark ID shared',
      body: 'Your trading partner shared their Embark ID for the active session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> setMyReadyState(TradingSession session, bool ready) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');

    final nextSession = uid == session.traderOneUid
        ? session.copyWith(traderOneReady: ready, updatedAt: DateTime.now())
        : uid == session.traderTwoUid
            ? session.copyWith(traderTwoReady: ready, updatedAt: DateTime.now())
            : (throw Exception('You are not part of this trade session.'));

    await _sessionsCollection.doc(session.id).update({
      if (uid == session.traderOneUid) 'traderOneReady': ready,
      if (uid == session.traderTwoUid) 'traderTwoReady': ready,
      'status': _sessionStatusValue(_deriveSessionStatus(nextSession)),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final targetUid = uid == session.traderOneUid
        ? session.traderTwoUid
        : session.traderOneUid;
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
    if (uid == null) throw Exception('You must be signed in.');
    if (uid != session.traderOneUid && uid != session.traderTwoUid) {
      throw Exception('You are not part of this trade session.');
    }
    if (firstDropUid != session.traderOneUid &&
        firstDropUid != session.traderTwoUid) {
      throw Exception('First drop must be one of the session traders.');
    }

    await _sessionsCollection.doc(session.id).update({
      'dropOrderAssigned': true,
      'firstDropUid': firstDropUid,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
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

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (uid == session.traderOneUid) {
      updates['traderOneMarkedComplete'] =
          outcome == TradingSessionStatus.completed;
      updates['traderOneMarkedNoShow'] =
          outcome == TradingSessionStatus.noShow;
      updates['traderOneMarkedBetrayal'] =
          outcome == TradingSessionStatus.betrayal;
    } else {
      updates['traderTwoMarkedComplete'] =
          outcome == TradingSessionStatus.completed;
      updates['traderTwoMarkedNoShow'] =
          outcome == TradingSessionStatus.noShow;
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

    await _sessionsCollection.doc(session.id).update(updates);

    final targetUid = uid == session.traderOneUid
        ? session.traderTwoUid
        : session.traderOneUid;
    await _safeNotify(
      targetUid: targetUid,
      type: TradingNotificationType.sessionOutcome,
      title: 'Trade session updated',
      body: 'Your trading partner recorded a ${outcome.name} outcome for the session.',
      listingId: session.listingId,
      offerId: session.offerId,
      sessionId: session.id,
    );
  }

  Future<void> seedDemoSessionIfEmpty() async {
    return;
  }
}
