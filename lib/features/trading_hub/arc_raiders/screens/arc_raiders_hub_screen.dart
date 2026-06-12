import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';
import '../widgets/arc_ad_banner_card.dart';

import '../../../../screens/build/app_bar.dart';
import '../../../../screens/build/app_drawer.dart';
import '../../../../widgets/electric_charge_border.dart';
import '../../../../widgets/static_watermark.dart';
import '../../../../widgets/theme.dart';
import '../../../../widgets/arc_responsive_chrome.dart';
import '../raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import '../raid_planner/screens/raid_planner_screen.dart';
import '../voice/voice_assistant_sheet.dart';
import 'arc_market_intelligence_screen.dart';
import 'arc_profile_edit_screen.dart';
import 'arc_match_rider_screen.dart';
import 'blueprint_grid_screen.dart';
import 'my_hub_screen.dart';
import 'scrappy_grid_screen.dart';
import 'smart_trade_assist_screen.dart';
import '../../../../features/feature_access_gate.dart';
import 'trader_hub_screen.dart';

class ArcRaidersHubScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders';

  const ArcRaidersHubScreen({super.key});

  @override
  State<ArcRaidersHubScreen> createState() => _ArcRaidersHubScreenState();
}

class _ArcRaidersHubScreenState extends State<ArcRaidersHubScreen> {
  final PageController _controller = PageController(viewportFraction: 0.42);
  int _selectedIndex = 0;

  late final List<_ArcHubFeature> _features = [
    _ArcHubFeature(
      title: 'My Hub',
      subtitle:
          'Your personal ARC command centre, progress, subscriptions and daily ops.',
      icon: Icons.dashboard_customize_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.smart,
      assetName: 'my_hub_card.webp',
      builder: (_) => const MyHubScreen(),
    ),
    _ArcHubFeature(
      title: 'Profile & Reputation',
      subtitle: 'Edit your trader profile, trust signals and raider identity.',
      icon: Icons.verified_user_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.intel,
      assetName: 'arc_hub_profile_reputation.webp',
      builder: (_) => const ArcProfileEditScreen(),
    ),
    _ArcHubFeature(
      title: 'Referral Tools',
      subtitle:
          'Community referrals, creator rewards and supporter growth tools.',
      icon: Icons.campaign_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.smart,
      assetName: 'arc_hub_referral_tools.webp',
      builder: (_) => const MyHubScreen(),
    ),
    _ArcHubFeature(
      title: 'Subscriptions',
      subtitle: 'Premium access, supporter perks and account upgrade options.',
      icon: Icons.workspace_premium_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.trading,
      assetName: 'arc_hub_subscriptions.webp',
      builder: (_) => const MyHubScreen(),
    ),
    _ArcHubFeature(
      title: 'Match a Raider',
      subtitle: 'Find squadmates, chill raiders and extraction partners.',
      icon: Icons.groups_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.match,
      assetName: 'arc_hub_match_a_raider.webp',
      builder: (_) => const ArcMatchRiderScreen(),
    ),
    _ArcHubFeature(
      title: 'Raid Planner',
      subtitle: 'Plan around active hunts, events and blueprint windows.',
      icon: Icons.route_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.raid,
      assetName: 'arc_hub_raid_planner.webp',
      builder: (_) => const RaidPlannerScreen(),
    ),
    _ArcHubFeature(
      title: 'Hunt Targets',
      subtitle: 'Edit your 5 active blueprint hunts used by the planner.',
      icon: Icons.track_changes_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.targets,
      assetName: 'arc_hub_hunt_targets.webp',
      builder: (_) => const RaidPlannerHuntTargetsScreen(),
    ),
    _ArcHubFeature(
      title: 'Trading',
      subtitle: 'Listings, offers, sessions and safer swap guidance.',
      icon: Icons.swap_horiz_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.trading,
      assetName: 'arc_hub_trading.webp',
      builder: (_) => const TraderHubScreen(),
    ),
    _ArcHubFeature(
      title: 'Smart Trade',
      subtitle: 'Turn duplicate blueprints into useful trade opportunities.',
      icon: Icons.auto_awesome_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.smart,
      assetName: 'arc_hub_smart_trade.webp',
      builder: (_) => const SmartTradeAssistScreen(),
    ),
    _ArcHubFeature(
      title: 'Community Intel',
      subtitle: 'Drop reports and blueprint location intelligence.',
      icon: Icons.radar_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.intel,
      assetName: 'arc_hub_community_intel.webp',
      builder: (_) => const ArcMarketIntelligenceScreen(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFeature(_ArcHubFeature feature) {
    const lockedTitles = {
      'Match a Raider',
      'Raid Planner',
      'Trading',
      'Smart Trade',
      'Community Intel',
      'Referral Tools',
      'Subscriptions',
    };

    if (lockedTitles.contains(feature.title)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FeatureLockedScreen(title: feature.title),
        ),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: feature.builder));
  }

  _ArcHubFeature _featureByTitle(String title) {
    return _features.firstWhere((feature) => feature.title == title);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _features[_selectedIndex];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()));
        },
        icon: const Icon(Icons.feedback_outlined),
        label: const Text('Feedback'),
      ),
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'ARC Raiders Hub',
        subtitle: 'Tracker, intel, trading and raid tools',
        showLogout: true,
      ),
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _ArcHubScreenBackdrop(accent: selected.accent),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.30, child: StaticWatermark()),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomReserve = ArcResponsiveChrome.bottomSafePadding(
                    context,
                  );
                  final maxWidth = ArcResponsiveChrome.maxContentWidth(context);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spaceS,
                      AppTheme.spaceS,
                      AppTheme.spaceS,
                      bottomReserve,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          children: [
                            _HubHeader(selected: selected),
                            const SizedBox(height: AppTheme.spaceS),
                            Expanded(
                              child: Center(
                                child: _PremiumFeatureCarousel(
                                  controller: _controller,
                                  selectedIndex: _selectedIndex,
                                  features: _features,
                                  onPageChanged: (index) {
                                    setState(() => _selectedIndex = index);
                                  },
                                  onOpen: _openFeature,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(
                      ArcResponsiveChrome.dockMaxWidth(context),
                      ArcResponsiveChrome.adMaxWidth(context),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spaceS,
                      0,
                      AppTheme.spaceS,
                      AppTheme.spaceXS,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _HubAdSlot(),
                        const SizedBox(height: AppTheme.spaceXS),
                        _ArcBottomDock(
                          onMatch: () =>
                              _openFeature(_featureByTitle('Match a Raider')),
                          onRaid: () =>
                              _openFeature(_featureByTitle('Raid Planner')),
                          onMic: () => UagVoiceArcAssistantSheet.show(context),
                          onTrading: () =>
                              _openFeature(_featureByTitle('Trading')),
                          onIntel: () =>
                              _openFeature(_featureByTitle('Community Intel')),
                        ),
                      ],
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

class _PremiumFeatureCarousel extends StatelessWidget {
  const _PremiumFeatureCarousel({
    required PageController controller,
    required this.selectedIndex,
    required this.features,
    required this.onPageChanged,
    required this.onOpen,
  });

  final int selectedIndex;
  final List<_ArcHubFeature> features;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<_ArcHubFeature> onOpen;

  int _wrap(int value) => (value + features.length) % features.length;

  void _step(int direction) {
    onPageChanged(_wrap(selectedIndex + direction));
  }

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 430;
        final isWide = constraints.maxWidth >= 900;
        final isTablet =
            constraints.maxWidth >= 650 && constraints.maxWidth < 900;
        final isCompactHeight = constraints.maxHeight < 640;
        final slots = isWide ? const [-2, 2, -1, 1, 0] : const [-1, 1, 0];

        final stageWidth = isWide
            ? math.min(constraints.maxWidth, 1180.0)
            : constraints.maxWidth;
        final stageHeight = isPhone
            ? math.min(constraints.maxHeight, 520.0)
            : math.min(constraints.maxHeight, isTablet ? 620.0 : 510.0);

        final centreCardHeight = isWide
            ? (isCompactHeight ? 278.0 : 304.0)
            : isTablet
            ? 350.0
            : 356.0;

        final dotsTop = centreCardHeight + (isPhone ? 14.0 : 16.0);
        final stripTop = dotsTop + (isPhone ? 24.0 : 24.0);
        final stripWidth = isPhone
            ? math.min(stageWidth - 38.0, 360.0)
            : math.min(stageWidth - 64.0, 560.0);

        final arrowTop = ((centreCardHeight - 48.0) / 2)
            .clamp(72.0, math.max(72.0, stageHeight - 180.0))
            .toDouble();
        final arrowInset = isPhone ? 8.0 : 26.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -100) {
              _step(1);
            } else if (velocity > 100) {
              _step(-1);
            }
          },
          child: Center(
            child: SizedBox(
              width: stageWidth,
              height: stageHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  for (final slot in slots)
                    _StaticRingFeatureSlot(
                      key: ValueKey('${selectedIndex}_$slot'),
                      canvasWidth: stageWidth,
                      canvasHeight: stageHeight,
                      slot: slot,
                      isWide: isWide,
                      isTablet: isTablet,
                      isCompactHeight: isCompactHeight,
                      feature: features[_wrap(selectedIndex + slot)],
                      selected: slot == 0,
                      onTap: slot == 0
                          ? () => onOpen(features[selectedIndex])
                          : () => onPageChanged(_wrap(selectedIndex + slot)),
                    ),
                  Positioned(
                    top: dotsTop,
                    child: _HubPageIndicator(
                      count: features.length,
                      selectedIndex: selectedIndex,
                      accent: features[selectedIndex].accent,
                    ),
                  ),
                  Positioned(
                    top: stripTop,
                    child: SizedBox(
                      width: stripWidth,
                      child: _HubQuickStrip(
                        selected: features[selectedIndex],
                        onOpen: () => onOpen(features[selectedIndex]),
                      ),
                    ),
                  ),
                  Positioned(
                    left: arrowInset,
                    top: arrowTop,
                    child: _ChevronButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => _step(-1),
                    ),
                  ),
                  Positioned(
                    right: arrowInset,
                    top: arrowTop,
                    child: _ChevronButton(
                      icon: Icons.chevron_right_rounded,
                      onPressed: () => _step(1),
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

class _StaticRingFeatureSlot extends StatelessWidget {
  const _StaticRingFeatureSlot({
    super.key,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.slot,
    required this.isWide,
    required this.isTablet,
    required this.isCompactHeight,
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final double canvasWidth;
  final double canvasHeight;
  final int slot;
  final bool isWide;
  final bool isTablet;
  final bool isCompactHeight;
  final _ArcHubFeature feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhone = canvasWidth < 430;
    final distance = slot.abs();

    final centerWidth = isWide
        ? (isCompactHeight ? 274.0 : 298.0)
        : isTablet
        ? 316.0
        : math.min(canvasWidth - 56.0, 312.0);
    final centerHeight = isWide
        ? (isCompactHeight ? 278.0 : 304.0)
        : isTablet
        ? 350.0
        : 356.0;

    final nearWidth = isWide
        ? (isCompactHeight ? 196.0 : 214.0)
        : isTablet
        ? 236.0
        : math.min(canvasWidth - 132.0, 210.0);
    final nearHeight = isWide
        ? (isCompactHeight ? 226.0 : 248.0)
        : isTablet
        ? 294.0
        : 302.0;

    final outerWidth = isWide ? (isCompactHeight ? 124.0 : 138.0) : 0.0;
    final outerHeight = isWide ? (isCompactHeight ? 172.0 : 192.0) : 0.0;

    final width = selected
        ? centerWidth
        : distance == 1
        ? nearWidth
        : outerWidth;
    final height = selected
        ? centerHeight
        : distance == 1
        ? nearHeight
        : outerHeight;

    final offset = selected
        ? 0.0
        : distance == 1
        ? (isWide
              ? (isCompactHeight ? 198.0 : 216.0)
              : isTablet
              ? 214.0
              : math.min(canvasWidth * 0.50, 186.0))
        : (isWide ? (isCompactHeight ? 334.0 : 362.0) : 0.0);

    final top = selected
        ? (isWide
              ? (isCompactHeight ? 0.0 : -6.0)
              : isTablet
              ? 8.0
              : 0.0)
        : distance == 1
        ? (isWide
              ? (isCompactHeight ? 34.0 : 30.0)
              : isTablet
              ? 42.0
              : 38.0)
        : (isCompactHeight ? 62.0 : 58.0);

    final opacity = selected
        ? 1.0
        : distance == 1
        ? (isPhone ? 0.52 : 0.76)
        : 0.32;

    final scale = selected ? 1.0 : (isPhone ? 0.96 : 1.0);
    final left = ((canvasWidth - width) / 2) + (slot < 0 ? -offset : offset);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: IgnorePointer(
            ignoring: !selected && isPhone,
            child: _StaticRingFeatureCard(
              feature: feature,
              selected: selected,
              compact: !selected,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcHubRealAssetBackdrop extends StatelessWidget {
  const _ArcHubRealAssetBackdrop({required this.feature});

  final _ArcHubFeature feature;

  @override
  Widget build(BuildContext context) {
    final path = 'assets/images/arc_raiders/hub/${feature.assetName}';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          path,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.12),
          errorBuilder: (context, error, stackTrace) {
            return _ArcHubArtBackdrop(
              accent: feature.accent,
              kind: feature.art,
            );
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.36),
              radius: 1.08,
              colors: [
                feature.accent.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.38),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.02),
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.66),
                Colors.black.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.42, 0.74, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticRingFeatureCard extends StatelessWidget {
  const _StaticRingFeatureCard({
    required this.feature,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _ArcHubFeature feature;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 430;
    final titleSize = selected ? (phone ? 23.0 : 28.0) : (phone ? 16.0 : 19.0);
    final bodySize = selected ? (phone ? 12.5 : 15.0) : (phone ? 10.5 : 12.0);
    final iconSize = selected ? (phone ? 28.0 : 34.0) : 24.0;

    return InkWell(
      borderRadius: BorderRadius.circular(selected ? 30 : 22),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(selected ? 30 : 22),
          border: Border.all(
            color: feature.accent.withValues(alpha: selected ? 0.88 : 0.58),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: feature.accent.withValues(alpha: selected ? 0.30 : 0.16),
              blurRadius: selected ? 30 : 16,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _ArcHubRealAssetBackdrop(feature: feature)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: compact ? 0.42 : 0.18),
                      Colors.black.withValues(alpha: compact ? 0.92 : 0.74),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: selected ? 16 : 14,
              left: selected ? 16 : 14,
              child: Container(
                width: selected ? (phone ? 50 : 58) : 44,
                height: selected ? (phone ? 50 : 58) : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.38),
                  border: Border.all(
                    color: feature.accent.withValues(alpha: 0.64),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: feature.accent.withValues(alpha: 0.34),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  feature.icon,
                  color: feature.accent,
                  size: iconSize,
                ),
              ),
            ),
            if (selected && !phone)
              Positioned(
                top: 18,
                right: 18,
                child: _ArcHubStatusPill(accent: feature.accent),
              ),
            Positioned(
              left: selected ? (phone ? 18 : 24) : 16,
              right: selected ? (phone ? 18 : 24) : 16,
              bottom: selected ? (phone ? 18 : 24) : 18,
              child: Column(
                crossAxisAlignment: phone && selected
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feature.title.toUpperCase(),
                    textAlign: phone && selected
                        ? TextAlign.center
                        : TextAlign.start,
                    maxLines: phone ? 2 : (compact ? 2 : 3),
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTheme.neonTextStyle(
                          fontSize: titleSize,
                          color: Colors.white,
                          isBold: true,
                        ).copyWith(
                          letterSpacing: phone ? 0.35 : 0.8,
                          height: 1.02,
                          shadows: [
                            Shadow(
                              color: feature.accent.withValues(alpha: 0.80),
                              blurRadius: selected ? 18 : 10,
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    feature.subtitle,
                    textAlign: phone && selected
                        ? TextAlign.center
                        : TextAlign.start,
                    maxLines: phone ? 3 : (compact ? 3 : 4),
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: bodySize,
                      color: Colors.white.withValues(alpha: 0.84),
                      isBold: true,
                    ).copyWith(height: 1.22),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: phone && selected
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: feature.accent,
                        size: compact ? 14 : 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to open',
                        style: AppTheme.bodyTextStyle(
                          fontSize: compact ? 10 : 11,
                          color: feature.accent,
                          isBold: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.selected});

  final _ArcHubFeature selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        ArcResponsiveChrome.width(context) >= 1100
            ? AppTheme.spaceS
            : AppTheme.spaceM,
        AppTheme.spaceM,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ARC Raiders Systems',
              style: AppTheme.neonTextStyle(
                fontSize: ArcResponsiveChrome.width(context) >= 1100 ? 21 : 25,
                color: selected.accent,
                isBold: true,
              ),
            ),
          ),
          _TinySystemChip(label: 'BETA', accent: selected.accent),
        ],
      ),
    );
  }
}

class _HubQuickStrip extends StatelessWidget {
  const _HubQuickStrip({required this.selected, required this.onOpen});

  final _ArcHubFeature selected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 430;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(selected.title),
        padding: EdgeInsets.fromLTRB(
          phone ? AppTheme.spaceM : AppTheme.spaceL,
          AppTheme.spaceM,
          phone ? AppTheme.spaceM : AppTheme.spaceL,
          AppTheme.spaceM,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(phone ? 24 : 28),
          border: Border.all(color: selected.accent.withValues(alpha: 0.36)),
          boxShadow: [
            BoxShadow(
              color: selected.accent.withValues(alpha: 0.12),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          selected.subtitle,
          textAlign: TextAlign.center,
          maxLines: phone ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyTextStyle(
            fontSize: phone ? 13 : 14,
            color: AppTheme.tradingMutedText,
            isBold: true,
          ).copyWith(height: 1.32),
        ),
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
  final PageController _controller = PageController(viewportFraction: 0.42);
  int _selectedIndex = 0;

  late final List<_ArcHubFeature> _trackingFeatures = [
    _ArcHubFeature(
      title: 'Blueprint Grid',
      subtitle: 'Owned, missing, dupes and blueprint hunt progress.',
      icon: Icons.grid_on_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.blueprints,
      assetName: 'arc_hub_blueprint_grid.webp',
      builder: (_) => const BlueprintGridScreen(),
    ),
    _ArcHubFeature(
      title: 'Scrappy Tracker',
      subtitle: 'Track upgrade materials and useful resource quantities.',
      icon: Icons.egg_alt_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.scrappy,
      assetName: 'arc_hub_scrappy_tracker.webp',
      builder: (_) => const ScrappyGridScreen(),
    ),
    _ArcHubFeature(
      title: 'Bench Tracker',
      subtitle:
          'Track bench materials, upgrade tiers and missing requirements.',
      icon: Icons.build_rounded,
      accent: AppTheme.neonCyan,
      art: _ArcHubArtKind.targets,
      assetName: 'arc_hub_bench_tracker.webp',
      builder: (_) => const ScrappyGridScreen.bench(),
    ),
    _ArcHubFeature(
      title: 'Quest Tracker',
      subtitle: 'Track trader quest items, hand-ins and collection progress.',
      icon: Icons.assignment_rounded,
      accent: AppTheme.neonPink,
      art: _ArcHubArtKind.intel,
      assetName: 'arc_hub_quest_tracker.webp',
      builder: (_) => const ScrappyGridScreen.quest(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFeature(_ArcHubFeature feature) {
    const lockedTitles = {
      'Match a Raider',
      'Raid Planner',
      'Trading',
      'Smart Trade',
      'Community Intel',
      'Referral Tools',
      'Subscriptions',
    };

    if (lockedTitles.contains(feature.title)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FeatureLockedScreen(title: feature.title),
        ),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: feature.builder));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _trackingFeatures[_selectedIndex];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()));
        },
        icon: const Icon(Icons.feedback_outlined),
        label: const Text('Feedback'),
      ),
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackgroundDeep,
        foregroundColor: Colors.white,
        title: Text(
          'Tracking',
          style: AppTheme.neonTextStyle(
            fontSize: 22,
            color: selected.accent,
            isBold: true,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _ArcHubScreenBackdrop(accent: selected.accent),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.30, child: StaticWatermark()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spaceM),
                Expanded(
                  child: _PremiumFeatureCarousel(
                    controller: _controller,
                    selectedIndex: _selectedIndex,
                    features: _trackingFeatures,
                    onPageChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    onOpen: _openFeature,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                const _HubAdSlot(),
                const SizedBox(height: AppTheme.spaceXS),
                _ArcBottomDock(
                  onMatch: () => Navigator.of(context).pop(),
                  onRaid: () => Navigator.of(context).pop(),
                  onMic: () => UagVoiceArcAssistantSheet.show(context),
                  onTrading: () => Navigator.of(context).pop(),
                  onIntel: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppTheme.spaceL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubAdSlot extends StatelessWidget {
  const _HubAdSlot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ArcResponsiveChrome.adMaxWidth(context),
        height: ArcResponsiveChrome.adHeight(context),
        child: const ArcAdBannerCard(),
      ),
    );
  }
}

class _ArcBottomDock extends StatelessWidget {
  const _ArcBottomDock({
    required this.onMatch,
    required this.onRaid,
    required this.onMic,
    required this.onTrading,
    required this.onIntel,
  });

  final VoidCallback onMatch;
  final VoidCallback onRaid;
  final VoidCallback onMic;
  final VoidCallback onTrading;
  final VoidCallback onIntel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppTheme.spaceM,
        0,
        AppTheme.spaceM,
        ArcResponsiveChrome.width(context) >= 1100
            ? AppTheme.spaceXS
            : AppTheme.spaceM,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceS,
        vertical: ArcResponsiveChrome.width(context) >= 1100
            ? AppTheme.spaceXS
            : AppTheme.spaceS,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.13),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockButton(
              icon: Icons.groups_rounded,
              label: 'Match',
              onTap: onMatch,
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: Icons.route_rounded,
              label: 'Raid',
              onTap: onRaid,
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
  const _ArcMicButton({required this.onTap});

  final VoidCallback onTap;

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
            width: ArcResponsiveChrome.width(context) >= 1100 ? 54 : 64,
            height: ArcResponsiveChrome.width(context) >= 1100 ? 54 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonPink.withValues(alpha: 0.22),
              border: Border.all(
                color: AppTheme.neonPink.withValues(alpha: 0.78),
              ),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppTheme.neonPink,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
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

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

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

class _HubPageIndicator extends StatelessWidget {
  const _HubPageIndicator({
    required this.count,
    required this.selectedIndex,
    required this.accent,
  });

  final int count;
  final int selectedIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final active = index == selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 22 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? accent : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.42),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _TinySystemChip extends StatelessWidget {
  const _TinySystemChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.44)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(
          fontSize: 11,
          color: accent,
          isBold: true,
        ),
      ),
    );
  }
}

class _ArcHubStatusPill extends StatelessWidget {
  const _ArcHubStatusPill({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: accent, size: 14),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcHubScreenBackdrop extends StatelessWidget {
  const _ArcHubScreenBackdrop({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ArcHubScreenBackdropPainter(accent: accent));
  }
}

class _ArcHubArtBackdrop extends StatelessWidget {
  const _ArcHubArtBackdrop({required this.accent, required this.kind});

  final Color accent;
  final _ArcHubArtKind kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArcHubArtPainter(accent: accent, kind: kind),
    );
  }
}

class _ArcHubScreenBackdropPainter extends CustomPainter {
  const _ArcHubScreenBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF040514),
          Color.lerp(accent, const Color(0xFF050612), 0.86)!,
          const Color(0xFF020208),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              accent.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.50, size.height * 0.32),
              radius: math.max(size.width, size.height) * 0.42,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.32),
      math.max(size.width, size.height) * 0.42,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcHubScreenBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _ArcHubArtPainter extends CustomPainter {
  const _ArcHubArtPainter({required this.accent, required this.kind});

  final Color accent;
  final _ArcHubArtKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF090B18),
          Color.lerp(accent, const Color(0xFF080812), 0.78)!,
          const Color(0xFF02030A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, background);
    _drawGrid(canvas, size);
    _drawGlowOrbs(canvas, size);
    _drawKindArt(canvas, size);
    _drawScannerLines(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;

    const gap = 28.0;
    for (var x = -size.width; x < size.width * 2; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.width * 0.55, 0),
        paint,
      );
    }

    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 24), paint);
    }
  }

  void _drawGlowOrbs(Canvas canvas, Size size) {
    final cyanGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              accent.withValues(alpha: 0.55),
              accent.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.30),
              radius: size.width * 0.46,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.30),
      size.width * 0.46,
      cyanGlow,
    );

    final pinkGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.neonPink.withValues(alpha: 0.32),
              AppTheme.neonPink.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.22, size.height * 0.74),
              radius: size.width * 0.42,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.74),
      size.width * 0.42,
      pinkGlow,
    );
  }

  void _drawKindArt(Canvas canvas, Size size) {
    switch (kind) {
      case _ArcHubArtKind.match:
        _drawSquadArt(canvas, size);
      case _ArcHubArtKind.blueprints:
        _drawBlueprintArt(canvas, size);
      case _ArcHubArtKind.raid:
        _drawRaidArt(canvas, size);
      case _ArcHubArtKind.targets:
        _drawTargetsArt(canvas, size);
      case _ArcHubArtKind.trading:
        _drawTradingArt(canvas, size);
      case _ArcHubArtKind.smart:
        _drawSmartArt(canvas, size);
      case _ArcHubArtKind.intel:
        _drawRaidArt(canvas, size);
      case _ArcHubArtKind.scrappy:
        _drawScrappyArt(canvas, size);
    }
  }

  void _drawSquadArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.84);

    final centre = Offset(size.width * 0.58, size.height * 0.42);
    final left = Offset(size.width * 0.38, size.height * 0.50);
    final right = Offset(size.width * 0.78, size.height * 0.52);

    canvas.drawCircle(centre, 36, paint);
    canvas.drawCircle(left, 25, paint);
    canvas.drawCircle(right, 25, paint);

    canvas.drawArc(
      Rect.fromCenter(center: centre.translate(0, 62), width: 150, height: 82),
      3.35,
      2.1,
      false,
      paint,
    );
  }

  void _drawBlueprintArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = accent.withValues(alpha: 0.82);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.20,
        size.width * 0.44,
        size.height * 0.44,
      ),
      const Radius.circular(18),
    );

    canvas.drawRRect(rect, paint);

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.28 + i * 0.08);
      canvas.drawLine(
        Offset(size.width * 0.40, y),
        Offset(size.width * 0.72, y),
        paint,
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.57, size.height * 0.42),
      38,
      paint..color = AppTheme.neonPink.withValues(alpha: 0.70),
    );
  }

  void _drawRaidArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = accent.withValues(alpha: 0.82);

    final centre = Offset(size.width * 0.58, size.height * 0.42);
    for (final radius in [32.0, 62.0, 92.0]) {
      canvas.drawCircle(centre, radius, paint);
    }

    canvas.drawLine(centre.translate(-118, 0), centre.translate(118, 0), paint);
    canvas.drawLine(centre.translate(0, -102), centre.translate(0, 102), paint);
    canvas.drawCircle(
      centre.translate(42, -34),
      8,
      Paint()..color = AppTheme.neonPink.withValues(alpha: 0.88),
    );
  }

  void _drawTargetsArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.86);

    final centre = Offset(size.width * 0.58, size.height * 0.42);
    canvas.drawCircle(centre, 86, paint);
    canvas.drawCircle(centre, 48, paint);
    canvas.drawCircle(centre, 12, Paint()..color = AppTheme.neonPink);
    canvas.drawLine(centre.translate(-104, 0), centre.translate(104, 0), paint);
    canvas.drawLine(centre.translate(0, -104), centre.translate(0, 104), paint);
  }

  void _drawScrappyArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.84);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.45),
        width: 116,
        height: 86,
      ),
      const Radius.circular(42),
    );
    canvas.drawRRect(body, paint);

    final head = Offset(size.width * 0.62, size.height * 0.30);
    canvas.drawCircle(head, 28, paint);
    canvas.drawPath(
      Path()
        ..moveTo(head.dx + 22, head.dy + 2)
        ..lineTo(head.dx + 52, head.dy + 12)
        ..lineTo(head.dx + 22, head.dy + 22),
      paint,
    );

    final comb = Paint()
      ..color = AppTheme.neonPink.withValues(alpha: 0.86)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(head.dx - 18 + i * 14, head.dy - 28 - (i == 1 ? 6 : 0)),
        9,
        comb,
      );
    }
  }

  void _drawTradingArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withValues(alpha: 0.82);

    final left = Rect.fromLTWH(size.width * 0.28, size.height * 0.32, 94, 70);
    final right = Rect.fromLTWH(size.width * 0.58, size.height * 0.24, 94, 70);

    canvas.drawRRect(
      RRect.fromRectAndRadius(left, const Radius.circular(16)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, const Radius.circular(16)),
      paint..color = AppTheme.neonPink.withValues(alpha: 0.76),
    );

    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.70);

    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.54),
      Offset(size.width * 0.64, size.height * 0.54),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.54),
      Offset(size.width * 0.58, size.height * 0.50),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.54),
      Offset(size.width * 0.58, size.height * 0.58),
      arrowPaint,
    );
  }

  void _drawSmartArt(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.84);

    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.22,
        size.width * 0.62,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.62,
        size.width * 0.84,
        size.height * 0.30,
      );
    canvas.drawPath(path, paint);

    for (final offset in [
      Offset(size.width * 0.32, size.height * 0.58),
      Offset(size.width * 0.62, size.height * 0.44),
      Offset(size.width * 0.84, size.height * 0.30),
    ]) {
      canvas.drawCircle(offset, 12, Paint()..color = AppTheme.neonPink);
    }
  }

  void _drawScannerLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    for (var y = 0.0; y < size.height; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcHubArtPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.kind != kind;
  }
}

// ARC HUB WEBP ASSET MANIFEST
// Drop generated/converted files here:
// assets/images/arc_raiders/hub/arc_hub_profile_reputation.webp
// assets/images/arc_raiders/hub/arc_hub_referral_tools.webp
// assets/images/arc_raiders/hub/arc_hub_subscriptions.webp
// assets/images/arc_raiders/hub/arc_hub_match_a_raider.webp
// assets/images/arc_raiders/hub/arc_hub_raid_planner.webp
// assets/images/arc_raiders/hub/arc_hub_tracking.webp
// assets/images/arc_raiders/hub/arc_hub_hunt_targets.webp
// assets/images/arc_raiders/hub/arc_hub_trading.webp
// assets/images/arc_raiders/hub/arc_hub_smart_trade.webp
// assets/images/arc_raiders/hub/arc_hub_community_intel.webp
// assets/images/arc_raiders/hub/arc_hub_blueprint_grid.webp
// assets/images/arc_raiders/hub/arc_hub_scrappy_tracker.webp
// assets/images/arc_raiders/hub/arc_hub_bench_tracker.webp
// assets/images/arc_raiders/hub/arc_hub_quest_tracker.webp
enum _ArcHubArtKind {
  match,
  blueprints,
  raid,
  targets,
  trading,
  smart,
  intel,
  scrappy,
}

class _ArcHubFeature {
  const _ArcHubFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.art,
    required this.assetName,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final _ArcHubArtKind art;
  final String assetName;
  final WidgetBuilder builder;
}
