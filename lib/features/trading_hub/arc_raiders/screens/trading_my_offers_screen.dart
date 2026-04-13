import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingMyOffersScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders/offers';

  const TradingMyOffersScreen({super.key});

  Color _statusColor(TradingOfferStatus status) {
    switch (status) {
      case TradingOfferStatus.pending:
        return Colors.amberAccent;
      case TradingOfferStatus.accepted:
        return Colors.greenAccent;
      case TradingOfferStatus.declined:
        return Colors.redAccent;
      case TradingOfferStatus.cancelled:
        return Colors.deepOrangeAccent;
      case TradingOfferStatus.expired:
        return Colors.redAccent;
    }
  }

  String _bundleText(TradingOffer offer) {
    final parts = <String>[];
    if (offer.smallBundles > 0) parts.add('${offer.smallBundles}×10');
    if (offer.mediumBundles > 0) parts.add('${offer.mediumBundles}×50');
    if (offer.largeBundles > 0) parts.add('${offer.largeBundles}×100');
    if (parts.isEmpty) return 'No seed bundles';
    return '${parts.join(' • ')} (${offer.seedTotal} total)';
  }

  Future<bool> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.tradingCardBackground,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _actionButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.45)),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _offerCard(BuildContext context, TradingRepository repository, TradingOffer offer) {
    final uid = repository.currentUid;
    final isSentByMe = uid == offer.senderUid;
    final canAction = offer.status == TradingOfferStatus.pending;
    final messenger = ScaffoldMessenger.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                    isSentByMe ? 'Offer Sent' : 'Offer Received',
                    style: AppTheme.tradingHeading(fontSize: 22),
                  ),
                ),
                Container(
                  padding: AppTheme.pillPadding,
                  decoration: AppTheme.tradingPillDecoration(
                    color: _statusColor(offer.status),
                  ),
                  child: Text(
                    offer.statusLabel,
                    style: TextStyle(
                      color: _statusColor(offer.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Blueprints: ${offer.offeredBlueprintText.isEmpty ? 'None listed' : offer.offeredBlueprintText}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Text('Seeds: ${_bundleText(offer)}', style: TextStyle(color: AppTheme.tradingMutedText)),
            const SizedBox(height: 6),
            Text('Resources: ${offer.includesResources ? offer.resourcesText : 'None'}', style: TextStyle(color: AppTheme.tradingMutedText)),
            if (offer.note.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Message: ${offer.note}', style: TextStyle(color: AppTheme.tradingFaintText)),
            ],
            const SizedBox(height: 6),
            Text('Listing ID: ${offer.listingId}', style: TextStyle(color: AppTheme.tradingFaintText, fontSize: 12)),
            if (offer.status == TradingOfferStatus.accepted) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TradingTradeSessionsScreen()),
                  );
                },
                icon: const Icon(Icons.event_available_rounded),
                label: const Text('Open Trade Sessions'),
              ),
            ] else if (canAction) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (isSentByMe)
                    _actionButton(
                      label: 'Cancel',
                      color: Colors.deepOrangeAccent,
                      icon: Icons.cancel_outlined,
                      onPressed: () async {
                        final confirmed = await _confirmAction(
                          context: context,
                          title: 'Cancel offer?',
                          message: 'This will cancel your trade offer.',
                          confirmText: 'Cancel Offer',
                          confirmColor: Colors.deepOrangeAccent,
                        );
                        if (!confirmed) return;
                        try {
                          await repository.cancelOffer(offer);
                          messenger.showSnackBar(const SnackBar(content: Text('Offer cancelled.')));
                        } catch (error) {
                          messenger.showSnackBar(SnackBar(content: Text('Could not cancel offer: $error')));
                        }
                      },
                    )
                  else ...[
                    _actionButton(
                      label: 'Decline',
                      color: Colors.redAccent,
                      icon: Icons.close_rounded,
                      onPressed: () async {
                        final confirmed = await _confirmAction(
                          context: context,
                          title: 'Decline offer?',
                          message: 'This will decline the offer for both traders.',
                          confirmText: 'Decline',
                          confirmColor: Colors.redAccent,
                        );
                        if (!confirmed) return;
                        try {
                          await repository.declineOffer(offer);
                          messenger.showSnackBar(const SnackBar(content: Text('Offer declined.')));
                        } catch (error) {
                          messenger.showSnackBar(SnackBar(content: Text('Could not decline offer: $error')));
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _actionButton(
                      label: 'Accept',
                      color: Colors.greenAccent,
                      icon: Icons.check_circle_outline,
                      onPressed: () async {
                        final confirmed = await _confirmAction(
                          context: context,
                          title: 'Accept offer?',
                          message: 'This will accept the offer, close the listing, decline the other pending offers and create a trade session.',
                          confirmText: 'Accept',
                          confirmColor: Colors.greenAccent,
                        );
                        if (!confirmed) return;
                        try {
                          await repository.acceptOffer(offer);
                          messenger.showSnackBar(const SnackBar(content: Text('Offer accepted and session created.')));
                        } catch (error) {
                          messenger.showSnackBar(SnackBar(content: Text('Could not accept offer: $error')));
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = TradingRepository();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('My Offers', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<List<TradingOffer>>(
              stream: repository.watchMyOffers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  );
                }

                final offers = snapshot.data ?? const <TradingOffer>[];
                if (offers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: AppTheme.pagePadding,
                      child: Text(
                        'No offers yet. Send offers from listing details and manage them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.tradingMutedText, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: AppTheme.pagePadding,
                  itemCount: offers.length,
                  itemBuilder: (context, index) => _offerCard(context, repository, offers[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
