import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingMyListingsScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders/my-listings';

  const TradingMyListingsScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  Widget _statusChip(TradingListing listing) {
    final color = listing.active ? AppTheme.neonCyan : Colors.white54;
    final label = listing.active ? 'Open' : 'Closed';
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

  Widget _listingCard(
    BuildContext context,
    TradingRepository repository,
    TradingListing listing,
  ) {
    final formatBits = <String>[
      listing.tradeFormatLabel,
      if (listing.allowPartialOffers) 'Partial offers on',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(),
      child: Padding(
        padding: AppTheme.sectionCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    style: AppTheme.tradingHeading(
                      fontSize: 22,
                      color: AppTheme.neonPink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _statusChip(listing),
              ],
            ),
            const SizedBox(height: AppTheme.spaceS),
            if (listing.isQueueLinked) ...[
              Container(
                padding: AppTheme.pillPadding,
                decoration: AppTheme.tradingPillDecoration(
                  color: AppTheme.warningAmber,
                ),
                child: Text(
                  listing.queueReleaseNumber <= 0
                      ? 'Queue source listing'
                      : 'Queue release ${listing.queueReleaseNumber + 1}',
                  style: const TextStyle(
                    color: AppTheme.warningAmber,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
            ],
            Text(
              'Offering: ${listing.offeredSummary}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Wanted: ${listing.wantedSummary}',
              style: TextStyle(color: AppTheme.tradingMutedText),
            ),
            if (formatBits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                formatBits.join(' - '),
                style: TextStyle(color: AppTheme.tradingFaintText),
              ),
            ],
            if (listing.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                listing.notes,
                style: TextStyle(color: AppTheme.tradingFaintText),
              ),
            ],
            const SizedBox(height: AppTheme.spaceM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: listing.active
                      ? () => repository.closeListing(listing.id)
                      : () => repository.reopenListing(listing.id),
                  icon: Icon(
                    listing.active
                        ? Icons.pause_circle_outline
                        : Icons.restart_alt_rounded,
                  ),
                  label: Text(
                    listing.active ? 'Close Listing' : 'Reopen Listing',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => repository.deleteListing(listing.id),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TradingRepository repository) {
    return Stack(
      children: [
        const Positioned.fill(child: ArcRaidersScreenBackdrop()),
        SafeArea(
          child: StreamBuilder<List<TradingListing>>(
            stream: repository.watchMyListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.neonCyan),
                );
              }

              final items = snapshot.data ?? const <TradingListing>[];
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                    child: Text(
                      'No listings yet. Create your first listing from the Trader Hub.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.tradingMutedText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                children: [
                  for (final item in items)
                    _listingCard(context, repository, item),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = TradingRepository();

    if (!showAppBar) {
      return _buildBody(context, repository);
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'My Listings',
          style: AppTheme.tradingHeading(fontSize: 25),
        ),
      ),
      body: _buildBody(context, repository),
    );
  }
}
