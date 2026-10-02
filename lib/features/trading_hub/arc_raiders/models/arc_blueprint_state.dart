import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcBlueprintOwnershipSource { unknown, manual, scan }

class ArcBlueprintState {
  final String blueprintId;
  final bool owned;
  final int dupesOwned;
  final int priorityRank;
  final DateTime? updatedAt;
  final ArcBlueprintOwnershipSource ownershipSource;

  const ArcBlueprintState({
    required this.blueprintId,
    required this.owned,
    required this.dupesOwned,
    required this.priorityRank,
    required this.updatedAt,
    this.ownershipSource = ArcBlueprintOwnershipSource.unknown,
  });

  factory ArcBlueprintState.empty(String blueprintId) {
    return ArcBlueprintState(
      blueprintId: blueprintId,
      owned: false,
      dupesOwned: 0,
      priorityRank: 0,
      updatedAt: null,
      ownershipSource: ArcBlueprintOwnershipSource.unknown,
    );
  }

  bool get wanted => !owned;
  bool get availableToTrade => dupesOwned > 0;
  bool get hasDuplicates => dupesOwned > 0;
  bool get isPrioritized => priorityRank > 0;
  bool get isManualOwnership =>
      owned && ownershipSource == ArcBlueprintOwnershipSource.manual;
  bool get isScanConfirmed =>
      owned && ownershipSource == ArcBlueprintOwnershipSource.scan;

  ArcBlueprintState copyWith({
    String? blueprintId,
    bool? owned,
    int? dupesOwned,
    int? priorityRank,
    DateTime? updatedAt,
    ArcBlueprintOwnershipSource? ownershipSource,
  }) {
    final nextOwned = owned ?? this.owned;
    final nextDupesRaw = dupesOwned ?? this.dupesOwned;
    final nextPriorityRaw = priorityRank ?? this.priorityRank;
    final safeDupes = nextDupesRaw < 0 ? 0 : nextDupesRaw;
    final safePriority = nextPriorityRaw < 0 ? 0 : nextPriorityRaw;
    final effectiveOwned = nextOwned || safeDupes > 0;
    final effectiveSource = effectiveOwned
        ? (ownershipSource ?? this.ownershipSource)
        : ArcBlueprintOwnershipSource.unknown;

    return ArcBlueprintState(
      blueprintId: blueprintId ?? this.blueprintId,
      owned: effectiveOwned,
      dupesOwned: effectiveOwned ? safeDupes : 0,
      priorityRank: safePriority,
      updatedAt: updatedAt ?? this.updatedAt,
      ownershipSource: effectiveSource,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'owned': owned,
      'dupesOwned': dupesOwned,
      'wanted': wanted,
      'availableToTrade': availableToTrade,
      'priorityRank': priorityRank,
      'ownershipSource': ownershipSource.name,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ArcBlueprintState.fromMap(Map<String, dynamic> map) {
    final blueprintId = (map['blueprintId'] ?? '') as String;

    final legacyOwnedCount = (map['ownedCount'] as num?)?.toInt();
    final dupesOwned =
        (map['dupesOwned'] as num?)?.toInt() ??
        (legacyOwnedCount == null
            ? 0
            : legacyOwnedCount > 0
            ? legacyOwnedCount - 1
            : 0);

    final explicitOwned = map['owned'] as bool?;
    final explicitWanted = map['wanted'] as bool?;
    final explicitAvailable = map['availableToTrade'] as bool?;
    final hasOwnershipSignal =
        explicitOwned != null ||
        legacyOwnedCount != null ||
        explicitAvailable == true ||
        dupesOwned > 0;
    final owned =
        explicitOwned ??
        (legacyOwnedCount != null
            ? legacyOwnedCount > 0
            : hasOwnershipSignal && explicitWanted != true);

    final rawPriority = (map['priorityRank'] as num?)?.toInt() ?? 0;
    final rawOwnershipSource = map['ownershipSource']?.toString().trim() ?? '';
    final ownershipSource = ArcBlueprintOwnershipSource.values.firstWhere(
      (value) => value.name == rawOwnershipSource,
      orElse: () => ArcBlueprintOwnershipSource.unknown,
    );

    return ArcBlueprintState(
      blueprintId: blueprintId,
      owned: owned || dupesOwned > 0,
      dupesOwned: dupesOwned < 0 ? 0 : dupesOwned,
      priorityRank: rawPriority < 0 ? 0 : rawPriority,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      ownershipSource: ownershipSource,
    );
  }
}

enum ArcBlueprintStateHydrationStatus { signedOut, loading, loaded, error }

class ArcBlueprintStateSnapshot {
  const ArcBlueprintStateSnapshot({
    required this.status,
    required this.states,
    this.userId,
    this.error,
  });

  final ArcBlueprintStateHydrationStatus status;
  final Map<String, ArcBlueprintState> states;
  final String? userId;
  final Object? error;

  bool get isLoading =>
      status == ArcBlueprintStateHydrationStatus.loading ||
      status == ArcBlueprintStateHydrationStatus.signedOut;

  bool get hasConfirmedLoad =>
      status == ArcBlueprintStateHydrationStatus.loaded;

  bool get isConfirmedEmpty => hasConfirmedLoad && states.isEmpty;

  bool get hasUsableState => states.isNotEmpty || hasConfirmedLoad;

  factory ArcBlueprintStateSnapshot.signedOut() {
    return const ArcBlueprintStateSnapshot(
      status: ArcBlueprintStateHydrationStatus.signedOut,
      states: <String, ArcBlueprintState>{},
    );
  }

  factory ArcBlueprintStateSnapshot.loading({
    required String userId,
    Map<String, ArcBlueprintState> states = const <String, ArcBlueprintState>{},
  }) {
    return ArcBlueprintStateSnapshot(
      status: ArcBlueprintStateHydrationStatus.loading,
      userId: userId,
      states: states,
    );
  }

  factory ArcBlueprintStateSnapshot.loaded({
    required String userId,
    required Map<String, ArcBlueprintState> states,
  }) {
    return ArcBlueprintStateSnapshot(
      status: ArcBlueprintStateHydrationStatus.loaded,
      userId: userId,
      states: states,
    );
  }

  factory ArcBlueprintStateSnapshot.failed({
    required String userId,
    Map<String, ArcBlueprintState> states = const <String, ArcBlueprintState>{},
    required Object error,
  }) {
    return ArcBlueprintStateSnapshot(
      status: ArcBlueprintStateHydrationStatus.error,
      userId: userId,
      states: states,
      error: error,
    );
  }
}
