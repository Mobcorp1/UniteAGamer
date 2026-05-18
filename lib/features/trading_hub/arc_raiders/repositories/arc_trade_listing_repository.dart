import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/arc_trade_listing.dart';

class ArcTradeListingRepository {
  ArcTradeListingRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('arc_trade_listings');

  Stream<List<ArcTradeListing>> watchMyListings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _collection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcTradeListing.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<ArcTradeListing>> watchOpenListings({
    String? region,
    String? platform,
    String? wantedBlueprintId,
  }) {
    Query<Map<String, dynamic>> query = _collection.where(
      'status',
      isEqualTo: 'open',
    );

    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    }
    if (platform != null && platform.isNotEmpty) {
      query = query.where('platform', isEqualTo: platform);
    }
    if (wantedBlueprintId != null && wantedBlueprintId.isNotEmpty) {
      query = query.where('wantedBlueprintId', isEqualTo: wantedBlueprintId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcTradeListing.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> createListing(ArcTradeListing listing) async {
    final doc = listing.id.isEmpty
        ? _collection.doc()
        : _collection.doc(listing.id);
    final now = DateTime.now();

    await doc.set(
      listing
          .copyWith(
            id: doc.id,
            userId: _auth.currentUser?.uid ?? listing.userId,
            createdAt: now,
            updatedAt: now,
          )
          .toMap(),
    );
  }

  Future<void> closeListing(String listingId) async {
    await _collection.doc(listingId).set({
      'status': 'closed',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> reopenListing(String listingId) async {
    await _collection.doc(listingId).set({
      'status': 'open',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> deleteListing(String listingId) async {
    await _collection.doc(listingId).delete();
  }
}
