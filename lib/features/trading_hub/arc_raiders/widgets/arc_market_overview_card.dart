import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_market_snapshot.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcMarketOverviewCard extends StatelessWidget {
  const ArcMarketOverviewCard({
    super.key,
    required this.snapshot,
    this.maxBreakdownItems = 5,
  });

  final ArcMarketSnapshot snapshot;
  final int maxBreakdownItems;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasReports) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(
          radius: 18,
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
        ),
        child: const Text(
          'No market data yet. As reports come in, this screen will show the hottest blueprints, maps, conditions and report trends.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: AppTheme.neonPink.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Overview',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Reports',
                value: '${snapshot.totalReports}',
                color: AppTheme.neonCyan,
              ),
              _StatChip(
                label: 'Blueprints',
                value: '${snapshot.uniqueBlueprints}',
                color: Colors.lightGreenAccent,
              ),
              _StatChip(
                label: 'Maps',
                value: '${snapshot.uniqueMaps}',
                color: Colors.amberAccent,
              ),
              _StatChip(
                label: 'Confidence',
                value: snapshot.confidenceLabel,
                color: AppTheme.neonPink,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceL),
          if (snapshot.topBlueprintLabel != null)
            _HeadlineLine(
              label: 'Most reported blueprint',
              value: snapshot.topBlueprintLabel!,
              color: AppTheme.neonCyan,
            ),
          if (snapshot.topMapLabel != null)
            _HeadlineLine(
              label: 'Hottest map',
              value: snapshot.topMapLabel!,
              color: Colors.lightGreenAccent,
            ),
          if (snapshot.topConditionLabel != null)
            _HeadlineLine(
              label: 'Top condition / event',
              value: snapshot.topConditionLabel!,
              color: Colors.amberAccent,
            ),
          const SizedBox(height: AppTheme.spaceL),
          if (snapshot.blueprintBreakdown.isNotEmpty)
            _BreakdownBlock(
              title: 'Top Blueprints',
              accentColor: AppTheme.neonCyan,
              items: snapshot.blueprintBreakdown
                  .take(maxBreakdownItems)
                  .toList(growable: false),
            ),
          if (snapshot.mapBreakdown.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceL),
            _BreakdownBlock(
              title: 'Hot Maps',
              accentColor: Colors.lightGreenAccent,
              items: snapshot.mapBreakdown
                  .take(maxBreakdownItems)
                  .toList(growable: false),
            ),
          ],
          if (snapshot.conditionBreakdown.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceL),
            _BreakdownBlock(
              title: 'Conditions / Events',
              accentColor: Colors.amberAccent,
              items: snapshot.conditionBreakdown
                  .take(maxBreakdownItems)
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadlineLine extends StatelessWidget {
  const _HeadlineLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, height: 1.35),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownBlock extends StatelessWidget {
  const _BreakdownBlock({
    required this.title,
    required this.accentColor,
    required this.items,
  });

  final String title;
  final Color accentColor;
  final List<ArcMarketSnapshotEntry> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.tradingHeading(fontSize: 18, color: accentColor),
        ),
        const SizedBox(height: AppTheme.spaceS),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM,
                vertical: AppTheme.spaceS,
              ),
              decoration: AppTheme.tradingCardDecoration(
                radius: 14,
                borderColor: accentColor.withValues(alpha: 0.14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${item.count} reports',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.percentageLabel,
                    style: AppTheme.neonTextStyle(
                      fontSize: 14,
                      color: accentColor,
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
