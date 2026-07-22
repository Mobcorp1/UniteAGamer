import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_cosmetic_equipability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_reward_eligibility.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';

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

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _seasonRef(String uid) =>
      _userRef(uid).collection('arc_season_state').doc('current');

  DocumentReference<Map<String, dynamic>> _equippedRef(String uid) =>
      _firestore.collection('arc_equipped_cosmetics').doc(uid);

  DocumentReference<Map<String, dynamic>> _operationsConfigRef() =>
      _firestore.collection('config').doc('arc_operations');

  Stream<ArcOperationsUserState> watchUserState() {
    final uid = _uid;
    if (uid == null) return Stream.value(ArcOperationsUserState.empty);

    final controller = StreamController<ArcOperationsUserState>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    summarySubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    profileSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    telemetrySubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    seasonSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    configSubscription;
    var disposed = false;
    var loadVersion = 0;
    var latestSummary = const <String, dynamic>{};
    Map<String, dynamic>? latestProfile;
    var latestTelemetry = const <String, dynamic>{};
    var latestSeason = const <String, dynamic>{};
    var latestConfig = const <String, dynamic>{};

    void addError(Object error, StackTrace stackTrace) {
      if (!disposed && !controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }

    Future<void> emitState() async {
      final version = ++loadVersion;
      try {
        final state = await _loadUserState(
          uid: uid,
          summary: latestSummary,
          profileData: latestProfile,
          telemetryData: latestTelemetry,
          seasonData: latestSeason,
          configData: latestConfig,
        );
        if (!disposed && !controller.isClosed && version == loadVersion) {
          controller.add(state);
        }
      } catch (error, stackTrace) {
        addError(error, stackTrace);
      }
    }

    controller.onListen = () {
      summarySubscription = _summaryRef(uid).snapshots().listen((
        summarySnapshot,
      ) {
        latestSummary = summarySnapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);

      profileSubscription = _profileRef(uid).snapshots().listen((
        profileSnapshot,
      ) {
        latestProfile = profileSnapshot.data();
        unawaited(emitState());
      }, onError: addError);

      telemetrySubscription = _telemetrySummaryRef(uid).snapshots().listen((
        telemetrySnapshot,
      ) {
        latestTelemetry = telemetrySnapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);

      seasonSubscription = _seasonRef(uid).snapshots().listen((seasonSnapshot) {
        latestSeason = seasonSnapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);

      configSubscription = _operationsConfigRef().snapshots().listen((
        configSnapshot,
      ) {
        latestConfig = configSnapshot.data() ?? const <String, dynamic>{};
        unawaited(emitState());
      }, onError: addError);
    };

    controller.onCancel = () async {
      disposed = true;
      await summarySubscription?.cancel();
      await profileSubscription?.cancel();
      await telemetrySubscription?.cancel();
      await seasonSubscription?.cancel();
      await configSubscription?.cancel();
    };

    return controller.stream;
  }

  Future<ArcOperationsUserState> _loadUserState({
    required String uid,
    required Map<String, dynamic> summary,
    required Map<String, dynamic>? profileData,
    required Map<String, dynamic> telemetryData,
    required Map<String, dynamic> seasonData,
    required Map<String, dynamic> configData,
  }) async {
    final progressSnapshot = await _progressRef(uid).get();
    final inventorySnapshot = await _inventoryRef(uid).get();
    final equippedSnapshot = await _equippedRef(uid).get();
    final equippedData = <String, dynamic>{
      ...?equippedSnapshot.data(),
      ...?profileData,
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
      seasonalXp:
          (summary['seasonalXp'] as num?)?.toInt() ??
          (summary['seasonXp'] as num?)?.toInt() ??
          0,
      operationCredits: (summary['operationCredits'] as num?)?.toInt() ?? 0,
      extraTradeSlots: (summary['extraTradeSlots'] as num?)?.toInt() ?? 0,
      extraMatchmakingSlots:
          (summary['extraMatchmakingSlots'] as num?)?.toInt() ?? 0,
      currentSeasonId:
          _string(summary['currentSeasonId']) ??
          _string(seasonData['currentSeasonId']) ??
          ArcSeasonResetPolicy.defaultCurrentSeasonId,
      lastCompletedSeasonId: _string(seasonData['lastCompletedSeasonId']),
      telemetrySummary: ArcOperationTelemetrySummary.fromMap(telemetryData),
      tuningConfig: ArcOperationTuningConfig.fromMap(configData),
    );
  }

  Future<void> trackProgress(ArcOperationTask task, {int amount = 1}) async {
    final uid = _uid;
    if (uid == null) return;

    final seasonId = await _currentSeasonId(uid);
    final ref = _progressRef(uid).doc(task.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existing = snapshot.data() ?? const <String, dynamic>{};
      final current = (existing['progress'] as num?)?.toInt() ?? task.progress;
      if (existing['claimed'] == true) return;
      final next = (current + amount).clamp(0, task.target);
      transaction.set(ref, {
        'operationId': task.id,
        'seasonId': seasonId,
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

    final seasonId = await _currentSeasonId(uid);
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
            final item = _inventoryItemForReward(reward, task, seasonId);
            firstCosmetic ??= item;
            transaction.set(_inventoryRef(uid).doc(reward.id), item.toMap());
          case ArcOperationRewardType.premiumTrial:
            creditsGain += reward.amount;
        }
      }

      transaction.set(summaryRef, {
        'intelXp': FieldValue.increment(xpGain),
        'seasonalXp': FieldValue.increment(xpGain),
        'operationCredits': FieldValue.increment(creditsGain),
        'extraTradeSlots': FieldValue.increment(tradeSlots),
        'extraMatchmakingSlots': FieldValue.increment(matchSlots),
        'currentSeasonId': seasonId,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (firstCosmetic != null) {
        final update = _equippedUpdateFor(firstCosmetic);
        if (update.isNotEmpty) {
          transaction.set(profileRef, update, SetOptions(merge: true));
          transaction.set(_equippedRef(uid), update, SetOptions(merge: true));
        }
      }

      transaction.set(progressRef, {
        'operationId': task.id,
        'seasonId': seasonId,
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

    final seasonId = await _currentSeasonId(uid);
    if (!ArcCosmeticEquipability.canEquip(item, currentSeasonId: seasonId)) {
      return;
    }

    final update = _equippedUpdateFor(item);
    if (update.isEmpty) return;

    final batch = _firestore.batch();
    batch.set(_profileRef(uid), update, SetOptions(merge: true));
    batch.set(_equippedRef(uid), update, SetOptions(merge: true));
    await batch.commit();
  }

  Future<List<String>> reconcileEquippedCosmetics() async {
    final uid = _uid;
    if (uid == null) return const <String>[];

    final seasonId = await _currentSeasonId(uid);
    final inventorySnapshot = await _inventoryRef(uid).get();
    final inventoryById = <String, ArcRewardInventoryItem>{
      for (final doc in inventorySnapshot.docs)
        doc.id: ArcRewardInventoryItem.fromMap(doc.id, doc.data()),
    };
    final profileSnapshot = await _profileRef(uid).get();
    final equippedSnapshot = await _equippedRef(uid).get();
    final equippedData = <String, dynamic>{
      ...?equippedSnapshot.data(),
      ...?profileSnapshot.data(),
    };
    final checks = <_EquippedCosmeticCheck>[
      const _EquippedCosmeticCheck(
        field: 'equippedBadgeId',
        mirrorField: 'badgeId',
      ),
      const _EquippedCosmeticCheck(
        field: 'equippedTitleId',
        mirrorField: 'titleId',
      ),
      const _EquippedCosmeticCheck(
        field: 'equippedProfileFrameId',
        mirrorField: 'profileFrameId',
      ),
      const _EquippedCosmeticCheck(
        field: 'equippedProfileBannerId',
        mirrorField: 'profileBannerId',
      ),
    ];
    final cleared = <String>[];
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

    for (final check in checks) {
      final rewardId =
          _string(equippedData[check.field]) ??
          _string(equippedData[check.mirrorField]);
      if (rewardId == null) continue;
      final item = inventoryById[rewardId];
      if (item == null ||
          ArcCosmeticEquipability.canEquip(item, currentSeasonId: seasonId)) {
        continue;
      }
      update[check.field] = FieldValue.delete();
      update[check.mirrorField] = FieldValue.delete();
      cleared.add(rewardId);
    }

    if (cleared.isEmpty) return const <String>[];

    final batch = _firestore.batch();
    batch.set(_profileRef(uid), update, SetOptions(merge: true));
    batch.set(_equippedRef(uid), update, SetOptions(merge: true));
    batch.set(_summaryRef(uid), {
      'lastCosmeticReconciliation': {
        'version': 1,
        'seasonId': seasonId,
        'clearedRewardIds': cleared,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    await batch.commit();
    return cleared;
  }

  Future<void> reconcileCurrentUserRewardsAndProgress() async {
    final uid = _uid;
    if (uid == null) return;

    final seasonId = await _currentSeasonId(uid);
    final userSnapshot = await _userRef(uid).get();
    final profileSnapshot = await _profileRef(uid).get();
    final telemetrySnapshot = await _telemetrySummaryRef(uid).get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final profileData = profileSnapshot.data() ?? const <String, dynamic>{};
    final traderProfileData = <String, dynamic>{
      ..._map(userData['traderProfile']),
      ...profileData,
    };
    final eligibility = const ArcRewardEligibilityEngine().evaluate(
      userData: <String, dynamic>{
        ...userData,
        ...profileData,
        'traderProfile': traderProfileData,
      },
      telemetryData: telemetrySnapshot.data() ?? const <String, dynamic>{},
    );

    final knownRewards = ArcOperationsSeedData.rewards;
    final eligibleRewardIds =
        eligibility.rewardIds
            .where(knownRewards.containsKey)
            .toList(growable: false)
          ..sort();
    final skippedRewardIds =
        eligibility.rewardIds
            .where((id) => !knownRewards.containsKey(id))
            .toList(growable: false)
          ..sort();
    final now = DateTime.now().toIso8601String();

    await _firestore.runTransaction((transaction) async {
      final grantedRewardIds = <String>[];
      final alreadyOwnedRewardIds = <String>[];
      final rewardSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final rewardId in eligibleRewardIds) {
        final snapshot = await transaction.get(
          _inventoryRef(uid).doc(rewardId),
        );
        rewardSnapshots[rewardId] = snapshot;
      }

      for (final rewardId in eligibleRewardIds) {
        final reward = knownRewards[rewardId];
        if (reward == null) continue;
        final snapshot = rewardSnapshots[rewardId];
        if (snapshot?.exists ?? false) {
          alreadyOwnedRewardIds.add(rewardId);
          continue;
        }

        final item = ArcRewardInventoryItem.fromReward(
          reward,
          sourceSeasonId: seasonId,
          sourceOperationId: 'eligibility_reconciliation',
          permanent: true,
          equipableAfterSeason: true,
        );
        transaction.set(_inventoryRef(uid).doc(rewardId), {
          ...item.toMap(),
          'grantSource': 'eligibility_reconciliation',
          'grantReason': eligibility.reasons[rewardId],
          'grantedAt': now,
          'unlockedAt': now,
        });
        grantedRewardIds.add(rewardId);
      }

      transaction.set(_summaryRef(uid), {
        'lastRewardReconciliation': {
          'version': 1,
          'eligibleRewardIds': eligibleRewardIds,
          'grantedRewardIds': grantedRewardIds,
          'alreadyOwnedRewardIds': alreadyOwnedRewardIds,
          'skippedRewardIds': skippedRewardIds,
          'seasonId': seasonId,
          'updatedAt': now,
        },
        'updatedAt': now,
      }, SetOptions(merge: true));
    });
  }

  Map<String, dynamic> _equippedUpdateFor(ArcRewardInventoryItem item) {
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

    switch (item.type) {
      case ArcOperationRewardType.badge:
        update['equippedBadgeId'] = item.rewardId;
        update['badgeId'] = item.rewardId;
      case ArcOperationRewardType.title:
        update['equippedTitleId'] = item.rewardId;
        update['titleId'] = item.rewardId;
      case ArcOperationRewardType.profileFrame:
        update['equippedProfileFrameId'] = item.rewardId;
        update['profileFrameId'] = item.rewardId;
      case ArcOperationRewardType.profileBanner:
        update['equippedProfileBannerId'] = item.rewardId;
        update['profileBannerId'] = item.rewardId;
      case ArcOperationRewardType.intelXp:
      case ArcOperationRewardType.tradeSlot:
      case ArcOperationRewardType.matchmakingSlot:
      case ArcOperationRewardType.premiumTrial:
      case ArcOperationRewardType.operationCredit:
        return const <String, dynamic>{};
    }

    return update;
  }

  ArcRewardInventoryItem _inventoryItemForReward(
    ArcOperationReward reward,
    ArcOperationTask task,
    String seasonId,
  ) {
    final permanent =
        task.grantsPermanentRewards ||
        reward.betaExclusive ||
        reward.rarity.isExclusive;
    return ArcRewardInventoryItem.fromReward(
      reward,
      sourceSeasonId: seasonId,
      sourceOperationId: task.id,
      permanent: permanent,
      equipableAfterSeason: permanent,
      currentSeasonUnlock: true,
    );
  }

  Future<String> _currentSeasonId(String uid) async {
    final snapshot = await _seasonRef(uid).get();
    final value = snapshot.data()?['currentSeasonId'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return ArcSeasonResetPolicy.defaultCurrentSeasonId;
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
    String? idempotencyKey,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final seasonId = await _currentSeasonId(uid);
    final safeAmount = amount <= 0 ? 1 : amount;
    final event = ArcOperationTelemetryEvent(
      type: type,
      amount: safeAmount,
      source: source,
      metadata: metadata,
    );

    final eventRef = idempotencyKey == null
        ? _telemetryRef(uid).doc()
        : _telemetryRef(uid).doc(_telemetryEventId(type, idempotencyKey));
    if (idempotencyKey != null) {
      final existingEvent = await eventRef.get();
      if (existingEvent.exists) return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    batch.set(eventRef, {
      ...event.toMap(),
      'seasonId': seasonId,
      'idempotencyKey': idempotencyKey,
    });
    batch.set(_telemetrySummaryRef(uid), {
      _summaryFieldForTelemetry(type): FieldValue.increment(safeAmount),
      'currentSeasonId': seasonId,
      'seasonActivity': FieldValue.increment(safeAmount),
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
        'seasonId': seasonId,
        'progress': next,
        'target': task.target,
        'claimed': existing['claimed'] == true,
        'lastTelemetryType': type.name,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> recordTradeCompleted({int amount = 1, String? sessionId}) =>
      recordTelemetry(
        ArcOperationTelemetryType.tradeCompleted,
        amount: amount,
        source: 'trade',
        idempotencyKey: sessionId == null ? null : 'session:$sessionId',
      );

  Future<void> recordListingCreated({int amount = 1, String? listingId}) =>
      recordTelemetry(
        ArcOperationTelemetryType.listingCreated,
        amount: amount,
        source: 'listing',
        idempotencyKey: listingId == null ? null : 'listing:$listingId',
      );

  Future<void> recordMatchmakingCompleted({int amount = 1, String? matchId}) =>
      recordTelemetry(
        ArcOperationTelemetryType.matchmakingCompleted,
        amount: amount,
        source: 'matchmaking',
        idempotencyKey: matchId == null ? null : 'match:$matchId',
      );

  Future<void> recordBlueprintReportSubmitted({
    int amount = 1,
    String? reportId,
  }) => recordTelemetry(
    ArcOperationTelemetryType.blueprintReportSubmitted,
    amount: amount,
    source: 'blueprint_intel',
    idempotencyKey: reportId == null ? null : 'report:$reportId',
  );

  Future<void> recordProfileCompleted() => recordTelemetry(
    ArcOperationTelemetryType.profileCompleted,
    source: 'profile',
    idempotencyKey: 'profile-completed',
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
    idempotencyKey: 'favourite-loadout-saved',
  );

  Future<void> recordFeedbackSubmitted() => recordTelemetry(
    ArcOperationTelemetryType.feedbackSubmitted,
    source: 'closed_beta',
  );

  Future<void> recordAvailabilitySaved() => recordTelemetry(
    ArcOperationTelemetryType.availabilitySaved,
    source: 'availability',
  );

  Future<void> recordIntelConfirmed({int amount = 1, String? confirmationId}) =>
      recordTelemetry(
        ArcOperationTelemetryType.intelConfirmed,
        amount: amount,
        source: 'blueprint_intel',
        idempotencyKey: confirmationId == null
            ? null
            : 'confirmation:$confirmationId',
      );

  Future<void> recordQuestCompleted({required String questId}) =>
      recordTelemetry(
        ArcOperationTelemetryType.questCompleted,
        source: 'quest_progression',
        metadata: {'questId': questId},
        idempotencyKey: 'quest:$questId',
      );

  Future<void> recordScrappyUpgradeCompleted({required int level}) =>
      recordTelemetry(
        ArcOperationTelemetryType.scrappyUpgradeCompleted,
        source: 'scrappy_progression',
        metadata: {'level': level},
        idempotencyKey: 'scrappy-level:$level',
      );

  Future<void> recordBenchUpgradeCompleted({
    required String benchId,
    required int level,
  }) => recordTelemetry(
    ArcOperationTelemetryType.benchUpgradeCompleted,
    source: 'bench_progression',
    metadata: {'benchId': benchId, 'level': level},
    idempotencyKey: '$benchId-level:$level',
  );

  Future<void> recordLogin() => recordTelemetry(
    ArcOperationTelemetryType.loginRecorded,
    source: 'session',
    idempotencyKey:
        'login-day:${DateTime.now().toUtc().toIso8601String().substring(0, 10)}',
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
      ArcOperationTelemetryType.availabilitySaved => 'availabilitySaved',
      ArcOperationTelemetryType.intelConfirmed => 'intelConfirmed',
      ArcOperationTelemetryType.questCompleted => 'questsCompleted',
      ArcOperationTelemetryType.scrappyUpgradeCompleted => 'scrappyUpgrades',
      ArcOperationTelemetryType.benchUpgradeCompleted => 'benchUpgrades',
    };
  }

  List<ArcOperationTask> _tasksForTelemetry(ArcOperationTelemetryType type) {
    final allTasks = ArcOperationsSeedData.allOperations;

    final ids = switch (type) {
      ArcOperationTelemetryType.tradeCompleted => const <String>{
        'beta_first_trade',
        'weekly_trade_run',
        'monthly_trader_bronze',
        'life_first_trade',
        'life_trader_50',
      },
      ArcOperationTelemetryType.listingCreated => const <String>{
        'beta_first_listing',
        'daily_refresh_listing',
      },
      ArcOperationTelemetryType.matchmakingCompleted => const <String>{
        'beta_match_raider',
      },
      ArcOperationTelemetryType.blueprintReportSubmitted => const <String>{
        'beta_verified_intel',
      },
      ArcOperationTelemetryType.intelConfirmed => const <String>{
        'daily_verify_intel',
        'weekly_verified_intel',
        'beta_verified_intel',
      },
      ArcOperationTelemetryType.loginRecorded => const <String>{
        'beta_return_days',
      },
      ArcOperationTelemetryType.profileCompleted => const <String>{
        'beta_complete_profile',
      },
      ArcOperationTelemetryType.referralCompleted => const <String>{
        'life_recruit_3',
      },
      ArcOperationTelemetryType.playerHelped => const <String>{
        'monthly_guardian',
        'life_guardian_10',
      },
      ArcOperationTelemetryType.guardianSessionCompleted => const <String>{
        'beta_guardian',
      },
      ArcOperationTelemetryType.communityContribution => const <String>{
        'monthly_guardian',
        'life_guardian_10',
      },
      ArcOperationTelemetryType.favouriteLoadoutSaved => const <String>{
        'beta_loadout_saved',
        'weekly_loadout_progress',
      },
      ArcOperationTelemetryType.questCompleted => const <String>{
        'beta_first_quest_complete',
      },
      ArcOperationTelemetryType.scrappyUpgradeCompleted => const <String>{
        'beta_first_scrappy_upgrade',
      },
      ArcOperationTelemetryType.benchUpgradeCompleted => const <String>{
        'beta_first_bench_upgrade',
      },
      ArcOperationTelemetryType.feedbackSubmitted => const <String>{
        'beta_feedback',
      },
      ArcOperationTelemetryType.availabilitySaved => const <String>{
        'daily_update_availability',
      },
    };

    return allTasks
        .where((task) => ids.contains(task.id))
        .toList(growable: false);
  }

  String _telemetryEventId(ArcOperationTelemetryType type, String key) {
    final normalized = key
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final suffix = normalized.isEmpty ? 'default' : normalized;
    return '${type.name}-$suffix';
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }
}

class _EquippedCosmeticCheck {
  const _EquippedCosmeticCheck({
    required this.field,
    required this.mirrorField,
  });

  final String field;
  final String mirrorField;
}
