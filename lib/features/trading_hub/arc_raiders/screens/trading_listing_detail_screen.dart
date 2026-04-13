import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_make_offer_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingListingDetailScreen extends StatelessWidget {
  const TradingListingDetailScreen({super.key, required this.listing});

  final TradingListing listing;

  Future<void> _requestCollectionView(BuildContext context) async {
    final repository = TradingRepository();
    try {
      await repository.requestCollectionView(listing);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection request sent.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send request: $e')),
      );
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
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
            style: AppTheme.tradingHeading(fontSize: 18, color: AppTheme.neonPink),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('None listed.', style: TextStyle(color: AppTheme.tradingFaintText))
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
              style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offeredList = listing.allOfferedItems;
    final wantedList = listing.listingType == TradingListingType.openToOffers
        ? const <String>[]
        : listing.allWantedItems;
    final structureBits = <String>[
      listing.tradeFormatLabel,
      if (listing.allowPartialOffers) 'Partial offers allowed',
      if (listing.seriousOffersOnly) 'Serious offers only',
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Listing Detail', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTheme.pageMaxWidth),
                child: ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    Container(
                      decoration: AppTheme.tradingCardDecoration(),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listing.title, style: AppTheme.tradingHeading(fontSize: 26)),
                          const SizedBox(height: AppTheme.spaceM),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(listing.riskLabel, listing.riskColor()),
                              _chip(listing.region, AppTheme.neonCyan),
                              _chip(listing.playWindow, AppTheme.neonPink),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceL),
                          _section('Offering', offeredList),
                          if (listing.listingType == TradingListingType.openToOffers)
                            _row('Looking for', 'Open to offers')
                          else
                            _section('Looking for', wantedList),
                          _row(
                            'Accepts',
                            [
                              if (listing.acceptsBlueprints) 'Blueprints',
                              if (listing.acceptsSeeds) 'Seeds',
                              if (listing.acceptsResources) 'Resources',
                            ].join(' • '),
                          ),
                          if (structureBits.isNotEmpty)
                            _row('Trade structure', structureBits.join(' • ')),
                          if (listing.notes.isNotEmpty) _row('Notes', listing.notes),
                          const SizedBox(height: 10),
                          Divider(color: AppTheme.tradingDivider),
                          const SizedBox(height: 10),
                          _row('Trader', listing.traderName),
                          _row('Gamertag', listing.gamerTag.isEmpty ? 'Not set' : listing.gamerTag),
                          _row(
                            'Preferred Platform',
                            listing.preferredPlatform.isEmpty ? 'Not set' : listing.preferredPlatform,
                          ),
                          _row(
                            'Reputation',
                            '${listing.completedTrades} completed • ${listing.noShows} no-shows • ${listing.betrayalFlags} flags',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    Container(
                      decoration: AppTheme.tradingCardDecoration(),
                      padding: AppTheme.sectionCardPadding,
                      child: Text(
                        'Current best practice: agree the exact split in chat first. If the listing is bundle only, treat it as one full trade. If mix-and-match is allowed, confirm exactly which items are swapping before you drop anything.',
                        style: TextStyle(color: AppTheme.tradingMutedText, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TradingMakeOfferScreen(listing: listing),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonPink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Make Offer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
