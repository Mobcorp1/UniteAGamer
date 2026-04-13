
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/services/arc_market_snapshot_service.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/arc_market_overview_card.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/arc_recent_reports_feed.dart';
import 'package:uag_traders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcMarketIntelligenceScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders/market';

  const ArcMarketIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ArcBlueprintRepository();
    const snapshotService = ArcMarketSnapshotService();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Market Intelligence',
          style: AppTheme.tradingHeading(
            fontSize: 25,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<List<ArcBlueprintDropReport>>(
              stream: repository.watchRecentReports(limit: 200),
              builder: (context, snapshot) {
                final reports = snapshot.data ?? const <ArcBlueprintDropReport>[];
                final market = snapshotService.build(reports);

                return ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    Text(
                      'Community pulse for Arc Raiders blueprint reports. Use this to spot hot maps, active conditions, and the items the community is seeing most often right now.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(ArcIntelExplorerScreen.routeName);
                        },
                        icon: const Icon(Icons.travel_explore_outlined),
                        label: const Text('Open Intel Explorer'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    CollapsibleSectionCard(
                      title: 'Market Overview',
                      initiallyExpanded: true,
                      titleColor: AppTheme.neonCyan,
                      child: ArcMarketOverviewCard(snapshot: market),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    CollapsibleSectionCard(
                      title: 'Recent Community Reports',
                      initiallyExpanded: false,
                      titleColor: AppTheme.neonPink,
                      child: ArcRecentReportsFeed(reports: reports),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
