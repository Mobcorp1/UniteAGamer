class ArcLoadoutReadiness {
  const ArcLoadoutReadiness({
    required this.ownedItems,
    required this.missingItems,
    required this.lockedItems,
    required this.readinessPercent,
  });

  final int ownedItems;
  final int missingItems;
  final int lockedItems;
  final int readinessPercent;

  bool get isRaidReady => readinessPercent >= 85;
}

class ArcReadinessCalculator {
  static ArcLoadoutReadiness calculate({
    required int ownedItems,
    required int missingItems,
    required int lockedItems,
  }) {
    final total = ownedItems + missingItems + lockedItems;

    if (total <= 0) {
      return const ArcLoadoutReadiness(
        ownedItems: 0,
        missingItems: 0,
        lockedItems: 0,
        readinessPercent: 0,
      );
    }

    final readiness = ((ownedItems / total) * 100).clamp(0, 100).round();

    return ArcLoadoutReadiness(
      ownedItems: ownedItems,
      missingItems: missingItems,
      lockedItems: lockedItems,
      readinessPercent: readiness,
    );
  }
}
