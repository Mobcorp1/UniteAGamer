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
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRaidersHubScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders';

  const ArcRaidersHubScreen({super.key});

  Widget _buildBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 520;

        final aspectRatio = width >= 760
            ? 16 / 4.8
            : isCompact
            ? 16 / 7.4
            : 16 / 6;

        final maxHeight = width >= 760
            ? 190.0
            : isCompact
            ? 118.0
            : 150.0;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
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
              aspectRatio: aspectRatio,
              child: Image.asset(
                'assets/arc_raiders/banners/arc_raiders_hub_banner.webp',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        );
      },
    );
  }

  String _stackedTitle(String title) {
    final words = title.trim().split(RegExp(r'\s+'));

    if (words.length < 2) {
      return title;
    }

    return '${words.first}\n${words.sublist(1).join(' ')}';
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElectricChargeBorder(
      active: true,
      radius: 14,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
            decoration: AppTheme.tradingCardDecoration(radius: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.neonCyan, size: 22),
                const SizedBox(height: 7),
                Text(
                  _stackedTitle(title),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.neonTextStyle(
                    fontSize: 14,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 10,
                      color: AppTheme.tradingMutedText,
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
    await showDialog(
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
    final tiles =
        <
          ({
            String title,
            String subtitle,
            IconData icon,
            String routeName,
            String? flag,
            bool comingSoonWhenLocked,
          })
        >[
          (
            title: 'Intel Snapshot',
            subtitle: 'Community drop signals and best current chances.',
            icon: Icons.insights_rounded,
            routeName: ArcMarketIntelligenceScreen.routeName,
            flag: null,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Blueprint Grid',
            subtitle: 'Track owned, missing, dupes and wanted blueprints.',
            icon: Icons.grid_view_rounded,
            routeName: BlueprintGridScreen.routeName,
            flag: null,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Raid Planner',
            subtitle: 'Plan raids around missing targets and seeded rules.',
            icon: Icons.route_rounded,
            routeName: RaidPlannerScreen.routeName,
            flag: null,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Scrappy Tracker',
            subtitle: 'Scrappy, bench and quest materials.',
            icon: Icons.widgets_rounded,
            routeName: ScrappyGridScreen.routeName,
            flag: FeatureAccessFlag.scrappyTracker,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Trader Hub',
            subtitle: 'Listings, offers, resources, giveaways and sessions.',
            icon: Icons.storefront_rounded,
            routeName: TraderHubScreen.routeName,
            flag: FeatureAccessFlag.traderHub,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Session Planner',
            subtitle: 'Schedule raids, trades and matchmaking sessions.',
            icon: Icons.calendar_month_rounded,
            routeName: SessionPlannerScreen.routeName,
            flag: FeatureAccessFlag.traderHub,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Voice Assistant',
            subtitle: 'Ask UAG Raider about items, quests and resources.',
            icon: Icons.mic_rounded,
            routeName: '',
            flag: null,
            comingSoonWhenLocked: false,
          ),
          (
            title: 'Match Raider',
            subtitle: 'Find players by vibe, platform and play window.',
            icon: Icons.groups_2_outlined,
            routeName: ArcMatchRiderScreen.routeName,
            flag: FeatureAccessFlag.matchRaider,
            comingSoonWhenLocked: true,
          ),
          (
            title: 'Play Like a Pro',
            subtitle: 'Pre-game, tilt reset and performance routines.',
            icon: Icons.psychology_outlined,
            routeName: PlayLikeAProScreen.routeName,
            flag: FeatureAccessFlag.playLockerPro,
            comingSoonWhenLocked: true,
          ),
          (
            title: 'Trader Profile',
            subtitle: 'Availability, identity and trading preferences.',
            icon: Icons.person_pin_circle_outlined,
            routeName: TradingProfileScreen.routeName,
            flag: FeatureAccessFlag.traderHub,
            comingSoonWhenLocked: false,
          ),
        ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'UAG Arc Raiders Hub',
        subtitle: 'Track, plan, trade, team up and improve your raids.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final viewportWidth = viewport.maxWidth;

                  final horizontalPadding = viewportWidth < 430
                      ? AppTheme.spaceM
                      : AppTheme.spaceL;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;

                          final crossAxisCount = width >= 900
                              ? 5
                              : width >= 620
                              ? 4
                              : 2;

                          final childAspectRatio = width >= 900
                              ? 1.62
                              : width >= 620
                              ? 1.42
                              : 1.2;

                          final gridSpacing = width < 430
                              ? 9.0
                              : AppTheme.spaceS;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildBanner(context),
                              const SizedBox(height: AppTheme.spaceM),
                              Text(
                                'UAG Arc Raiders Hub',
                                textAlign: TextAlign.center,
                                style: AppTheme.neonTextStyle(
                                  fontSize: width < 430 ? 22 : 26,
                                  color: AppTheme.neonCyan,
                                  isBold: true,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Blueprint tracking, intel, raid planning, trading, teammate matching and performance tools.',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyTextStyle(
                                  fontSize: width < 430 ? 12 : 13,
                                  color: AppTheme.tradingMutedText,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              GridView.builder(
                                itemCount: tiles.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: gridSpacing,
                                      crossAxisSpacing: gridSpacing,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                itemBuilder: (context, index) {
                                  final tile = tiles[index];

                                  return _buildHubCard(
                                    title: tile.title,
                                    subtitle: tile.subtitle,
                                    icon: tile.icon,
                                    onTap: () async {
                                      if (tile.title == 'Voice Assistant') {
                                        UagVoiceAssistantSheet.show(context);
                                        return;
                                      }

                                      if (tile.flag != null) {
                                        final hasAccess =
                                            await FeatureAccess.hasAccess(
                                              tile.flag!,
                                            );

                                        if (!context.mounted) {
                                          return;
                                        }

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

                                      if (!context.mounted) {
                                        return;
                                      }

                                      Navigator.pushNamed(
                                        context,
                                        tile.routeName,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
