import 'package:uag_traders_hub/features/monetisation/screens/admin_monetisation_dashboard.dart';
import 'package:uag_traders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRaidersHubScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders';

  const ArcRaidersHubScreen({super.key});

  @override
  State<ArcRaidersHubScreen> createState() => _ArcRaidersHubScreenState();
}

class _ArcRaidersHubScreenState extends State<ArcRaidersHubScreen> {
  final PageController _controller = PageController(viewportFraction: 0.72);
  int _selectedIndex = 0;

  late final List<_ArcHubFeature> _features = [
    _ArcHubFeature(
      title: 'Tracking',
      subtitle: 'Blueprint Grid, Scrappy, benches and quest tracking.',
      icon: Icons.grid_view_rounded,
      accent: AppTheme.neonCyan,
      builder: (_) => const _TrackingMenuScreen(),
    ),
    _ArcHubFeature(
      title: 'Raid Planner',
      subtitle: 'Plan around active hunts, events and blueprint targets.',
      icon: Icons.route_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const RaidPlannerScreen(),
    ),
    _ArcHubFeature(
      title: 'Hunt Targets',
      subtitle:
          'Edit your 5 active blueprint hunts used by Smart Trade Assist.',
      icon: Icons.track_changes_rounded,
      accent: AppTheme.neonCyan,
      builder: (_) => const RaidPlannerHuntTargetsScreen(),
    ),
    _ArcHubFeature(
      title: 'Trading',
      subtitle: 'Listings, offers, sessions and swap planning.',
      icon: Icons.swap_horiz_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const TraderHubScreen(),
    ),
    _ArcHubFeature(
      title: 'Smart Trade',
      subtitle: 'Turn duplicate blueprints into useful trade opportunities.',
      icon: Icons.auto_awesome_rounded,
      accent: AppTheme.neonCyan,
      builder: (_) => const SmartTradeAssistScreen(),
    ),
    _ArcHubFeature(
      title: 'Play Like a Pro',
      subtitle: 'Warm-ups, focus systems and performance routines.',
      icon: Icons.sports_esports_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const ProfileSettingsScreen(),
    ),
    _ArcHubFeature(
      title: 'ARC Assistant',
      subtitle: 'Open the voice assistant from the hub or centre mic.',
      icon: Icons.mic_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const _ArcArcAssistantLauncherScreen(),
    ),
    _ArcHubFeature(
      title: 'Feedback',
      subtitle: 'Review beta feedback and support tools.',
      icon: Icons.feedback_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const AdminMonetisationDashboard(),
    ),
    _ArcHubFeature(
      title: 'Community Intel',
      subtitle: 'Drop reports and blueprint location intelligence.',
      icon: Icons.radar_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const ArcMarketIntelligenceScreen(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final target = (index + _features.length) % _features.length;

    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openFeature(_ArcHubFeature feature) {
    Navigator.of(context).push(MaterialPageRoute(builder: feature.builder));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _features[_selectedIndex];

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Column(
              children: [
                _HubHeader(selected: selected),
                const SizedBox(height: 4),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _controller,
                        itemCount: _features.length,
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final feature = _features[index];

                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final double distance =
                                  _controller.position.haveDimensions
                                  ? (((_controller.page ??
                                                _selectedIndex.toDouble()) -
                                            index.toDouble())
                                        .toDouble())
                                  : ((_selectedIndex.toDouble() -
                                            index.toDouble())
                                        .toDouble());

                              final double clamped = distance
                                  .abs()
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                              final double scale = (1.0 - (clamped * 0.14))
                                  .toDouble();
                              final double opacity = (1.0 - (clamped * 0.32))
                                  .toDouble();
                              final double yOffset = (clamped * 16.0)
                                  .toDouble();

                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(0, yOffset),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: _FeatureBarrelCard(
                              feature: feature,
                              selected: index == _selectedIndex,
                              onTap: () => _openFeature(feature),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 8,
                        child: _ChevronButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => _goTo(_selectedIndex - 1),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: _ChevronButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: () => _goTo(_selectedIndex + 1),
                        ),
                      ),
                    ],
                  ),
                ),
                _FloatingDescription(feature: selected),
                const SizedBox(height: 4),
                _ArcBottomDock(
                  onBlueprints: () => _openFeature(
                    _ArcHubFeature(
                      title: 'Blueprint Grid',
                      subtitle:
                          'Track owned, missing and duplicate blueprints.',
                      icon: Icons.grid_on_rounded,
                      accent: AppTheme.neonCyan,
                      builder: (_) => const BlueprintGridScreen(),
                    ),
                  ),
                  onHunts: () => _openFeature(
                    _ArcHubFeature(
                      title: 'Hunt Targets',
                      subtitle: 'Edit your active blueprint hunt priorities.',
                      icon: Icons.track_changes_rounded,
                      accent: AppTheme.neonPink,
                      builder: (_) => const RaidPlannerHuntTargetsScreen(),
                    ),
                  ),
                  onMic: () => UagVoiceArcAssistantSheet.show(context),
                  onTrading: () => _openFeature(
                    _ArcHubFeature(
                      title: 'Trading',
                      subtitle: 'Open Trader Hub.',
                      icon: Icons.swap_horiz_rounded,
                      accent: AppTheme.neonPink,
                      builder: (_) => const TraderHubScreen(),
                    ),
                  ),
                  onIntel: () => _openFeature(
                    _ArcHubFeature(
                      title: 'Intel',
                      subtitle: 'Open Community Intel.',
                      icon: Icons.radar_rounded,
                      accent: AppTheme.neonCyan,
                      builder: (_) => const ArcMarketIntelligenceScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMenuScreen extends StatefulWidget {
  const _TrackingMenuScreen();

  @override
  State<_TrackingMenuScreen> createState() => _TrackingMenuScreenState();
}

class _TrackingMenuScreenState extends State<_TrackingMenuScreen> {
  final PageController _controller = PageController(viewportFraction: 0.78);
  int _selectedIndex = 0;

  late final List<_ArcHubFeature> _trackingFeatures = [
    _ArcHubFeature(
      title: 'Blueprint Grid',
      subtitle: 'Owned, missing, dupes and blueprint hunt progress.',
      icon: Icons.grid_on_rounded,
      accent: AppTheme.neonCyan,
      builder: (_) => const BlueprintGridScreen(),
    ),
    _ArcHubFeature(
      title: 'Scrappy Tracker',
      subtitle: 'Track upgrade materials and useful resource quantities.',
      icon: Icons.inventory_2_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const ScrappyGridScreen(),
    ),
    _ArcHubFeature(
      title: 'Bench Tracker',
      subtitle:
          'Track station upgrades, bench materials and tier requirements.',
      icon: Icons.build_rounded,
      accent: AppTheme.neonCyan,
      builder: (_) => const ScrappyGridScreen.bench(),
    ),
    _ArcHubFeature(
      title: 'Quest Tracker',
      subtitle:
          'Track quest collection items, hand-ins and progress requirements.',
      icon: Icons.assignment_rounded,
      accent: AppTheme.neonPink,
      builder: (_) => const ScrappyGridScreen.quest(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final target =
        (index + _trackingFeatures.length) % _trackingFeatures.length;

    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _trackingFeatures[_selectedIndex];

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackgroundDeep,
        foregroundColor: Colors.white,
        title: Text(
          'Tracking',
          style: AppTheme.neonTextStyle(
            fontSize: 22,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 4),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _controller,
                        itemCount: _trackingFeatures.length,
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final feature = _trackingFeatures[index];

                          return _FeatureBarrelCard(
                            feature: feature,
                            selected: index == _selectedIndex,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: feature.builder),
                              );
                            },
                          );
                        },
                      ),
                      Positioned(
                        left: 8,
                        child: _ChevronButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => _goTo(_selectedIndex - 1),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: _ChevronButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: () => _goTo(_selectedIndex + 1),
                        ),
                      ),
                    ],
                  ),
                ),
                _FloatingDescription(feature: selected),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  final _ArcHubFeature selected;

  const _HubHeader({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceS,
        AppTheme.spaceS,
        AppTheme.spaceM,
        0,
      ),
      child: Builder(
        builder: (menuContext) {
          return Row(
            children: [
              IconButton(
                tooltip: 'Menu',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                onPressed: () => Scaffold.of(menuContext).openDrawer(),
                icon: Icon(
                  Icons.menu_rounded,
                  color: selected.accent,
                  size: 28,
                ),
              ),
              Icon(Icons.hexagon_rounded, color: selected.accent, size: 22),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  'UAG Arc Raiders Hub',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.neonTextStyle(
                    fontSize: 21,
                    color: selected.accent,
                    isBold: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureBarrelCard extends StatelessWidget {
  final _ArcHubFeature feature;
  final bool selected;
  final VoidCallback onTap;

  const _FeatureBarrelCard({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = selected ? 176.0 : 146.0;
    final iconSize = selected ? 48.0 : 38.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElectricChargeBorder(
            active: selected,
            radius: 999,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
                  border: Border.all(
                    color: selected
                        ? feature.accent.withValues(alpha: 0.92)
                        : feature.accent.withValues(alpha: 0.32),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: feature.accent.withValues(alpha: 0.26),
                            blurRadius: 34,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: feature.accent.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Icon(feature.icon, color: feature.accent, size: iconSize),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: feature.accent.withValues(alpha: selected ? 0.62 : 0.22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feature.title,
                  textAlign: TextAlign.center,
                  style: AppTheme.neonTextStyle(
                    fontSize: selected ? 18 : 15,
                    color: selected ? feature.accent : Colors.white70,
                    isBold: true,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tap to open',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                      isBold: true,
                    ),
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

class _FloatingDescription extends StatelessWidget {
  final _ArcHubFeature feature;

  const _FloatingDescription({required this.feature});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(feature.title),
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: feature.accent.withValues(alpha: 0.32)),
        ),
        child: Text(
          feature.subtitle,
          textAlign: TextAlign.center,
          style: AppTheme.bodyTextStyle(
            fontSize: 13,
            color: AppTheme.tradingMutedText,
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ChevronButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onPressed == null ? 0.25 : 1,
      duration: const Duration(milliseconds: 160),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.72),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.34)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: AppTheme.neonCyan,
          iconSize: 34,
        ),
      ),
    );
  }
}

class _ArcBottomDock extends StatelessWidget {
  final VoidCallback onBlueprints;
  final VoidCallback onHunts;
  final VoidCallback onMic;
  final VoidCallback onTrading;
  final VoidCallback onIntel;

  const _ArcBottomDock({
    required this.onBlueprints,
    required this.onHunts,
    required this.onMic,
    required this.onTrading,
    required this.onIntel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        0,
        AppTheme.spaceM,
        AppTheme.spaceM,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceS,
        vertical: AppTheme.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockButton(
              icon: Icons.grid_on_rounded,
              label: 'Grid',
              onTap: onBlueprints,
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: Icons.track_changes_rounded,
              label: 'Hunts',
              onTap: onHunts,
            ),
          ),
          _ArcMicButton(onTap: onMic),
          Expanded(
            child: _DockButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Trade',
              onTap: onTrading,
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: Icons.radar_rounded,
              label: 'Intel',
              onTap: onIntel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcMicButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ArcMicButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceS),
      child: ElectricChargeBorder(
        active: true,
        radius: 999,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonPink.withValues(alpha: 0.22),
              border: Border.all(
                color: AppTheme.neonPink.withValues(alpha: 0.78),
              ),
            ),
            child: Icon(Icons.mic_rounded, color: AppTheme.neonPink, size: 32),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.neonCyan, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white70,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcArcAssistantLauncherScreen extends StatelessWidget {
  const _ArcArcAssistantLauncherScreen();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UagVoiceArcAssistantSheet.show(context);
      Navigator.of(context).maybePop();
    });

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ArcHubFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final WidgetBuilder builder;

  const _ArcHubFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
  });
}
