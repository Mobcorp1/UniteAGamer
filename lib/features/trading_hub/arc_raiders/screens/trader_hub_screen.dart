import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TraderHubScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/trader-hub';

  const TraderHubScreen({super.key, this.initialIndex = 0, this.initialActivityTab = 0});

  final int initialIndex;
  final int initialActivityTab;

  @override
  State<TraderHubScreen> createState() => _TraderHubScreenState();
}

class _TraderHubScreenState extends State<TraderHubScreen> {
  late int _currentIndex;

  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  static const List<String> _titles = <String>[
    'Trader Hub',
    'Create Listing',
    'Trading Activity',
    'Trade Sessions',
    'Alerts',
    'Trader Profile',
  ];

  static const List<String> _subtitles = <String>[
    'Market, profile, filters and live listings in one place.',
    'Build a trade listing without leaving the trading shell.',
    'Track your listings and offers without bouncing between screens.',
    'Confirm sessions, booking slots and readiness from one tab.',
    'Offer, session and collection updates land here.',
    'Identity, visibility, availability and referral tools.',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _titles.length - 1);
    _navigatorKeys = List.generate(_titles.length, (_) => GlobalKey<NavigatorState>());
  }

  @override
  void didUpdateWidget(covariant TraderHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = widget.initialIndex.clamp(0, _titles.length - 1);
    if (targetIndex != _currentIndex) {
      setState(() => _currentIndex = targetIndex);
    }
  }

  Widget _rootForIndex(int index) {
    switch (index) {
      case 0:
        return const TradingListingsScreen(showAppBar: false, embedProfileSummary: true);
      case 1:
        return const TradingCreateListingScreen(showAppBar: false);
      case 2:
        return TradingActivityScreen(showAppBar: false, initialTabIndex: widget.initialActivityTab);
      case 3:
        return const TradingTradeSessionsScreen(showAppBar: false);
      case 4:
        return const TradingNotificationsScreen(showAppBar: false);
      case 5:
        return const TradingProfileScreen(showAppBar: false);
      default:
        return const TradingListingsScreen(showAppBar: false, embedProfileSummary: true);
    }
  }

  void _onTap(int index) {
    if (index == _currentIndex) {
      final navigator = _navigatorKeys[index].currentState;
      navigator?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }

  BottomNavigationBarItem _item({
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final iconWidget = badgeCount <= 0
        ? Icon(icon)
        : Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon),
              Positioned(
                right: -8,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.neonPink,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.darkBackground, width: 1.4),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.darkBackground,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          );
    return BottomNavigationBarItem(icon: iconWidget, label: label);
  }

  Widget _tabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _rootForIndex(index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = TradingRepository();

    return StreamBuilder<List<TradingNotification>>(
      stream: repository.watchNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <TradingNotification>[];
        final unreadCount = notifications.where((item) => !item.read).length;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            final navigator = _navigatorKeys[_currentIndex].currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
              return;
            }

            Navigator.maybeOf(context)?.pop();
          },
          child: Scaffold(
            backgroundColor: AppTheme.darkBackground,
            appBar: UagAppBar(
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  final navigator = _navigatorKeys[_currentIndex].currentState;
                  if (navigator != null && navigator.canPop()) {
                    navigator.pop();
                    return;
                  }
                  Navigator.maybeOf(context)?.pop();
                },
              ),
              title: _titles[_currentIndex],
              subtitle: _subtitles[_currentIndex],
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: IndexedStack(
              index: _currentIndex,
              children: List.generate(
                _titles.length,
                (index) => Offstage(
                  offstage: _currentIndex != index,
                  child: _tabNavigator(index),
                ),
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: _onTap,
              backgroundColor: AppTheme.cardBackgroundDeep,
              selectedItemColor: AppTheme.neonPink,
              unselectedItemColor: AppTheme.tradingFaintText,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              items: [
                _item(icon: Icons.storefront_rounded, label: 'Market'),
                _item(icon: Icons.add_circle_outline, label: 'Create'),
                _item(icon: Icons.swap_horiz_rounded, label: 'Activity'),
                _item(icon: Icons.handshake_outlined, label: 'Sessions'),
                _item(icon: Icons.notifications_active_outlined, label: 'Alerts', badgeCount: unreadCount),
                _item(icon: Icons.person_outline_rounded, label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}
