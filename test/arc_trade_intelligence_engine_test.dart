import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_network_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';

void main() {
  group('ArcTradeIntelligenceEngine network matching', () {
    const engine = ArcTradeIntelligenceEngine();
    const currentUid = 'raider-a';

    test('finds direct two-player match', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{'tempest': 1},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'a-listing',
            ownerUid: currentUid,
            offered: 'Tempest',
            wanted: 'Wolfpack',
          ),
          _listing(
            id: 'b-listing',
            ownerUid: 'raider-b',
            offered: 'Wolfpack',
            wanted: 'Tempest',
          ),
        ],
        currentUid: currentUid,
      );

      expect(summary.directMatches, hasLength(1));
      expect(summary.directMatches.first.satisfiesTopWanted, isTrue);
      expect(
        summary.directMatches.first.currentUserReceives.first.id,
        'wolfpack',
      );
    });

    test('detects valid three-player circular trade', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{'tempest': 1},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'a-listing',
            ownerUid: currentUid,
            offered: 'Tempest',
            wanted: 'Wolfpack',
          ),
          _listing(
            id: 'b-listing',
            ownerUid: 'raider-b',
            offered: 'Bobcat',
            wanted: 'Tempest',
          ),
          _listing(
            id: 'c-listing',
            ownerUid: 'raider-c',
            offered: 'Wolfpack',
            wanted: 'Bobcat',
          ),
        ],
        currentUid: currentUid,
      );

      expect(summary.directMatches, isEmpty);
      expect(summary.threeRaiderChains, hasLength(1));
      expect(
        summary.threeRaiderChains.first.reason,
        contains('gives Wolfpack to you'),
      );
    });

    test('deduplicates circular chains', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{'tempest': 1},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'a-listing',
            ownerUid: currentUid,
            offered: 'Tempest',
            wanted: 'Wolfpack',
          ),
          _listing(
            id: 'b-listing',
            ownerUid: 'raider-b',
            offered: 'Bobcat',
            wanted: 'Tempest',
          ),
          _listing(
            id: 'c-listing',
            ownerUid: 'raider-c',
            offered: 'Wolfpack',
            wanted: 'Bobcat',
          ),
        ],
        currentUid: currentUid,
      );

      final ids = summary.threeRaiderChains.map((item) => item.id).toSet();
      expect(ids, hasLength(summary.threeRaiderChains.length));
      expect(summary.threeRaiderChains, hasLength(1));
    });

    test('rejects self-trades', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{'tempest': 1},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'a-listing',
            ownerUid: currentUid,
            offered: 'Tempest',
            wanted: 'Wolfpack',
          ),
          _listing(
            id: 'a-second-listing',
            ownerUid: currentUid,
            offered: 'Wolfpack',
            wanted: 'Tempest',
          ),
        ],
        currentUid: currentUid,
      );

      expect(summary.directMatches, isEmpty);
      expect(summary.threeRaiderChains, isEmpty);
    });

    test('rejects missing duplicate or offer compatibility', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{'tempest': 1},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'a-listing',
            ownerUid: currentUid,
            offered: 'Tempest',
            wanted: 'Wolfpack',
          ),
          _listing(
            id: 'b-listing',
            ownerUid: 'raider-b',
            offered: 'Bobcat',
            wanted: 'Wolfpack',
          ),
        ],
        currentUid: currentUid,
      );

      expect(summary.directMatches, isEmpty);
      expect(summary.threeRaiderChains, isEmpty);
    });

    test('ranks direct match for highest-priority wanted item first', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{'tempest': 1, 'bobcat': 1},
          wantedPriority: const <String, int>{'wolfpack': 1, 'crash-mat': 2},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'a-top',
            ownerUid: currentUid,
            offered: 'Tempest',
            wanted: 'Wolfpack',
          ),
          _listing(
            id: 'b-top',
            ownerUid: 'raider-b',
            offered: 'Wolfpack',
            wanted: 'Tempest',
          ),
          _listing(
            id: 'a-secondary',
            ownerUid: currentUid,
            offered: 'Bobcat',
            wanted: 'Crash Mat',
          ),
          _listing(
            id: 'c-secondary',
            ownerUid: 'raider-c',
            offered: 'Crash Mat',
            wanted: 'Bobcat',
          ),
        ],
        currentUid: currentUid,
      );

      expect(summary.directMatches, hasLength(2));
      expect(
        summary.directMatches.first.currentUserReceives.first.id,
        'wolfpack',
      );
    });

    test('calculates partial payment for preparation opportunity', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'b-listing',
            ownerUid: 'raider-b',
            offered: 'Wolfpack',
            wanted: '3 Queen Reactors',
          ),
        ],
        currentUid: currentUid,
        ownedItemQuantities: const <String, int>{'queen-reactor': 1},
      );

      expect(summary.preparationOpportunities, hasLength(1));
      final opportunity = summary.preparationOpportunities.first;
      expect(opportunity.requiredItems.first.quantity, 3);
      expect(opportunity.ownedItems.first.quantity, 1);
      expect(opportunity.remainingItems.first.quantity, 2);
      expect(opportunity.actionLabel, 'Prepare for this trade');
    });

    test('transitions preparation readiness to ready', () {
      final opportunity = ArcTradeOpportunity(
        id: 'prepare:b-listing',
        type: ArcTradeOpportunityType.prepare,
        title: 'Prepare for Priority Trade',
        reason: 'Missing payment.',
        actionLabel: 'Prepare for this trade',
        confidence: 68,
        rankScore: 100,
        listingIds: const <String>['b-listing'],
        participantUids: const <String>['raider-b'],
        currentUserGives: const <ArcTradeItemQuantity>[
          ArcTradeItemQuantity(
            id: 'queen-reactor',
            label: 'Queen Reactor',
            quantity: 3,
          ),
        ],
        currentUserReceives: const <ArcTradeItemQuantity>[
          ArcTradeItemQuantity(id: 'wolfpack', label: 'Wolfpack', quantity: 1),
        ],
        requiredItems: const <ArcTradeItemQuantity>[
          ArcTradeItemQuantity(
            id: 'queen-reactor',
            label: 'Queen Reactor',
            quantity: 3,
          ),
        ],
        ownedItems: const <ArcTradeItemQuantity>[
          ArcTradeItemQuantity(
            id: 'queen-reactor',
            label: 'Queen Reactor',
            quantity: 1,
          ),
        ],
        remainingItems: const <ArcTradeItemQuantity>[
          ArcTradeItemQuantity(
            id: 'queen-reactor',
            label: 'Queen Reactor',
            quantity: 2,
          ),
        ],
        targetListingId: 'b-listing',
        targetPlayerId: 'raider-b',
      );
      final preparation = engine.buildPreparation(
        userId: currentUid,
        opportunity: opportunity,
        now: DateTime(2026),
      );

      final ready = engine.recalculatePreparationReadiness(
        preparation: preparation,
        ownedItemQuantities: const <String, int>{'queen-reactor': 3},
        now: DateTime(2026, 1, 2),
      );

      expect(ready.status, ArcTradePreparationStatus.ready);
      expect(ready.remainingItems, isEmpty);
    });

    test('uses structured accepted bundle components for preparation', () {
      final summary = engine.buildNetworkSummary(
        blueprintStates: _states(
          duplicates: const <String, int>{},
          wantedPriority: const <String, int>{'wolfpack': 1},
        ),
        activeListings: <TradingListing>[
          _listing(
            id: 'structured-listing',
            ownerUid: 'raider-b',
            offered: 'Wolfpack',
            wanted: 'Exact payment',
            acceptedBundles: const <ArcTradeBundleTemplate>[
              ArcTradeBundleTemplate(
                id: 'queen-payment',
                name: 'Queen Reactor payment',
                components: <ArcTradeBundleComponent>[
                  ArcTradeBundleComponent(
                    id: 'queen-reactor',
                    type: ArcTradeBundleComponentType.resource,
                    itemId: 'queen-reactor',
                    itemName: 'Queen Reactor',
                    quantity: 2,
                  ),
                ],
              ),
            ],
          ),
        ],
        currentUid: currentUid,
        ownedItemQuantities: const <String, int>{'queen-reactor': 1},
      );

      final opportunity = summary.preparationOpportunities.single;

      expect(opportunity.requiredItems.first.id, 'queen-reactor');
      expect(opportunity.ownedItems.first.quantity, 1);
      expect(opportunity.remainingItems.first.quantity, 1);
    });

    test('scores confirmed structured bundles above preparing bundles', () {
      const listingBundle = ArcTradeBundleTemplate(
        id: 'payment',
        name: 'Payment',
        components: <ArcTradeBundleComponent>[
          ArcTradeBundleComponent(
            id: 'queen-reactor',
            type: ArcTradeBundleComponentType.resource,
            itemId: 'queen-reactor',
            itemName: 'Queen Reactor',
            quantity: 1,
          ),
        ],
      );
      final listing = _listing(
        id: 'structured-score',
        ownerUid: 'raider-b',
        offered: 'Wolfpack',
        wanted: 'Queen Reactor',
        acceptedBundles: const <ArcTradeBundleTemplate>[listingBundle],
      );
      const confirmed = ArcExactTradeBundleOffer(
        templateId: 'payment',
        completionConfirmed: true,
        components: <ArcTradeBundleComponent>[
          ArcTradeBundleComponent(
            id: 'queen-reactor',
            type: ArcTradeBundleComponentType.resource,
            itemId: 'queen-reactor',
            itemName: 'Queen Reactor',
            quantity: 1,
          ),
        ],
      );
      const preparing = ArcExactTradeBundleOffer(
        templateId: 'payment',
        preparing: true,
        components: <ArcTradeBundleComponent>[
          ArcTradeBundleComponent(
            id: 'queen-reactor',
            type: ArcTradeBundleComponentType.resource,
            itemId: 'queen-reactor',
            itemName: 'Queen Reactor',
            quantity: 1,
          ),
        ],
      );

      final confirmedScore = engine.scoreOfferForListing(
        listing: listing,
        offeredBlueprintNames: const <String>[],
        offeredTradeItemNames: const <String>[],
        seedTotal: 0,
        includesResources: false,
        resourceText: '',
        exactBundleOffer: confirmed,
      );
      final preparingScore = engine.scoreOfferForListing(
        listing: listing,
        offeredBlueprintNames: const <String>[],
        offeredTradeItemNames: const <String>[],
        seedTotal: 0,
        includesResources: false,
        resourceText: '',
        exactBundleOffer: preparing,
      );

      expect(confirmedScore.label, 'Structured Match');
      expect(confirmedScore.score, greaterThan(preparingScore.score));
      expect(confirmedScore.hints.join(' '), contains('confirmed'));
    });
  });
}

Map<String, ArcBlueprintState> _states({
  required Map<String, int> duplicates,
  required Map<String, int> wantedPriority,
}) {
  final states = <String, ArcBlueprintState>{};

  for (final entry in duplicates.entries) {
    states[entry.key] = ArcBlueprintState(
      blueprintId: entry.key,
      owned: true,
      dupesOwned: entry.value,
      priorityRank: 0,
      updatedAt: null,
    );
  }

  for (final entry in wantedPriority.entries) {
    states[entry.key] = ArcBlueprintState(
      blueprintId: entry.key,
      owned: false,
      dupesOwned: 0,
      priorityRank: entry.value,
      updatedAt: null,
    );
  }

  return states;
}

TradingListing _listing({
  required String id,
  required String ownerUid,
  required String offered,
  required String wanted,
  bool active = true,
  List<ArcTradeBundleTemplate> acceptedBundles =
      const <ArcTradeBundleTemplate>[],
}) {
  final now = DateTime.now();
  return TradingListing(
    id: id,
    ownerUid: ownerUid,
    traderName: ownerUid,
    gamerTag: '',
    preferredPlatform: 'Any',
    title: '$offered for $wanted',
    offeredItem: offered,
    wantedText: wanted,
    offeredBlueprintNames: <String>[offered],
    wantedBlueprintNames: <String>[wanted],
    offeredAssetNames: const <String>[],
    wantedAssetNames: const <String>[],
    offeredTradeItemIds: <String>[_id(offered)],
    wantedTradeItemIds: <String>[_id(wanted)],
    offeredTradeItemNames: <String>[offered],
    wantedTradeItemNames: <String>[wanted],
    wantsNothing: false,
    listingType: TradingListingType.specificWant,
    riskLevel: TradingRiskLevel.low,
    completedTrades: 3,
    noShows: 0,
    betrayalFlags: 0,
    region: 'EU',
    playWindow: 'Evening',
    smallBundles: 0,
    mediumBundles: 0,
    largeBundles: 0,
    seedTotalOffered: 0,
    acceptsBlueprints: true,
    acceptsSeeds: false,
    acceptsResources: true,
    seriousOffersOnly: false,
    tradeAsBundle: true,
    allowPartialOffers: false,
    acceptedBundles: acceptedBundles,
    expiresAt: now.add(const Duration(days: 3)),
    notes: '',
    active: active,
    createdAt: now,
    updatedAt: now,
  );
}

String _id(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
