import 'package:flutter/material.dart';

import '../models/arc_trade_listing.dart';
import '../repositories/arc_trade_listing_repository.dart';

class ArcMyTradeListingsScreen extends StatelessWidget {
  const ArcMyTradeListingsScreen({super.key});

  static const routeName = '/arc-my-trade-listings';

  @override
  Widget build(BuildContext context) {
    final repository = ArcTradeListingRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('My Trade Listings')),
      body: StreamBuilder<List<ArcTradeListing>>(
        stream: repository.watchMyListings(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ArcTradeListing>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return const Center(child: Text('No listings yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(
                    '${item.offeredBlueprintName} → ${item.wantedBlueprintName}',
                  ),
                  subtitle: Text(
                    '${item.region} • ${item.platform}\n'
                    'Status: ${item.status}\n'
                    '${item.note.isEmpty ? 'No notes' : item.note}',
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
    );
  }
}
