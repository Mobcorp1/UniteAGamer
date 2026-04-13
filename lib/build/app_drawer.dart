import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/home_screen.dart';
import 'package:uag_traders_hub/build/trading_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';

class AppDrawer extends StatefulWidget {
  final double drawerWidth;

  const AppDrawer({super.key, this.drawerWidth = 300});

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

  int _a(double opacity) => (opacity.clamp(0.0, 1.0) * 255).round();

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    nav.pop();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    nav.pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _colorAnimation.value ?? Colors.white;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    final items = <_DrawerItem>[
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
        'Browse Listings',
        Icons.view_list_outlined,
        TradingListingsScreen.routeName,
      ),
      _DrawerItem(
        'Create Listing',
        Icons.add_circle_outline,
        TradingCreateListingScreen.routeName,
      ),
      if (isLoggedIn)
        _DrawerItem(
          'My Listings',
          Icons.inventory_2_outlined,
          TradingMyListingsScreen.routeName,
        ),
      if (isLoggedIn)
        _DrawerItem(
          'My Offers',
          Icons.local_offer_outlined,
          TradingMyOffersScreen.routeName,
        ),
      if (isLoggedIn)
        _DrawerItem(
          'Trade Sessions',
          Icons.event_available_outlined,
          TradingTradeSessionsScreen.routeName,
        ),
      if (isLoggedIn)
        _DrawerItem(
          'Trader Profile',
          Icons.verified_user_outlined,
          TradingProfileScreen.routeName,
        ),
    ];

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
                  color: dynamicColor.withAlpha(_a(0.70)),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Drawer(
              child: Column(
                children: [
                  SafeArea(
                    minimum: const EdgeInsets.only(top: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: dynamicColor.withAlpha(_a(0.65)),
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
                  ),
                  Divider(
                    color: dynamicColor.withAlpha(_a(0.70)),
                    thickness: 1.5,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = currentRoute == item.routeName;
                        return ListTile(
                          leading: Icon(
                            item.icon,
                            color: selected
                                ? AppTheme.neonPink
                                : AppTheme.neonCyan,
                          ),
                          title: Text(
                            item.title,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 15,
                              color: selected
                                  ? AppTheme.neonPink
                                  : Colors.white,
                              isBold: selected,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: selected
                                ? AppTheme.neonPink
                                : Colors.white54,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            if (currentRoute == item.routeName) return;
                            Navigator.of(context).pushNamed(item.routeName);
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
  final String title;
  final IconData icon;
  final String routeName;

  _DrawerItem(this.title, this.icon, this.routeName);
}
