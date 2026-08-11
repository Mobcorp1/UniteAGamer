import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_make_offer_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_cosmetic_identity_strip.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingListingDetailScreen extends StatelessWidget {
  const TradingListingDetailScreen({super.key, required this.listing});

  final TradingListing listing;

  Future<void> _requestCollectionView(BuildContext context) async {
    final repository = TradingRepository();
    try {
      await repository.requestCollectionView(listing);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Collection request sent.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send request: $e')));
    }
  }

  Future<void> _toggleFavouriteSeller(
    BuildContext context,
    TradingRepository repository, {
    required bool currentlyFavourite,
  }) async {
    try {
      await repository.setFavouriteRider(
        riderUid: listing.ownerUid,
        favourite: !currentlyFavourite,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyFavourite
                ? '${listing.traderName} removed from Favourite Riders.'
                : '${listing.traderName} added to Favourite Riders.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update favourite: $e')));
    }
  }

  Future<void> _watchFirstOfferedBlueprint(
    BuildContext context,
    TradingRepository repository,
  ) async {
    if (listing.offeredBlueprintNames.isEmpty) return;
    final blueprintName = listing.offeredBlueprintNames.first;
    final match = ArcBlueprintSeedData.blueprints.where(
      (blueprint) =>
          blueprint.name.toLowerCase() == blueprintName.toLowerCase() ||
          blueprint.id.toLowerCase() == blueprintName.toLowerCase(),
    );
    final blueprint = match.isEmpty ? null : match.first;
    try {
      await repository.createOrReactivateBlueprintWatch(
        blueprintId: blueprint?.id ?? blueprintName,
        blueprintDisplayName: blueprint?.name ?? blueprintName,
        linkedListingId: listing.id,
        preferredAcquisitionMethods: const <String>['Trade listings'],
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$blueprintName watch is active.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not watch blueprint: $error')),
      );
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _section(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'None listed.',
              style: TextStyle(color: AppTheme.tradingFaintText),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => Container(
                      padding: AppTheme.pillPadding,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: AppTheme.tradingCardBackground,
                        border: Border.all(color: AppTheme.tradingSoftBorder),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppTheme.tradingMutedText,
            fontSize: 14,
            fontFamily: AppTheme.bodyFontFamily,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppTheme.neonPink,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _intelligencePanel(ArcTradeListingScore intelligence) {
    return Container(
      decoration: AppTheme.tradingCardDecoration(
        borderColor: intelligence.isActionable
            ? AppTheme.neonCyan.withValues(alpha: 0.34)
            : AppTheme.tradingSoftBorder,
      ),
      padding: AppTheme.sectionCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(intelligence.label, AppTheme.neonPink),
              _chip('Intel ${intelligence.score}%', AppTheme.neonCyan),
              _chip(intelligence.recommendation, Colors.amberAccent),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            intelligence.reason,
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: Colors.white70,
              isBold: true,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            intelligence.reputationHint,
            style: TextStyle(color: AppTheme.tradingMutedText, height: 1.3),
          ),
          if (intelligence.reasons.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: intelligence.reasons
                  .map((reason) => _chip(reason, AppTheme.neonCyan))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = TradingRepository();
    final offeredList = listing.allOfferedItems;
    final wantedList = listing.listingType == TradingListingType.openToOffers
        ? const <String>[]
        : listing.allWantedItems;
    final structureBits = <String>[
      listing.tradeFormatLabel,
      if (listing.hasExactAcceptedBundles) listing.structuredTermsSummary,
      if (listing.allowPartialOffers) 'Partial offers allowed',
      if (listing.seriousOffersOnly) 'Serious offers only',
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Listing Detail',
          style: AppTheme.tradingHeading(fontSize: 25),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.pageMaxWidth,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    StreamBuilder<Map<String, ArcBlueprintState>>(
                      stream: repository.watchBlueprintStates(),
                      builder: (context, stateSnapshot) {
                        final intelligence = const ArcTradeIntelligenceEngine()
                            .scoreListing(
                              listing: listing,
                              blueprintStates:
                                  stateSnapshot.data ??
                                  const <String, ArcBlueprintState>{},
                              currentUid: repository.currentUid,
                            );

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: Column(
                            children: [
                              Container(
                                decoration: AppTheme.tradingCardDecoration(),
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.title,
                                      style: AppTheme.tradingHeading(
                                        fontSize: 26,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceM),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _chip(
                                          listing.riskLabel,
                                          listing.riskColor(),
                                        ),
                                        _chip(
                                          listing.region,
                                          AppTheme.neonCyan,
                                        ),
                                        _chip(
                                          listing.playWindow,
                                          AppTheme.neonPink,
                                        ),
                                        _chip(
                                          listing.listingModeLabel,
                                          AppTheme.warningAmber,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTheme.spaceM),
                                    TradingCosmeticIdentityStrip(
                                      repository: repository,
                                      uid: listing.ownerUid,
                                      displayName: listing.traderName,
                                      subtitle: [
                                        if (listing.gamerTag.isNotEmpty)
                                          listing.gamerTag,
                                        if (listing
                                            .preferredPlatform
                                            .isNotEmpty)
                                          listing.preferredPlatform,
                                        listing.reputationSummary,
                                      ].join(' - '),
                                    ),
                                    StreamBuilder<Set<String>>(
                                      stream: repository
                                          .watchFavouriteRiderIds(),
                                      builder: (context, favouriteSnapshot) {
                                        final favouriteIds =
                                            favouriteSnapshot.data ??
                                            const <String>{};
                                        final isFavourite = favouriteIds
                                            .contains(listing.ownerUid);
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _toggleFavouriteSeller(
                                                  context,
                                                  repository,
                                                  currentlyFavourite:
                                                      isFavourite,
                                                ),
                                            icon: Icon(
                                              isFavourite
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                            ),
                                            label: Text(
                                              isFavourite
                                                  ? 'Favourite Rider'
                                                  : 'Add Favourite Rider',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (listing
                                        .offeredBlueprintNames
                                        .isNotEmpty)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _watchFirstOfferedBlueprint(
                                                context,
                                                repository,
                                              ),
                                          icon: const Icon(
                                            Icons.add_alert_outlined,
                                          ),
                                          label: const Text('WATCH BLUEPRINT'),
                                        ),
                                      ),
                                    const SizedBox(height: AppTheme.spaceM),
                                    _section('Offering', offeredList),
                                    if (listing.listingType ==
                                        TradingListingType.openToOffers)
                                      _row('Looking for', 'Open to offers')
                                    else
                                      _section('Looking for', wantedList),
                                    _row(
                                      'Accepts',
                                      [
                                        if (listing.acceptsBlueprints)
                                          'Blueprints',
                                        if (listing.acceptsSeeds) 'Seeds',
                                        if (listing.acceptsResources)
                                          'Resources',
                                      ].join(' - '),
                                    ),
                                    if (structureBits.isNotEmpty)
                                      _row(
                                        'Trade structure',
                                        structureBits.join(' - '),
                                      ),
                                    _row(
                                      'Listing mode',
                                      listing.listingModeLabel,
                                    ),
                                    if (listing.isQueueLinked)
                                      _row(
                                        'Queue',
                                        listing.queueReleaseNumber <= 0
                                            ? 'Source listing'
                                            : 'Released copy ${listing.queueReleaseNumber + 1}',
                                      ),
                                    _row(
                                      'Active offer cap',
                                      '${listing.maxActiveOffers}',
                                    ),
                                    if (listing.notes.isNotEmpty)
                                      _row('Notes', listing.notes),
                                    const SizedBox(height: 10),
                                    Divider(color: AppTheme.tradingDivider),
                                    const SizedBox(height: 10),
                                    _row('Trader', listing.traderName),
                                    _row(
                                      'Gamertag',
                                      listing.gamerTag.isEmpty
                                          ? 'Not set'
                                          : listing.gamerTag,
                                    ),
                                    _row(
                                      'Preferred Platform',
                                      listing.preferredPlatform.isEmpty
                                          ? 'Not set'
                                          : listing.preferredPlatform,
                                    ),
                                    _row(
                                      'Reputation',
                                      '${listing.completedTrades} completed - ${listing.noShows} no-shows - ${listing.betrayalFlags} flags',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _intelligencePanel(intelligence),
                              const SizedBox(height: AppTheme.spaceM),
                              Container(
                                decoration: AppTheme.tradingCardDecoration(),
                                padding: AppTheme.sectionCardPadding,
                                child: Text(
                                  'Current best practice: agree the exact split in chat first. If the listing is bundle only, treat it as one full trade. If mix-and-match is allowed, confirm exactly which items are swapping before you drop anything.',
                                  style: TextStyle(
                                    color: AppTheme.tradingMutedText,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TradingMakeOfferScreen(
                                      listing: listing,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonPink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Make Offer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _requestCollectionView(context),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Request Dupes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 104),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
