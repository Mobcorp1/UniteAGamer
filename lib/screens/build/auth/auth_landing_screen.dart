import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/auth/auth_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AuthLandingScreen extends StatefulWidget {
  static const String routeName = '/auth-landing';

  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _carouselController;

  static const List<_FeatureSlide> _slides = [
    _FeatureSlide(
      title: 'My Hub',
      subtitle: 'Track rewards, referrals, reputation and hunt priorities.',
      image: 'assets/images/arc_raiders/hub/arc_hub_my_hub.webp',
      icon: Icons.dashboard_customize_outlined,
      accent: AppTheme.neonCyan,
    ),
    _FeatureSlide(
      title: 'Tracking',
      subtitle: 'Blueprint grid, ownership, dupes and wanted progress.',
      image: 'assets/images/arc_raiders/hub/arc_hub_tracking.webp',
      icon: Icons.track_changes_rounded,
      accent: AppTheme.neonCyan,
    ),
    _FeatureSlide(
      title: 'Trading',
      subtitle: 'Create listings, browse offers and plan safer swaps.',
      image: 'assets/images/arc_raiders/hub/arc_hub_trading.webp',
      icon: Icons.handshake_rounded,
      accent: AppTheme.neonPink,
    ),
    _FeatureSlide(
      title: 'Match a Raider',
      subtitle: 'Find raiders by focus, playstyle and availability.',
      image: 'assets/images/arc_raiders/hub/arc_hub_match_a_raider.webp',
      icon: Icons.groups_2_rounded,
      accent: Colors.orangeAccent,
    ),
    _FeatureSlide(
      title: 'Smart Trade',
      subtitle: 'Use inventory intelligence to spot better trades.',
      image: 'assets/images/arc_raiders/hub/arc_hub_smart_trade.webp',
      icon: Icons.auto_awesome_rounded,
      accent: Colors.lightGreenAccent,
    ),
    _FeatureSlide(
      title: 'Raid Planner',
      subtitle: 'Plan raid windows, hunt targets and extraction routes.',
      image: 'assets/images/arc_raiders/hub/arc_hub_raid_planner.webp',
      icon: Icons.map_outlined,
      accent: Colors.amberAccent,
    ),
    _FeatureSlide(
      title: 'Blueprint Grid',
      subtitle: 'Track the complete ARC blueprint collection visually.',
      image: 'assets/images/arc_raiders/hub/arc_hub_blueprint_grid.webp',
      icon: Icons.grid_view_rounded,
      accent: AppTheme.neonCyan,
    ),
    _FeatureSlide(
      title: 'Community Intel',
      subtitle: 'Use drop reports and community sightings to hunt smarter.',
      image: 'assets/images/arc_raiders/hub/arc_hub_community_intel.webp',
      icon: Icons.radar_rounded,
      accent: Colors.cyanAccent,
    ),
    _FeatureSlide(
      title: 'Scrappy Tracker',
      subtitle: 'Track resources, upgrade needs and tradable extras.',
      image: 'assets/images/arc_raiders/hub/arc_hub_scrappy_tracker.webp',
      icon: Icons.inventory_2_outlined,
      accent: Colors.deepPurpleAccent,
    ),
    _FeatureSlide(
      title: 'Market Watch',
      subtitle: 'See demand, supply and trading opportunities.',
      image: 'assets/images/arc_raiders/hub/arc_hub_market_watch.webp',
      icon: Icons.show_chart_rounded,
      accent: AppTheme.neonPink,
    ),
    _FeatureSlide(
      title: 'Hunt Targets',
      subtitle: 'Focus high-value targets and routes before raids.',
      image: 'assets/images/arc_raiders/hub/arc_hub_hunt_targets.webp',
      icon: Icons.my_location_rounded,
      accent: Colors.redAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  void _openAuth({required bool login}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AuthScreen(initialIsLogin: login)),
    );
  }

  Widget _background() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset(
            'assets/images/auth_bg_landscape.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const StaticWatermark(),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.48)),
        const StaticWatermark(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.76),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _brand(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 26,
        compact ? 12 : 18,
        compact ? 14 : 26,
        0,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icon/uag_traders_icon_transparent.webp',
            width: compact ? 34 : 46,
            height: compact ? 34 : 46,
            errorBuilder: (_, _, _) => Icon(
              Icons.swap_horiz_rounded,
              color: AppTheme.neonCyan,
              size: compact ? 30 : 42,
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Text(
              'UAG ARC RAIDERS HUB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.neonTextStyle(
                fontSize: compact ? 16 : 25,
                color: Colors.white,
                isBold: true,
              ).copyWith(letterSpacing: compact ? 1.3 : 2.6),
            ),
          ),
          if (!compact) ...[
            TextButton.icon(
              onPressed: () => _openAuth(login: true),
              icon: const Icon(
                Icons.login_rounded,
                color: AppTheme.neonCyan,
                size: 18,
              ),
              label: const Text(
                'Log In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => _openAuth(login: false),
                child: const Text('Create Account'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hero(BoxConstraints constraints) {
    final compact = constraints.maxWidth < 720;
    final veryCompact = constraints.maxWidth < 420;
    final fontSize = constraints.maxWidth >= 1320
        ? 64.0
        : constraints.maxWidth >= 980
        ? 52.0
        : constraints.maxWidth >= 720
        ? 40.0
        : veryCompact
        ? 25.0
        : 28.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style:
                    AppTheme.heroTextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                    ).copyWith(
                      letterSpacing: compact ? 1.45 : 5.5,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.95),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                children: const [
                  TextSpan(text: 'CONNECT. '),
                  TextSpan(
                    text: 'TRADE. ',
                    style: TextStyle(color: AppTheme.neonCyan),
                  ),
                  TextSpan(
                    text: 'HUNT. ',
                    style: TextStyle(color: AppTheme.neonPink),
                  ),
                  TextSpan(text: 'EXTRACT.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              'Your Arc Raiders trading companion. Built for tracking, trust, marketplace intelligence and extraction ready coordination.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyTextStyle(
                fontSize: compact ? 13.0 : 18,
                color: Colors.white.withValues(alpha: 0.86),
                isBold: true,
              ),
            ),
          ),
          if (compact) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _openAuth(login: false),
                      child: const Text('Create Account'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _openAuth(login: true),
                      child: const Text('Log In'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _carousel(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final compact = width < 620;
    final veryCompact = width < 420;

    final cardWidth = veryCompact
        ? 166.0
        : compact
        ? 205.0
        : width >= 1320
        ? 282.0
        : width >= 980
        ? 255.0
        : 238.0;

    final cardHeight = veryCompact
        ? 162.0
        : compact
        ? 192.0
        : 255.0;

    const gap = 14.0;
    final loopWidth = _slides.length * (cardWidth + gap);

    return SizedBox(
      width: double.infinity,
      height: cardHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _carouselController,
          builder: (context, _) {
            final offset = -_carouselController.value * loopWidth;
            return OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var round = 0; round < 3; round++)
                      for (final slide in _slides)
                        Padding(
                          padding: const EdgeInsets.only(right: gap),
                          child: _FeatureImageCard(
                            slide: slide,
                            width: cardWidth,
                            height: cardHeight,
                            compact: compact,
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _trustStrip(bool compact) {
    final items = [
      _TrustBadge(icon: Icons.shield_outlined, text: 'Trusted Network'),
      _TrustBadge(icon: Icons.balance_rounded, text: 'Fair Trading'),
      _TrustBadge(icon: Icons.radar_rounded, text: 'Live Intel'),
      _TrustBadge(icon: Icons.groups_2_outlined, text: 'Community First'),
      _TrustBadge(
        icon: Icons.health_and_safety_outlined,
        text: 'Safety Conscious',
      ),
      _TrustBadge(icon: Icons.lock_outline_rounded, text: 'Privacy Focused'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 8 : 16,
      runSpacing: compact ? 8 : 12,
      children: items,
    );
  }

  Widget _trustPanel(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 18,
        vertical: compact ? 10 : 17,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.16)),
      ),
      child: _trustStrip(compact),
    );
  }

  Widget _mobileBody(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 22),
      child: Column(
        children: [
          _carousel(constraints),
          const Spacer(flex: 1),
          _hero(constraints),
          const Spacer(flex: 1),
          _trustPanel(true),
        ],
      ),
    );
  }

  Widget _desktopBody(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 112),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _carousel(constraints),
            const SizedBox(height: 26),
            _hero(constraints),
            const SizedBox(height: 24),
            _trustPanel(false),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          return Stack(
            fit: StackFit.expand,
            children: [
              _background(),
              SafeArea(
                child: Column(
                  children: [
                    Align(alignment: Alignment.topLeft, child: _brand(compact)),
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(top: compact ? 10 : 14),
                      color: AppTheme.neonCyan.withValues(alpha: 0.42),
                    ),
                    Expanded(
                      child: compact
                          ? _mobileBody(constraints)
                          : _desktopBody(constraints),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureSlide {
  const _FeatureSlide({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final Color accent;
}

class _FeatureImageCard extends StatelessWidget {
  const _FeatureImageCard({
    required this.slide,
    required this.width,
    required this.height,
    required this.compact,
  });

  final _FeatureSlide slide;
  final double width;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: slide.accent.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: slide.accent.withValues(alpha: 0.22),
              blurRadius: 19,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                slide.image,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => Container(
                  color: AppTheme.cardBackgroundAlt,
                  child: Icon(
                    slide.icon,
                    color: slide.accent,
                    size: compact ? 50 : 76,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: compact ? 9 : 12,
                left: compact ? 9 : 12,
                child: Container(
                  width: compact ? 34 : 42,
                  height: compact ? 34 : 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: slide.accent.withValues(alpha: 0.82),
                    ),
                  ),
                  child: Icon(
                    slide.icon,
                    color: slide.accent,
                    size: compact ? 19 : 23,
                  ),
                ),
              ),
              Positioned(
                left: compact ? 10 : 14,
                right: compact ? 10 : 14,
                bottom: compact ? 10 : 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: slide.accent,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.subtitle,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 10.5 : 12.5,
                        height: 1.22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 17),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
