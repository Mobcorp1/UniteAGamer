import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/services/automation/smart_trade_assist_engine.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SmartTradeAssistScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders/smart-trade-assist';

  const SmartTradeAssistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demoOpportunities = const SmartTradeAssistEngine()
        .buildFullOpportunityStack(
          duplicateBlueprintQuantities: const {
            'wolfpack': 3,
            'power-descender': 1,
          },
          topFiveWantedBlueprintIds: const [
            'rascal',
            'extended-barrel-ii',
            'muzzle-brake-ii',
            'burletta',
            'equalizer',
          ],
          missingBlueprintIds: const ['canto', 'venator', 'jupiter'],
          usefulResourceIds: const [
            'mechanical-components',
            'electrical-components',
            'industrial-components',
          ],
        );

    return Scaffold(
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
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              children: [
                _IntroCard(opportunityCount: demoOpportunities.length),
                const SizedBox(height: AppTheme.spaceM),
                _SummaryCard(opportunities: demoOpportunities),
                const SizedBox(height: AppTheme.spaceM),
                ...demoOpportunities
                    .take(12)
                    .map(
                      (opportunity) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                        child: _OpportunityCard(opportunity: opportunity),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final int opportunityCount;

  const _IntroCard({required this.opportunityCount});

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
              'Turns duplicate blueprints into useful trade opportunities by checking Top 5 targets first, then missing blueprints, then useful resource bundles.',
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: AppTheme.tradingMutedText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$opportunityCount suggested opportunities ready for wiring.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.neonCyan,
                isBold: true,
              ),
            ),
          ],
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

  const _OpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final targetText = opportunity.requestedBlueprintId != null
        ? opportunity.requestedBlueprintId!
        : opportunity.requestedResourceIds.join(', ');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${opportunity.duplicateBlueprintId} â†’ $targetText',
            style: AppTheme.neonTextStyle(
              fontSize: 17,
              color: AppTheme.neonCyan,
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
            'Available dupes: ${opportunity.duplicateQuantityAvailable} â€¢ Priority rank: ${opportunity.priorityRank}',
            style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
