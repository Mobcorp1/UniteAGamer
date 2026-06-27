import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  DocumentReference<Map<String, dynamic>> _equippedRef(String uid) =>
      _firestore.collection('arc_equipped_cosmetics').doc(uid);

  Stream<ArcOperationsUserState> watchUserState() {
    final uid = _uid;
    if (uid == null) return Stream.value(ArcOperationsUserState.empty);

    return _summaryRef(uid).snapshots().asyncMap((summarySnapshot) async {
      final summary = summarySnapshot.data() ?? const <String, dynamic>{};
      final progressSnapshot = await _progressRef(uid).get();
      final inventorySnapshot = await _inventoryRef(uid).get();
      final equippedSnapshot = await _equippedRef(uid).get();

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
        equippedCosmetics: ArcEquippedCosmetics.fromMap(
          equippedSnapshot.data(),
        ),
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
    final equippedRef = _equippedRef(uid);

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
        final update = <String, dynamic>{};
        if (firstCosmetic.type == ArcOperationRewardType.badge) {
          update['badgeId'] = firstCosmetic.rewardId;
          update['badgeAssetPath'] = firstCosmetic.assetPath;
        }
        if (firstCosmetic.type == ArcOperationRewardType.title) {
          update['titleId'] = firstCosmetic.rewardId;
          update['titleLabel'] = firstCosmetic.label;
        }
        if (firstCosmetic.type == ArcOperationRewardType.profileFrame) {
          update['profileFrameId'] = firstCosmetic.rewardId;
          update['profileFrameAssetPath'] = firstCosmetic.assetPath;
        }
        if (update.isNotEmpty) {
          update['updatedAt'] = DateTime.now().toIso8601String();
          transaction.set(equippedRef, update, SetOptions(merge: true));
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

    final update = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (item.type == ArcOperationRewardType.badge) {
      update['badgeId'] = item.rewardId;
      update['badgeAssetPath'] = item.assetPath;
    }
    if (item.type == ArcOperationRewardType.title) {
      update['titleId'] = item.rewardId;
      update['titleLabel'] = item.label;
    }
    if (item.type == ArcOperationRewardType.profileFrame) {
      update['profileFrameId'] = item.rewardId;
      update['profileFrameAssetPath'] = item.assetPath;
    }

    await _equippedRef(uid).set(update, SetOptions(merge: true));
  }
}
