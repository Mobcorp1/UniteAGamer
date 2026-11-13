import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
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

    return TradingCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      accent: listing.active ? AppTheme.neonCyan : AppTheme.tradingFaintText,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final offered = _exchangePanel(
                label: 'YOU OFFER',
                value: listing.offeredSummary,
                icon: Icons.upload_rounded,
                accent: ArcUiTokens.secondaryAccent,
              );
              final wanted = _exchangePanel(
                label: 'YOU WANT',
                value: listing.wantedSummary,
                icon: Icons.download_rounded,
                accent: ArcUiTokens.primaryAccent,
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [offered, const SizedBox(height: 8), wanted],
                );
              }
              return Row(
                children: [
                  Expanded(child: offered),
                  const SizedBox(width: 8),
                  Expanded(child: wanted),
                ],
              );
            },
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
    );
  }

  Widget _exchangePanel({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: accent,
        borderOpacity: 0.20,
        radius: ArcUiTokens.radiusM,
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ArcUiTokens.label(color: accent)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.cardTitle(
                    fontSize: 13,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TradingRepository repository) {
    return ArcRaidersScreenShell(
      showAdBanner: false,
      child: SafeArea(
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
                  child: const ArcRaidersStatePanel(
                    title: 'No listings yet',
                    message:
                        'Create a trade listing from Trader Hub when you have items to offer.',
                    icon: Icons.inventory_2_outlined,
                    accent: ArcUiTokens.secondaryAccent,
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
