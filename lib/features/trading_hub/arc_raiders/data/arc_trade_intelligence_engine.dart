import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';

class ArcTradeIntelligenceEngine {
  const ArcTradeIntelligenceEngine();

  ArcTradeIntelligenceSummary buildSummary({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<TradingListing> activeListings,
    String? currentUid,
    int suggestionLimit = 8,
  }) {
    if (activeListings.isEmpty && blueprintStates.isEmpty) {
      return ArcTradeIntelligenceSummary.empty;
    }

    final scores =
        activeListings
            .where((listing) => listing.isLive)
            .where(
              (listing) => currentUid == null || listing.ownerUid != currentUid,
            )
            .map(
              (listing) => _ScoredListing(
                listing: listing,
                score: scoreListing(
                  listing: listing,
                  blueprintStates: blueprintStates,
                  currentUid: currentUid,
                ),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final scoreCompare = b.score.score.compareTo(a.score.score);
            if (scoreCompare != 0) return scoreCompare;
            return a.listing.expiresAt.compareTo(b.listing.expiresAt);
          });

    final suggestions = scores
        .where((item) => item.score.isActionable)
        .map(
          (item) => _suggestionForListing(
            listing: item.listing,
            score: item.score,
            blueprintStates: blueprintStates,
          ),
        )
        .take(suggestionLimit)
        .toList(growable: false);

    final duplicateSuggestions = suggestions
        .where((suggestion) => suggestion.offeredItems.isNotEmpty)
        .toList(growable: false);

    return ArcTradeIntelligenceSummary(
      suggestions: suggestions,
      duplicateSuggestions: duplicateSuggestions,
      wantedScores: scoreWantedItems(
        blueprintStates: blueprintStates,
        activeListings: activeListings,
      ).take(6).toList(growable: false),
      duplicateScores: scoreDuplicateUsefulness(
        blueprintStates: blueprintStates,
        activeListings: activeListings,
      ).take(6).toList(growable: false),
      bestListingScore: scores.isEmpty ? null : scores.first.score,
    );
  }

  ArcTradeListingScore scoreListing({
    required TradingListing listing,
    required Map<String, ArcBlueprintState> blueprintStates,
    String? currentUid,
  }) {
    if (!listing.isLive) {
      return const ArcTradeListingScore(
        score: 0,
        label: 'Inactive',
        reason: 'This listing is no longer live.',
        recommendation: 'Skip',
        reasons: <String>['Listing is not live'],
        matchingOfferedItems: <String>[],
        matchingWantedItems: <String>[],
        reputationHint: 'Reputation not applied',
      );
    }

    if (currentUid != null && listing.ownerUid == currentUid) {
      return const ArcTradeListingScore(
        score: 0,
        label: 'Your Listing',
        reason: 'This is your own listing.',
        recommendation: 'Manage listing',
        reasons: <String>['Own listing'],
        matchingOfferedItems: <String>[],
        matchingWantedItems: <String>[],
        reputationHint: 'Own profile',
      );
    }

    final statesKnown = blueprintStates.isNotEmpty;
    final duplicateBlueprints = _duplicateBlueprints(blueprintStates);
    final missingBlueprints = statesKnown
        ? _missingBlueprints(blueprintStates)
        : const <String, ArcBlueprint>{};
    final offeredMatches = <String>[];
    final wantedMatches = <String>[];
    final reasons = <String>[];
    var score = 12;

    for (final blueprint in missingBlueprints.values) {
      if (_listingOffersBlueprint(listing, blueprint)) {
        offeredMatches.add(blueprint.name);
        score += blueprint.rarity == ArcBlueprintRarity.legendary ? 38 : 28;
        score += _priorityBonus(blueprintStates[blueprint.id]);
      }
    }

    for (final entry in duplicateBlueprints.entries) {
      final blueprint = entry.value;
      if (_listingWantsBlueprint(listing, blueprint)) {
        wantedMatches.add(blueprint.name);
        score += 24 + math.min(12, entry.key.dupesOwned * 3);
      }
    }

    if (listing.wantsNothing) {
      score += 18;
      reasons.add('Free giveaway');
    }
    if (listing.listingType == TradingListingType.openToOffers) {
      score += duplicateBlueprints.isNotEmpty ? 10 : 3;
      reasons.add('Open to offers');
    }
    if (listing.allowPartialOffers) {
      score += 4;
      reasons.add('Partial offers allowed');
    }
    if (listing.seedTotalOffered > 0 && statesKnown) {
      score += 4;
      reasons.add('Seed value listed');
    }

    final reputationAdjustment = _reputationAdjustment(listing);
    score += reputationAdjustment;

    if (offeredMatches.isNotEmpty) {
      reasons.add('Helps missing collection');
    }
    if (wantedMatches.isNotEmpty) {
      reasons.add('Uses duplicate blueprint value');
    }
    if (listing.riskLevel == TradingRiskLevel.low) {
      reasons.add('Lower risk trader');
    } else if (listing.riskLevel == TradingRiskLevel.high) {
      reasons.add('Reputation caution');
    }

    final clamped = score.clamp(0, 100).toInt();
    return ArcTradeListingScore(
      score: clamped,
      label: _listingScoreLabel(
        score: clamped,
        offeredMatches: offeredMatches,
        wantedMatches: wantedMatches,
      ),
      reason: _listingReason(
        offeredMatches: offeredMatches,
        wantedMatches: wantedMatches,
        listing: listing,
        statesKnown: statesKnown,
      ),
      recommendation: _recommendedActionLabel(clamped, listing),
      reasons: reasons.isEmpty
          ? const <String>['No direct collection signal']
          : reasons.toList(growable: false),
      matchingOfferedItems: offeredMatches.toList(growable: false),
      matchingWantedItems: wantedMatches.toList(growable: false),
      reputationHint: _reputationHint(listing),
    );
  }

  List<ArcTradeItemScore> scoreWantedItems({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<TradingListing> activeListings,
  }) {
    if (blueprintStates.isEmpty) return const <ArcTradeItemScore>[];

    final listingDemand = _wantedTokenCounts(activeListings);
    final listingSupply = _offeredTokenCounts(activeListings);
    final scores = <ArcTradeItemScore>[];

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          blueprintStates[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);
      if (state.owned) continue;

      final tokenDemand = listingDemand[_normalise(blueprint.name)] ?? 0;
      final idDemand = listingDemand[_normalise(blueprint.id)] ?? 0;
      final tokenSupply = listingSupply[_normalise(blueprint.name)] ?? 0;
      final idSupply = listingSupply[_normalise(blueprint.id)] ?? 0;
      final demand = tokenDemand + idDemand;
      final supply = tokenSupply + idSupply;
      final priority = _priorityBonus(state);
      final score =
          (35 +
                  _rarityScore(blueprint.rarity) * 7 +
                  priority +
                  demand * 4 +
                  math.min(12, supply * 3))
              .clamp(0, 100)
              .toInt();

      scores.add(
        ArcTradeItemScore(
          id: blueprint.id,
          label: blueprint.name,
          score: score,
          reason: _wantedReason(
            state: state,
            blueprint: blueprint,
            demand: demand,
            supply: supply,
          ),
        ),
      );
    }

    scores.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.label.compareTo(b.label);
    });
    return scores;
  }

  List<ArcTradeItemScore> scoreDuplicateUsefulness({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<TradingListing> activeListings,
  }) {
    if (blueprintStates.isEmpty) return const <ArcTradeItemScore>[];

    final listingDemand = _wantedTokenCounts(activeListings);
    final scores = <ArcTradeItemScore>[];

    for (final entry in _duplicateBlueprints(blueprintStates).entries) {
      final state = entry.key;
      final blueprint = entry.value;
      final demand =
          (listingDemand[_normalise(blueprint.name)] ?? 0) +
          (listingDemand[_normalise(blueprint.id)] ?? 0);
      final score =
          (30 +
                  math.min(18, state.dupesOwned * 4) +
                  _rarityScore(blueprint.rarity) * 6 +
                  demand * 8)
              .clamp(0, 100)
              .toInt();

      scores.add(
        ArcTradeItemScore(
          id: blueprint.id,
          label: blueprint.name,
          score: score,
          reason: demand > 0
              ? '$demand active listing ${demand == 1 ? 'wants' : 'want'} this duplicate.'
              : '${state.dupesOwned} duplicate ${state.dupesOwned == 1 ? 'copy' : 'copies'} available for listing drafts.',
        ),
      );
    }

    scores.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.label.compareTo(b.label);
    });
    return scores;
  }

  ArcOfferValueScore scoreOfferForListing({
    required TradingListing listing,
    required List<String> offeredBlueprintNames,
    required List<String> offeredTradeItemNames,
    required int seedTotal,
    required bool includesResources,
    required String resourceText,
  }) {
    if (listing.wantsNothing) {
      return const ArcOfferValueScore(
        score: 100,
        label: 'Giveaway Claim',
        summary: 'This listing does not require a return offer.',
        hints: <String>['Keep the note clear and confirm pickup details.'],
      );
    }

    final wantedTokens = _tokensFrom([
      listing.wantedText,
      ...listing.wantedBlueprintNames,
      ...listing.wantedAssetNames,
      ...listing.wantedTradeItemNames,
      ...listing.wantedTradeItemIds,
    ]);
    final offeredTokens = _tokensFrom([
      ...offeredBlueprintNames,
      ...offeredTradeItemNames,
      if (includesResources) resourceText,
    ]);
    final directMatches = offeredTokens.intersection(wantedTokens);
    final hints = <String>[];
    var score = 12;

    if (directMatches.isNotEmpty) {
      score += 48;
      hints.add('Offer includes ${directMatches.length} requested match.');
    }
    if (seedTotal > 0 && listing.acceptsSeeds) {
      score += math.min(24, 8 + (seedTotal / 50).floor() * 4);
      hints.add('Seeds are accepted by this listing.');
    } else if (seedTotal > 0) {
      score += 4;
      hints.add('Seeds add value, but this listing did not request them.');
    }
    if (includesResources && listing.acceptsResources) {
      score += 14;
      hints.add('Resources are accepted by this listing.');
    }
    if (offeredTradeItemNames.isNotEmpty) {
      score += math.min(16, offeredTradeItemNames.length * 5);
      hints.add('Trade assets increase offer flexibility.');
    }
    if (offeredBlueprintNames.isNotEmpty && listing.acceptsBlueprints) {
      score += math.min(16, offeredBlueprintNames.length * 6);
      hints.add('Blueprints are accepted by this listing.');
    }
    if (listing.seriousOffersOnly && directMatches.isEmpty) {
      score -= 12;
      hints.add(
        'Serious-only listing: include a direct wanted item if possible.',
      );
    }

    final clamped = score.clamp(0, 100).toInt();
    return ArcOfferValueScore(
      score: clamped,
      label: _offerScoreLabel(clamped),
      summary: _offerSummaryLabel(clamped),
      hints: hints.isEmpty
          ? const <String>[
              'Add a requested blueprint, item, seed bundle or resource to improve this offer.',
            ]
          : hints.toList(growable: false),
    );
  }

  ArcTradeMatchSuggestion _suggestionForListing({
    required TradingListing listing,
    required ArcTradeListingScore score,
    required Map<String, ArcBlueprintState> blueprintStates,
  }) {
    final duplicateOffers = score.matchingWantedItems.isNotEmpty
        ? score.matchingWantedItems
        : _topDuplicateLabels(blueprintStates).take(2).toList(growable: false);
    final requested = score.matchingOfferedItems.isNotEmpty
        ? score.matchingOfferedItems
        : listing.allOfferedItems.take(3).toList(growable: false);

    return ArcTradeMatchSuggestion(
      title: score.label,
      reason: score.reason,
      offeredItems: duplicateOffers,
      requestedItems: requested,
      confidence: score.score,
      priority: _priorityLabel(score.score),
      actionLabel: score.recommendation,
      routeName: TraderHubScreen.routeName,
      listingId: listing.id,
      listingScore: score,
    );
  }

  Map<ArcBlueprintState, ArcBlueprint> _duplicateBlueprints(
    Map<String, ArcBlueprintState> states,
  ) {
    final duplicates = <ArcBlueprintState, ArcBlueprint>{};
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (state.hasDuplicates) {
        duplicates[state] = blueprint;
      }
    }
    return duplicates;
  }

  Map<String, ArcBlueprint> _missingBlueprints(
    Map<String, ArcBlueprintState> states,
  ) {
    final missing = <String, ArcBlueprint>{};
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (!state.owned) {
        missing[blueprint.id] = blueprint;
      }
    }
    return missing;
  }

  List<String> _topDuplicateLabels(Map<String, ArcBlueprintState> states) {
    final scored = _duplicateBlueprints(states).entries.toList()
      ..sort((a, b) {
        final dupeCompare = b.key.dupesOwned.compareTo(a.key.dupesOwned);
        if (dupeCompare != 0) return dupeCompare;
        return _rarityScore(
          b.value.rarity,
        ).compareTo(_rarityScore(a.value.rarity));
      });
    return scored.map((entry) => entry.value.name).toList(growable: false);
  }

  bool _listingOffersBlueprint(TradingListing listing, ArcBlueprint blueprint) {
    final tokens = _tokensFrom([
      listing.offeredItem,
      ...listing.offeredBlueprintNames,
      ...listing.offeredTradeItemIds,
      ...listing.offeredTradeItemNames,
    ]);
    return tokens.contains(_normalise(blueprint.id)) ||
        tokens.contains(_normalise(blueprint.name));
  }

  bool _listingWantsBlueprint(TradingListing listing, ArcBlueprint blueprint) {
    final tokens = _tokensFrom([
      listing.wantedText,
      ...listing.wantedBlueprintNames,
      ...listing.wantedTradeItemIds,
      ...listing.wantedTradeItemNames,
    ]);
    return tokens.contains(_normalise(blueprint.id)) ||
        tokens.contains(_normalise(blueprint.name));
  }

  Map<String, int> _wantedTokenCounts(List<TradingListing> listings) {
    final counts = <String, int>{};
    for (final listing in listings.where((item) => item.isLive)) {
      for (final token in _tokensFrom([
        listing.wantedText,
        ...listing.wantedBlueprintNames,
        ...listing.wantedAssetNames,
        ...listing.wantedTradeItemIds,
        ...listing.wantedTradeItemNames,
      ])) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> _offeredTokenCounts(List<TradingListing> listings) {
    final counts = <String, int>{};
    for (final listing in listings.where((item) => item.isLive)) {
      for (final token in _tokensFrom([
        listing.offeredItem,
        ...listing.offeredBlueprintNames,
        ...listing.offeredAssetNames,
        ...listing.offeredTradeItemIds,
        ...listing.offeredTradeItemNames,
      ])) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }
    return counts;
  }

  Set<String> _tokensFrom(Iterable<String> values) {
    return values
        .expand((value) => value.split(','))
        .map(_normalise)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  int _priorityBonus(ArcBlueprintState? state) {
    final rank = state?.priorityRank ?? 0;
    if (rank <= 0) return 0;
    if (rank == 1) return 26;
    if (rank == 2) return 22;
    if (rank == 3) return 18;
    if (rank == 4) return 14;
    if (rank == 5) return 10;
    return 4;
  }

  int _rarityScore(ArcBlueprintRarity rarity) {
    switch (rarity) {
      case ArcBlueprintRarity.legendary:
        return 5;
      case ArcBlueprintRarity.epic:
        return 4;
      case ArcBlueprintRarity.rare:
        return 3;
      case ArcBlueprintRarity.uncommon:
        return 2;
      case ArcBlueprintRarity.common:
        return 1;
    }
  }

  int _reputationAdjustment(TradingListing listing) {
    switch (listing.riskLevel) {
      case TradingRiskLevel.low:
        return 8;
      case TradingRiskLevel.medium:
        return 0;
      case TradingRiskLevel.high:
        return -14;
    }
  }

  String _reputationHint(TradingListing listing) {
    switch (listing.riskLevel) {
      case TradingRiskLevel.low:
        return '${listing.completedTrades} completed trades, no current caution flags.';
      case TradingRiskLevel.medium:
        return 'Moderate reputation signal; confirm details before swapping.';
      case TradingRiskLevel.high:
        return 'Caution: no-shows or flags are present. Verify terms carefully.';
    }
  }

  String _listingScoreLabel({
    required int score,
    required List<String> offeredMatches,
    required List<String> wantedMatches,
  }) {
    if (score >= 88 && offeredMatches.isNotEmpty && wantedMatches.isNotEmpty) {
      return 'High Value Match';
    }
    if (offeredMatches.isNotEmpty && wantedMatches.isNotEmpty) {
      return 'Good Blueprint Swap';
    }
    if (offeredMatches.isNotEmpty) return 'Helps Your Collection';
    if (wantedMatches.isNotEmpty) return 'Duplicate Clearance';
    if (score >= 55) return 'Worth Reviewing';
    return 'Low Priority';
  }

  String _listingReason({
    required List<String> offeredMatches,
    required List<String> wantedMatches,
    required TradingListing listing,
    required bool statesKnown,
  }) {
    if (!statesKnown) {
      return 'Blueprint state is not available yet, so this is a general trade read.';
    }
    if (offeredMatches.isNotEmpty && wantedMatches.isNotEmpty) {
      return 'They offer ${offeredMatches.first} and want ${wantedMatches.first}.';
    }
    if (offeredMatches.isNotEmpty) {
      return 'They offer ${offeredMatches.first}, which is missing from your collection.';
    }
    if (wantedMatches.isNotEmpty) {
      return 'They want ${wantedMatches.first}, which you have duplicated.';
    }
    if (listing.wantsNothing) return 'Free giveaway listing.';
    return 'No direct duplicate or missing blueprint match found.';
  }

  String _recommendedActionLabel(int score, TradingListing listing) {
    if (listing.wantsNothing) return 'Claim giveaway';
    if (score >= 75) return 'Make offer';
    if (score >= 50) return 'Review trade';
    return 'Inspect listing';
  }

  String _wantedReason({
    required ArcBlueprintState state,
    required ArcBlueprint blueprint,
    required int demand,
    required int supply,
  }) {
    final parts = <String>[
      '${blueprint.rarityLabel} missing blueprint',
      if (state.priorityRank > 0) 'priority #${state.priorityRank}',
      if (demand > 0) '$demand active demand signal',
      if (supply > 0) '$supply active supply signal',
    ];
    return parts.join(' - ');
  }

  String _offerScoreLabel(int score) {
    if (score >= 82) return 'High Value Offer';
    if (score >= 62) return 'Good Offer';
    if (score >= 42) return 'Possible Offer';
    return 'Low Priority Offer';
  }

  String _offerSummaryLabel(int score) {
    if (score >= 82) return 'Strong match for this listing.';
    if (score >= 62) return 'Likely useful, confirm exact terms.';
    if (score >= 42) {
      return 'Some value present, but add a closer match if possible.';
    }
    return 'Add a direct wanted item before sending if you can.';
  }

  String _priorityLabel(int score) {
    if (score >= 82) return 'High';
    if (score >= 60) return 'Medium';
    return 'Low';
  }

  String _normalise(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ScoredListing {
  const _ScoredListing({required this.listing, required this.score});

  final TradingListing listing;
  final ArcTradeListingScore score;
}
