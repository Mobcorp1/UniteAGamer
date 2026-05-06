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
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
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

  Widget _buildHubCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElectricChargeBorder(
      active: true,
      radius: 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(radius: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.neonCyan, size: 30),
                const SizedBox(height: AppTheme.spaceM),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: AppTheme.neonTextStyle(
                          fontSize: 18,
                          color: AppTheme.neonCyan,
                          isBold: true,
                        ),
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

  Future<void> _showComingSoon(BuildContext context, String title) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          shape: AppTheme.tradingDialogShape(),
          title: Text(
            '$title — Coming Soon',
            style: AppTheme.tradingHeading(fontSize: 22, color: Colors.white),
          ),
          content: Text(
            'This feature is not available in the current beta build yet.',
            style: AppTheme.bodyTextStyle(
              fontSize: 14,
              color: AppTheme.tradingMutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'OK',
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: AppTheme.neonCyan,
                  isBold: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <({
      String title,
      IconData icon,
      String routeName,
      String? flag,
      bool comingSoonWhenLocked,
    })>[
      (
        title: 'Intel Snapshot',
        icon: Icons.insights_rounded,
        routeName: ArcMarketIntelligenceScreen.routeName,
        flag: null,
        comingSoonWhenLocked: false,
      ),
      (
        title: 'Blueprint Grid',
        icon: Icons.grid_view_rounded,
        routeName: BlueprintGridScreen.routeName,
        flag: null,
        comingSoonWhenLocked: false,
      ),
      (
        title: 'Raid Planner',
        icon: Icons.route_rounded,
        routeName: RaidPlannerScreen.routeName,
        flag: null,
        comingSoonWhenLocked: false,
      ),
      (
        title: 'Scrappy Tracker',
        icon: Icons.widgets_rounded,
        routeName: ScrappyGridScreen.routeName,
        flag: FeatureAccessFlag.scrappyTracker,
        comingSoonWhenLocked: false,
      ),
      (
        title: 'Trader Hub',
        icon: Icons.storefront_rounded,
        routeName: TraderHubScreen.routeName,
        flag: FeatureAccessFlag.traderHub,
        comingSoonWhenLocked: false,
      ),
      (
        title: 'Match-a-Raider',
        icon: Icons.groups_2_outlined,
        routeName: ArcMatchRiderScreen.routeName,
        flag: FeatureAccessFlag.matchRaider,
        comingSoonWhenLocked: true,
      ),
      (
        title: 'PlayLocker Pro',
        icon: Icons.psychology_outlined,
        routeName: PlayLikeAProScreen.routeName,
        flag: FeatureAccessFlag.playLockerPro,
        comingSoonWhenLocked: true,
      ),
      (
        title: 'Trader Profile',
        icon: Icons.person_pin_circle_outlined,
        routeName: TradingProfileScreen.routeName,
        flag: FeatureAccessFlag.traderHub,
        comingSoonWhenLocked: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'ARC Raiders Hub',
        subtitle:
            'High-level tools for tracking, intel, trading, teaming and performance.',
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
                  constraints: const BoxConstraints(maxWidth: 940),
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = (width / 180).floor().clamp(
                          2,
                          4,
                        );
                        final childAspectRatio = width >= 760
                            ? 2.35
                            : width >= 520
                            ? 1.9
                            : 1.5;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildBanner(),
                            const SizedBox(height: 18),
                            Text(
                              'ARC Raiders Hub',
                              textAlign: TextAlign.center,
                              style: AppTheme.neonTextStyle(
                                fontSize: 28,
                                color: AppTheme.neonCyan,
                                isBold: true,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            Text(
                              'Blueprint tracking, personalised intel, trader flow, teammate matching and performance tools.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              itemCount: tiles.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
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
                                          await FeatureAccess.hasAccess(
                                            tile.flag!,
                                          );
                                      if (!context.mounted) return;
                                      if (!hasAccess) {
                                        if (tile.comingSoonWhenLocked) {
                                          await _showComingSoon(
                                            context,
                                            tile.title,
                                          );
                                        } else {
                                          await FeatureAccess.showLockedDialog(
                                            context,
                                            title: tile.title,
                                          );
                                        }
                                        return;
                                      }
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pushNamed(
                                      context,
                                      tile.routeName,
                                    );
                                  },
                                );
                              },
                            ),
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
