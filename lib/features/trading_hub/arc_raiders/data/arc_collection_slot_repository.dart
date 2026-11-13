import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'arc_native_collection_screenshot_recognizer.dart';

/// Collection states are independent of arc_blueprints and its duplicate model.
/// A native screenshot establishes only ownership, NEVER duplicate quantity.
class ArcAdditionalCollectionState {
  const ArcAdditionalCollectionState({
    this.ownedSlots = const <int>{},
    this.duplicateCounts = const <int, int>{},
    this.clearedSlots = const <int>{},
  });

  final Set<int> ownedSlots;
  final Map<int, int> duplicateCounts;
  /// Explicit user removals override any legacy additive import.
  final Set<int> clearedSlots;

  int get duplicateTotal => duplicateCounts.values.fold<int>(0, (a, b) => a + b);

  static ArcAdditionalCollectionState decode(
      Object? raw, ArcNativeCollectionKind kind) {
    if (raw is! Map) return const ArcAdditionalCollectionState();
    final cleared = ArcCollectionSlotRepository.decodeOwned(raw['clearedSlots'], kind);
    final owned = ArcCollectionSlotRepository.decodeOwned(raw['ownedSlots'], kind)
      ..removeAll(cleared);
    final dupes = <int, int>{};
    final rawDupes = raw['duplicateCounts'];
    if (rawDupes is Map) {
      rawDupes.forEach((key, value) {
        final position = int.tryParse(key.toString());
        if (position != null && position >= 1 && position <= kind.slots &&
            value is num && value.toInt() > 0 && value.toInt() <= 999) {
          if (!cleared.contains(position)) {
            dupes[position] = value.toInt();
            owned.add(position);
          }
        }
      });
    }
    return ArcAdditionalCollectionState(
      ownedSlots: Set.unmodifiable(owned),
      duplicateCounts: Map.unmodifiable(dupes),
      clearedSlots: Set.unmodifiable(cleared),
    );
  }

  /// Additive ownership; explicit duplicate editing is the only way to change
  /// duplicate quantities. Missing screenshot positions never remove ownership.
  static ArcAdditionalCollectionState merge(
      ArcAdditionalCollectionState current,
      ArcNativeCollectionKind kind,
      Iterable<int> addOwned,
      Map<int, int> editedDuplicates, {
      Iterable<int> clearOwned = const <int>{},
      }) {
    final nextOwned = <int>{...current.ownedSlots};
    final nextCleared = <int>{...current.clearedSlots};
    for (final slot in clearOwned) {
      if (slot < 1 || slot > kind.slots) {
        throw RangeError('Invalid collection slot $slot');
      }
      nextOwned.remove(slot);
      nextCleared.add(slot);
    }
    for (final slot in addOwned) {
      if (slot < 1 || slot > kind.slots) throw RangeError('Invalid collection slot $slot');
      nextOwned.add(slot);
      nextCleared.remove(slot);
    }
    final nextDuplicates = <int, int>{...current.duplicateCounts}
      ..removeWhere((slot, _) => nextCleared.contains(slot));
    editedDuplicates.forEach((slot, quantity) {
      if (slot < 1 || slot > kind.slots || quantity < 0 || quantity > 999) {
        throw RangeError('Invalid duplicate count for slot $slot');
      }
      if (quantity == 0) {
        nextDuplicates.remove(slot);
      } else {
        nextDuplicates[slot] = quantity;
        nextOwned.add(slot);
        nextCleared.remove(slot);
      }
    });
    return ArcAdditionalCollectionState(
      ownedSlots: Set.unmodifiable(nextOwned),
      duplicateCounts: Map.unmodifiable(nextDuplicates),
      clearedSlots: Set.unmodifiable(nextCleared),
    );
  }

  Map<String, dynamic> encode() => <String, dynamic>{
        'ownedSlots': ownedSlots.toList()..sort(),
        'clearedSlots': clearedSlots.toList()..sort(),
        'duplicateCounts': <String, int>{
          for (final entry in duplicateCounts.entries) '${entry.key}': entry.value,
        },
        'schemaVersion': 2,
      };
}

/// Persists to the existing owner-protected users/{uid} document, not to a
/// new subcollection requiring unverified deployed Firestore rule changes.
/// Legacy arc_collection_slots ownership is read when access permits.
class ArcCollectionSlotRepository {
  ArcCollectionSlotRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw StateError('Sign in before saving your collection.');
    return firestore.collection('users').doc(uid);
  }

  static Set<int> decodeOwned(Object? raw, ArcNativeCollectionKind kind) {
    if (raw is! List) return <int>{};
    return raw.whereType<num>().map((n) => n.toInt())
        .where((slot) => slot >= 1 && slot <= kind.slots).toSet();
  }

  static ArcAdditionalCollectionState _stateFromUser(
      Map<String, dynamic>? user, ArcNativeCollectionKind kind) {
    final all = user?['uagCollectionsV1'];
    return ArcAdditionalCollectionState.decode(all is Map ? all[kind.key] : null, kind);
  }

  Future<ArcAdditionalCollectionState> read(ArcNativeCollectionKind kind) async {
    final doc = _userDoc();
    final main = await doc.get();
    var state = _stateFromUser(main.data(), kind);
    // The previous pass wrote to this path, so do not strand those users.
    try {
      final legacy = await doc.collection('arc_collection_slots').doc(kind.key).get();
      state = ArcAdditionalCollectionState.merge(
        state, kind,
        decodeOwned(legacy.data()?['ownedSlots'], kind)
            .difference(state.clearedSlots), const {},
      );
    } on FirebaseException {
      // New subcollection could lack deployed permissions. Main owner document
      // remains the persistence path. Never claim a failed main read succeeded.
    }
    return state;
  }

  Future<Set<int>> readOwned(ArcNativeCollectionKind kind) async =>
      (await read(kind)).ownedSlots;

  Future<ArcAdditionalCollectionState> save({
    required ArcNativeCollectionKind kind,
    required Iterable<int> addOwned,
    Map<int, int> editedDuplicates = const <int, int>{},
    Iterable<int> clearOwned = const <int>{},
  }) async {
    final additions = addOwned.toSet();
    final removals = clearOwned.toSet();
    if (additions.intersection(removals).isNotEmpty) {
      throw ArgumentError('Cannot add and clear the same slot together.');
    }
    // Validate before starting a transaction, including when no changes exist.
    ArcAdditionalCollectionState.merge(
      const ArcAdditionalCollectionState(), kind, additions, editedDuplicates,
      clearOwned: removals,
    );
    final doc = _userDoc();
    // Read legacy before transaction, then merge it IN the transaction with
    // latest user data. This is additive and safe under concurrent updates.
    var legacyOwned = <int>{};
    try {
      final legacy = await doc.collection('arc_collection_slots').doc(kind.key).get();
      legacyOwned = decodeOwned(legacy.data()?['ownedSlots'], kind);
    } on FirebaseException {
      // Legacy may not be readable in the deployed ruleset.
    }
    return firestore.runTransaction<ArcAdditionalCollectionState>((txn) async {
      final current = await txn.get(doc);
      final base = _stateFromUser(current.data(), kind);
      final result = ArcAdditionalCollectionState.merge(
        base, kind,
        <int>{...legacyOwned.difference(base.clearedSlots).difference(removals),
          ...additions}, editedDuplicates, clearOwned: removals,
      );
      txn.set(doc, <String, dynamic>{
        'uagCollectionsV1': {kind.key: result.encode()},
      }, SetOptions(merge: true));
      return result;
    });
  }

  // Backward compatibility for last pass callers.
  Future<Set<int>> addConfirmedOwned(
      ArcNativeCollectionKind kind, Iterable<int> confirmedSlots) async =>
      (await save(kind: kind, addOwned: confirmedSlots)).ownedSlots;
}
