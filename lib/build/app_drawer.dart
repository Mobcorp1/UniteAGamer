import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/home_screen.dart';
import 'package:uag_traders_hub/features/feature_access_gate.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_traders_hub/screens/build/feedback_screen.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/widgets/uag_drawer_nav_tile.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, this.drawerWidth = 320});

  final double drawerWidth;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: AppTheme.neonCyan,
      end: AppTheme.neonPink,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  Widget _buildDrawerHeader(Color dynamicColor) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 8),
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: dynamicColor.withValues(alpha: 0.65),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icon/uag_traders_icon_transparent.webp',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  AppTheme.animatedText(
                    'UAG Traders Hub',
                    AppTheme.heroTextStyle(
                      fontSize: 23,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DrawerItem> _buildItems(bool isLoggedIn) {
    return <_DrawerItem>[
      const _DrawerItem(
        title: 'Home',
        icon: Icons.home_outlined,
        routeName: HomeScreen.routeName,
      ),
      const _DrawerItem(
        title: 'Intel Snapshot',
        icon: Icons.insights_rounded,
        routeName: ArcMarketIntelligenceScreen.routeName,
      ),
      const _DrawerItem(
        title: 'Blueprint Grid',
        icon: Icons.grid_view_rounded,
        routeName: BlueprintGridScreen.routeName,
      ),
      const _DrawerItem(
        title: 'Raid Planner',
        icon: Icons.route_rounded,
        routeName: RaidPlannerScreen.routeName,
      ),
      const _DrawerItem(
        title: 'Scrappy Tracker',
        icon: Icons.widgets_rounded,
        routeName: ScrappyGridScreen.routeName,
        flag: FeatureAccessFlag.scrappyTracker,
      ),
      const _DrawerItem(
        title: 'Trade Hub',
        icon: Icons.storefront_rounded,
        routeName: TraderHubScreen.routeName,
        flag: FeatureAccessFlag.traderHub,
      ),
      const _DrawerItem(
        title: 'Match Raider',
        icon: Icons.groups_2_outlined,
        routeName: ArcMatchRiderScreen.routeName,
        flag: FeatureAccessFlag.matchRaider,
        comingSoonWhenLocked: true,
      ),
      const _DrawerItem(
        title: 'Play Like a Pro',
        icon: Icons.psychology_outlined,
        routeName: PlayLikeAProScreen.routeName,
        flag: FeatureAccessFlag.playLockerPro,
        comingSoonWhenLocked: true,
      ),
      const _DrawerItem(
        title: 'Trader Profile',
        icon: Icons.person_pin_circle_outlined,
        routeName: TradingProfileScreen.routeName,
        flag: FeatureAccessFlag.traderHub,
      ),
      const _DrawerItem(
        title: 'Admin Console',
        icon: Icons.admin_panel_settings_outlined,
        routeName: AdminConsoleScreen.routeName,
      ),
      if (isLoggedIn)
        const _DrawerItem(
          title: 'Beta Feedback',
          icon: Icons.rate_review_outlined,
          routeName: FeedbackScreen.routeName,
        ),
    ];
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

  Future<void> _openItem(BuildContext context, _DrawerItem item) async {
    final navigator = Navigator.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (item.routeName == currentRoute) {
      navigator.pop();
      return;
    }

    if (item.flag != null) {
      final hasAccess = await FeatureAccess.hasAccess(item.flag!);
      if (!context.mounted) return;

      if (!hasAccess) {
        navigator.pop();
        if (item.comingSoonWhenLocked) {
          await _showComingSoon(context, item.title);
        } else {
          await FeatureAccess.showLockedDialog(context, title: item.title);
        }
        return;
      }
    }

    navigator.pop();
    navigator.pushNamedAndRemoveUntil(item.routeName, (route) => route.isFirst);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.neonPink,
            side: const BorderSide(color: AppTheme.neonPink),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _colorAnimation.value ?? Colors.white;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final items = _buildItems(isLoggedIn);
    final media = MediaQuery.of(context);
    final drawerWidth = widget.drawerWidth.clamp(280.0, media.size.width * 0.92);

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            left: false,
            right: false,
            top: false,
            bottom: false,
            child: Container(
              width: drawerWidth,
              decoration: BoxDecoration(
                border: Border.all(color: dynamicColor, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: dynamicColor.withValues(alpha: 0.7),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Drawer(
                child: Column(
                  children: [
                    _buildDrawerHeader(dynamicColor),
                    Divider(
                      color: dynamicColor.withValues(alpha: 0.7),
                      thickness: 1.5,
                      height: 1,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom: isLoggedIn
                              ? 8
                              : media.padding.bottom + AppTheme.spaceL,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (context, index) {
                          final item = items[index];
                          final next = index + 1 < items.length
                              ? items[index + 1]
                              : null;

                          if (item.title == 'Home' ||
                              item.title == 'Trader Profile' ||
                              next?.title == 'Admin Console') {
                            return Divider(
                              color: AppTheme.tradingDivider,
                              height: 1,
                            );
                          }

                          return const SizedBox.shrink();
                        },
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return UagDrawerNavTile(
                            title: item.title,
                            icon: item.icon,
                            selected: currentRoute == item.routeName,
                            onTap: () => _openItem(context, item),
                          );
                        },
                      ),
                    ),
                    if (isLoggedIn)
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 12),
                        child: _buildLogoutButton(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.routeName,
    this.flag,
    this.comingSoonWhenLocked = false,
  });

  final String title;
  final IconData icon;
  final String routeName;
  final String? flag;
  final bool comingSoonWhenLocked;
}
