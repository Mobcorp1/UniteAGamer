import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_bundle_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_network_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';

class ArcTradeIntelligenceEngine {
  const ArcTradeIntelligenceEngine();

  ArcTradeNetworkSummary buildNetworkSummary({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<TradingListing> activeListings,
    required String? currentUid,
    Map<String, int> ownedItemQuantities = const <String, int>{},
    int limitPerSection = 6,
  }) {
    final uid = currentUid?.trim() ?? '';
    if (uid.isEmpty || activeListings.isEmpty) {
      return ArcTradeNetworkSummary.empty;
    }

    final signals = activeListings
        .where((listing) => listing.isLive)
        .map(_ListingSignal.fromListing)
        .where((signal) => signal.hasTradeShape)
        .toList(growable: false);
    if (signals.isEmpty) return ArcTradeNetworkSummary.empty;

    final mySignals = signals
        .where((signal) => signal.ownerUid == uid)
        .toList(growable: false);
    final otherSignals = signals
        .where((signal) => signal.ownerUid != uid)
        .toList(growable: false);
    final ownedQuantities = buildOwnedItemQuantities(
      blueprintStates: blueprintStates,
      trackedItemQuantities: ownedItemQuantities,
    );
    final wantedPriority = _wantedPriorityByItemId(blueprintStates);

    final direct = _buildDirectMatches(
      mySignals: mySignals,
      otherSignals: otherSignals,
      wantedPriority: wantedPriority,
      limit: limitPerSection,
    );
    final chains = _buildThreeRaiderChains(
      mySignals: mySignals,
      otherSignals: otherSignals,
      wantedPriority: wantedPriority,
      limit: limitPerSection,
    );
    final preparation = _buildPreparationOpportunities(
      otherSignals: otherSignals,
      wantedPriority: wantedPriority,
      ownedQuantities: ownedQuantities,
      limit: limitPerSection,
    );
    final needsMine = _buildPeopleNeedingMyItems(
      otherSignals: otherSignals,
      ownedQuantities: ownedQuantities,
      limit: limitPerSection,
    );
    final offersWanted = _buildPeopleOfferingWantedItems(
      otherSignals: otherSignals,
      wantedPriority: wantedPriority,
      limit: limitPerSection,
    );

    return ArcTradeNetworkSummary(
      directMatches: direct,
      threeRaiderChains: chains,
      preparationOpportunities: preparation,
      playersNeedingMyItems: needsMine,
      playersOfferingWantedItems: offersWanted,
    );
  }

  Map<String, int> buildOwnedItemQuantities({
    required Map<String, ArcBlueprintState> blueprintStates,
    Map<String, int> trackedItemQuantities = const <String, int>{},
  }) {
    final owned = <String, int>{};

    void add(String raw, int quantity) {
      if (quantity <= 0) return;
      final item = _itemFromValue(raw, fallbackQuantity: quantity);
      if (item.isEmpty) return;
      owned[item.id] = (owned[item.id] ?? 0) + quantity;
    }

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          blueprintStates[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);
      if (state.dupesOwned <= 0) continue;
      add(blueprint.id, state.dupesOwned);
      add(blueprint.name, state.dupesOwned);
    }

    for (final entry in trackedItemQuantities.entries) {
      add(entry.key, entry.value);
    }

    return owned;
  }

  ArcTradePreparation buildPreparation({
    required String userId,
    required ArcTradeOpportunity opportunity,
    required DateTime now,
  }) {
    final status = opportunity.remainingItems.isEmpty
        ? ArcTradePreparationStatus.ready
        : ArcTradePreparationStatus.farming;
    final idSource = [
      userId,
      opportunity.targetListingId ?? opportunity.id,
      opportunity.requiredItems.map((item) => '${item.id}:${item.quantity}'),
    ].join('|');

    return ArcTradePreparation(
      id: _stableId('prep-$idSource'),
      userId: userId,
      targetListingId: opportunity.targetListingId ?? '',
      targetPlayerId: opportunity.targetPlayerId ?? '',
      listingTitle: opportunity.title,
      requiredItems: opportunity.requiredItems,
      ownedItems: opportunity.ownedItems,
      remainingItems: opportunity.remainingItems,
      status: status,
      createdAt: now,
      updatedAt: now,
      note: 'Opportunity is not guaranteed until both parties agree.',
    );
  }

  ArcTradePreparation recalculatePreparationReadiness({
    required ArcTradePreparation preparation,
    required Map<String, int> ownedItemQuantities,
    required DateTime now,
  }) {
    final readiness = _readinessFor(
      preparation.requiredItems,
      ownedItemQuantities,
    );
    final nextStatus = preparation.status.isTerminal
        ? preparation.status
        : readiness.remainingItems.isEmpty
        ? ArcTradePreparationStatus.ready
        : ArcTradePreparationStatus.farming;

    return preparation.copyWith(
      ownedItems: readiness.ownedItems,
      remainingItems: readiness.remainingItems,
      status: nextStatus,
      updatedAt: now,
    );
  }

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
    ArcExactTradeBundleOffer? exactBundleOffer,
  }) {
    if (listing.wantsNothing) {
      return const ArcOfferValueScore(
        score: 100,
        label: 'Giveaway Claim',
        summary: 'This listing does not require a return offer.',
        hints: <String>['Keep the note clear and confirm pickup details.'],
      );
    }

    final structuredScore = exactBundleOffer == null
        ? null
        : _scoreExactBundleOffer(
            listing: listing,
            exactBundleOffer: exactBundleOffer,
          );
    if (structuredScore != null) return structuredScore;

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

  ArcOfferValueScore? _scoreExactBundleOffer({
    required TradingListing listing,
    required ArcExactTradeBundleOffer exactBundleOffer,
  }) {
    final templates = listing.acceptedBundles.where(
      (bundle) => bundle.active && bundle.id == exactBundleOffer.templateId,
    );
    if (templates.isEmpty) {
      return const ArcOfferValueScore(
        score: 20,
        label: 'Bundle Unavailable',
        summary: 'The selected structured bundle is no longer listed.',
        hints: <String>[
          'Refresh the listing before sending or shape a custom offer.',
        ],
      );
    }

    final template = templates.first;
    final result = const ArcTradeBundleEngine().compare(
      template: template,
      offer: exactBundleOffer,
    );
    final hints = <String>[
      template.effectiveTerms.summary,
      if (result.missing.isNotEmpty) 'Missing: ${result.missing.join(', ')}.',
      if (result.incorrect.isNotEmpty) ...result.incorrect,
      if (result.unexpected.isNotEmpty)
        'Unexpected: ${result.unexpected.join(', ')}.',
      if (result.equivalentSubstitutions.isNotEmpty)
        'Substitutions: ${result.equivalentSubstitutions.join(', ')}.',
      if (exactBundleOffer.preparing)
        'Sender marked this bundle as still being prepared.',
      if (exactBundleOffer.completionConfirmed)
        'Sender confirmed the selected bundle is ready.',
    ];
    final baseScore = switch (result.status) {
      ArcTradeBundleMatchStatus.exact => 90,
      ArcTradeBundleMatchStatus.partial => 58,
      ArcTradeBundleMatchStatus.mismatch => 24,
    };
    final adjusted =
        (baseScore +
                (exactBundleOffer.completionConfirmed ? 4 : 0) -
                (exactBundleOffer.preparing ? 8 : 0))
            .clamp(0, 100)
            .toInt();

    return ArcOfferValueScore(
      score: adjusted,
      label: result.isExact ? 'Structured Match' : _offerScoreLabel(adjusted),
      summary: result.isExact
          ? 'This offer matches the seller-approved structured bundle.'
          : 'This offer does not fully match the seller-approved bundle yet.',
      hints: hints,
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

  List<ArcTradeOpportunity> _buildDirectMatches({
    required List<_ListingSignal> mySignals,
    required List<_ListingSignal> otherSignals,
    required Map<String, int> wantedPriority,
    required int limit,
  }) {
    final matches = <ArcTradeOpportunity>[];
    final seen = <String>{};

    for (final mine in mySignals) {
      if (mine.hasSameOfferedAndWanted) continue;
      for (final theirs in otherSignals) {
        if (theirs.hasSameOfferedAndWanted) continue;
        if (mine.listing.id == theirs.listing.id ||
            mine.ownerUid == theirs.ownerUid) {
          continue;
        }

        final iGive = _intersection(mine.offeredItems, theirs.wantedItems);
        final iReceive = _intersection(theirs.offeredItems, mine.wantedItems);
        if (iGive.isEmpty || iReceive.isEmpty) continue;

        final key = 'direct:${mine.listing.id}:${theirs.listing.id}';
        if (!seen.add(key)) continue;

        final topWanted = _containsTopWanted(iReceive, wantedPriority);
        final priority = _bestPriority(iReceive, wantedPriority);
        final confidence = (topWanted ? 96 : 86) + _reputationBonus(theirs);
        matches.add(
          ArcTradeOpportunity(
            id: key,
            type: ArcTradeOpportunityType.direct,
            title: topWanted ? 'Perfect Direct Match' : 'Direct Trade Match',
            reason:
                'You can offer ${_itemsLabel(iGive)} for ${_itemsLabel(iReceive)} through ${theirs.listing.traderName}.',
            actionLabel: 'Open listing',
            confidence: confidence.clamp(0, 100),
            rankScore: topWanted ? 5000 - priority : 3000 - priority,
            listingIds: <String>[mine.listing.id, theirs.listing.id],
            participantUids: <String>[mine.ownerUid, theirs.ownerUid],
            currentUserGives: iGive,
            currentUserReceives: iReceive,
            requiredItems: iGive,
            ownedItems: iGive,
            remainingItems: const <ArcTradeItemQuantity>[],
            targetListingId: theirs.listing.id,
            targetPlayerId: theirs.ownerUid,
            routeName: TraderHubScreen.routeName,
            satisfiesTopWanted: topWanted,
            progressionHint: topWanted
                ? 'Fulfils your highest priority wanted item.'
                : 'Fulfils a wanted item with an active reciprocal listing.',
            isGuaranteed: false,
            notes: const <String>[
              'Not guaranteed until both parties agree in chat.',
            ],
          ),
        );
      }
    }

    matches.sort(_opportunitySort);
    return matches.take(limit).toList(growable: false);
  }

  List<ArcTradeOpportunity> _buildThreeRaiderChains({
    required List<_ListingSignal> mySignals,
    required List<_ListingSignal> otherSignals,
    required Map<String, int> wantedPriority,
    required int limit,
  }) {
    final chains = <ArcTradeOpportunity>[];
    final seen = <String>{};

    for (final mine in mySignals) {
      if (mine.hasSameOfferedAndWanted) continue;
      for (final middle in otherSignals) {
        if (middle.hasSameOfferedAndWanted ||
            middle.ownerUid == mine.ownerUid) {
          continue;
        }
        final mineToMiddle = _intersection(
          mine.offeredItems,
          middle.wantedItems,
        );
        if (mineToMiddle.isEmpty) continue;

        for (final end in otherSignals) {
          if (end.hasSameOfferedAndWanted ||
              end.listing.id == middle.listing.id ||
              end.ownerUid == mine.ownerUid ||
              end.ownerUid == middle.ownerUid) {
            continue;
          }

          final middleToEnd = _intersection(
            middle.offeredItems,
            end.wantedItems,
          );
          final endToMine = _intersection(end.offeredItems, mine.wantedItems);
          if (middleToEnd.isEmpty || endToMine.isEmpty) continue;

          final listingKey = [
            mine.listing.id,
            middle.listing.id,
            end.listing.id,
          ]..sort();
          final key = 'chain:${listingKey.join(':')}';
          if (!seen.add(key)) continue;

          final topWanted = _containsTopWanted(endToMine, wantedPriority);
          final priority = _bestPriority(endToMine, wantedPriority);
          final confidence =
              (topWanted ? 84 : 74) +
              ((_reputationBonus(middle) + _reputationBonus(end)) / 2).round();

          chains.add(
            ArcTradeOpportunity(
              id: key,
              type: ArcTradeOpportunityType.threeRaiderChain,
              title: topWanted
                  ? 'High-Value Three-Raider Chain'
                  : 'Three-Raider Chain',
              reason:
                  'You give ${_itemsLabel(mineToMiddle)} to ${middle.listing.traderName}; '
                  '${middle.listing.traderName} gives ${_itemsLabel(middleToEnd)} to ${end.listing.traderName}; '
                  '${end.listing.traderName} gives ${_itemsLabel(endToMine)} to you.',
              actionLabel: 'Review chain',
              confidence: confidence.clamp(0, 100),
              rankScore: topWanted ? 4200 - priority : 2400 - priority,
              listingIds: <String>[
                mine.listing.id,
                middle.listing.id,
                end.listing.id,
              ],
              participantUids: <String>[
                mine.ownerUid,
                middle.ownerUid,
                end.ownerUid,
              ],
              currentUserGives: mineToMiddle,
              currentUserReceives: endToMine,
              requiredItems: mineToMiddle,
              ownedItems: mineToMiddle,
              remainingItems: const <ArcTradeItemQuantity>[],
              targetListingId: end.listing.id,
              targetPlayerId: end.ownerUid,
              routeName: TraderHubScreen.routeName,
              satisfiesTopWanted: topWanted,
              progressionHint: topWanted
                  ? 'Completes your highest priority wanted item through a three-player loop.'
                  : 'Turns your duplicate into a wanted item through two other listings.',
              isGuaranteed: false,
              notes: const <String>[
                'Every participant must still agree before this trade is real.',
              ],
            ),
          );
        }
      }
    }

    chains.sort(_opportunitySort);
    return chains.take(limit).toList(growable: false);
  }

  List<ArcTradeOpportunity> _buildPreparationOpportunities({
    required List<_ListingSignal> otherSignals,
    required Map<String, int> wantedPriority,
    required Map<String, int> ownedQuantities,
    required int limit,
  }) {
    final opportunities = <ArcTradeOpportunity>[];

    for (final listing in otherSignals) {
      if (listing.wantedItems.isEmpty || listing.hasSameOfferedAndWanted) {
        continue;
      }

      final receive = _wantedItemsFrom(listing.offeredItems, wantedPriority);
      if (receive.isEmpty) continue;

      final readiness = _readinessFor(listing.wantedItems, ownedQuantities);
      if (readiness.remainingItems.isEmpty) continue;

      final topWanted = _containsTopWanted(receive, wantedPriority);
      final priority = _bestPriority(receive, wantedPriority);
      final ownedAny = readiness.ownedItems.any((item) => item.quantity > 0);
      final confidence = topWanted ? 68 : 56;

      opportunities.add(
        ArcTradeOpportunity(
          id: 'prepare:${listing.listing.id}',
          type: ArcTradeOpportunityType.prepare,
          title: topWanted ? 'Prepare for Priority Trade' : 'Prepare for Trade',
          reason:
              '${listing.listing.traderName} offers ${_itemsLabel(receive)}. '
              'You still need ${_itemsLabel(readiness.remainingItems)} to meet the requested payment.',
          actionLabel: 'Prepare for this trade',
          confidence: confidence,
          rankScore: topWanted
              ? 1500 - priority + (ownedAny ? 80 : 0)
              : 900 - priority + (ownedAny ? 60 : 0),
          listingIds: <String>[listing.listing.id],
          participantUids: <String>[listing.ownerUid],
          currentUserGives: listing.wantedItems,
          currentUserReceives: receive,
          requiredItems: listing.wantedItems,
          ownedItems: readiness.ownedItems,
          remainingItems: readiness.remainingItems,
          targetListingId: listing.listing.id,
          targetPlayerId: listing.ownerUid,
          routeName: TraderHubScreen.routeName,
          satisfiesTopWanted: topWanted,
          progressionHint: ownedAny
              ? 'Partial payment is already tracked.'
              : 'Farm or trade for the requested payment first.',
          isGuaranteed: false,
          notes: const <String>[
            'This watch does not reserve or lock the listing.',
          ],
        ),
      );
    }

    opportunities.sort(_opportunitySort);
    return opportunities.take(limit).toList(growable: false);
  }

  List<ArcTradeOpportunity> _buildPeopleNeedingMyItems({
    required List<_ListingSignal> otherSignals,
    required Map<String, int> ownedQuantities,
    required int limit,
  }) {
    final ownedItems = ownedQuantities.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => ArcTradeItemQuantity(
            id: entry.key,
            label: entry.key,
            quantity: 1,
          ),
        )
        .toList(growable: false);
    final results = <ArcTradeOpportunity>[];

    for (final listing in otherSignals) {
      final give = _intersection(ownedItems, listing.wantedItems);
      if (give.isEmpty) continue;
      results.add(
        ArcTradeOpportunity(
          id: 'needs:${listing.listing.id}',
          type: ArcTradeOpportunityType.prepare,
          title: 'Player Needs Your Duplicate',
          reason: '${listing.listing.traderName} needs ${_itemsLabel(give)}.',
          actionLabel: 'Inspect listing',
          confidence: 44,
          rankScore: 440,
          listingIds: <String>[listing.listing.id],
          participantUids: <String>[listing.ownerUid],
          currentUserGives: give,
          currentUserReceives: listing.offeredItems.take(2).toList(),
          requiredItems: give,
          ownedItems: give,
          remainingItems: const <ArcTradeItemQuantity>[],
          targetListingId: listing.listing.id,
          targetPlayerId: listing.ownerUid,
          routeName: TraderHubScreen.routeName,
          isGuaranteed: false,
        ),
      );
    }

    results.sort(_opportunitySort);
    return results.take(limit).toList(growable: false);
  }

  List<ArcTradeOpportunity> _buildPeopleOfferingWantedItems({
    required List<_ListingSignal> otherSignals,
    required Map<String, int> wantedPriority,
    required int limit,
  }) {
    final results = <ArcTradeOpportunity>[];

    for (final listing in otherSignals) {
      final receive = _wantedItemsFrom(listing.offeredItems, wantedPriority);
      if (receive.isEmpty) continue;
      final topWanted = _containsTopWanted(receive, wantedPriority);
      results.add(
        ArcTradeOpportunity(
          id: 'offers:${listing.listing.id}',
          type: ArcTradeOpportunityType.prepare,
          title: topWanted ? 'Priority Item Available' : 'Wanted Item Seen',
          reason:
              '${listing.listing.traderName} is offering ${_itemsLabel(receive)}.',
          actionLabel: 'Inspect listing',
          confidence: topWanted ? 58 : 48,
          rankScore: topWanted ? 620 : 520,
          listingIds: <String>[listing.listing.id],
          participantUids: <String>[listing.ownerUid],
          currentUserGives: listing.wantedItems,
          currentUserReceives: receive,
          requiredItems: listing.wantedItems,
          ownedItems: const <ArcTradeItemQuantity>[],
          remainingItems: listing.wantedItems,
          targetListingId: listing.listing.id,
          targetPlayerId: listing.ownerUid,
          routeName: TraderHubScreen.routeName,
          satisfiesTopWanted: topWanted,
          isGuaranteed: false,
        ),
      );
    }

    results.sort(_opportunitySort);
    return results.take(limit).toList(growable: false);
  }

  _PaymentReadiness _readinessFor(
    List<ArcTradeItemQuantity> requiredItems,
    Map<String, int> ownedQuantities,
  ) {
    final owned = <ArcTradeItemQuantity>[];
    final remaining = <ArcTradeItemQuantity>[];

    for (final required in _combineQuantities(requiredItems)) {
      final available = ownedQuantities[required.id] ?? 0;
      final ownedQuantity = math.min(required.quantity, available);
      if (ownedQuantity > 0) {
        owned.add(required.copyWith(quantity: ownedQuantity));
      }
      final missing = required.quantity - ownedQuantity;
      if (missing > 0) {
        remaining.add(required.copyWith(quantity: missing));
      }
    }

    return _PaymentReadiness(
      ownedItems: owned.toList(growable: false),
      remainingItems: remaining.toList(growable: false),
    );
  }

  List<ArcTradeItemQuantity> _intersection(
    List<ArcTradeItemQuantity> first,
    List<ArcTradeItemQuantity> second,
  ) {
    final byId = <String, ArcTradeItemQuantity>{
      for (final item in second) item.id: item,
    };
    final matches = <ArcTradeItemQuantity>[];
    final seen = <String>{};

    for (final item in first) {
      final match = byId[item.id];
      if (match == null || !seen.add(item.id)) continue;
      matches.add(
        item.copyWith(quantity: math.min(item.quantity, match.quantity)),
      );
    }
    return matches.toList(growable: false);
  }

  List<ArcTradeItemQuantity> _wantedItemsFrom(
    List<ArcTradeItemQuantity> items,
    Map<String, int> wantedPriority,
  ) {
    final result = items
        .where((item) => wantedPriority.containsKey(item.id))
        .toList(growable: false);
    result.sort((a, b) {
      final priorityCompare = (wantedPriority[a.id] ?? 9999).compareTo(
        wantedPriority[b.id] ?? 9999,
      );
      if (priorityCompare != 0) return priorityCompare;
      return a.label.compareTo(b.label);
    });
    return result;
  }

  Map<String, int> _wantedPriorityByItemId(
    Map<String, ArcBlueprintState> states,
  ) {
    final wanted = <String, int>{};
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (state.owned) continue;
      final priority = state.priorityRank > 0 ? state.priorityRank : 999;
      wanted[_itemFromValue(blueprint.id).id] = priority;
      wanted[_itemFromValue(blueprint.name).id] = priority;
    }
    return wanted;
  }

  bool _containsTopWanted(
    List<ArcTradeItemQuantity> items,
    Map<String, int> wantedPriority,
  ) {
    return items.any((item) => wantedPriority[item.id] == 1);
  }

  int _bestPriority(
    List<ArcTradeItemQuantity> items,
    Map<String, int> wantedPriority,
  ) {
    var best = 9999;
    for (final item in items) {
      best = math.min(best, wantedPriority[item.id] ?? 9999);
    }
    return best;
  }

  int _reputationBonus(_ListingSignal signal) {
    switch (signal.listing.riskLevel) {
      case TradingRiskLevel.low:
        return 4;
      case TradingRiskLevel.medium:
        return 0;
      case TradingRiskLevel.high:
        return -8;
    }
  }

  int _opportunitySort(ArcTradeOpportunity a, ArcTradeOpportunity b) {
    final rankCompare = b.rankScore.compareTo(a.rankScore);
    if (rankCompare != 0) return rankCompare;
    final confidenceCompare = b.confidence.compareTo(a.confidence);
    if (confidenceCompare != 0) return confidenceCompare;
    return a.id.compareTo(b.id);
  }

  String _itemsLabel(List<ArcTradeItemQuantity> items) {
    if (items.isEmpty) return 'nothing tracked';
    return items
        .take(3)
        .map(
          (item) =>
              item.quantity > 1 ? '${item.quantity} ${item.label}' : item.label,
        )
        .join(', ');
  }

  List<ArcTradeItemQuantity> _combineQuantities(
    Iterable<ArcTradeItemQuantity> items,
  ) {
    final byId = <String, ArcTradeItemQuantity>{};
    for (final item in items) {
      if (item.isEmpty) continue;
      final existing = byId[item.id];
      byId[item.id] = existing == null
          ? item
          : existing.copyWith(quantity: existing.quantity + item.quantity);
    }
    final values = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return values.toList(growable: false);
  }

  List<ArcTradeItemQuantity> _extractListingItems({
    required List<String> idValues,
    required List<String> nameValues,
    int includeSeeds = 0,
  }) {
    final items = <ArcTradeItemQuantity>[];

    for (var index = 0; index < idValues.length; index++) {
      final rawId = idValues[index].trim();
      if (rawId.isEmpty) continue;
      final label =
          index < nameValues.length && nameValues[index].trim().isNotEmpty
          ? nameValues[index].trim()
          : rawId;
      final labelItem = _itemFromValue(label);
      final idItem = _itemFromValue(rawId);
      items.add(labelItem);
      if (idItem.id != labelItem.id) items.add(idItem);
    }

    for (final value in nameValues) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) continue;
      for (final part in cleaned.split(',')) {
        final item = _itemFromValue(part);
        if (!item.isEmpty) items.add(item);
      }
    }

    if (includeSeeds > 0) {
      items.add(
        ArcTradeItemQuantity(
          id: 'assorted-seeds',
          label: 'Assorted Seeds',
          quantity: includeSeeds,
        ),
      );
    }

    return _combineListingQuantities(items);
  }

  List<ArcTradeItemQuantity> _itemsFromBundleComponents(
    Iterable<ArcTradeBundleComponent> components,
  ) {
    return _combineListingQuantities(
      components.map((component) {
        final source = component.itemId.trim().isNotEmpty
            ? component.itemId
            : component.itemName;
        final item = _itemFromValue(
          source,
          fallbackQuantity: component.quantity,
        );
        return item.copyWith(
          label: component.itemName.trim().isEmpty
              ? item.label
              : component.itemName.trim(),
          quantity: component.quantity,
        );
      }),
    );
  }

  List<ArcTradeItemQuantity> _combineListingQuantities(
    Iterable<ArcTradeItemQuantity> items,
  ) {
    final byId = <String, ArcTradeItemQuantity>{};
    for (final item in items) {
      if (item.isEmpty) continue;
      final existing = byId[item.id];
      if (existing == null || item.quantity > existing.quantity) {
        byId[item.id] = item;
      }
    }
    final values = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return values.toList(growable: false);
  }

  ArcTradeItemQuantity _itemFromValue(
    String value, {
    int fallbackQuantity = 1,
  }) {
    var raw = value.trim();
    if (raw.isEmpty) {
      return const ArcTradeItemQuantity(id: '', label: '', quantity: 0);
    }

    var quantity = fallbackQuantity <= 0 ? 1 : fallbackQuantity;
    final quantityMatch = RegExp(r'^\s*(\d+)[\s-]+(.+)$').firstMatch(raw);
    if (quantityMatch != null) {
      quantity = int.tryParse(quantityMatch.group(1) ?? '') ?? quantity;
      raw = quantityMatch.group(2)?.trim() ?? raw;
    }

    final blueprint = _blueprintFor(raw);
    if (blueprint != null) {
      return ArcTradeItemQuantity(
        id: _itemId(blueprint.id),
        label: blueprint.name,
        quantity: quantity,
      );
    }

    final unified = UnifiedItemIndex.findBest(raw);
    if (unified != null) {
      return ArcTradeItemQuantity(
        id: _itemId(unified.id),
        label: unified.name,
        quantity: quantity,
      );
    }

    return ArcTradeItemQuantity(
      id: _itemId(raw),
      label: _titleFromRaw(raw),
      quantity: quantity,
    );
  }

  ArcBlueprint? _blueprintFor(String value) {
    final normalized = _normalise(value);
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (_normalise(blueprint.id) == normalized ||
          _normalise(blueprint.name) == normalized) {
        return blueprint;
      }
    }
    return null;
  }

  String _itemId(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _titleFromRaw(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(RegExp(r'\s+|-+|_+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _stableId(String raw) {
    return _itemId(raw).replaceAll(RegExp(r'-+'), '-');
  }
}

class _ScoredListing {
  const _ScoredListing({required this.listing, required this.score});

  final TradingListing listing;
  final ArcTradeListingScore score;
}

class _PaymentReadiness {
  const _PaymentReadiness({
    required this.ownedItems,
    required this.remainingItems,
  });

  final List<ArcTradeItemQuantity> ownedItems;
  final List<ArcTradeItemQuantity> remainingItems;
}

class _ListingSignal {
  const _ListingSignal({
    required this.listing,
    required this.ownerUid,
    required this.offeredItems,
    required this.wantedItems,
  });

  final TradingListing listing;
  final String ownerUid;
  final List<ArcTradeItemQuantity> offeredItems;
  final List<ArcTradeItemQuantity> wantedItems;

  bool get hasTradeShape => offeredItems.isNotEmpty;

  bool get hasSameOfferedAndWanted {
    final wantedIds = wantedItems.map((item) => item.id).toSet();
    return offeredItems.any((item) => wantedIds.contains(item.id));
  }

  factory _ListingSignal.fromListing(TradingListing listing) {
    final engine = const ArcTradeIntelligenceEngine();
    final offeredItems = engine._extractListingItems(
      idValues: listing.offeredTradeItemIds,
      nameValues: <String>[
        listing.offeredItem,
        ...listing.offeredBlueprintNames,
        ...listing.offeredAssetNames,
        ...listing.offeredTradeItemNames,
      ],
      includeSeeds: listing.seedTotalOffered,
    );
    final explicitWantedItems = listing.wantsNothing
        ? const <ArcTradeItemQuantity>[]
        : engine._extractListingItems(
            idValues: listing.wantedTradeItemIds,
            nameValues: <String>[
              listing.wantedText,
              ...listing.wantedBlueprintNames,
              ...listing.wantedAssetNames,
              ...listing.wantedTradeItemNames,
            ],
          );
    final structuredWantedItems = listing.wantsNothing
        ? const <ArcTradeItemQuantity>[]
        : engine._itemsFromBundleComponents(
            listing.acceptedBundles
                .where((bundle) => bundle.active)
                .expand((bundle) => bundle.components),
          );
    return _ListingSignal(
      listing: listing,
      ownerUid: listing.ownerUid,
      offeredItems: offeredItems,
      wantedItems: structuredWantedItems.isNotEmpty
          ? structuredWantedItems
          : explicitWantedItems,
    );
  }
}
