class TradingAutomationService {
  const TradingAutomationService();

  List<String> detectNewDuplicateBlueprints({
    required List<String> ownedBlueprints,
    required List<String> duplicateBlueprints,
  }) {
    return ownedBlueprints
        .where((item) => duplicateBlueprints.contains(item))
        .toList();
  }

  List<String> generateSuggestedListings({required List<String> duplicates}) {
    return duplicates;
  }

  List<String> findMatchingTrades({
    required List<String> wanted,
    required List<String> available,
  }) {
    return wanted.where((item) => available.contains(item)).toList();
  }
}
