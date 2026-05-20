class SmartTradeInventoryInput {
  final Map<String, int> duplicateBlueprintQuantities;
  final List<String> topFiveWantedBlueprintIds;
  final List<String> missingBlueprintIds;
  final List<String> usefulResourceIds;

  const SmartTradeInventoryInput({
    required this.duplicateBlueprintQuantities,
    required this.topFiveWantedBlueprintIds,
    required this.missingBlueprintIds,
    required this.usefulResourceIds,
  });

  bool get hasDuplicates {
    return duplicateBlueprintQuantities.values.any((quantity) => quantity > 0);
  }

  SmartTradeInventoryInput normalised() {
    return SmartTradeInventoryInput(
      duplicateBlueprintQuantities: {
        for (final entry in duplicateBlueprintQuantities.entries)
          if (entry.key.trim().isNotEmpty && entry.value > 0)
            entry.key.trim(): entry.value,
      },
      topFiveWantedBlueprintIds: _normaliseIds(
        topFiveWantedBlueprintIds,
      ).take(5).toList(),
      missingBlueprintIds: _normaliseIds(missingBlueprintIds),
      usefulResourceIds: _normaliseIds(usefulResourceIds),
    );
  }

  static List<String> _normaliseIds(List<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final cleaned = value.trim();

      if (cleaned.isEmpty || seen.contains(cleaned)) {
        continue;
      }

      seen.add(cleaned);
      result.add(cleaned);
    }

    return result;
  }
}
