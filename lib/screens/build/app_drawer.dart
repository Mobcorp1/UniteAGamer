import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/home_screen.dart';
import 'package:uag_traders_hub/build/trading_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
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
                    'UAG Traders Hub',
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

  List<_DrawerItem> _buildItems(bool isLoggedIn) {
    return <_DrawerItem>[
      _DrawerItem('Home', Icons.home_outlined, HomeScreen.routeName),
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
      ),
      if (isLoggedIn)
        _DrawerItem(
          'Beta Feedback',
          Icons.rate_review_outlined,
          FeedbackScreen.routeName,
        ),
    ];
  }

  void _openRoute(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    navigator.pop();
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == routeName) return;
    navigator.pushNamedAndRemoveUntil(routeName, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _colorAnimation.value ?? Colors.white;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final items = _buildItems(isLoggedIn);

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
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return UagDrawerNavTile(
                          title: item.title,
                          icon: item.icon,
                          selected: currentRoute == item.routeName,
                          onTap: () => _openRoute(context, item.routeName),
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
  const _DrawerItem(this.title, this.icon, this.routeName);

  final String title;
  final IconData icon;
  final String routeName;
}
