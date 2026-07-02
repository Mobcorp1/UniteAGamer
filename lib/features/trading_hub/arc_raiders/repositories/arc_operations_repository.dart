import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';

class ArcOperationsRepository {
  ArcOperationsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _summaryRef(String uid) =>
      _firestore.collection('arc_operation_progress').doc(uid);

  CollectionReference<Map<String, dynamic>> _progressRef(String uid) =>
      _summaryRef(uid).collection('operations');

  CollectionReference<Map<String, dynamic>> _inventoryRef(String uid) =>
      _firestore
          .collection('arc_rewards_inventory')
          .doc(uid)
          .collection('items');

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('trading_activity')
      .doc('profile');

  DocumentReference<Map<String, dynamic>> _equippedRef(String uid) =>
      _firestore.collection('arc_equipped_cosmetics').doc(uid);

  Stream<ArcOperationsUserState> watchUserState() {
    final uid = _uid;
    if (uid == null) return Stream.value(ArcOperationsUserState.empty);

    return _summaryRef(uid).snapshots().asyncMap((summarySnapshot) async {
      final summary = summarySnapshot.data() ?? const <String, dynamic>{};
      final progressSnapshot = await _progressRef(uid).get();
      final inventorySnapshot = await _inventoryRef(uid).get();
      final profileSnapshot = await _profileRef(uid).get();
      final equippedSnapshot = await _equippedRef(uid).get();
      final equippedData = <String, dynamic>{
        ...?equippedSnapshot.data(),
        ...?profileSnapshot.data(),
      };

      final progressById = <String, ArcOperationProgress>{};
      for (final doc in progressSnapshot.docs) {
        progressById[doc.id] = ArcOperationProgress.fromMap(doc.id, doc.data());
      }

      final inventory = inventorySnapshot.docs
          .map((doc) => ArcRewardInventoryItem.fromMap(doc.id, doc.data()))
          .toList();

      return ArcOperationsUserState(
        progressById: progressById,
        inventory: inventory,
        equippedCosmetics: ArcEquippedCosmetics.fromMap(equippedData),
        intelXp: (summary['intelXp'] as num?)?.toInt() ?? 0,
        operationCredits: (summary['operationCredits'] as num?)?.toInt() ?? 0,
        extraTradeSlots: (summary['extraTradeSlots'] as num?)?.toInt() ?? 0,
        extraMatchmakingSlots:
            (summary['extraMatchmakingSlots'] as num?)?.toInt() ?? 0,
      );
    });
  }

  Future<void> trackProgress(ArcOperationTask task, {int amount = 1}) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _progressRef(uid).doc(task.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existing = snapshot.data() ?? const <String, dynamic>{};
      final current = (existing['progress'] as num?)?.toInt() ?? task.progress;
      final next = (current + amount).clamp(0, task.target);
      transaction.set(ref, {
        'operationId': task.id,
        'progress': next,
        'target': task.target,
        'claimed': existing['claimed'] == true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> claimReward(ArcOperationTask task) async {
    final uid = _uid;
    if (uid == null) return;

    final progressRef = _progressRef(uid).doc(task.id);
    final summaryRef = _summaryRef(uid);
    final profileRef = _profileRef(uid);

    await _firestore.runTransaction((transaction) async {
      final progressSnapshot = await transaction.get(progressRef);
      final progressData = progressSnapshot.data() ?? const <String, dynamic>{};
      final progress =
          (progressData['progress'] as num?)?.toInt() ?? task.progress;
      final alreadyClaimed = progressData['claimed'] == true;

      if (progress < task.target || alreadyClaimed) return;

      var xpGain = 0;
      var creditsGain = 0;
      var tradeSlots = 0;
      var matchSlots = 0;
      ArcRewardInventoryItem? firstCosmetic;

      for (final reward in task.rewards) {
        switch (reward.type) {
          case ArcOperationRewardType.intelXp:
            xpGain += reward.amount;
          case ArcOperationRewardType.operationCredit:
            creditsGain += reward.amount;
          case ArcOperationRewardType.tradeSlot:
            tradeSlots += reward.amount;
          case ArcOperationRewardType.matchmakingSlot:
            matchSlots += reward.amount;
          case ArcOperationRewardType.badge:
          case ArcOperationRewardType.title:
          case ArcOperationRewardType.profileFrame:
          case ArcOperationRewardType.profileBanner:
            final item = ArcRewardInventoryItem.fromReward(reward);
            firstCosmetic ??= item;
            transaction.set(_inventoryRef(uid).doc(reward.id), item.toMap());
          case ArcOperationRewardType.premiumTrial:
            creditsGain += reward.amount;
        }
      }

      transaction.set(summaryRef, {
        'intelXp': FieldValue.increment(xpGain),
        'operationCredits': FieldValue.increment(creditsGain),
        'extraTradeSlots': FieldValue.increment(tradeSlots),
        'extraMatchmakingSlots': FieldValue.increment(matchSlots),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (firstCosmetic != null) {
        final update = _equippedUpdateFor(firstCosmetic);
        if (update.isNotEmpty) {
          transaction.set(profileRef, update, SetOptions(merge: true));
        }
      }

      transaction.set(progressRef, {
        'operationId': task.id,
        'progress': progress,
        'target': task.target,
        'claimed': true,
        'claimedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> equipCosmetic(ArcRewardInventoryItem item) async {
    final uid = _uid;
    if (uid == null) return;

    final update = _equippedUpdateFor(item);
    if (update.isEmpty) return;

    await _profileRef(uid).set(update, SetOptions(merge: true));
  }

  Map<String, dynamic> _equippedUpdateFor(ArcRewardInventoryItem item) {
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

    switch (item.type) {
      case ArcOperationRewardType.badge:
        update['equippedBadgeId'] = item.rewardId;
      case ArcOperationRewardType.title:
        update['equippedTitleId'] = item.rewardId;
      case ArcOperationRewardType.profileFrame:
        update['equippedProfileFrameId'] = item.rewardId;
      case ArcOperationRewardType.profileBanner:
        update['equippedProfileBannerId'] = item.rewardId;
      case ArcOperationRewardType.intelXp:
      case ArcOperationRewardType.tradeSlot:
      case ArcOperationRewardType.matchmakingSlot:
      case ArcOperationRewardType.premiumTrial:
      case ArcOperationRewardType.operationCredit:
        return const <String, dynamic>{};
    }

    return update;
  }

  CollectionReference<Map<String, dynamic>> _telemetryRef(String uid) =>
      _firestore
          .collection('arc_operation_telemetry')
          .doc(uid)
          .collection('events');

  DocumentReference<Map<String, dynamic>> _telemetrySummaryRef(String uid) =>
      _firestore.collection('arc_operation_telemetry').doc(uid);

  Future<void> recordTelemetry(
    ArcOperationTelemetryType type, {
    int amount = 1,
    String source = 'app',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final safeAmount = amount <= 0 ? 1 : amount;
    final event = ArcOperationTelemetryEvent(
      type: type,
      amount: safeAmount,
      source: source,
      metadata: metadata,
    );

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    batch.set(_telemetryRef(uid).doc(), event.toMap());
    batch.set(_telemetrySummaryRef(uid), {
      _summaryFieldForTelemetry(type): FieldValue.increment(safeAmount),
      'lastEventName': event.eventName,
      'lastEventAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    for (final task in _tasksForTelemetry(type)) {
      final ref = _progressRef(uid).doc(task.id);
      final currentSnapshot = await ref.get();
      final existing = currentSnapshot.data() ?? const <String, dynamic>{};
      final current = (existing['progress'] as num?)?.toInt() ?? task.progress;
      final next = (current + safeAmount).clamp(0, task.target).toInt();
      batch.set(ref, {
        'operationId': task.id,
        'progress': next,
        'target': task.target,
        'claimed': existing['claimed'] == true,
        'lastTelemetryType': type.name,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> recordTradeCompleted({int amount = 1}) => recordTelemetry(
    ArcOperationTelemetryType.tradeCompleted,
    amount: amount,
    source: 'trade',
  );

  Future<void> recordListingCreated({int amount = 1}) => recordTelemetry(
    ArcOperationTelemetryType.listingCreated,
    amount: amount,
    source: 'listing',
  );

  Future<void> recordMatchmakingCompleted({int amount = 1}) => recordTelemetry(
    ArcOperationTelemetryType.matchmakingCompleted,
    amount: amount,
    source: 'matchmaking',
  );

  Future<void> recordBlueprintReportSubmitted({int amount = 1}) =>
      recordTelemetry(
        ArcOperationTelemetryType.blueprintReportSubmitted,
        amount: amount,
        source: 'blueprint_intel',
      );

  Future<void> recordProfileCompleted() => recordTelemetry(
    ArcOperationTelemetryType.profileCompleted,
    source: 'profile',
  );

  Future<void> recordReferralCompleted({int amount = 1}) => recordTelemetry(
    ArcOperationTelemetryType.referralCompleted,
    amount: amount,
    source: 'referral',
  );

  Future<void> recordPlayerHelped({int amount = 1}) => recordTelemetry(
    ArcOperationTelemetryType.playerHelped,
    amount: amount,
    source: 'guardian',
  );

  Future<void> recordGuardianSessionCompleted({int amount = 1}) =>
      recordTelemetry(
        ArcOperationTelemetryType.guardianSessionCompleted,
        amount: amount,
        source: 'guardian',
      );

  Future<void> recordFavouriteLoadoutSaved() => recordTelemetry(
    ArcOperationTelemetryType.favouriteLoadoutSaved,
    source: 'favourite_loadout',
  );

  Future<void> recordFeedbackSubmitted() => recordTelemetry(
    ArcOperationTelemetryType.feedbackSubmitted,
    source: 'closed_beta',
  );

  Future<void> recordLogin() => recordTelemetry(
    ArcOperationTelemetryType.loginRecorded,
    source: 'session',
  );

  String _summaryFieldForTelemetry(ArcOperationTelemetryType type) {
    return switch (type) {
      ArcOperationTelemetryType.tradeCompleted => 'tradesCompleted',
      ArcOperationTelemetryType.listingCreated => 'listingsCreated',
      ArcOperationTelemetryType.matchmakingCompleted => 'matchmakingSessions',
      ArcOperationTelemetryType.blueprintReportSubmitted => 'blueprintReports',
      ArcOperationTelemetryType.loginRecorded => 'loginEvents',
      ArcOperationTelemetryType.profileCompleted => 'profileCompletions',
      ArcOperationTelemetryType.referralCompleted => 'referrals',
      ArcOperationTelemetryType.playerHelped => 'playersHelped',
      ArcOperationTelemetryType.guardianSessionCompleted => 'guardianSessions',
      ArcOperationTelemetryType.communityContribution =>
        'communityContributions',
      ArcOperationTelemetryType.favouriteLoadoutSaved =>
        'favouriteLoadoutsSaved',
      ArcOperationTelemetryType.feedbackSubmitted => 'feedbackSubmitted',
    };
  }

  List<ArcOperationTask> _tasksForTelemetry(ArcOperationTelemetryType type) {
    final allTasks = <ArcOperationTask>[
      ...ArcOperationsSeedData.dailyOperations,
      ...ArcOperationsSeedData.weeklyOperations,
      ...ArcOperationsSeedData.monthlyOperations,
      ...ArcOperationsSeedData.lifetimeOperations,
      ...ArcOperationsSeedData.betaOperations,
    ];

    bool matches(ArcOperationTask task) {
      return switch (type) {
        ArcOperationTelemetryType.tradeCompleted =>
          task.category == ArcOperationCategory.trading,
        ArcOperationTelemetryType.listingCreated =>
          task.category == ArcOperationCategory.trading,
        ArcOperationTelemetryType.matchmakingCompleted =>
          task.category == ArcOperationCategory.matchmaking,
        ArcOperationTelemetryType.blueprintReportSubmitted =>
          task.category == ArcOperationCategory.intel,
        ArcOperationTelemetryType.loginRecorded =>
          task.category == ArcOperationCategory.onboarding ||
              task.category == ArcOperationCategory.community,
        ArcOperationTelemetryType.profileCompleted =>
          task.category == ArcOperationCategory.onboarding,
        ArcOperationTelemetryType.referralCompleted =>
          task.category == ArcOperationCategory.referral,
        ArcOperationTelemetryType.playerHelped =>
          task.category == ArcOperationCategory.community ||
              task.category == ArcOperationCategory.guardian,
        ArcOperationTelemetryType.guardianSessionCompleted =>
          task.category == ArcOperationCategory.guardian,
        ArcOperationTelemetryType.communityContribution =>
          task.category == ArcOperationCategory.community,
        ArcOperationTelemetryType.favouriteLoadoutSaved =>
          task.category == ArcOperationCategory.loadout,
        ArcOperationTelemetryType.feedbackSubmitted =>
          task.category == ArcOperationCategory.beta,
      };
    }

    return allTasks.where(matches).toList(growable: false);
  }
}
