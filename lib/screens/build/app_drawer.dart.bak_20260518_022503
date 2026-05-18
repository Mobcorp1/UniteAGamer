import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_entry_gate.dart';
import 'package:uag_traders_hub/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/trading_hub_screen.dart';
import 'package:uag_traders_hub/features/feature_access_gate.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
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
  const AppDrawer({super.key, this.drawerWidth = 300});

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
    final nav = Navigator.of(context);
    nav.pop();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    nav.pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  Widget _buildDrawerHeader(Color dynamicColor) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedTextKit(
                animatedTexts: [
                  AppTheme.animatedText(
                    'UAG Arc Raiders Hub',
                    AppTheme.heroTextStyle(
                      fontSize: 24,
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

  List<_DrawerEntry> _buildItems(bool isLoggedIn, bool adminMode) {
    return <_DrawerEntry>[
      _DrawerItem('Home', Icons.home_outlined, AppEntryGate.routeName),
      _DrawerItem(
        'Trading Hub',
        Icons.hub_outlined,
        TradingHubScreen.routeName,
      ),
      _DrawerItem(
        'ARC Raiders Hub',
        Icons.rocket_launch_outlined,
        ArcRaidersHubScreen.routeName,
      ),
      const _DrawerSection('ARC Raiders Tools'),
      _DrawerItem(
        'Intel Snapshot',
        Icons.insights_rounded,
        ArcMarketIntelligenceScreen.routeName,
      ),
      _DrawerItem(
        'Blueprint Grid',
        Icons.grid_view_rounded,
        BlueprintGridScreen.routeName,
      ),
      _DrawerItem(
        'Raid Planner',
        Icons.route_rounded,
        RaidPlannerScreen.routeName,
      ),
      _DrawerItem(
        'Scrappy Tracker',
        Icons.widgets_rounded,
        ScrappyGridScreen.routeName,
        accessFlag: FeatureAccessFlag.scrappyTracker,
      ),
      _DrawerItem(
        'Trader Hub',
        Icons.storefront_rounded,
        TraderHubScreen.routeName,
        accessFlag: FeatureAccessFlag.traderHub,
      ),
      _DrawerItem(
        'Match-a-Raider',
        Icons.groups_2_outlined,
        ArcMatchRiderScreen.routeName,
        accessFlag: FeatureAccessFlag.matchRaider,
        showComingSoonWhenLocked: true,
      ),
      _DrawerItem(
        'Play Like A Pro',
        Icons.psychology_outlined,
        PlayLikeAProScreen.routeName,
        accessFlag: FeatureAccessFlag.playLockerPro,
        showComingSoonWhenLocked: true,
      ),
      if (isLoggedIn)
        _DrawerItem(
          'Trader Profile',
          Icons.person_pin_circle_outlined,
          TradingProfileScreen.routeName,
          accessFlag: FeatureAccessFlag.traderHub,
        ),
      const _DrawerSection('Account + Support'),
      if (adminMode)
        _DrawerItem(
          'Admin Console',
          Icons.admin_panel_settings_outlined,
          AdminConsoleScreen.routeName,
        ),
      if (isLoggedIn)
        _DrawerItem(
          'Beta Feedback',
          Icons.rate_review_outlined,
          FeedbackScreen.routeName,
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

  Future<void> _openRoute(
    BuildContext context,
    String routeName, {
    String? accessFlag,
    String? title,
    bool showComingSoonWhenLocked = false,
  }) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    if (accessFlag != null) {
      final hasAccess = await FeatureAccess.hasAccess(accessFlag);
      if (!context.mounted) return;
      if (!hasAccess) {
        if (showComingSoonWhenLocked) {
          await _showComingSoon(context, title ?? 'Coming Soon');
        } else {
          await FeatureAccess.showLockedDialog(
            context,
            title: title ?? 'Coming Soon',
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == routeName) return;
    navigator.pushNamedAndRemoveUntil(routeName, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _colorAnimation.value ?? Colors.white;
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: widget.drawerWidth,
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
                  ),
                  Expanded(
                    child:
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: user == null
                              ? null
                              : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .get(),
                          builder: (context, snapshot) {
                            final userData = snapshot.data?.data() ?? {};
                            final adminMode =
                                userData['isAdmin'] == true ||
                                userData['isDev'] == true;
                            final items = _buildItems(isLoggedIn, adminMode);

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final entry = items[index];
                                if (entry is _DrawerSection) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      14,
                                      18,
                                      6,
                                    ),
                                    child: Text(
                                      entry.title,
                                      style: AppTheme.bodyTextStyle(
                                        fontSize: 12,
                                        color: AppTheme.tradingFaintText,
                                        isBold: true,
                                      ),
                                    ),
                                  );
                                }

                                final item = entry as _DrawerItem;
                                return UagDrawerNavTile(
                                  title: item.title,
                                  icon: item.icon,
                                  selected: currentRoute == item.routeName,
                                  onTap: () => _openRoute(
                                    context,
                                    item.routeName,
                                    accessFlag: item.accessFlag,
                                    title: item.title,
                                    showComingSoonWhenLocked:
                                        item.showComingSoonWhenLocked,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  ),
                  if (isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.neonPink,
                            side: const BorderSide(color: AppTheme.neonPink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

sealed class _DrawerEntry {
  const _DrawerEntry();
}

class _DrawerSection extends _DrawerEntry {
  const _DrawerSection(this.title);

  final String title;
}

class _DrawerItem extends _DrawerEntry {
  const _DrawerItem(
    this.title,
    this.icon,
    this.routeName, {
    this.accessFlag,
    this.showComingSoonWhenLocked = false,
  });

  final String title;
  final IconData icon;
  final String routeName;
  final String? accessFlag;
  final bool showComingSoonWhenLocked;
}
