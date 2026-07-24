import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository_state.dart';

class ArcScrappyRepository {
  ArcScrappyRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collection = 'arc_scrappy_states';

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _statesRef {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return _firestore.collection('users').doc(uid).collection(_collection);
  }

  Stream<ArcScrappyRepositoryState<Map<String, ArcScrappyState>>>
  watchMyScrappyStates() {
    final initialState =
        Stream<ArcScrappyRepositoryState<Map<String, ArcScrappyState>>>.value(
          const ArcScrappyRepositoryState<Map<String, ArcScrappyState>>(
            status: ArcScrappyRepositoryStateStatus.restoring,
          ),
        );

    final authStateStream = _auth
        .authStateChanges()
        .asyncMap<ArcScrappyRepositoryState<Map<String, ArcScrappyState>>>((
          user,
        ) {
          if (user == null) {
            return const ArcScrappyRepositoryState<
              Map<String, ArcScrappyState>
            >(status: ArcScrappyRepositoryStateStatus.unauthenticated);
          }
          return const ArcScrappyRepositoryState<Map<String, ArcScrappyState>>(
            status: ArcScrappyRepositoryStateStatus.loading,
          );
        });

    return Stream<
          ArcScrappyRepositoryState<Map<String, ArcScrappyState>>
        >.multi((controller) async {
          await for (final state in initialState) {
            if (!controller.isClosed) {
              controller.add(state);
            }
          }
          await for (final state in authStateStream) {
            if (!controller.isClosed) {
              controller.add(state);
            }
          }
        })
        .asyncExpand((state) {
          final uid = _uid;
          if (uid == null || uid.isEmpty) {
            return Stream.value(ArcScrappyRepositoryState.unauthenticated());
          }
          final statesRef = _firestore
              .collection('users')
              .doc(uid)
              .collection(_collection);
          return statesRef
              .snapshots()
              .map<ArcScrappyRepositoryState<Map<String, ArcScrappyState>>>((
                snapshot,
              ) {
                final map = <String, ArcScrappyState>{};
                for (final doc in snapshot.docs) {
                  final raw = Map<String, dynamic>.from(doc.data());
                  final updated = raw['updatedAt'];
                  if (updated is Timestamp) {
                    raw['updatedAt'] = updated.toDate();
                  }
                  map[doc.id] = ArcScrappyState.fromJson(raw, itemId: doc.id);
                }
                if (map.isEmpty) {
                  return ArcScrappyRepositoryState<
                    Map<String, ArcScrappyState>
                  >.empty();
                }
                return ArcScrappyRepositoryState<
                  Map<String, ArcScrappyState>
                >.loaded(map);
              })
              .handleError(
                (Object error) =>
                    ArcScrappyRepositoryState<
                      Map<String, ArcScrappyState>
                    >.error(error),
              );
        });
  }

  Stream<Map<String, ArcScrappyState>> watchMyScrappyStateMap() {
    return watchMyScrappyStates().map(
      (state) => state.data ?? const <String, ArcScrappyState>{},
    );
  }

  Future<void> saveScrappyState(
    ArcScrappyState state, {
    int? neededCount,
  }) async {
    final statesRef = _statesRef;
    if (statesRef == null) {
      return;
    }

    final resolvedNeeded = neededCount ?? _neededCountFor(state.itemId);

    await statesRef
        .doc(state.itemId)
        .set(
          state
              .copyWith(updatedAt: DateTime.now())
              .toJson(neededCount: resolvedNeeded),
          SetOptions(merge: true),
        );
  }

  int _neededCountFor(String itemId) {
    for (final item in ArcScrappySeedData.items) {
      if (item.id == itemId) return item.neededCount;
    }
    for (final item in ArcBenchUpgradeSeedData.items) {
      if (item.id == itemId) return item.neededCount;
    }
    return 1;
  }

  Future<void> resetAllScrappyStates(Iterable<String> itemIds) async {
    final statesRef = _statesRef;
    if (statesRef == null) {
      return;
    }

    final batch = _firestore.batch();
    for (final itemId in itemIds) {
      batch.delete(statesRef.doc(itemId));
    }
    await batch.commit();
  }
}
