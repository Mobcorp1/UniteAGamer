import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';

class ArcBlueprintTruthSnapshot {
  final Map<String, ArcBlueprintState> statesByBlueprintId;
  final List<TradingListing> activeListings;
  final Set<String> ownedBlueprintIds;
  final Set<String> missingBlueprintIds;
  final Set<String> duplicateBlueprintIds;
  final Set<String> marketplaceAvailableBlueprintIds;
  final List<String> topFiveWantedBlueprintIds;
  final List<String> smartHuntBlueprintIds;

  const ArcBlueprintTruthSnapshot({
    required this.statesByBlueprintId,
    required this.activeListings,
    required this.ownedBlueprintIds,
    required this.missingBlueprintIds,
    required this.duplicateBlueprintIds,
    required this.marketplaceAvailableBlueprintIds,
    required this.topFiveWantedBlueprintIds,
    required this.smartHuntBlueprintIds,
  });

  bool isOwned(String blueprintId) => ownedBlueprintIds.contains(blueprintId);

  bool isMissing(String blueprintId) =>
      missingBlueprintIds.contains(blueprintId);

  bool hasDuplicate(String blueprintId) =>
      duplicateBlueprintIds.contains(blueprintId);

  bool isMarketplaceAvailable(String blueprintId) =>
      marketplaceAvailableBlueprintIds.contains(blueprintId);

  ArcBlueprintState stateFor(String blueprintId) =>
      statesByBlueprintId[blueprintId] ?? ArcBlueprintState.empty(blueprintId);
}

class ArcBlueprintSourceOfTruthService {
  const ArcBlueprintSourceOfTruthService();

  ArcBlueprintTruthSnapshot buildSnapshot({
    required Map<String, ArcBlueprintState> statesByBlueprintId,
    required List<TradingListing> activeListings,
  }) {
    final ownedIds = <String>{};
    final missingIds = <String>{};
    final duplicateIds = <String>{};

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          statesByBlueprintId[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);

      if (state.owned) {
        ownedIds.add(blueprint.id);
      } else {
        missingIds.add(blueprint.id);
      }

      if (state.hasDuplicates) {
        duplicateIds.add(blueprint.id);
      }
    }

    final marketplaceAvailableIds = _resolveMarketplaceAvailableBlueprintIds(
      activeListings,
    );

    final topFiveWanted = _resolveTopFiveWantedBlueprintIds(
      statesByBlueprintId,
    );

    final smartHunts = _resolveSmartHuntBlueprintIds(
      statesByBlueprintId: statesByBlueprintId,
      marketplaceAvailableIds: marketplaceAvailableIds,
      topFiveWantedBlueprintIds: topFiveWanted,
    );

    return ArcBlueprintTruthSnapshot(
      statesByBlueprintId: statesByBlueprintId,
      activeListings: activeListings,
      ownedBlueprintIds: ownedIds,
      missingBlueprintIds: missingIds,
      duplicateBlueprintIds: duplicateIds,
      marketplaceAvailableBlueprintIds: marketplaceAvailableIds,
      topFiveWantedBlueprintIds: topFiveWanted,
      smartHuntBlueprintIds: smartHunts,
    );
  }

  List<String> removeOwnedHunts({
    required Iterable<String> huntBlueprintIds,
    required Map<String, ArcBlueprintState> statesByBlueprintId,
  }) {
    return huntBlueprintIds
        .where((blueprintId) {
          final state =
              statesByBlueprintId[blueprintId] ??
              ArcBlueprintState.empty(blueprintId);
          return !state.owned;
        })
        .toList(growable: false);
  }

  bool canCreateManualTradeFromBlueprint({
    required String blueprintId,
    required Map<String, ArcBlueprintState> statesByBlueprintId,
  }) {
    final state =
        statesByBlueprintId[blueprintId] ??
        ArcBlueprintState.empty(blueprintId);
    return state.hasDuplicates;
  }

  bool shouldUseAutoTradeSetup({
    required String blueprintId,
    required Map<String, ArcBlueprintState> statesByBlueprintId,
  }) {
    return !canCreateManualTradeFromBlueprint(
      blueprintId: blueprintId,
      statesByBlueprintId: statesByBlueprintId,
    );
  }

  List<String> refillHunts({
    required Iterable<String> currentHunts,
    required Map<String, ArcBlueprintState> statesByBlueprintId,
    required List<TradingListing> activeListings,
    int maxTargets = 5,
  }) {
    final marketplaceAvailableIds = _resolveMarketplaceAvailableBlueprintIds(
      activeListings,
    );

    final cleaned = removeOwnedHunts(
      huntBlueprintIds: currentHunts,
      statesByBlueprintId: statesByBlueprintId,
    ).where((id) => id.trim().isNotEmpty).toList();

    final selected = <String>[];

    for (final id in cleaned) {
      if (!selected.contains(id)) {
        selected.add(id);
      }
      if (selected.length >= maxTargets) {
        return selected;
      }
    }

    final topFive = _resolveTopFiveWantedBlueprintIds(statesByBlueprintId);
    for (final id in topFive) {
      final state = statesByBlueprintId[id] ?? ArcBlueprintState.empty(id);
      if (!state.owned && !selected.contains(id)) {
        selected.add(id);
      }
      if (selected.length >= maxTargets) {
        return selected;
      }
    }

    final candidates = ArcBlueprintSeedData.blueprints.where((blueprint) {
      final state =
          statesByBlueprintId[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);
      return !state.owned && !selected.contains(blueprint.id);
    }).toList();

    candidates.sort((a, b) {
      final aTrade = marketplaceAvailableIds.contains(a.id) ? 1 : 0;
      final bTrade = marketplaceAvailableIds.contains(b.id) ? 1 : 0;
      final tradeCompare = bTrade.compareTo(aTrade);
      if (tradeCompare != 0) {
        return tradeCompare;
      }

      final rarityCompare = _rarityScore(
        b.rarity,
      ).compareTo(_rarityScore(a.rarity));
      if (rarityCompare != 0) {
        return rarityCompare;
      }

      return a.sortOrder.compareTo(b.sortOrder);
    });

    for (final blueprint in candidates) {
      selected.add(blueprint.id);
      if (selected.length >= maxTargets) {
        break;
      }
    }

    return selected;
  }

  List<String> _resolveTopFiveWantedBlueprintIds(
    Map<String, ArcBlueprintState> statesByBlueprintId,
  ) {
    final ranked =
        statesByBlueprintId.entries
            .where((entry) => entry.value.priorityRank >= 1)
            .where((entry) => entry.value.priorityRank <= 5)
            .where((entry) => !entry.value.owned)
            .toList()
          ..sort(
            (a, b) => a.value.priorityRank.compareTo(b.value.priorityRank),
          );

    return ranked.map((entry) => entry.key).toList(growable: false);
  }

  List<String> _resolveSmartHuntBlueprintIds({
    required Map<String, ArcBlueprintState> statesByBlueprintId,
    required Set<String> marketplaceAvailableIds,
    required List<String> topFiveWantedBlueprintIds,
  }) {
    final selected = <String>[];

    for (final id in topFiveWantedBlueprintIds) {
      final state = statesByBlueprintId[id] ?? ArcBlueprintState.empty(id);
      if (!state.owned && !selected.contains(id)) {
        selected.add(id);
      }
      if (selected.length >= 5) {
        return selected;
      }
    }

    final candidates = ArcBlueprintSeedData.blueprints.where((blueprint) {
      final state =
          statesByBlueprintId[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);
      return !state.owned && !selected.contains(blueprint.id);
    }).toList();

    candidates.sort((a, b) {
      final aTrade = marketplaceAvailableIds.contains(a.id) ? 1 : 0;
      final bTrade = marketplaceAvailableIds.contains(b.id) ? 1 : 0;
      final tradeCompare = bTrade.compareTo(aTrade);
      if (tradeCompare != 0) {
        return tradeCompare;
      }

      final rarityCompare = _rarityScore(
        b.rarity,
      ).compareTo(_rarityScore(a.rarity));
      if (rarityCompare != 0) {
        return rarityCompare;
      }

      return a.sortOrder.compareTo(b.sortOrder);
    });

    for (final blueprint in candidates) {
      selected.add(blueprint.id);
      if (selected.length >= 5) {
        break;
      }
    }

    return selected;
  }

  Set<String> _resolveMarketplaceAvailableBlueprintIds(
    List<TradingListing> activeListings,
  ) {
    final offeredTokens = <String>{};

    for (final listing in activeListings) {
      if (!listing.active) {
        continue;
      }

      offeredTokens.add(_normalise(listing.offeredItem));
      offeredTokens.addAll(listing.offeredBlueprintNames.map(_normalise));
      offeredTokens.addAll(listing.offeredAssetNames.map(_normalise));
      offeredTokens.addAll(listing.offeredTradeItemIds.map(_normalise));
      offeredTokens.addAll(listing.offeredTradeItemNames.map(_normalise));
    }

    return ArcBlueprintSeedData.blueprints
        .where(
          (blueprint) =>
              offeredTokens.contains(_normalise(blueprint.id)) ||
              offeredTokens.contains(_normalise(blueprint.name)),
        )
        .map((blueprint) => blueprint.id)
        .toSet();
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

  String _normalise(String value) {
    return value.trim().toLowerCase();
  }
}
