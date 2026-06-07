import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/arc_blueprint_source_of_truth_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/automation/smart_trade_assist_engine.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class SmartTradeAssistScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/smart-trade-assist';

  const SmartTradeAssistScreen({super.key});

  @override
  State<SmartTradeAssistScreen> createState() => _SmartTradeAssistScreenState();
}

class _SmartTradeAssistScreenState extends State<SmartTradeAssistScreen> {
  final TradingRepository _repository = TradingRepository();
  final SmartTradeAssistEngine _engine = const SmartTradeAssistEngine();
  final ArcBlueprintSourceOfTruthService _truthService =
      const ArcBlueprintSourceOfTruthService();

  final Set<String> _busyKeys = <String>{};
  final Set<String> _createdListingKeys = <String>{};
  final Set<String> _sentOfferKeys = <String>{};

  Map<String, String> get _blueprintNamesById {
    return {
      for (final blueprint in ArcBlueprintSeedData.blueprints)
        blueprint.id: blueprint.name,
    };
  }

  String _labelForBlueprint(String id) {
    return _blueprintNamesById[id] ?? _titleFromId(id);
  }

  String _titleFromId(String id) {
    return id
        .split('-')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          if (part.length == 1) {
            return part.toUpperCase();
          }

          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _labelForResources(List<String> ids) {
    return ids.map(_titleFromId).join(', ');
  }

  String _targetLabel(SmartTradeOpportunity opportunity) {
    if (opportunity.requestedBlueprintId != null) {
      return _labelForBlueprint(opportunity.requestedBlueprintId!);
    }

    return _labelForResources(opportunity.requestedResourceIds);
  }

  String _opportunityKey(SmartTradeOpportunity opportunity) {
    return [
      opportunity.tier.name,
      opportunity.duplicateBlueprintId,
      opportunity.requestedBlueprintId ?? '',
      opportunity.requestedResourceIds.join('|'),
    ].join('::');
  }

  Map<String, int> _duplicateQuantitiesFromStates(
    Map<String, ArcBlueprintState> states,
  ) {
    final duplicates = <String, int>{};

    for (final entry in states.entries) {
      final id = entry.key.trim();
      final quantity = entry.value.dupesOwned;

      if (id.isNotEmpty && quantity > 0) {
        duplicates[id] = quantity;
      }
    }

    return duplicates;
  }

  List<String> _topFiveWantedFromStates(Map<String, ArcBlueprintState> states) {
    final prioritized =
        states.values
            .where((state) => state.priorityRank > 0)
            .toList(growable: false)
          ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));

    return prioritized
        .where((state) => state.blueprintId.trim().isNotEmpty)
        .map((state) => state.blueprintId.trim())
        .take(5)
        .toList(growable: false);
  }

  List<String> _missingBlueprintsFromStates(
    Map<String, ArcBlueprintState> states, [
    List<TradingListing> listings = const <TradingListing>[],
  ]) {
    return _truthService
        .buildSnapshot(statesByBlueprintId: states, activeListings: listings)
        .missingBlueprintIds
        .toList(growable: false);
  }

  List<SmartTradeOpportunity> _buildOpportunities(
    Map<String, ArcBlueprintState> states, [
    List<TradingListing> listings = const <TradingListing>[],
  ]) {
    final truth = _truthService.buildSnapshot(
      statesByBlueprintId: states,
      activeListings: listings,
    );
    final duplicates = _duplicateQuantitiesFromStates(states);
    final topFive = truth.topFiveWantedBlueprintIds;
    final missing = _missingBlueprintsFromStates(states, listings);

    if (duplicates.isEmpty || topFive.isEmpty) {
      return const <SmartTradeOpportunity>[];
    }

    return _engine.buildFullOpportunityStack(
      duplicateBlueprintQuantities: duplicates,
      topFiveWantedBlueprintIds: topFive,
      missingBlueprintIds: missing,
      usefulResourceIds: const <String>[],
    );
  }

  bool _listingMatchesOpportunity(
    TradingListing listing,
    SmartTradeOpportunity opportunity,
  ) {
    if (!listing.isLive) {
      return false;
    }

    if (listing.ownerUid == _repository.currentUid) {
      return false;
    }

    final duplicateLabel = _labelForBlueprint(opportunity.duplicateBlueprintId);
    final targetLabel = _targetLabel(opportunity);

    final wantedValues = <String>[
      listing.wantedText,
      ...listing.wantedBlueprintNames,
      ...listing.wantedAssetNames,
      ...listing.wantedTradeItemNames,
      ...listing.wantedTradeItemIds,
    ].map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty);

    final offeredValues = <String>[
      listing.offeredItem,
      ...listing.offeredBlueprintNames,
      ...listing.offeredAssetNames,
      ...listing.offeredTradeItemNames,
      ...listing.offeredTradeItemIds,
    ].map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty);

    final wantsMyDuplicate = wantedValues.any(
      (value) =>
          value == opportunity.duplicateBlueprintId.toLowerCase() ||
          value == duplicateLabel.toLowerCase(),
    );

    final offersMyTarget = offeredValues.any(
      (value) =>
          value == (opportunity.requestedBlueprintId ?? '').toLowerCase() ||
          value == targetLabel.toLowerCase(),
    );

    return wantsMyDuplicate && offersMyTarget;
  }

  List<TradingListing> _matchesForOpportunity(
    List<TradingListing> listings,
    SmartTradeOpportunity opportunity,
  ) {
    return listings
        .where((listing) => _listingMatchesOpportunity(listing, opportunity))
        .toList(growable: false);
  }

  Future<void> _createListing(SmartTradeOpportunity opportunity) async {
    final key = _opportunityKey(opportunity);

    if (_busyKeys.contains(key)) {
      return;
    }

    setState(() => _busyKeys.add(key));

    final duplicateLabel = _labelForBlueprint(opportunity.duplicateBlueprintId);
    final targetLabel = _targetLabel(opportunity);
    final wantsBlueprint = opportunity.requestedBlueprintId != null;

    try {
      await _repository.createListing(
        offeredItem: duplicateLabel,
        wantedText: targetLabel,
        listingType: TradingListingType.specificWant,
        playWindow: 'Flexible',
        smallBundles: 0,
        mediumBundles: 0,
        largeBundles: 0,
        acceptsBlueprints: wantsBlueprint,
        acceptsSeeds: false,
        acceptsResources: !wantsBlueprint,
        seriousOffersOnly: true,
        notes:
            'Created from Smart Trade Assist. Duplicate available: $duplicateLabel. Wanted: $targetLabel.',
        expiryDuration: const Duration(days: 3),
        offeredBlueprintNames: [duplicateLabel],
        wantedBlueprintNames: wantsBlueprint ? [targetLabel] : const [],
        offeredTradeItemIds: [opportunity.duplicateBlueprintId],
        offeredTradeItemNames: [duplicateLabel],
        wantedTradeItemIds: wantsBlueprint
            ? [opportunity.requestedBlueprintId!]
            : opportunity.requestedResourceIds,
        wantedTradeItemNames: wantsBlueprint
            ? [targetLabel]
            : opportunity.requestedResourceIds.map(_titleFromId).toList(),
        tradeAsBundle: true,
        allowPartialOffers: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdListingKeys.add(key);
      });

      _showSnack('Listing created: $duplicateLabel for $targetLabel');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('Could not create listing: $error');
    } finally {
      if (mounted) {
        setState(() => _busyKeys.remove(key));
      }
    }
  }

  Future<void> _createAllListings(
    List<SmartTradeOpportunity> opportunities,
  ) async {
    final listingOpportunities = opportunities
        .where(
          (item) => item.tier == SmartTradeOpportunityTier.publicListingDraft,
        )
        .where((item) => !_createdListingKeys.contains(_opportunityKey(item)))
        .toList(growable: false);

    if (listingOpportunities.isEmpty) {
      _showSnack('No new listing drafts to create.');
      return;
    }

    var created = 0;

    for (final opportunity in listingOpportunities) {
      await _createListing(opportunity);
      created++;
    }

    if (!mounted) {
      return;
    }

    _showSnack('Created $created Smart Trade listing drafts.');
  }

  Future<void> _sendOffer({
    required TradingListing listing,
    required SmartTradeOpportunity opportunity,
  }) async {
    final key = '${listing.id}::${_opportunityKey(opportunity)}';

    if (_busyKeys.contains(key)) {
      return;
    }

    setState(() => _busyKeys.add(key));

    final duplicateLabel = _labelForBlueprint(opportunity.duplicateBlueprintId);
    final targetLabel = _targetLabel(opportunity);

    try {
      await _repository.createOffer(
        listing: listing,
        offeredBlueprintText: duplicateLabel,
        smallBundles: 0,
        mediumBundles: 0,
        largeBundles: 0,
        includesResources: false,
        resourcesText: '',
        note:
            'Smart Trade Assist match: I can offer $duplicateLabel for $targetLabel.',
        offeredTradeItemIds: [opportunity.duplicateBlueprintId],
        offeredTradeItemNames: [duplicateLabel],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sentOfferKeys.add(key);
      });

      _showSnack('Offer sent for $duplicateLabel.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('Could not send offer: $error');
    } finally {
      if (mounted) {
        setState(() => _busyKeys.remove(key));
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.cardBackgroundDeep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const ArcCompanionBottomDock(
        activeLabel: 'Smart Trade',
      ),
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackgroundDeep,
        foregroundColor: Colors.white,
        title: Text(
          'Smart Trade Assist',
          style: AppTheme.neonTextStyle(
            fontSize: 22,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _repository.watchBlueprintStates(),
              builder: (context, stateSnapshot) {
                final states =
                    stateSnapshot.data ?? const <String, ArcBlueprintState>{};
                final opportunities = _buildOpportunities(states);
                final duplicateTotal = _duplicateQuantitiesFromStates(
                  states,
                ).values.fold<int>(0, (total, quantity) => total + quantity);
                final topFive = _topFiveWantedFromStates(states);

                return StreamBuilder<List<TradingListing>>(
                  stream: _repository.watchActiveListings(),
                  builder: (context, listingSnapshot) {
                    final listings =
                        listingSnapshot.data ?? const <TradingListing>[];

                    return ListView(
                      padding: const EdgeInsets.all(AppTheme.spaceM),
                      children: [
                        _IntroCard(
                          opportunityCount: opportunities.length,
                          duplicateTotal: duplicateTotal,
                          targetCount: topFive.length,
                          onCreateAll: opportunities.isEmpty
                              ? null
                              : () => _createAllListings(opportunities),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        if (opportunities.isEmpty)
                          const _EmptyStateCard()
                        else ...[
                          _SummaryCard(opportunities: opportunities),
                          const SizedBox(height: AppTheme.spaceM),
                          ...opportunities.map((opportunity) {
                            final matches = _matchesForOpportunity(
                              listings,
                              opportunity,
                            );

                            final key = _opportunityKey(opportunity);

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spaceS,
                              ),
                              child: _OpportunityCard(
                                opportunity: opportunity,
                                duplicateLabel: _labelForBlueprint(
                                  opportunity.duplicateBlueprintId,
                                ),
                                targetLabel: _targetLabel(opportunity),
                                directMatches: matches,
                                created: _createdListingKeys.contains(key),
                                busy: _busyKeys.contains(key),
                                onCreateListing: () =>
                                    _createListing(opportunity),
                                onSendOffer: matches.isEmpty
                                    ? null
                                    : () => _sendOffer(
                                        listing: matches.first,
                                        opportunity: opportunity,
                                      ),
                                offerSent:
                                    matches.isNotEmpty &&
                                    _sentOfferKeys.contains(
                                      '${matches.first.id}::$key',
                                    ),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final int opportunityCount;
  final int duplicateTotal;
  final int targetCount;
  final VoidCallback? onCreateAll;

  const _IntroCard({
    required this.opportunityCount,
    required this.duplicateTotal,
    required this.targetCount,
    required this.onCreateAll,
  });

  @override
  Widget build(BuildContext context) {
    return ElectricChargeBorder(
      active: true,
      radius: 18,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Value Engine',
              style: AppTheme.neonTextStyle(
                fontSize: 24,
                color: AppTheme.neonPink,
                isBold: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live scan of your Blueprint Tracker dupes, Raid Planner active hunt targets, missing blueprints, and active marketplace listings.',
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.tradingMutedText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$duplicateTotal duplicate blueprints / $targetCount priority targets / $opportunityCount opportunities',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.neonCyan,
                isBold: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateAll,
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: const Text('Create all listing drafts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(radius: 16),
      child: Text(
        'No smart trade opportunities yet. Mark duplicate blueprints in the tracker and set your 5 active hunt targets in Raid Planner.',
        style: AppTheme.bodyTextStyle(
          fontSize: 14,
          color: AppTheme.tradingMutedText,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<SmartTradeOpportunity> opportunities;

  const _SummaryCard({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final listingDrafts = opportunities
        .where(
          (item) => item.tier == SmartTradeOpportunityTier.publicListingDraft,
        )
        .length;
    final missingFallbacks = opportunities
        .where(
          (item) =>
              item.tier == SmartTradeOpportunityTier.missingBlueprintMatch,
        )
        .length;
    final resourceFallbacks = opportunities
        .where(
          (item) => item.tier == SmartTradeOpportunityTier.usefulResourceBundle,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(radius: 16),
      child: Wrap(
        spacing: AppTheme.spaceS,
        runSpacing: AppTheme.spaceS,
        children: [
          _MetricPill(label: 'Listing drafts', value: listingDrafts),
          _MetricPill(label: 'Missing fallback', value: missingFallbacks),
          _MetricPill(label: 'Resource bundles', value: resourceFallbacks),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final int value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.72),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: Colors.white,
          isBold: true,
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final SmartTradeOpportunity opportunity;
  final String duplicateLabel;
  final String targetLabel;
  final List<TradingListing> directMatches;
  final bool created;
  final bool busy;
  final bool offerSent;
  final VoidCallback onCreateListing;
  final VoidCallback? onSendOffer;

  const _OpportunityCard({
    required this.opportunity,
    required this.duplicateLabel,
    required this.targetLabel,
    required this.directMatches,
    required this.created,
    required this.busy,
    required this.offerSent,
    required this.onCreateListing,
    required this.onSendOffer,
  });

  String get _tierLabel {
    switch (opportunity.tier) {
      case SmartTradeOpportunityTier.directTopFiveMatch:
        return 'Direct Top 5 Match';
      case SmartTradeOpportunityTier.missingBlueprintMatch:
        return 'Missing Blueprint Fallback';
      case SmartTradeOpportunityTier.valueCounterOffer:
        return 'Value Counter Offer';
      case SmartTradeOpportunityTier.usefulResourceBundle:
        return 'Useful Resource Bundle';
      case SmartTradeOpportunityTier.publicListingDraft:
        return 'Listing Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDirectMatch = directMatches.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
        border: Border.all(
          color: hasDirectMatch
              ? AppTheme.neonCyan.withValues(alpha: 0.62)
              : AppTheme.neonPink.withValues(alpha: 0.34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$duplicateLabel -> $targetLabel',
            style: AppTheme.neonTextStyle(
              fontSize: 17,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tierLabel,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: AppTheme.neonPink,
              isBold: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            opportunity.reason,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available dupes: ${opportunity.duplicateQuantityAvailable} / Priority rank: ${opportunity.priorityRank}',
            style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
          ),
          if (hasDirectMatch) ...[
            const SizedBox(height: 8),
            Text(
              'Direct match found: ${directMatches.first.traderDisplayLine}',
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: AppTheme.neonCyan,
                isBold: true,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: busy || created ? null : onCreateListing,
                icon: Icon(
                  created
                      ? Icons.check_circle_rounded
                      : Icons.add_business_rounded,
                ),
                label: Text(created ? 'Listing created' : 'Create listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  foregroundColor: Colors.white,
                ),
              ),
              if (hasDirectMatch)
                OutlinedButton.icon(
                  onPressed: busy || offerSent ? null : onSendOffer,
                  icon: Icon(
                    offerSent ? Icons.check_circle_rounded : Icons.send_rounded,
                  ),
                  label: Text(offerSent ? 'Offer sent' : 'Send offer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.neonCyan,
                    side: BorderSide(color: AppTheme.neonCyan),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
