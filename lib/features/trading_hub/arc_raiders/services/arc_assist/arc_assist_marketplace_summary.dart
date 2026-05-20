import '../automation/smart_trade_assist_engine.dart';

class ArcAssistMarketplaceSummary {
  final int directMatches;
  final int listingDrafts;
  final int missingBlueprintFallbacks;
  final int resourceFallbacks;
  final List<SmartTradeOpportunity> opportunities;

  const ArcAssistMarketplaceSummary({
    required this.directMatches,
    required this.listingDrafts,
    required this.missingBlueprintFallbacks,
    required this.resourceFallbacks,
    required this.opportunities,
  });

  bool get hasOpportunities => opportunities.isNotEmpty;

  String get spokenSummary {
    if (!hasOpportunities) {
      return 'No useful marketplace opportunities found yet.';
    }

    final parts = <String>[];

    if (directMatches > 0) {
      parts.add('$directMatches direct trade matches');
    }

    if (listingDrafts > 0) {
      parts.add('$listingDrafts listing drafts');
    }

    if (missingBlueprintFallbacks > 0) {
      parts.add('$missingBlueprintFallbacks missing blueprint fallbacks');
    }

    if (resourceFallbacks > 0) {
      parts.add('$resourceFallbacks useful resource bundles');
    }

    return 'Marketplace scan found ${parts.join(', ')}.';
  }
}

class ArcAssistMarketplaceSummaryBuilder {
  const ArcAssistMarketplaceSummaryBuilder();

  ArcAssistMarketplaceSummary build(List<SmartTradeOpportunity> opportunities) {
    var directMatches = 0;
    var listingDrafts = 0;
    var missingBlueprintFallbacks = 0;
    var resourceFallbacks = 0;

    for (final opportunity in opportunities) {
      switch (opportunity.tier) {
        case SmartTradeOpportunityTier.directTopFiveMatch:
          directMatches++;
          break;
        case SmartTradeOpportunityTier.publicListingDraft:
          listingDrafts++;
          break;
        case SmartTradeOpportunityTier.missingBlueprintMatch:
          missingBlueprintFallbacks++;
          break;
        case SmartTradeOpportunityTier.usefulResourceBundle:
          resourceFallbacks++;
          break;
        case SmartTradeOpportunityTier.valueCounterOffer:
          missingBlueprintFallbacks++;
          break;
      }
    }

    return ArcAssistMarketplaceSummary(
      directMatches: directMatches,
      listingDrafts: listingDrafts,
      missingBlueprintFallbacks: missingBlueprintFallbacks,
      resourceFallbacks: resourceFallbacks,
      opportunities: opportunities,
    );
  }
}
