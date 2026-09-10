import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingActivityScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/activity';

  const TradingActivityScreen({
    super.key,
    this.showAppBar = true,
    this.initialTabIndex = 0,
  });

  final bool showAppBar;
  final int initialTabIndex;

  @override
  State<TradingActivityScreen> createState() => _TradingActivityScreenState();
}

class _TradingActivityScreenState extends State<TradingActivityScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant TradingActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTabIndex.clamp(0, 3);
    if (nextIndex != _selectedIndex) {
      setState(() => _selectedIndex = nextIndex);
    }
  }

  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppTheme.tradingCardDecoration(
          radius: 16,
          borderColor: selected
              ? AppTheme.neonPink
              : AppTheme.tradingSoftBorder,
          backgroundColor: AppTheme.cardBackground,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppTheme.neonPink : AppTheme.neonCyan,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );

    return ElectricChargeBorder(active: selected, radius: 16, child: content);
  }

  @override
  Widget build(BuildContext context) {
    final views = <Widget>[
      const TradingMyListingsScreen(showAppBar: false),
      const TradingMyOffersScreen(showAppBar: false),
      const TradingBlueprintWatchesScreen(showAppBar: false),
      const TradingListingQueuesScreen(showAppBar: false),
    ];

    final content = ArcRaidersScreenShell(
      showAdBanner: false,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppTheme.pagePadding.copyWith(bottom: AppTheme.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ArcRaidersPageHeader(
                    title: 'TRADING ACTIVITY',
                    subtitle: 'Listings, offers, watches and queue releases.',
                    icon: Icons.swap_horiz_rounded,
                    accent: ArcUiTokens.secondaryAccent,
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      ArcTacticalStatusPill(
                        label: 'Live flow',
                        icon: Icons.bolt_rounded,
                        accent: ArcUiTokens.secondaryAccent,
                      ),
                      ArcTacticalStatusPill(
                        label: 'Trade safety',
                        icon: Icons.verified_user_outlined,
                        accent: ArcUiTokens.success,
                      ),
                      ArcTacticalStatusPill(
                        label: 'Blueprint demand',
                        icon: Icons.add_alert_outlined,
                        accent: ArcUiTokens.primaryAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _toggleButton(
                          label: 'Listings',
                          icon: Icons.inventory_2_outlined,
                          selected: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        const SizedBox(width: 10),
                        _toggleButton(
                          label: 'Offers',
                          icon: Icons.local_offer_outlined,
                          selected: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                        const SizedBox(width: 10),
                        _toggleButton(
                          label: 'Watches',
                          icon: Icons.add_alert_outlined,
                          selected: _selectedIndex == 2,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        const SizedBox(width: 10),
                        _toggleButton(
                          label: 'Queues',
                          icon: Icons.dynamic_feed_outlined,
                          selected: _selectedIndex == 3,
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: views),
            ),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: content,
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Activity', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: content,
    );
  }
}
