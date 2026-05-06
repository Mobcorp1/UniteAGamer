import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/features/feature_access_gate.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRaidersHubScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders';

  const ArcRaidersHubScreen({super.key});

  Widget _buildBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0.4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 6,
          child: Image.asset(
            'assets/arc_raiders/banners/arc_raiders_hub_banner.webp',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  String _splitTitle(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) return title;
    return '${words.first}\n${words.sublist(1).join(' ')}';
  }

  Widget _buildHubCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElectricChargeBorder(
      active: true,
      radius: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: AppTheme.tradingCardDecoration(radius: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.neonCyan, size: 25),
                const SizedBox(height: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _splitTitle(title),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTheme.neonTextStyle(
                        fontSize: 15,
                        color: AppTheme.neonCyan,
                        isBold: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerStructureCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: AppTheme.neonPink.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracker structure',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Blueprints, Scrappy, Bench and Quest items now open as focused tracker workflows instead of being buried together on one overloaded page.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <({String title, IconData icon, String routeName, String? flag})>[
      (
        title: 'Intel Snapshot',
        icon: Icons.insights_rounded,
        routeName: ArcMarketIntelligenceScreen.routeName,
        flag: null,
      ),
      (
        title: 'Blueprint Grid',
        icon: Icons.grid_view_rounded,
        routeName: BlueprintGridScreen.routeName,
        flag: null,
      ),
      (
        title: 'Raid Planner',
        icon: Icons.route_rounded,
        routeName: RaidPlannerScreen.routeName,
        flag: null,
      ),
      (
        title: 'Scrappy Tracker',
        icon: Icons.pets_rounded,
        routeName: ScrappyGridScreen.routeName,
        flag: FeatureAccessFlag.scrappyTracker,
      ),
      (
        title: 'Bench Tracker',
        icon: Icons.handyman_rounded,
        routeName: ScrappyGridScreen.benchRouteName,
        flag: FeatureAccessFlag.scrappyTracker,
      ),
      (
        title: 'Quest Tracker',
        icon: Icons.assignment_turned_in_rounded,
        routeName: ScrappyGridScreen.questRouteName,
        flag: FeatureAccessFlag.scrappyTracker,
      ),
      (
        title: 'Trade Hub',
        icon: Icons.storefront_rounded,
        routeName: TraderHubScreen.routeName,
        flag: FeatureAccessFlag.traderHub,
      ),
      (
        title: 'Match Raider',
        icon: Icons.groups_2_outlined,
        routeName: ArcMatchRiderScreen.routeName,
        flag: FeatureAccessFlag.matchRaider,
      ),
      (
        title: 'Play Like a Pro',
        icon: Icons.psychology_outlined,
        routeName: PlayLikeAProScreen.routeName,
        flag: FeatureAccessFlag.playLockerPro,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'ARC Raiders Hub',
        subtitle: 'Tracking, intel, trading, teaming and performance tools.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = (width / 150).floor().clamp(2, 5);
                        final childAspectRatio = width >= 820
                            ? 1.35
                            : width >= 560
                                ? 1.18
                                : 1.05;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildBanner(),
                            const SizedBox(height: 16),
                            Text(
                              'ARC Raiders Hub',
                              textAlign: TextAlign.center,
                              style: AppTheme.neonTextStyle(
                                fontSize: 27,
                                color: AppTheme.neonCyan,
                                isBold: true,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            Text(
                              'Open the exact workflow you need: blueprint tracking, resource tracking, bench upgrades, quests, planning, trading or performance.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 18),
                            GridView.builder(
                              itemCount: tiles.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final tile = tiles[index];
                                return _buildHubCard(
                                  title: tile.title,
                                  icon: tile.icon,
                                  onTap: () async {
                                    if (tile.flag != null) {
                                      final hasAccess =
                                          await FeatureAccess.hasAccess(tile.flag!);
                                      if (!context.mounted) return;
                                      if (!hasAccess) {
                                        await FeatureAccess.showLockedDialog(
                                          context,
                                          title: tile.title,
                                        );
                                        return;
                                      }
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pushNamed(context, tile.routeName);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceL),
                            _buildTrackerStructureCard(context),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
