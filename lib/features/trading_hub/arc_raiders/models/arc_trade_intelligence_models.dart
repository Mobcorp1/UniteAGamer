import 'package:flutter/foundation.dart';

@immutable
class ArcTradeListingScore {
  const ArcTradeListingScore({
    required this.score,
    required this.label,
    required this.reason,
    required this.recommendation,
    required this.reasons,
    required this.matchingOfferedItems,
    required this.matchingWantedItems,
    required this.reputationHint,
  });

  final int score;
  final String label;
  final String reason;
  final String recommendation;
  final List<String> reasons;
  final List<String> matchingOfferedItems;
  final List<String> matchingWantedItems;
  final String reputationHint;

  static const neutral = ArcTradeListingScore(
    score: 0,
    label: 'Low Priority',
    reason: 'No direct collection or duplicate signal is available yet.',
    recommendation: 'Review manually',
    reasons: <String>[],
    matchingOfferedItems: <String>[],
    matchingWantedItems: <String>[],
    reputationHint: 'Reputation unavailable',
  );

  bool get isActionable => score >= 45;
  bool get isHighValue => score >= 80;
}

@immutable
class ArcTradeItemScore {
  const ArcTradeItemScore({
    required this.id,
    required this.label,
    required this.score,
    required this.reason,
  });

  final String id;
  final String label;
  final int score;
  final String reason;
}

@immutable
class ArcTradeMatchSuggestion {
  const ArcTradeMatchSuggestion({
    required this.title,
    required this.reason,
    required this.offeredItems,
    required this.requestedItems,
    required this.confidence,
    required this.priority,
    required this.actionLabel,
    required this.routeName,
    required this.listingId,
    required this.listingScore,
  });

  final String title;
  final String reason;
  final List<String> offeredItems;
  final List<String> requestedItems;
  final int confidence;
  final String priority;
  final String actionLabel;
  final String? routeName;
  final String? listingId;
  final ArcTradeListingScore listingScore;
}

@immutable
class ArcOfferValueScore {
  const ArcOfferValueScore({
    required this.score,
    required this.label,
    required this.summary,
    required this.hints,
  });

  final int score;
  final String label;
  final String summary;
  final List<String> hints;
}

@immutable
class ArcTradeIntelligenceSummary {
  const ArcTradeIntelligenceSummary({
    required this.suggestions,
    required this.duplicateSuggestions,
    required this.wantedScores,
    required this.duplicateScores,
    required this.bestListingScore,
  });

  final List<ArcTradeMatchSuggestion> suggestions;
  final List<ArcTradeMatchSuggestion> duplicateSuggestions;
  final List<ArcTradeItemScore> wantedScores;
  final List<ArcTradeItemScore> duplicateScores;
  final ArcTradeListingScore? bestListingScore;

  static const empty = ArcTradeIntelligenceSummary(
    suggestions: <ArcTradeMatchSuggestion>[],
    duplicateSuggestions: <ArcTradeMatchSuggestion>[],
    wantedScores: <ArcTradeItemScore>[],
    duplicateScores: <ArcTradeItemScore>[],
    bestListingScore: null,
  );

  bool get hasSuggestions => suggestions.isNotEmpty;
  int get bestConfidence =>
      suggestions.isEmpty ? 0 : suggestions.first.confidence;
}
