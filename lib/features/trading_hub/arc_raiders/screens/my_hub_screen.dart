import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/my_intel_screen.dart';
import 'package:uag_traders_hub/features/monetisation/screens/monetisation_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/screens/build/app_drawer.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class MyHubScreen extends StatefulWidget {
  static const routeName = '/my-hub';

  const MyHubScreen({super.key});

  @override
  State<MyHubScreen> createState() => _MyHubScreenState();
}

class _MyHubScreenState extends State<MyHubScreen> {
  late final PageController _controller;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index > 7) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'My Hub',
        subtitle: 'Your personal command centre.',
      ),
      drawer: const AppDrawer(drawerWidth: 300),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MyHubBackdrop(),
          SafeArea(
            child: user == null
                ? const Center(
                    child: Text(
                      'Log in to view My Hub.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() ?? {};
                      return _MyHubCarousel(
                        controller: _controller,
                        activeIndex: _activeIndex,
                        onChanged: (index) =>
                            setState(() => _activeIndex = index),
                        onPrevious: () => _goTo(_activeIndex - 1),
                        onNext: () => _goTo(_activeIndex + 1),
                        userData: data,
                        email: user.email,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MyHubCarousel extends StatelessWidget {
  const _MyHubCarousel({
    required this.controller,
    required this.activeIndex,
    required this.onChanged,
    required this.onPrevious,
    required this.onNext,
    required this.userData,
    required this.email,
  });

  final PageController controller;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Map<String, dynamic> userData;
  final String? email;

  String _readString(List<String> keys, String fallback) {
    for (final key in keys) {
      final value = userData[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }

    final basicProfile = userData['basicProfile'];
    if (basicProfile is Map<String, dynamic>) {
      for (final key in keys) {
        final value = basicProfile[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }

    final traderProfile = userData['traderProfile'];
    if (traderProfile is Map<String, dynamic>) {
      for (final key in keys) {
        final value = traderProfile[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }

    return fallback;
  }

  int _readInt(String key, int fallback) {
    final value = userData[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  double _readDouble(String key, double fallback) {
    final value = userData[key];
    if (value is num) return value.toDouble();
    return fallback;
  }

  bool _readBool(String key, bool fallback) {
    final value = userData[key];
    if (value is bool) return value;
    if (value is String) {
      final normalised = value.trim().toLowerCase();
      if (normalised == 'true' || normalised == 'active') return true;
      if (normalised == 'false' || normalised == 'inactive') return false;
    }
    return fallback;
  }

  List<String> _readList(String key) {
    final value = userData[key];
    if (value is List) return value.whereType<String>().toList();
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _readString([
      'displayName',
      'uagName',
      'traderName',
    ], 'Raider');
    final tier = _readString(['subscriptionTier'], 'Raider');
    final referralCode = _readString(['referralCode'], 'SETUP-PENDING');
    final successfulTrades = _readInt('successfulTrades', 0);
    final verifiedIntel = _readInt('verifiedIntelReports', 0);
    final activeReferrals = _readInt('activeReferrals', 0);
    final commission = _readDouble(
      'referralCommissionRate',
      tier.toLowerCase() == 'overseer'
          ? 10
          : tier.toLowerCase() == 'operator'
          ? 5
          : 0,
    );
    final wantedLoadout = _readList('loadoutWantedBlueprints');
    final tradeWanted = _readList('tradeAssistWantedBlueprints');
    final subscriptionStatus = _readString([
      'subscriptionStatus',
      'subscriptionState',
    ], tier.toLowerCase() == 'raider' ? 'Free' : 'Active');
    final nextBillingDate = _readString(
      ['nextBillingDate', 'nextBillingCycle', 'billingCycle'],
      tier.toLowerCase() == 'raider' ? 'Upgrade anytime' : 'Next cycle pending',
    );
    final monthlyReferralTarget = _readInt('monthlyReferralTarget', 10);
    final referralProgress = monthlyReferralTarget == 0
        ? 0
        : ((activeReferrals / monthlyReferralTarget) * 100)
              .clamp(0, 100)
              .round();
    final commissionTier = commission >= 10
        ? 'Overseer'
        : commission >= 5
        ? 'Operator'
        : 'Raider';
    final premiumActive = _readBool(
      'premiumEntitlementActive',
      tier.toLowerCase() != 'raider',
    );

    final sections = <_HubSection>[
      _HubSection(
        title: 'Tracking',
        subtitle:
            'Blueprints, ownership, missing items and hunt targets live here now.',
        icon: Icons.grid_view_rounded,
        accent: AppTheme.neonCyan,
        image: 'assets/images/arc_raiders/hub/arc_hub_tracking.webp',
        body: [
          _HubMetric(label: 'Blueprint Grid', value: 'Open tracker'),
          _HubMetric(
            label: 'Loadout wanted',
            value: '${wantedLoadout.length} item(s)',
          ),
          _HubMetric(
            label: 'Trade hooks',
            value: '${tradeWanted.length} item(s)',
          ),
        ],
        primaryLabel: 'Open Tracking',
        onPrimary: () =>
            Navigator.of(context).pushNamed(BlueprintGridScreen.routeName),
        secondaryLabel: 'Favourite Loadout',
        onSecondary: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavouriteLoadoutScreen()),
        ),
      ),
      _HubSection(
        title: 'Favourite Loadout',
        subtitle:
            'Primary, secondary, fibre augment, quick-use tools and priority scoring.',
        icon: Icons.inventory_2_outlined,
        accent: AppTheme.neonPink,
        image: 'assets/images/arc_raiders/hub/arc_hub_hunt_targets.webp',
        body: [
          _HubMetric(label: 'Missing hooks', value: '${wantedLoadout.length}'),
          _HubMetric(label: 'Sync', value: 'Blueprint + Trade Assist'),
          _HubMetric(label: 'Mode', value: 'Wipe recovery'),
        ],
        primaryLabel: 'Edit Loadout',
        onPrimary: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavouriteLoadoutScreen()),
        ),
      ),
      _HubSection(
        title: 'My Intel',
        subtitle:
            'Review your latest reports, correct mistakes, or delete wrong submissions.',
        icon: Icons.article_outlined,
        accent: Colors.amberAccent,
        image: 'assets/images/arc_raiders/hub/arc_hub_community_intel.webp',
        body: [
          _HubMetric(label: 'Verified Intel', value: '$verifiedIntel'),
          _HubMetric(label: 'Latest Reports', value: 'Last 5'),
          _HubMetric(label: 'Actions', value: 'Edit / Delete'),
        ],
        primaryLabel: 'Open My Intel',
        onPrimary: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyIntelScreen())),
        secondaryLabel: 'Community Intel',
        onSecondary: () => Navigator.of(
          context,
        ).pushNamed(ArcMarketIntelligenceScreen.routeName),
      ),
      _HubSection(
        title: 'Trade Assist',
        subtitle:
            'Missing loadout items now feed smart wanted hooks for future matching.',
        icon: Icons.auto_awesome_rounded,
        accent: Colors.lightGreenAccent,
        image: 'assets/images/arc_raiders/hub/arc_hub_smart_trade.webp',
        body: [
          _HubMetric(label: 'Wanted items', value: '${tradeWanted.length}'),
          _HubMetric(label: 'Trade status', value: 'Hooks ready'),
          _HubMetric(label: 'Next layer', value: 'Dupe matching'),
        ],
        primaryLabel: 'Open Trader Hub',
        onPrimary: () =>
            Navigator.of(context).pushNamed(TraderHubScreen.routeName),
      ),
      _HubSection(
        title: 'Reputation',
        subtitle:
            'Your trust pulse across trades, intel and future matchmaking behaviour.',
        icon: Icons.verified_user_outlined,
        accent: Colors.lightGreenAccent,
        image: 'assets/images/arc_raiders/hub/arc_hub_unite_hub.webp',
        body: [
          _HubMetric(label: 'Successful Trades', value: '$successfulTrades'),
          _HubMetric(label: 'Verified Intel', value: '$verifiedIntel'),
          _HubMetric(label: 'Trust Layer', value: 'Building'),
        ],
        primaryLabel: 'Edit Profile',
        onPrimary: () =>
            Navigator.of(context).pushNamed(TradingProfileScreen.routeName),
      ),
      _HubSection(
        title: 'Referrals',
        subtitle:
            'Track your code, active referrals, subscription tier and progression path.',
        icon: Icons.hub_outlined,
        accent: AppTheme.neonPink,
        image: 'assets/images/arc_raiders/hub/arc_hub_market_watch.webp',
        body: [
          _HubMetric(label: 'Tier', value: tier),
          _HubMetric(label: 'Active Referrals', value: '$activeReferrals'),
          _HubMetric(
            label: 'Commission',
            value: '${commission.toStringAsFixed(0)}%',
          ),
          _HubMetric(label: 'Code', value: referralCode),
        ],
        primaryLabel: 'Open Profile',
        onPrimary: () =>
            Navigator.of(context).pushNamed(TradingProfileScreen.routeName),
      ),
      _HubSection(
        title: 'Subscriptions',
        subtitle:
            'Manage your access tier, billing cycle, referral earnings and premium unlock path.',
        icon: Icons.workspace_premium_outlined,
        accent: AppTheme.neonCyan,
        image: 'assets/images/arc_raiders/hub/arc_hub_market_watch.webp',
        body: [
          _HubMetric(label: 'Current tier', value: tier),
          _HubMetric(label: 'Status', value: subscriptionStatus),
          _HubMetric(label: 'Billing', value: nextBillingDate),
          _HubMetric(label: 'Commission tier', value: commissionTier),
          _HubMetric(label: 'Referral progress', value: '$referralProgress%'),
          _HubMetric(
            label: 'Premium boosts',
            value: premiumActive ? 'Unlocked' : 'Locked',
          ),
        ],
        primaryLabel: tier.toLowerCase() == 'raider'
            ? 'Upgrade Access'
            : 'Manage Subscription',
        onPrimary: () =>
            Navigator.of(context).pushNamed(MonetisationScreen.routeName),
        secondaryLabel: 'View Referral Profile',
        onSecondary: () =>
            Navigator.of(context).pushNamed(TradingProfileScreen.routeName),
      ),
      _HubSection(
        title: 'Monthly Operations',
        subtitle: 'A neon preview for the 28-day quests and reward engine.',
        icon: Icons.assignment_turned_in_outlined,
        accent: Colors.amberAccent,
        image: 'assets/images/arc_raiders/hub/arc_hub_quest_tracker.webp',
        body: [
          _HubMetric(label: 'Trade Operation', value: 'Coming soon'),
          _HubMetric(label: 'Intel Operation', value: 'Coming soon'),
          _HubMetric(label: 'Referral Operation', value: 'Coming soon'),
        ],
        primaryLabel: 'Match a Raider',
        onPrimary: () =>
            Navigator.of(context).pushNamed(ArcMatchRiderScreen.routeName),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final carouselHeight = compact ? 610.0 : 560.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 24,
            compact ? 12 : 22,
            compact ? 12 : 24,
            30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HubHero(
                    displayName: displayName,
                    tier: tier,
                    activeIndex: activeIndex,
                    total: sections.length,
                    onPrevious: activeIndex == 0 ? null : onPrevious,
                    onNext: activeIndex == sections.length - 1 ? null : onNext,
                  ),
                  const SizedBox(height: 14),
                  _HubTabStrip(
                    sections: sections,
                    activeIndex: activeIndex,
                    onTap: (index) {
                      controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: carouselHeight,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: sections.length,
                      onPageChanged: onChanged,
                      itemBuilder: (context, index) {
                        return AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          scale: activeIndex == index ? 1 : 0.95,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: _HubCarouselCard(section: sections[index]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuickActionRail(
                    onTracking: () => Navigator.of(
                      context,
                    ).pushNamed(BlueprintGridScreen.routeName),
                    onLoadout: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FavouriteLoadoutScreen(),
                      ),
                    ),
                    onIntel: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyIntelScreen()),
                    ),
                    onTrading: () => Navigator.of(
                      context,
                    ).pushNamed(TraderHubScreen.routeName),
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

class _HubHero extends StatelessWidget {
  const _HubHero({
    required this.displayName,
    required this.tier,
    required this.activeIndex,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final String displayName;
  final String tier;
  final int activeIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return ElectricChargeBorder(
      active: true,
      radius: 26,
      padding: const EdgeInsets.all(1.4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/icon/uag_traders_icon_transparent.webp',
              height: 64,
              errorBuilder: (_, _, _) => const Icon(
                Icons.dashboard_customize_outlined,
                color: AppTheme.neonCyan,
                size: 54,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $displayName',
                    style: AppTheme.tradingHeading(
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'My Hub is your personal tracking, intel, reputation, loadout and reward space.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$tier access • ${activeIndex + 1} / $total',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ArrowButton(
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 6),
            _ArrowButton(icon: Icons.chevron_right_rounded, onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

class _HubTabStrip extends StatelessWidget {
  const _HubTabStrip({
    required this.sections,
    required this.activeIndex,
    required this.onTap,
  });

  final List<_HubSection> sections;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = sections[index];
          final active = activeIndex == index;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? section.accent.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? section.accent.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    section.icon,
                    size: 17,
                    color: active ? section.accent : Colors.white54,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    section.title,
                    style: TextStyle(
                      color: active ? section.accent : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HubCarouselCard extends StatelessWidget {
  const _HubCarouselCard({required this.section});

  final _HubSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: section.accent.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: section.accent.withValues(alpha: 0.11),
            blurRadius: 28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            section.image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const StaticWatermark(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.58)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.58),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(section.icon, color: section.accent, size: 38),
                const SizedBox(height: 12),
                Text(
                  section.title,
                  textAlign: TextAlign.center,
                  style: AppTheme.tradingHeading(
                    fontSize: 31,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.32),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  alignment: WrapAlignment.center,
                  children: section.body
                      .map(
                        (metric) => _HubMetricPill(
                          label: metric.label,
                          value: metric.value,
                          accent: section.accent,
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: section.onPrimary,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(section.primaryLabel),
                ),
                if (section.secondaryLabel != null &&
                    section.onSecondary != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: section.onSecondary,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(section.secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRail extends StatelessWidget {
  const _QuickActionRail({
    required this.onTracking,
    required this.onLoadout,
    required this.onIntel,
    required this.onTrading,
  });

  final VoidCallback onTracking;
  final VoidCallback onLoadout;
  final VoidCallback onIntel;
  final VoidCallback onTrading;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _HubQuickButton(
          icon: Icons.grid_view_rounded,
          label: 'Tracking',
          onPressed: onTracking,
        ),
        _HubQuickButton(
          icon: Icons.inventory_2_outlined,
          label: 'Loadout',
          onPressed: onLoadout,
        ),
        _HubQuickButton(
          icon: Icons.article_outlined,
          label: 'My Intel',
          onPressed: onIntel,
        ),
        _HubQuickButton(
          icon: Icons.storefront_rounded,
          label: 'Trading',
          onPressed: onTrading,
        ),
      ],
    );
  }
}

class _HubQuickButton extends StatelessWidget {
  const _HubQuickButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.42)),
      ),
    );
  }
}

class _HubMetricPill extends StatelessWidget {
  const _HubMetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      color: onPressed == null ? Colors.white30 : AppTheme.neonCyan,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.34),
      ),
    );
  }
}

class _MyHubBackdrop extends StatelessWidget {
  const _MyHubBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const StaticWatermark(),
        ),
        Container(color: Colors.black.withValues(alpha: 0.62)),
        const StaticWatermark(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.82),
                AppTheme.darkBackground.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.94),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HubSection {
  const _HubSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.image,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String image;
  final List<_HubMetric> body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
}

class _HubMetric {
  const _HubMetric({required this.label, required this.value});

  final String label;
  final String value;
}
