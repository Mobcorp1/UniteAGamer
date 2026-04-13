import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
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
          width: 1.0,
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

  Widget _buildInfoCard() {
    return const CollapsibleSectionCard(
      title: 'Blueprint Intel',
      initiallyExpanded: false,
      child: Text(
        'Use the blueprint grid to log ownership, duplicates, wanted items, trade-ready stock, and where blueprints were found. This will later power community drop data and smarter trading.',
        style: TextStyle(color: Colors.white70, height: 1.35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <({String title, IconData icon, String routeName})>[
      (title: 'Market Intel', icon: Icons.insights_rounded, routeName: ArcMarketIntelligenceScreen.routeName),
      (title: 'Blueprint Grid', icon: Icons.grid_view_rounded, routeName: BlueprintGridScreen.routeName),
      (title: 'Scrappy Tracker', icon: Icons.widgets_rounded, routeName: ScrappyGridScreen.routeName),
      (title: 'Browse Listings', icon: Icons.view_list_rounded, routeName: TradingListingsScreen.routeName),
      (title: 'Create Listing', icon: Icons.add_circle_outline, routeName: TradingCreateListingScreen.routeName),
      (title: 'My Listings', icon: Icons.inventory_2_outlined, routeName: TradingMyListingsScreen.routeName),
      (title: 'My Offers', icon: Icons.local_offer_outlined, routeName: TradingMyOffersScreen.routeName),
      (title: 'Notifications', icon: Icons.notifications_active_outlined, routeName: TradingNotificationsScreen.routeName),
      (title: 'Trade Sessions', icon: Icons.handshake_outlined, routeName: TradingTradeSessionsScreen.routeName),
      (title: 'Trader Profile', icon: Icons.person_outline, routeName: TradingProfileScreen.routeName),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'ARC Raiders Hub',
          style: AppTheme.neonTextStyle(
            fontSize: 25,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
        centerTitle: false,
      ),
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
                        final crossAxisCount = (width / 180).floor().clamp(2, 4);
                        final childAspectRatio = width >= 760 ? 2.35 : width >= 520 ? 1.9 : 1.5;

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
                              'Blueprint tracking, drop intel, trading, offers, sessions and trader profile tools.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              itemCount: tiles.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                  onTap: () => Navigator.pushNamed(context, tile.routeName),
                                );
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceL),
                            _buildInfoCard(),
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
