import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/feature_access_gate.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/app_entry_gate.dart';
import 'package:uag_traders_hub/build/trading_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_traders_hub/screens/build/feedback_screen.dart';
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
                    'UAG Raiders Hub',
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

  List<_DrawerItem> _buildItems(bool isLoggedIn, bool adminMode) {
    return <_DrawerItem>[
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
      _DrawerItem(
        'Trader Hub',
        Icons.storefront_rounded,
        TraderHubScreen.routeName,
        accessFlag: FeatureAccessFlag.traderHub,
      ),
      if (isLoggedIn)
        _DrawerItem(
          'Trader Profile',
          Icons.person_outline_rounded,
          TradingProfileScreen.routeName,
          accessFlag: FeatureAccessFlag.traderHub,
        ),
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

  Future<void> _openRoute(
    BuildContext context,
    String routeName, {
    String? accessFlag,
    String? title,
  }) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    if (accessFlag != null) {
      final hasAccess = await FeatureAccess.hasAccess(accessFlag);
      if (!context.mounted) return;
      if (!hasAccess) {
        await FeatureAccess.showLockedDialog(
          context,
          title: title ?? 'Coming Soon',
        );
        return;
      }
    }

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
                    child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: user == null
                          ? null
                          : FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                      builder: (context, snapshot) {
                        final userData = snapshot.data?.data() ?? <String, dynamic>{};
                        final adminMode = userData['isAdmin'] == true || userData['isDev'] == true;
                        final items = _buildItems(isLoggedIn, adminMode);

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return UagDrawerNavTile(
                              title: item.title,
                              icon: item.icon,
                              selected: currentRoute == item.routeName,
                              onTap: () => _openRoute(
                                context,
                                item.routeName,
                                accessFlag: item.accessFlag,
                                title: item.title,
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

class _DrawerItem {
  const _DrawerItem(this.title, this.icon, this.routeName, {this.accessFlag});

  final String title;
  final IconData icon;
  final String routeName;
  final String? accessFlag;
}
