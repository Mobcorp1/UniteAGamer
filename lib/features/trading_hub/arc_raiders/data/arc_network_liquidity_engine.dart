class ArcNetworkLiquiditySnapshot {
  const ArcNetworkLiquiditySnapshot({
    required this.openListings,
    required this.activeTraders,
    required this.alignedListingPairs,
    required this.reciprocalTradePairs,
    required this.searchableMatchProfiles,
    required this.profilesWithPotentialCandidate,
    required this.potentialCandidatePairs,
  });

  final int openListings;
  final int activeTraders;
  final int alignedListingPairs;
  final int reciprocalTradePairs;
  final int searchableMatchProfiles;
  final int profilesWithPotentialCandidate;
  final int potentialCandidatePairs;
}

class ArcNetworkLiquidityEngine {
  const ArcNetworkLiquidityEngine();

  ArcNetworkLiquiditySnapshot calculate({
    required List<Map<String, dynamic>> listings,
    required List<Map<String, dynamic>> profiles,
  }) {
    final open = listings
        .where((item) => _text(item['status']).toLowerCase() == 'open')
        .toList(growable: false);
    final traders = open
        .map((item) => _text(item['userId']))
        .where((value) => value.isNotEmpty)
        .toSet();

    var aligned = 0;
    var reciprocal = 0;
    for (var i = 0; i < open.length; i++) {
      for (var j = i + 1; j < open.length; j++) {
        final a = open[i];
        final b = open[j];
        if (_text(a['userId']).isNotEmpty &&
            _text(a['userId']) == _text(b['userId'])) {
          continue;
        }
        final aOffersBNeeds = _sameItem(
          a['offeredBlueprintId'],
          a['offeredBlueprintName'],
          b['wantedBlueprintId'],
          b['wantedBlueprintName'],
        );
        final bOffersANeeds = _sameItem(
          b['offeredBlueprintId'],
          b['offeredBlueprintName'],
          a['wantedBlueprintId'],
          a['wantedBlueprintName'],
        );
        if (aOffersBNeeds || bOffersANeeds) aligned++;
        if (aOffersBNeeds && bOffersANeeds) reciprocal++;
      }
    }

    final visible = profiles
        .where((item) => item['visibleInSearch'] == true)
        .toList(growable: false);
    final candidateOwners = <int>{};
    var pairs = 0;
    for (var i = 0; i < visible.length; i++) {
      for (var j = i + 1; j < visible.length; j++) {
        if (_potentialMatch(visible[i], visible[j])) {
          pairs++;
          candidateOwners
            ..add(i)
            ..add(j);
        }
      }
    }

    return ArcNetworkLiquiditySnapshot(
      openListings: open.length,
      activeTraders: traders.length,
      alignedListingPairs: aligned,
      reciprocalTradePairs: reciprocal,
      searchableMatchProfiles: visible.length,
      profilesWithPotentialCandidate: candidateOwners.length,
      potentialCandidatePairs: pairs,
    );
  }

  bool _potentialMatch(Map<String, dynamic> a, Map<String, dynamic> b) {
    final regionA = _text(a['region']).toLowerCase();
    final regionB = _text(b['region']).toLowerCase();
    if (regionA.isNotEmpty && regionB.isNotEmpty && regionA != regionB) {
      return false;
    }

    final platformA = _text(a['platform']).toLowerCase();
    final platformB = _text(b['platform']).toLowerCase();
    final crossplay =
        a['crossplayEnabled'] != false && b['crossplayEnabled'] != false;
    if (!crossplay &&
        platformA.isNotEmpty &&
        platformB.isNotEmpty &&
        platformA != platformB) {
      return false;
    }
    return true;
  }

  bool _sameItem(
    Object? leftId,
    Object? leftName,
    Object? rightId,
    Object? rightName,
  ) {
    final left = <String>{_normal(leftId), _normal(leftName)}
      ..removeWhere((value) => value.isEmpty);
    final right = <String>{_normal(rightId), _normal(rightName)}
      ..removeWhere((value) => value.isEmpty);
    return left.intersection(right).isNotEmpty;
  }

  String _normal(Object? value) =>
      _text(value).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  String _text(Object? value) => value?.toString().trim() ?? '';
}
