import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmartTradeMatch {
  const SmartTradeMatch({
    required this.listingCollection,
    required this.listingId,
    required this.ownerUid,
    required this.offeredItemIds,
    required this.wantedItemIds,
    required this.offeredLabels,
    required this.wantedLabels,
    required this.score,
    required this.scoreLabel,
    required this.reason,
    required this.createdAt,
    required this.rawData,
  });

  final String listingCollection;
  final String listingId;
  final String ownerUid;
  final List<String> offeredItemIds;
  final List<String> wantedItemIds;
  final List<String> offeredLabels;
  final List<String> wantedLabels;
  final int score;
  final String scoreLabel;
  final String reason;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  bool get isPerfect => score >= 100;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'listingCollection': listingCollection,
      'listingId': listingId,
      'ownerUid': ownerUid,
      'offeredItemIds': offeredItemIds,
      'wantedItemIds': wantedItemIds,
      'offeredLabels': offeredLabels,
      'wantedLabels': wantedLabels,
      'score': score,
      'scoreLabel': scoreLabel,
      'reason': reason,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class SmartTradeSuggestion {
  const SmartTradeSuggestion({
    required this.duplicateItemId,
    required this.priorityWantedItemIds,
    required this.bestMatches,
    required this.readyListingDraft,
  });

  final String duplicateItemId;
  final List<String> priorityWantedItemIds;
  final List<SmartTradeMatch> bestMatches;
  final Map<String, dynamic> readyListingDraft;

  bool get hasPerfectMatch => bestMatches.any((match) => match.isPerfect);
  bool get hasAnyMatch => bestMatches.isNotEmpty;
}

class SmartTradeIntelligenceService {
  SmartTradeIntelligenceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const List<String> listingCollections = <String>[
    'arc_trade_listings',
    'trading_listings',
  ];

  String? get currentUid => _auth.currentUser?.uid;

  Future<List<SmartTradeMatch>> findMatchesForDuplicate({
    required String duplicateItemId,
    required List<String> priorityWantedItemIds,
    int limitPerCollection = 80,
  }) async {
    final uid = currentUid;
    if (uid == null) return <SmartTradeMatch>[];

    final normalizedDuplicate = _normalizeId(duplicateItemId);
    final normalizedWanted = priorityWantedItemIds
        .map(_normalizeId)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final results = <SmartTradeMatch>[];

    for (final collection in listingCollections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('active', isEqualTo: true)
          .limit(limitPerCollection)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ownerUid = _stringValue(data, <String>[
          'ownerUid',
          'creatorUid',
          'sellerUid',
          'uid',
        ]);

        if (ownerUid == uid) continue;

        final offeredIds = _extractIds(data, <String>[
          'offeredBlueprintId',
          'offeredItemId',
          'offeredTradeItemId',
          'offeredBlueprintIds',
          'offeredItemIds',
          'offeredTradeItemIds',
          'offeredItems',
          'offeringIds',
        ]);

        final wantedIds = _extractIds(data, <String>[
          'wantedBlueprintId',
          'wantedItemId',
          'wantedTradeItemId',
          'wantedBlueprintIds',
          'wantedItemIds',
          'wantedTradeItemIds',
          'wantedItems',
          'wantingIds',
        ]);

        final offeredLabels = _extractLabels(data, <String>[
          'offeredBlueprintName',
          'offeredItemName',
          'offeredTradeItemName',
          'offeredBlueprintNames',
          'offeredItemNames',
          'offeredTradeItemNames',
          'offeredLabels',
        ]);

        final wantedLabels = _extractLabels(data, <String>[
          'wantedBlueprintName',
          'wantedItemName',
          'wantedTradeItemName',
          'wantedBlueprintNames',
          'wantedItemNames',
          'wantedTradeItemNames',
          'wantedLabels',
        ]);

        if (offeredIds.isEmpty || wantedIds.isEmpty) continue;

        final theyWantYourDuplicate = wantedIds.contains(normalizedDuplicate);
        final offeredPriorityRank = _bestPriorityRank(
          offeredIds,
          normalizedWanted,
        );

        if (!theyWantYourDuplicate && offeredPriorityRank == null) continue;

        if (theyWantYourDuplicate && offeredPriorityRank != null) {
          final score = _scoreForPriorityRank(offeredPriorityRank);
          results.add(
            SmartTradeMatch(
              listingCollection: collection,
              listingId: doc.id,
              ownerUid: ownerUid,
              offeredItemIds: offeredIds,
              wantedItemIds: wantedIds,
              offeredLabels: offeredLabels,
              wantedLabels: wantedLabels,
              score: score,
              scoreLabel: score >= 100 ? 'Perfect Match' : 'Strong Match',
              reason:
                  'They want your duplicate and are offering priority #${offeredPriorityRank + 1}.',
              createdAt: _dateValue(data['createdAt']),
              rawData: data,
            ),
          );
          continue;
        }

        if (theyWantYourDuplicate) {
          results.add(
            SmartTradeMatch(
              listingCollection: collection,
              listingId: doc.id,
              ownerUid: ownerUid,
              offeredItemIds: offeredIds,
              wantedItemIds: wantedIds,
              offeredLabels: offeredLabels,
              wantedLabels: wantedLabels,
              score: 70,
              scoreLabel: 'They Want Yours',
              reason:
                  'They want your duplicate, but they are not currently offering one of your priority targets.',
              createdAt: _dateValue(data['createdAt']),
              rawData: data,
            ),
          );
          continue;
        }

        if (offeredPriorityRank != null) {
          results.add(
            SmartTradeMatch(
              listingCollection: collection,
              listingId: doc.id,
              ownerUid: ownerUid,
              offeredItemIds: offeredIds,
              wantedItemIds: wantedIds,
              offeredLabels: offeredLabels,
              wantedLabels: wantedLabels,
              score: 45 - offeredPriorityRank,
              scoreLabel: 'Priority Seen',
              reason:
                  'They are offering your priority #${offeredPriorityRank + 1}, but they have not listed your duplicate as wanted.',
              createdAt: _dateValue(data['createdAt']),
              rawData: data,
            ),
          );
        }
      }
    }

    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;

      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return results.take(20).toList(growable: false);
  }

  Future<SmartTradeSuggestion> buildSuggestionForDuplicate({
    required String duplicateItemId,
    required List<String> priorityWantedItemIds,
    String? duplicateLabel,
    List<String> priorityWantedLabels = const <String>[],
  }) async {
    final matches = await findMatchesForDuplicate(
      duplicateItemId: duplicateItemId,
      priorityWantedItemIds: priorityWantedItemIds,
    );

    final wantedId = priorityWantedItemIds.isNotEmpty
        ? priorityWantedItemIds.first
        : '';
    final wantedLabel = priorityWantedLabels.isNotEmpty
        ? priorityWantedLabels.first
        : wantedId;

    final listingDraft = <String, dynamic>{
      'offeredBlueprintId': duplicateItemId,
      'offeredBlueprintName': duplicateLabel ?? duplicateItemId,
      'wantedBlueprintId': wantedId,
      'wantedBlueprintName': wantedLabel,
      'active': true,
      'status': 'active',
      'source': 'smart_trade_intelligence',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return SmartTradeSuggestion(
      duplicateItemId: duplicateItemId,
      priorityWantedItemIds: priorityWantedItemIds,
      bestMatches: matches,
      readyListingDraft: listingDraft,
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> createSmartListing({
    required Map<String, dynamic> listingDraft,
    String collection = 'arc_trade_listings',
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('You must be signed in to create a smart listing.');
    }

    final payload = Map<String, dynamic>.from(listingDraft)
      ..['ownerUid'] = uid
      ..['active'] = true
      ..['status'] = 'active'
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    return _firestore.collection(collection).add(payload);
  }

  Future<DocumentReference<Map<String, dynamic>>> createSmartOffer({
    required SmartTradeMatch match,
    required String offeredItemId,
    required String wantedItemId,
    String collection = 'trading_offers',
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('You must be signed in to create a smart offer.');
    }

    return _firestore.collection(collection).add(<String, dynamic>{
      'listingId': match.listingId,
      'listingCollection': match.listingCollection,
      'senderUid': uid,
      'receiverUid': match.ownerUid,
      'offeredBlueprintId': offeredItemId,
      'wantedBlueprintId': wantedItemId,
      'status': 'pending',
      'source': 'smart_trade_intelligence',
      'score': match.score,
      'scoreLabel': match.scoreLabel,
      'reason': match.reason,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int? _bestPriorityRank(
    List<String> offeredIds,
    List<String> wantedPriorityIds,
  ) {
    for (var index = 0; index < wantedPriorityIds.length; index++) {
      if (offeredIds.contains(wantedPriorityIds[index])) {
        return index;
      }
    }
    return null;
  }

  int _scoreForPriorityRank(int rank) {
    if (rank <= 0) return 100;
    if (rank == 1) return 95;
    if (rank == 2) return 90;
    if (rank == 3) return 86;
    if (rank == 4) return 82;
    return 78;
  }

  List<String> _extractIds(Map<String, dynamic> data, List<String> keys) {
    final ids = <String>{};

    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      if (value is String) {
        final normalized = _normalizeId(value);
        if (normalized.isNotEmpty) ids.add(normalized);
        continue;
      }

      if (value is Iterable) {
        for (final item in value) {
          if (item is String) {
            final normalized = _normalizeId(item);
            if (normalized.isNotEmpty) ids.add(normalized);
          } else if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = _stringValue(map, <String>[
              'id',
              'itemId',
              'blueprintId',
              'tradeItemId',
            ]);
            final normalized = _normalizeId(id);
            if (normalized.isNotEmpty) ids.add(normalized);
          }
        }
        continue;
      }

      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final id = _stringValue(map, <String>[
          'id',
          'itemId',
          'blueprintId',
          'tradeItemId',
        ]);
        final normalized = _normalizeId(id);
        if (normalized.isNotEmpty) ids.add(normalized);
      }
    }

    return ids.toList(growable: false);
  }

  List<String> _extractLabels(Map<String, dynamic> data, List<String> keys) {
    final labels = <String>{};

    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      if (value is String && value.trim().isNotEmpty) {
        labels.add(value.trim());
        continue;
      }

      if (value is Iterable) {
        for (final item in value) {
          if (item is String && item.trim().isNotEmpty) {
            labels.add(item.trim());
          } else if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final label = _stringValue(map, <String>['name', 'label', 'title']);
            if (label.trim().isNotEmpty) labels.add(label.trim());
          }
        }
      }
    }

    return labels.toList(growable: false);
  }

  String _stringValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _normalizeId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  DateTime? _dateValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
