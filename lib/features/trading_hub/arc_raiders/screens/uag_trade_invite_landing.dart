import 'package:flutter/material.dart';

import '../models/trading_listing.dart';
import '../repositories/trading_repository.dart';
import '../services/uag_trade_invite_service.dart';
import 'trading_listing_detail_screen.dart';
import 'trading_listings_screen.dart';

/// Shown only INSIDE AppEntryGate after authentication, legal consent and
/// mandatory onboarding. A page view never submits an offer or booking.
class UagTradeInviteLanding extends StatefulWidget {
  const UagTradeInviteLanding({super.key, required this.token, required this.onExit});

  final String token;
  final VoidCallback onExit;

  @override
  State<UagTradeInviteLanding> createState() => _UagTradeInviteLandingState();
}

class _UagTradeInviteLandingState extends State<UagTradeInviteLanding> {
  late final Future<Map<String, dynamic>> _claim;
  final TradingRepository _trading = TradingRepository();

  @override
  void initState() {
    super.initState();
    _claim = UagTradeInviteService.instance.claim(widget.token);
  }

  Future<void> _exit() async {
    await UagTradeInviteService.instance.clearPending();
    if (mounted) widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07131D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2735),
        foregroundColor: const Color(0xFF6CE6EA),
        title: const Text('RAIDER TRADE INVITATION'),
        leading: IconButton(onPressed: _exit, icon: const Icon(Icons.close)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _claim,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('INVITATION UNAVAILABLE', style: TextStyle(color: Color(0xFFFF91C8), fontSize: 20)),
                const SizedBox(height: 10),
                const Text('This trading link cannot be opened right now. It may have expired or been revoked. Ask the Raider for a new link.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                TextButton(onPressed: _exit, child: const Text('Return to UAG')),
              ]),
            ));
          }
          final info = snapshot.data!;
          final ownerUid = info['ownerUid']?.toString() ?? '';
          final alias = info['alias']?.toString() ?? 'UAG Raider';
          return StreamBuilder<List<TradingListing>>(
            stream: _trading.watchActiveListings(),
            builder: (context, listings) {
              final matching = (listings.data ?? const <TradingListing>[])
                  .where((listing) => listing.ownerUid == ownerUid && listing.active)
                  .toList(growable: false);
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text('TRADE WITH $alias', style: const TextStyle(fontSize: 25,
                  color: Color(0xFF69E5E9), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Your link brought you directly back to the original Raider. Review an active listing to make an explicit offer and arrange a session.',
                  style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 18),
                if (!listings.hasData && !listings.hasError)
                  const Center(child: CircularProgressIndicator()),
                if (listings.hasError)
                  const Text('Listings are temporarily unavailable.', style: TextStyle(color: Colors.orangeAccent)),
                if (listings.hasData && matching.isEmpty)
                  const Text('This Raider has no active trade listings yet. You can browse the Trading Hub while they prepare a listing.',
                    style: TextStyle(color: Colors.white70)),
                ...matching.map((listing) => Card(
                  color: const Color(0xFF163342),
                  child: ListTile(
                    title: Text(listing.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${listing.offeredItem} · Wants: ${listing.wantedText}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF92C8)),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => TradingListingDetailScreen(listing: listing),
                    )),
                  ),
                )),
                const SizedBox(height: 14),
                FilledButton.icon(onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TradingListingsScreen())),
                  icon: const Icon(Icons.swap_horiz), label: const Text('BROWSE TRADING HUB')),
                TextButton(onPressed: _exit, child: const Text('Return to Command Centre')),
              ]);
            },
          );
        },
      ),
    );
  }
}
