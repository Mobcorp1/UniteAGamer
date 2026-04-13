import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingListingCard extends StatelessWidget {
  const TradingListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.trailing,
    this.showStatus = false,
  });

  final TradingListing listing;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStatus;

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

  Widget _metaChip(String label) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.tradingCardBackground,
        border: Border.all(color: AppTheme.tradingSoftBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.tradingMutedText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.tradingMutedText,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = listing.isLive ? AppTheme.neonCyan : Colors.white54;
    final statusLabel = listing.isLive ? 'Live' : (listing.active ? 'Expired' : 'Closed');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(),
        child: Padding(
          padding: AppTheme.sectionCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: AppTheme.tradingHeading(
                        fontSize: 22,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(width: 12),
                    _chip(statusLabel, statusColor),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(listing.riskLabel, listing.riskColor()),
                  _metaChip(listing.region),
                  _metaChip(listing.playWindow),
                  _metaChip(listing.expiryLabel()),
                  _metaChip(listing.listingTypeLabel),
                  if (listing.seriousOffersOnly) _metaChip('Serious only'),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              _labelValue('Offering', listing.offeredItem),
              const SizedBox(height: AppTheme.spaceS),
              _labelValue('Wants', listing.wantedText),
              const SizedBox(height: AppTheme.spaceS),
              _labelValue('Accepts', listing.acceptedTradeTypesLabel),
              if (listing.hasSeedOffer) ...[
                const SizedBox(height: AppTheme.spaceS),
                _labelValue('Seed Value', '${listing.seedTotalOffered} seeds'),
              ],
              if (listing.notes.trim().isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceS),
                _labelValue('Notes', listing.notes.trim()),
              ],
              const SizedBox(height: AppTheme.spaceM),
              Divider(color: AppTheme.tradingDivider),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                listing.traderDisplayLine,
                style: TextStyle(
                  color: AppTheme.tradingMutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                listing.reputationSummary,
                style: TextStyle(color: AppTheme.tradingFaintText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
