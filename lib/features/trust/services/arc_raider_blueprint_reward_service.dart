import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

import '../models/arc_raider_contract_models.dart';

class ArcRaiderBlueprintRewardService {
  ArcRaiderBlueprintRewardService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _states(String uid) =>
      _db.collection('users').doc(uid).collection('arc_blueprints');

  Future<Map<String, ArcBlueprintState>> _loadStates(String uid) async {
    if (uid.trim().isEmpty) return const <String, ArcBlueprintState>{};
    final snapshot = await _states(uid).get();
    return {
      for (final doc in snapshot.docs)
        doc.id: ArcBlueprintState.fromMap({
          ...doc.data(),
          'blueprintId':
              (doc.data()['blueprintId'] as String?)?.trim().isNotEmpty == true
              ? doc.data()['blueprintId']
              : doc.id,
        }),
    };
  }

  Future<int> maxDistinctBlueprintRewards(String creatorUid) async {
    final states = await _loadStates(creatorUid);
    return states.values.where((state) => state.dupesOwned > 0).length;
  }

  Future<void> validateOffer({
    required String creatorUid,
    required int rewardCount,
  }) async {
    if (rewardCount < 1) {
      throw ArgumentError('Blueprint rewards offered must be at least 1.');
    }
    final available = await maxDistinctBlueprintRewards(creatorUid);
    if (rewardCount > available) {
      throw StateError(
        'You only have $available distinct Blueprint duplicate${available == 1 ? '' : 's'} available to offer.',
      );
    }
  }

  Future<List<String>> snapshotDuplicateBlueprintIds(String creatorUid) async {
    final states = await _loadStates(creatorUid);
    final ids = states.entries
        .where((entry) => entry.value.dupesOwned > 0)
        .map((entry) => entry.key)
        .toSet();
    return ArcBlueprintSeedData.blueprints
        .where((blueprint) => ids.contains(blueprint.id))
        .map((blueprint) => blueprint.id)
        .toList(growable: false);
  }

  Future<List<ArcRaiderBlueprintRewardCandidate>> eligibleCandidates({
    required Iterable<String> creatorPool,
    required String claimantUid,
  }) async {
    final claimant = await _loadStates(claimantUid);
    final pool = creatorPool.toSet();
    return ArcBlueprintSeedData.blueprints
        .where((blueprint) => pool.contains(blueprint.id))
        .where((blueprint) {
          final state =
              claimant[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
          return !state.owned;
        })
        .map(
          (blueprint) => ArcRaiderBlueprintRewardCandidate(
            blueprintId: blueprint.id,
            name: blueprint.name,
          ),
        )
        .toList(growable: false);
  }

  Future<void> settleCompletedContract({
    required String contractId,
    required String moderatorUid,
    required String resolution,
  }) async {
    final contractRef = _db.collection('arc_raider_contracts').doc(contractId);

    await _db.runTransaction((tx) async {
      final contractSnapshot = await tx.get(contractRef);
      if (!contractSnapshot.exists) {
        throw StateError('Contract not found.');
      }
      final contract = ArcRaiderContract.fromMap(contractSnapshot.data()!);
      if (contract.blueprintRewardCount <= 0) {
        throw StateError('This contract has no Blueprint reward to settle.');
      }
      if (contract.hunterUid.isEmpty) {
        throw StateError('The contract has no claimant.');
      }
      if (!{
        ArcRaiderContractStatus.evidenceSubmitted,
        ArcRaiderContractStatus.disputed,
      }.contains(contract.status)) {
        throw StateError('Invalid contract completion state.');
      }

      final selected = contract.blueprintRewardSelection.toSet().toList();
      if (selected.length != contract.blueprintRewardCount) {
        throw StateError(
          'The claimant must choose exactly ${contract.blueprintRewardCount} Blueprint reward${contract.blueprintRewardCount == 1 ? '' : 's'} before completion.',
        );
      }
      if (!selected.every(contract.blueprintRewardPool.contains)) {
        throw StateError(
          'A selected Blueprint is not part of the offered duplicate pool.',
        );
      }

      final creatorRefs = <String, DocumentReference<Map<String, dynamic>>>{};
      final claimantRefs = <String, DocumentReference<Map<String, dynamic>>>{};
      final creatorSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final claimantSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};

      // Firestore transactions require every read to happen before writes.
      for (final blueprintId in selected) {
        final creatorRef = _states(contract.reporterUid).doc(blueprintId);
        final claimantRef = _states(contract.hunterUid).doc(blueprintId);
        creatorRefs[blueprintId] = creatorRef;
        claimantRefs[blueprintId] = claimantRef;
        creatorSnapshots[blueprintId] = await tx.get(creatorRef);
        claimantSnapshots[blueprintId] = await tx.get(claimantRef);
      }

      for (final blueprintId in selected) {
        final creatorState = ArcBlueprintState.fromMap({
          ...?creatorSnapshots[blueprintId]?.data(),
          'blueprintId': blueprintId,
        });
        final claimantState = ArcBlueprintState.fromMap({
          ...?claimantSnapshots[blueprintId]?.data(),
          'blueprintId': blueprintId,
        });

        if (creatorState.dupesOwned < 1) {
          throw StateError(
            'A selected Blueprint duplicate is no longer available. Refresh the reward selection before completing the contract.',
          );
        }
        if (claimantState.owned) {
          throw StateError(
            'The claimant now owns one of the selected Blueprints. Refresh the reward selection before completing the contract.',
          );
        }

        tx.set(
          creatorRefs[blueprintId]!,
          creatorState
              .copyWith(
                owned: true,
                dupesOwned: creatorState.dupesOwned - 1,
                updatedAt: DateTime.now(),
              )
              .toMap(),
          SetOptions(merge: true),
        );
        tx.set(
          claimantRefs[blueprintId]!,
          claimantState
              .copyWith(owned: true, updatedAt: DateTime.now())
              .toMap(),
          SetOptions(merge: true),
        );
      }

      tx.update(contractRef, {
        'status': ArcRaiderContractStatus.completed.name,
        'resolution': resolution.trim(),
        'moderatedByUid': moderatorUid,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'blueprintRewardsSettled': true,
      });
    });
  }
}
