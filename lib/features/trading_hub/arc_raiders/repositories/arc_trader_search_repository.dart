import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/arc_trader_search_result.dart';

class ArcTraderSearchRepository {
  ArcTraderSearchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<ArcTraderSearchResult>> searchTraders({
    String? region,
    String? platform,
    String? wantedBlueprintId,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection('arc_trader_profiles').where('visibleInSearch', isEqualTo: true);

    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    }

    if (platform != null && platform.isNotEmpty) {
      query = query.where('platform', isEqualTo: platform);
    }

    final profileSnapshot = await query.get();
    final awaySnapshot = await _firestore.collection('arc_trader_away').get();
    final listingsSnapshot = await _firestore
        .collection('arc_trade_listings')
        .where('status', isEqualTo: 'open')
        .get();

    final awayByUser = <String, bool>{
      for (final doc in awaySnapshot.docs) doc.id: (doc.data()['isAway'] ?? false) as bool,
    };

    final listingsByUser = <String, List<Map<String, dynamic>>>{};
    for (final doc in listingsSnapshot.docs) {
      final data = doc.data();
      final userId = (data['userId'] ?? '') as String;
      if (userId.isEmpty) continue;
      listingsByUser.putIfAbsent(userId, () => []).add(data);
    }

    final results = <ArcTraderSearchResult>[];

    for (final doc in profileSnapshot.docs) {
      final data = doc.data();
      final userId = doc.id;
      final userListings = listingsByUser[userId] ?? const [];
      final matchingCount = wantedBlueprintId == null || wantedBlueprintId.isEmpty
          ? 0
          : userListings.where((item) => item['offeredBlueprintId'] == wantedBlueprintId).length;

      results.add(
        ArcTraderSearchResult(
          userId: userId,
          uagId: (data['uagId'] ?? '') as String,
          uagName: (data['uagName'] ?? '') as String,
          region: (data['region'] ?? '') as String,
          platform: (data['platform'] ?? '') as String,
          visibleInSearch: (data['visibleInSearch'] ?? true) as bool,
          isAway: awayByUser[userId] ?? false,
          openListingsCount: userListings.length,
          matchingOfferCount: matchingCount,
          availabilitySummary: 'Check schedule',
        ),
      );
    }

    results.sort((a, b) {
      final matchCompare = b.matchingOfferCount.compareTo(a.matchingOfferCount);
      if (matchCompare != 0) return matchCompare;
      return b.openListingsCount.compareTo(a.openListingsCount);
    });

    return results;
  }
}
