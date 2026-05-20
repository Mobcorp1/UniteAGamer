enum SmartTradeOpportunityTier {
  directTopFiveMatch,
  missingBlueprintMatch,
  valueCounterOffer,
  usefulResourceBundle,
  publicListingDraft,
}

class SmartTradeOpportunity {
  final SmartTradeOpportunityTier tier;
  final String duplicateBlueprintId;
  final String? requestedBlueprintId;
  final List<String> requestedResourceIds;
  final int duplicateQuantityAvailable;
  final int priorityRank;
  final String reason;

  const SmartTradeOpportunity({
    required this.tier,
    required this.duplicateBlueprintId,
    required this.requestedBlueprintId,
    required this.requestedResourceIds,
    required this.duplicateQuantityAvailable,
    required this.priorityRank,
    required this.reason,
  });
}

class SmartTradeAssistEngine {
  const SmartTradeAssistEngine();

  Map<String, int> duplicateQuantitiesFromStates({
    required Map<String, int> dupesOwnedByBlueprintId,
  }) {
    final result = <String, int>{};

    for (final entry in dupesOwnedByBlueprintId.entries) {
      if (entry.value > 0) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  List<SmartTradeOpportunity> buildTopFiveListingDrafts({
    required Map<String, int> duplicateBlueprintQuantities,
    required List<String> topFiveWantedBlueprintIds,
  }) {
    final opportunities = <SmartTradeOpportunity>[];

    for (final duplicateEntry in duplicateBlueprintQuantities.entries) {
      final duplicateBlueprintId = duplicateEntry.key;
      final quantity = duplicateEntry.value;

      if (quantity <= 0) {
        continue;
      }

      for (var index = 0; index < topFiveWantedBlueprintIds.length; index++) {
        final wantedBlueprintId = topFiveWantedBlueprintIds[index];

        if (wantedBlueprintId.trim().isEmpty ||
            wantedBlueprintId == duplicateBlueprintId) {
          continue;
        }

        opportunities.add(
          SmartTradeOpportunity(
            tier: SmartTradeOpportunityTier.publicListingDraft,
            duplicateBlueprintId: duplicateBlueprintId,
            requestedBlueprintId: wantedBlueprintId,
            requestedResourceIds: const [],
            duplicateQuantityAvailable: quantity,
            priorityRank: index + 1,
            reason:
                'Create listing draft for duplicate blueprint against top priority target.',
          ),
        );
      }
    }

    return opportunities;
  }

  List<SmartTradeOpportunity> buildMissingBlueprintFallbacks({
    required String duplicateBlueprintId,
    required int duplicateQuantityAvailable,
    required List<String> missingBlueprintIds,
    required Set<String> topFiveWantedBlueprintIds,
  }) {
    if (duplicateQuantityAvailable <= 0) {
      return const [];
    }

    final opportunities = <SmartTradeOpportunity>[];

    for (final missingBlueprintId in missingBlueprintIds) {
      if (missingBlueprintId == duplicateBlueprintId ||
          topFiveWantedBlueprintIds.contains(missingBlueprintId)) {
        continue;
      }

      opportunities.add(
        SmartTradeOpportunity(
          tier: SmartTradeOpportunityTier.missingBlueprintMatch,
          duplicateBlueprintId: duplicateBlueprintId,
          requestedBlueprintId: missingBlueprintId,
          requestedResourceIds: const [],
          duplicateQuantityAvailable: duplicateQuantityAvailable,
          priorityRank: 99,
          reason:
              'Fallback opportunity for duplicate blueprint against another missing blueprint.',
        ),
      );
    }

    return opportunities;
  }

  List<SmartTradeOpportunity> buildUsefulResourceFallbacks({
    required String duplicateBlueprintId,
    required int duplicateQuantityAvailable,
    required List<String> usefulResourceIds,
  }) {
    if (duplicateQuantityAvailable <= 0 || usefulResourceIds.isEmpty) {
      return const [];
    }

    return [
      SmartTradeOpportunity(
        tier: SmartTradeOpportunityTier.usefulResourceBundle,
        duplicateBlueprintId: duplicateBlueprintId,
        requestedBlueprintId: null,
        requestedResourceIds: usefulResourceIds.take(3).toList(),
        duplicateQuantityAvailable: duplicateQuantityAvailable,
        priorityRank: 199,
        reason:
            'Fallback opportunity for useful resource bundle based on tracker needs.',
      ),
    ];
  }
}
