import 'arc_assist_marketplace_summary.dart';

class ArcAssistMarketplaceSpeechService {
  const ArcAssistMarketplaceSpeechService();

  String buildSpokenReadout(ArcAssistMarketplaceSummary summary) {
    if (!summary.hasOpportunities) {
      return 'No useful marketplace opportunities found yet.';
    }

    final parts = <String>[];

    if (summary.directMatches > 0) {
      parts.add('${summary.directMatches} direct trade matches');
    }

    if (summary.listingDrafts > 0) {
      parts.add('${summary.listingDrafts} listing drafts');
    }

    if (summary.missingBlueprintFallbacks > 0) {
      parts.add(
        '${summary.missingBlueprintFallbacks} missing blueprint fallbacks',
      );
    }

    if (summary.resourceFallbacks > 0) {
      parts.add('${summary.resourceFallbacks} useful resource bundles');
    }

    if (parts.isEmpty) {
      return 'Marketplace scan found opportunities ready to review.';
    }

    return 'Marketplace scan found ${parts.join(', ')}. Open Smart Trade Assist to review them.';
  }

  String buildShortHudLine(ArcAssistMarketplaceSummary summary) {
    if (!summary.hasOpportunities) {
      return 'No smart trades found';
    }

    return '${summary.opportunities.length} smart trade opportunities';
  }
}
