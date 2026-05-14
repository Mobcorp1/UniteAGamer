import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_item_advice_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_invite.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';

class UagVoiceTradeMarketResult {
  const UagVoiceTradeMarketResult({
    required this.query,
    required this.matchedItemName,
    required this.listings,
  });

  final String query;
  final String matchedItemName;
  final List<TradingListing> listings;
}

class UagVoiceTodayResult<T> {
  const UagVoiceTodayResult({required this.items, this.errorMessage});

  final List<T> items;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
}

class UagVoiceAppContextService {
  UagVoiceAppContextService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('trading_listings');
  CollectionReference<Map<String, dynamic>> get _tradeSessions =>
      _firestore.collection('trading_sessions');
  CollectionReference<Map<String, dynamic>> get _matchInvites =>
      _firestore.collection('arc_match_rider_invites');

  Future<UagVoiceTradeMarketResult> findTradeDemand(String query) async {
    final cleaned = query.trim();
    final item = ArcItemAdviceIndex.search(cleaned).isEmpty
        ? UnifiedItemIndex.findBest(cleaned)
        : ArcItemAdviceIndex.search(cleaned).first;
    final matchedName = item?.name ?? cleaned;
    final aliases = <String>{
      cleaned,
      matchedName,
      if (item != null) item.id,
      if (item != null) ...item.aliases,
    }.map(UnifiedItemIndex.normalize).where((value) => value.isNotEmpty).toSet();

    final uid = currentUid;
    final snapshot = await _listings
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final now = DateTime.now();
    final matches = <TradingListing>[];
    for (final doc in snapshot.docs) {
      final listing = TradingListing.fromMap(doc.data());
      if (uid != null && listing.ownerUid == uid) {
        continue;
      }
      if (!listing.active || listing.expiresAt.isBefore(now)) {
        continue;
      }
      if (_listingWantsAny(listing, aliases)) {
        matches.add(listing);
      }
    }

    matches.sort((a, b) {
      final aScore = _listingOfferScore(a);
      final bScore = _listingOfferScore(b);
      final scoreCompare = bScore.compareTo(aScore);
      if (scoreCompare != 0) return scoreCompare;
      final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });

    return UagVoiceTradeMarketResult(
      query: cleaned,
      matchedItemName: matchedName,
      listings: matches.take(6).toList(growable: false),
    );
  }

  Future<UagVoiceTodayResult<TradingSession>> findTradeSessionsToday() async {
    final uid = currentUid;
    if (uid == null) {
      return const UagVoiceTodayResult<TradingSession>(
        items: <TradingSession>[],
        errorMessage: 'You need to be signed in before I can check trade sessions.',
      );
    }

    try {
      final results = await Future.wait([
        _tradeSessions.where('traderOneUid', isEqualTo: uid).limit(75).get(),
        _tradeSessions.where('traderTwoUid', isEqualTo: uid).limit(75).get(),
      ]);

      final merged = <String, TradingSession>{};
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          merged[doc.id] = TradingSession.fromMap(doc.data());
        }
      }

      final today = merged.values
          .where((session) {
            final scheduledAt = session.effectiveScheduledAt;
            if (scheduledAt == null) return false;
            return _isToday(scheduledAt);
          })
          .toList(growable: false)
        ..sort((a, b) {
          final aTime = a.effectiveScheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.effectiveScheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });

      return UagVoiceTodayResult<TradingSession>(items: today);
    } catch (error) {
      return UagVoiceTodayResult<TradingSession>(
        items: const <TradingSession>[],
        errorMessage: 'I could not check trade sessions: $error',
      );
    }
  }

  Future<UagVoiceTodayResult<ArcMatchRiderInvite>> findMatchActivityToday() async {
    final uid = currentUid;
    if (uid == null) {
      return const UagVoiceTodayResult<ArcMatchRiderInvite>(
        items: <ArcMatchRiderInvite>[],
        errorMessage: 'You need to be signed in before I can check Match Raider activity.',
      );
    }

    try {
      final results = await Future.wait([
        _matchInvites.where('senderUid', isEqualTo: uid).limit(75).get(),
        _matchInvites.where('recipientUid', isEqualTo: uid).limit(75).get(),
      ]);

      final merged = <String, ArcMatchRiderInvite>{};
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          merged[doc.id] = ArcMatchRiderInvite.fromMap(doc.data());
        }
      }

      final today = merged.values
          .where((invite) {
            final date = invite.updatedAt ?? invite.createdAt;
            if (date == null) return false;
            return _isToday(date);
          })
          .toList(growable: false)
        ..sort((a, b) {
          final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      return UagVoiceTodayResult<ArcMatchRiderInvite>(items: today);
    } catch (error) {
      return UagVoiceTodayResult<ArcMatchRiderInvite>(
        items: const <ArcMatchRiderInvite>[],
        errorMessage: 'I could not check Match Raider activity: $error',
      );
    }
  }

  bool _listingWantsAny(TradingListing listing, Set<String> normalizedAliases) {
    final wanted = <String>[
      ...listing.wantedBlueprintNames,
      ...listing.wantedAssetNames,
      ...listing.wantedTradeItemIds,
      ...listing.wantedTradeItemNames,
      listing.wantedText,
      listing.title,
    ].map(UnifiedItemIndex.normalize).where((value) => value.isNotEmpty).toList(growable: false);

    for (final wantedValue in wanted) {
      for (final alias in normalizedAliases) {
        if (wantedValue == alias || wantedValue.contains(alias) || alias.contains(wantedValue)) {
          return true;
        }
      }
    }
    return false;
  }

  int _listingOfferScore(TradingListing listing) {
    var score = 0;
    score += listing.offeredBlueprintNames.length * 24;
    score += listing.offeredTradeItemNames.length * 18;
    score += listing.offeredAssetNames.length * 14;
    score += listing.seedTotalOffered ~/ 10;
    if (listing.completedTrades > 0) score += listing.completedTrades.clamp(0, 25).toInt();
    if (listing.riskLevel == TradingRiskLevel.low) score += 12;
    if (listing.riskLevel == TradingRiskLevel.high) score -= 18;
    if (listing.wantsNothing) score -= 8;
    return score;
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }
}
