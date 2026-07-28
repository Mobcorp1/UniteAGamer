import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_item_dependency_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_resource_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';

class ArcPersonalItemIntelligenceEngine {
  const ArcPersonalItemIntelligenceEngine();

  static const String unsafeRecycleMessage =
      'Do not recycle yet - UAG does not have sufficiently verified requirement data for this item.';

  ArcPersonalItemRecommendationResult evaluate({
    required String query,
    ArcPersonalItemDataset? dataset,
    ArcPersonalItemInventorySnapshot inventory =
        const ArcPersonalItemInventorySnapshot(),
    ArcResourceIntelligence? resourceIntelligence,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    List<TradingListing> activeListings = const <TradingListing>[],
    ArcSavedLoadout? favouriteLoadout,
    DateTime? now,
  }) {
    final effectiveDataset =
        dataset ?? ArcPersonalItemDependencyCatalog.current;
    final effectiveNow = now ?? DateTime.now().toUtc();
    final record = effectiveDataset.findBest(query);
    if (record == null) {
      return _unknown(
        query: query,
        dataset: effectiveDataset,
        reason: unsafeRecycleMessage,
      );
    }

    final freshness = record.isFreshAt(effectiveNow)
        ? 'fresh'
        : 'stale-or-unknown';
    final ownedQuantity = inventory.quantityFor(record.id, record.name);
    final protection = inventory.protectionFor(record.id, record.name);
    final reservedForTrade = inventory.reservedFor(record.id, record.name);
    final promisedForTrade = inventory.promisedFor(record.id, record.name);
    final tradeReservations = reservedForTrade + promisedForTrade;
    final tradeOpportunities = _tradeOpportunitiesFor(
      record: record,
      activeListings: activeListings,
    );
    final resourceEntry = _resourceEntryFor(record, resourceIntelligence);
    final blueprint = _blueprintFor(record);
    final loadoutHit = _loadoutHit(record, favouriteLoadout);
    final secondaryReasons = <String>[
      'Dataset: ${effectiveDataset.version}.',
      'Verification: ${record.verificationState.label}.',
      if (freshness != 'fresh') unsafeRecycleMessage,
      if (record.commonFarmingSources.isNotEmpty)
        'Farm route: ${record.commonFarmingSources.first}',
      if (tradeOpportunities.isNotEmpty)
        'Live trade signal: ${tradeOpportunities.first.reason}',
    ];
    final conflicts = <ArcPersonalItemRecommendation>[];

    if (protection != null && protection.blocksRecycle) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.reserve,
        primaryReason: 'User protection is active: ${protection.summary}.',
        secondaryReasons: secondaryReasons,
        requiredQuantity: math.max(1, protection.customMinimumQuantity),
        ownedQuantity: ownedQuantity,
        surplusQuantity: math.max(
          0,
          ownedQuantity - math.max(1, protection.customMinimumQuantity),
        ),
        confidence: 1,
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[
          ArcPersonalItemRecommendation.recycle,
          ArcPersonalItemRecommendation.sell,
          ArcPersonalItemRecommendation.trade,
        ],
        suggestedAction: 'Keep the override until you clear it manually.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: const <String>[],
      );
    }

    if (tradeReservations > 0) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.reserve,
        primaryReason:
            '$tradeReservations ${record.name} ${tradeReservations == 1 ? 'is' : 'are'} reserved for trade commitments.',
        secondaryReasons: secondaryReasons,
        requiredQuantity: tradeReservations,
        ownedQuantity: ownedQuantity,
        surplusQuantity: math.max(0, ownedQuantity - tradeReservations),
        confidence: 0.98,
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[
          ArcPersonalItemRecommendation.recycle,
          ArcPersonalItemRecommendation.sell,
        ],
        suggestedAction: 'Keep reserved stock until the trade is complete.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: const <String>[],
      );
    }

    if (blueprint != null) {
      final state =
          blueprintStates[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);
      if (!state.owned) {
        return _result(
          query: query,
          record: record,
          dataset: effectiveDataset,
          outcome: ArcPersonalItemRecommendation.use,
          primaryReason:
              'Blueprint Tracker says ${blueprint.name} is not owned yet.',
          secondaryReasons: <String>[
            ...secondaryReasons,
            'Learn/consume this before treating it as trade stock.',
          ],
          requiredQuantity: 1,
          ownedQuantity: 0,
          surplusQuantity: 0,
          confidence: 1,
          dataFreshness: freshness,
          conflictingRecommendations: const <ArcPersonalItemRecommendation>[
            ArcPersonalItemRecommendation.recycle,
            ArcPersonalItemRecommendation.sell,
          ],
          suggestedAction: 'Keep and learn the blueprint after extraction.',
          relevantTradeOpportunities: tradeOpportunities,
          relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
          linkedObjectiveIds: <String>['blueprint:${blueprint.id}'],
        );
      }
      if (state.dupesOwned > 0 || ownedQuantity > 1) {
        final surplus = math.max(
          state.dupesOwned,
          math.max(0, ownedQuantity - 1),
        );
        return _result(
          query: query,
          record: record,
          dataset: effectiveDataset,
          outcome: tradeOpportunities.isNotEmpty
              ? ArcPersonalItemRecommendation.trade
              : ArcPersonalItemRecommendation.list,
          primaryReason:
              '${blueprint.name} is already learned and has $surplus duplicate ${surplus == 1 ? 'copy' : 'copies'} tracked.',
          secondaryReasons: secondaryReasons,
          requiredQuantity: 1,
          ownedQuantity: math.max(ownedQuantity, state.dupesOwned + 1),
          surplusQuantity: surplus,
          confidence: 0.96,
          dataFreshness: freshness,
          conflictingRecommendations: const <ArcPersonalItemRecommendation>[
            ArcPersonalItemRecommendation.recycle,
          ],
          suggestedAction: tradeOpportunities.isNotEmpty
              ? 'Inspect the matching trade before selling the duplicate.'
              : 'List the duplicate or keep it as trade stock.',
          relevantTradeOpportunities: tradeOpportunities,
          relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
          linkedObjectiveIds: <String>['blueprint:${blueprint.id}'],
        );
      }
    }

    if (loadoutHit.isNotEmpty) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.equip,
        primaryReason:
            '${record.name} is part of Favourite Loadout: $loadoutHit.',
        secondaryReasons: secondaryReasons,
        requiredQuantity: 1,
        ownedQuantity: ownedQuantity,
        surplusQuantity: math.max(0, ownedQuantity - 1),
        confidence: 0.94,
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[
          ArcPersonalItemRecommendation.recycle,
          ArcPersonalItemRecommendation.sell,
        ],
        suggestedAction: 'Keep enough copies to run your saved loadout.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: <String>[
          'loadout:${favouriteLoadout?.id ?? 'favourite'}',
        ],
      );
    }

    if (resourceEntry != null && resourceEntry.requiredCount > 0) {
      final surplus = math.max(
        0,
        math.max(ownedQuantity, resourceEntry.ownedCount) -
            resourceEntry.requiredCount,
      );
      if (resourceEntry.missingCount > 0 || resourceEntry.neverTrade) {
        return _result(
          query: query,
          record: record,
          dataset: effectiveDataset,
          outcome: ArcPersonalItemRecommendation.keep,
          primaryReason: resourceEntry.recommendation,
          secondaryReasons: <String>[
            ...secondaryReasons,
            'Tracked systems: ${resourceEntry.systemSummary}.',
          ],
          requiredQuantity: resourceEntry.requiredCount,
          ownedQuantity: math.max(ownedQuantity, resourceEntry.ownedCount),
          surplusQuantity: surplus,
          confidence: 0.94,
          dataFreshness: freshness,
          conflictingRecommendations: const <ArcPersonalItemRecommendation>[
            ArcPersonalItemRecommendation.recycle,
            ArcPersonalItemRecommendation.sell,
          ],
          suggestedAction: resourceEntry.tradeActionLabel == 'Farm'
              ? 'Farm this before spending or trading it.'
              : 'Keep required stock until blockers clear.',
          relevantTradeOpportunities: tradeOpportunities,
          relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
          linkedObjectiveIds: resourceEntry.requirements
              .map((requirement) => requirement.source)
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false),
        );
      }
      if (surplus > 0 && tradeOpportunities.isNotEmpty) {
        return _result(
          query: query,
          record: record,
          dataset: effectiveDataset,
          outcome: ArcPersonalItemRecommendation.trade,
          primaryReason:
              '$surplus surplus ${record.name} can answer a live trade signal.',
          secondaryReasons: secondaryReasons,
          requiredQuantity: resourceEntry.requiredCount,
          ownedQuantity: math.max(ownedQuantity, resourceEntry.ownedCount),
          surplusQuantity: surplus,
          confidence: 0.88,
          dataFreshness: freshness,
          conflictingRecommendations: const <ArcPersonalItemRecommendation>[],
          suggestedAction: 'Offer only the surplus quantity.',
          relevantTradeOpportunities: tradeOpportunities,
          relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
          linkedObjectiveIds: const <String>[],
        );
      }
    }

    if (record.dependencies.isNotEmpty) {
      final requiredQuantity = record.dependencies.fold<int>(
        0,
        (total, dependency) => total + dependency.requiredQuantity,
      );
      final activeSystems =
          record.dependencies
              .where(
                (dependency) => !dependency.futureOnly || dependency.blocking,
              )
              .map((dependency) => dependency.system)
              .toSet()
              .toList(growable: false)
            ..sort();
      final surplus = math.max(0, ownedQuantity - requiredQuantity);
      if (surplus > 0 && tradeOpportunities.isNotEmpty) {
        return _result(
          query: query,
          record: record,
          dataset: effectiveDataset,
          outcome: ArcPersonalItemRecommendation.trade,
          primaryReason:
              '$requiredQuantity ${record.name} ${requiredQuantity == 1 ? 'is' : 'are'} reserved for ${activeSystems.isEmpty ? 'tracked progression' : activeSystems.join(', ')}; only trade the $surplus surplus.',
          secondaryReasons: <String>[
            ...secondaryReasons,
            ...record.dependencies
                .take(5)
                .map(
                  (dependency) => '${dependency.system}: ${dependency.label}.',
                ),
          ],
          requiredQuantity: requiredQuantity,
          ownedQuantity: ownedQuantity,
          surplusQuantity: surplus,
          confidence: 0.9,
          dataFreshness: freshness,
          conflictingRecommendations: const <ArcPersonalItemRecommendation>[
            ArcPersonalItemRecommendation.recycle,
            ArcPersonalItemRecommendation.sell,
          ],
          suggestedAction:
              'Reserve the required quantity and offer surplus only.',
          relevantTradeOpportunities: tradeOpportunities,
          relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
          linkedObjectiveIds: record.dependencies
              .map((dependency) => dependency.objectiveId)
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false),
        );
      }
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.keep,
        primaryReason:
            '${record.name} is required by ${activeSystems.isEmpty ? 'tracked progression' : activeSystems.join(', ')}.',
        secondaryReasons: <String>[
          ...secondaryReasons,
          ...record.dependencies
              .take(5)
              .map(
                (dependency) => '${dependency.system}: ${dependency.label}.',
              ),
        ],
        requiredQuantity: requiredQuantity,
        ownedQuantity: ownedQuantity,
        surplusQuantity: surplus,
        confidence: 0.9,
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[
          ArcPersonalItemRecommendation.recycle,
          ArcPersonalItemRecommendation.sell,
        ],
        suggestedAction: 'Keep until the linked requirement is complete.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: record.dependencies
            .map((dependency) => dependency.objectiveId)
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false),
      );
    }

    if (record.craftingUses.isNotEmpty ||
        record.weaponCraftingUses.isNotEmpty ||
        record.attachmentCraftingUses.isNotEmpty ||
        record.consumableCraftingUses.isNotEmpty) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.craft,
        primaryReason: '${record.name} has known crafting or upgrade uses.',
        secondaryReasons: secondaryReasons,
        requiredQuantity: record.dependencies.fold<int>(
          0,
          (total, dependency) => total + dependency.requiredQuantity,
        ),
        ownedQuantity: ownedQuantity,
        surplusQuantity: 0,
        confidence: 0.82,
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[
          ArcPersonalItemRecommendation.recycle,
        ],
        suggestedAction: 'Keep it until the crafting requirement is complete.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: record.dependencies
            .map((dependency) => dependency.objectiveId)
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false),
      );
    }

    if (tradeOpportunities.isNotEmpty) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.trade,
        primaryReason: tradeOpportunities.first.reason,
        secondaryReasons: secondaryReasons,
        requiredQuantity: 0,
        ownedQuantity: ownedQuantity,
        surplusQuantity: ownedQuantity,
        confidence: tradeOpportunities.first.confidence,
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[],
        suggestedAction: 'Open Trade Hub before selling or recycling it.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: const <String>[],
      );
    }

    if (record.generallySafeToSell && ownedQuantity > 0) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.sell,
        primaryReason:
            '${record.name} has no known personal requirement in the current dataset.',
        secondaryReasons: secondaryReasons,
        requiredQuantity: 0,
        ownedQuantity: ownedQuantity,
        surplusQuantity: ownedQuantity,
        confidence: math.min(0.88, record.confidence),
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[],
        suggestedAction: 'Sell only if stash pressure needs the space.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: const <String>[],
      );
    }

    if (_canRecycle(record: record, freshness: freshness)) {
      return _result(
        query: query,
        record: record,
        dataset: effectiveDataset,
        outcome: ArcPersonalItemRecommendation.recycle,
        primaryReason:
            '${record.name} has verified no current personal, quest, Scrappy, Bench, loadout or trade requirement.',
        secondaryReasons: secondaryReasons,
        requiredQuantity: 0,
        ownedQuantity: ownedQuantity,
        surplusQuantity: ownedQuantity,
        confidence: math.min(0.86, record.confidence),
        dataFreshness: freshness,
        conflictingRecommendations: const <ArcPersonalItemRecommendation>[],
        suggestedAction:
            'Recycle surplus only after confirming the item match.',
        relevantTradeOpportunities: tradeOpportunities,
        relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
        linkedObjectiveIds: const <String>[],
      );
    }

    conflicts.addAll(const <ArcPersonalItemRecommendation>[
      ArcPersonalItemRecommendation.recycle,
      ArcPersonalItemRecommendation.sell,
    ]);
    return _result(
      query: query,
      record: record,
      dataset: effectiveDataset,
      outcome: ArcPersonalItemRecommendation.unknown,
      primaryReason: unsafeRecycleMessage,
      secondaryReasons: secondaryReasons,
      requiredQuantity: record.dependencies.fold<int>(
        0,
        (total, dependency) => total + dependency.requiredQuantity,
      ),
      ownedQuantity: ownedQuantity,
      surplusQuantity: 0,
      confidence: math.min(0.7, record.confidence),
      dataFreshness: freshness,
      conflictingRecommendations: conflicts,
      suggestedAction:
          'Keep for now or protect the item until UAG verifies the dependency data.',
      relevantTradeOpportunities: tradeOpportunities,
      relevantRouteOrFarmingOpportunity: _farmHint(record, resourceEntry),
      linkedObjectiveIds: record.dependencies
          .map((dependency) => dependency.objectiveId)
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  ArcPersonalItemCoverageReport coverage({ArcPersonalItemDataset? dataset}) {
    return (dataset ?? ArcPersonalItemDependencyCatalog.current).coverage;
  }

  bool _canRecycle({
    required ArcPersonalItemRecord record,
    required String freshness,
  }) {
    return freshness == 'fresh' &&
        record.canRecommendRecycle &&
        !record.hasDependencyData &&
        record.recycleOutputs.isNotEmpty;
  }

  ArcPersonalItemRecommendationResult _unknown({
    required String query,
    required ArcPersonalItemDataset dataset,
    required String reason,
  }) {
    return ArcPersonalItemRecommendationResult(
      query: query,
      outcome: ArcPersonalItemRecommendation.unknown,
      primaryReason: reason,
      secondaryReasons: const <String>[
        'No canonical item match was found in the current UAG dataset.',
      ],
      linkedObjectiveIds: const <String>[],
      requiredQuantity: 0,
      ownedQuantity: 0,
      surplusQuantity: 0,
      confidence: 0,
      dataVersion: dataset.version,
      dataFreshness: 'unknown',
      conflictingRecommendations: const <ArcPersonalItemRecommendation>[
        ArcPersonalItemRecommendation.recycle,
        ArcPersonalItemRecommendation.sell,
      ],
      suggestedAction: 'Keep for now and check the item manually.',
      relevantTradeOpportunities: const <ArcPersonalItemTradeOpportunity>[],
      relevantRouteOrFarmingOpportunity: '',
    );
  }

  ArcPersonalItemRecommendationResult _result({
    required String query,
    required ArcPersonalItemRecord record,
    required ArcPersonalItemDataset dataset,
    required ArcPersonalItemRecommendation outcome,
    required String primaryReason,
    required List<String> secondaryReasons,
    required int requiredQuantity,
    required int ownedQuantity,
    required int surplusQuantity,
    required double confidence,
    required String dataFreshness,
    required List<ArcPersonalItemRecommendation> conflictingRecommendations,
    required String suggestedAction,
    required List<ArcPersonalItemTradeOpportunity> relevantTradeOpportunities,
    required String relevantRouteOrFarmingOpportunity,
    required List<String> linkedObjectiveIds,
  }) {
    return ArcPersonalItemRecommendationResult(
      query: query,
      record: record,
      outcome: outcome,
      primaryReason: primaryReason,
      secondaryReasons: secondaryReasons
          .where((reason) => reason.trim().isNotEmpty)
          .toSet()
          .toList(growable: false),
      linkedObjectiveIds: linkedObjectiveIds.toSet().toList(growable: false),
      requiredQuantity: math.max(0, requiredQuantity),
      ownedQuantity: math.max(0, ownedQuantity),
      surplusQuantity: math.max(0, surplusQuantity),
      confidence: confidence.clamp(0, 1).toDouble(),
      dataVersion: dataset.version,
      dataFreshness: dataFreshness,
      conflictingRecommendations: conflictingRecommendations.toSet().toList(
        growable: false,
      ),
      suggestedAction: suggestedAction,
      relevantTradeOpportunities: relevantTradeOpportunities,
      relevantRouteOrFarmingOpportunity: relevantRouteOrFarmingOpportunity,
    );
  }

  ArcResourceIntelligenceEntry? _resourceEntryFor(
    ArcPersonalItemRecord record,
    ArcResourceIntelligence? resourceIntelligence,
  ) {
    if (resourceIntelligence == null) return null;
    final key = _key(record.id);
    final nameKey = _key(record.name);
    for (final entry in resourceIntelligence.entries) {
      final entryKey = _key(entry.id);
      final entryNameKey = _key(entry.name);
      if (entryKey == key ||
          entryNameKey == key ||
          entryKey == nameKey ||
          entryNameKey == nameKey) {
        return entry;
      }
    }
    return null;
  }

  ArcBlueprint? _blueprintFor(ArcPersonalItemRecord record) {
    final key = _key(record.id);
    final nameKey = _key(record.name.replaceAll(' Blueprint', ''));
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (_key(blueprint.id) == key ||
          _key(blueprint.name) == key ||
          _key(blueprint.id) == nameKey ||
          _key(blueprint.name) == nameKey) {
        return blueprint;
      }
    }
    if (record.category.toLowerCase() != 'blueprint') return null;
    final normalized = UnifiedItemIndex.normalize(record.name);
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final blueprintName = UnifiedItemIndex.normalize(blueprint.name);
      if (normalized.contains(blueprintName) ||
          blueprintName.contains(normalized)) {
        return blueprint;
      }
    }
    return null;
  }

  String _loadoutHit(
    ArcPersonalItemRecord record,
    ArcSavedLoadout? favouriteLoadout,
  ) {
    if (favouriteLoadout == null) return '';
    final key = _key(record.name);
    final matches = <String>[];
    void check(String label, String value) {
      if (_key(value) == key) matches.add(label);
    }

    check('primary weapon', favouriteLoadout.primaryWeapon);
    check('secondary weapon', favouriteLoadout.secondaryWeapon);
    check('augment', favouriteLoadout.augment);
    for (final item in favouriteLoadout.primaryAttachments) {
      check('primary attachment', item);
    }
    for (final item in favouriteLoadout.secondaryAttachments) {
      check('secondary attachment', item);
    }
    for (final item in favouriteLoadout.equipment) {
      check('equipment', item);
    }
    for (final item in favouriteLoadout.consumables) {
      check('consumable', item);
    }
    for (final item in favouriteLoadout.quickUse) {
      check('quick use', item);
    }
    return matches.toSet().join(', ');
  }

  List<ArcPersonalItemTradeOpportunity> _tradeOpportunitiesFor({
    required ArcPersonalItemRecord record,
    required List<TradingListing> activeListings,
  }) {
    if (activeListings.isEmpty) {
      return const <ArcPersonalItemTradeOpportunity>[];
    }
    final aliases = <String>{
      record.id,
      record.name,
      ...record.aliases,
    }.map(_key).where((value) => value.isNotEmpty).toSet();
    final now = DateTime.now();
    final results = <ArcPersonalItemTradeOpportunity>[];
    for (final listing in activeListings) {
      if (!listing.isLive || listing.expiresAt.isBefore(now)) continue;
      if (listing.ownerUid.trim().isEmpty) continue;
      if (_listingWantsAny(listing, aliases)) {
        results.add(
          ArcPersonalItemTradeOpportunity(
            id: 'wants-${listing.id}-${record.id}',
            title: 'Trader wants ${record.name}',
            reason: '${listing.traderName} wants ${record.name}.',
            actionLabel: 'Open Trade Hub',
            confidence: listing.riskLevel == TradingRiskLevel.low ? 0.82 : 0.68,
            listingId: listing.id,
            traderUid: listing.ownerUid,
          ),
        );
      }
      if (_listingOffersAny(listing, aliases)) {
        results.add(
          ArcPersonalItemTradeOpportunity(
            id: 'offers-${listing.id}-${record.id}',
            title: 'Trader offers ${record.name}',
            reason: '${listing.traderName} is offering ${record.name}.',
            actionLabel: 'Inspect listing',
            confidence: listing.riskLevel == TradingRiskLevel.low ? 0.78 : 0.64,
            listingId: listing.id,
            traderUid: listing.ownerUid,
          ),
        );
      }
    }
    results.sort((left, right) => right.confidence.compareTo(left.confidence));
    return results.take(5).toList(growable: false);
  }

  bool _listingWantsAny(TradingListing listing, Set<String> aliases) {
    return _valuesMatch(<String>[
      listing.wantedText,
      ...listing.wantedBlueprintNames,
      ...listing.wantedAssetNames,
      ...listing.wantedTradeItemIds,
      ...listing.wantedTradeItemNames,
    ], aliases);
  }

  bool _listingOffersAny(TradingListing listing, Set<String> aliases) {
    return _valuesMatch(<String>[
      listing.offeredItem,
      ...listing.offeredBlueprintNames,
      ...listing.offeredAssetNames,
      ...listing.offeredTradeItemIds,
      ...listing.offeredTradeItemNames,
    ], aliases);
  }

  bool _valuesMatch(List<String> values, Set<String> aliases) {
    for (final value in values.map(_key)) {
      if (value.isEmpty) continue;
      for (final alias in aliases) {
        if (value == alias || value.contains(alias) || alias.contains(value)) {
          return true;
        }
      }
    }
    return false;
  }

  String _farmHint(
    ArcPersonalItemRecord record,
    ArcResourceIntelligenceEntry? resourceEntry,
  ) {
    if (resourceEntry != null && resourceEntry.farmHint.trim().isNotEmpty) {
      return resourceEntry.farmHint;
    }
    if (record.commonFarmingSources.isNotEmpty) {
      return record.commonFarmingSources.first;
    }
    return '';
  }

  String _key(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

extension ArcPersonalItemRecommendationNavigation
    on ArcPersonalItemRecommendationResult {
  String get routeName {
    if (relevantTradeOpportunities.isNotEmpty) return TraderHubScreen.routeName;
    switch (outcome) {
      case ArcPersonalItemRecommendation.trade:
      case ArcPersonalItemRecommendation.list:
        return TraderHubScreen.routeName;
      case ArcPersonalItemRecommendation.keep:
      case ArcPersonalItemRecommendation.reserve:
      case ArcPersonalItemRecommendation.use:
      case ArcPersonalItemRecommendation.equip:
      case ArcPersonalItemRecommendation.craft:
      case ArcPersonalItemRecommendation.sell:
      case ArcPersonalItemRecommendation.recycle:
      case ArcPersonalItemRecommendation.unknown:
        return '';
    }
  }
}
