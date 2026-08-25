import 'package:flutter/material.dart';

import '../models/arc_trade_listing.dart';
import '../repositories/arc_trade_listing_repository.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMyTradeListingsScreen extends StatelessWidget {
  const ArcMyTradeListingsScreen({super.key});

  static const routeName = '/arc-my-trade-listings';

  @override
  Widget build(BuildContext context) {
    final repository = ArcTradeListingRepository();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'My Trade Listings',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: StreamBuilder<List<ArcTradeListing>>(
            stream: repository.watchMyListings(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <ArcTradeListing>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No listings yet.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 14,
                      color: AppTheme.tradingMutedText,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return TradingCard(
                    accent: item.isOpen
                        ? AppTheme.neonCyan
                        : AppTheme.tradingMutedText,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${item.offeredBlueprintName} -> ${item.wantedBlueprintName}',
                        style: AppTheme.tradingHeading(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${item.region} - ${item.platform}\n'
                        'Status: ${item.status}\n'
                        '${item.note.isEmpty ? 'No notes' : item.note}',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 13,
                          color: AppTheme.tradingMutedText,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'close') {
                            await repository.closeListing(item.id);
                          } else if (value == 'reopen') {
                            await repository.reopenListing(item.id);
                          } else if (value == 'delete') {
                            await repository.deleteListing(item.id);
                          }
                        },
                        itemBuilder: (context) => [
                          if (item.isOpen)
                            const PopupMenuItem(
                              value: 'close',
                              child: Text('Close'),
                            ),
                          if (!item.isOpen)
                            const PopupMenuItem(
                              value: 'reopen',
                              child: Text('Reopen'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemCount: items.length,
              );
            },
          ),
        ),
      ),
    );
  }
}
