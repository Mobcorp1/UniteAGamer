// UAG ARC SHARED ARCHITECTURE LAYER
//
// This file is the official shared ARC Raiders screen architecture layer.
//
// LIVE RESPONSIBILITIES:
// - cinematic ARC backdrop
// - shared watermark/background visual foundation
// - shared responsive page content helpers
// - shared page list spacing helpers
// - shared section/header/banner card foundations
//
// IMPORTANT:
// Do not delete this file while live screens import:
// - ArcRaidersScreenBackdrop
// - ArcRaidersPageList
// - ArcRaidersPageHeader
// - ArcRaidersHeroBanner
// - ArcRaidersSectionCard
//
// Keep blueprint grid rendering, portrait carousel logic, ownership/dupe logic,
// _buildGrid, and BlueprintTile structure isolated from architecture cleanup passes.
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';

class ArcRaidersScreenBackdrop extends StatelessWidget {
  const ArcRaidersScreenBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const UagCinematicBackground(
      backgroundAsset: UagVisualAssets.arcBackground,
      backgroundOpacity: 0.34,
      watermarkOpacity: 0.10,
      showGrid: false,
    );
  }
}

class ArcRaidersScreenShell extends StatelessWidget {
  const ArcRaidersScreenShell({
    super.key,
    required this.child,
    this.useSafeArea = false,
    this.showAdBanner = true,
    this.adTier = ArcAdAccessTier.free,
    this.showAdsForTraderPro = false,
  });

  final Widget child;
  final bool useSafeArea;
  final bool showAdBanner;
  final ArcAdAccessTier adTier;
  final bool showAdsForTraderPro;

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: child) : child;
    final shouldReserveAdSlot =
        showAdBanner &&
        ArcAdBannerCard.shouldShowForTier(
          tier: adTier,
          showForTraderPro: showAdsForTraderPro,
        );

    return Stack(
      children: [
        const Positioned.fill(child: ArcRaidersScreenBackdrop()),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.045),
                    Colors.transparent,
                    AppTheme.neonPink.withValues(alpha: 0.055),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              Expanded(child: content),
              if (shouldReserveAdSlot)
                ArcAdBannerCard(
                  tier: adTier,
                  showForTraderPro: showAdsForTraderPro,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArcRaidersResponsiveContent extends StatelessWidget {
  const ArcRaidersResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1160,
    this.padding = const EdgeInsets.fromLTRB(8, 2, 8, 8),
    this.alignTop = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );

    if (!alignTop) return content;

    return Align(alignment: Alignment.topCenter, child: content);
  }
}

class ArcRaidersPageScaffold extends StatelessWidget {
  const ArcRaidersPageScaffold({
    super.key,
    required this.child,
    this.maxWidth = 1320,
    this.useSafeArea = true,
    this.showAdBanner = true,
    this.adTier = ArcAdAccessTier.free,
    this.showAdsForTraderPro = false,
  });

  final Widget child;
  final double maxWidth;
  final bool useSafeArea;
  final bool showAdBanner;
  final ArcAdAccessTier adTier;
  final bool showAdsForTraderPro;

  @override
  Widget build(BuildContext context) {
    return ArcRaidersScreenShell(
      useSafeArea: useSafeArea,
      showAdBanner: showAdBanner,
      adTier: adTier,
      showAdsForTraderPro: showAdsForTraderPro,
      child: ArcRaidersResponsiveContent(maxWidth: maxWidth, child: child),
    );
  }
}

class ArcRaidersPageList extends StatelessWidget {
  const ArcRaidersPageList({
    super.key,
    required this.children,
    this.maxWidth = 1160,
    this.padding = const EdgeInsets.fromLTRB(8, 2, 8, 8),
    this.bottomPadding = 76,
    this.physics,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double bottomPadding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: physics,
      padding: EdgeInsets.zero,
      children: [
        ArcRaidersResponsiveContent(
          maxWidth: maxWidth,
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children,
              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ],
    );
  }
}

class ArcRaidersPageHeader extends StatelessWidget {
  const ArcRaidersPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.logoAsset,
    this.trailing,
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? logoAsset;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 430;

    Widget leadingIcon() {
      if (logoAsset != null) {
        return Image.asset(
          logoAsset!,
          width: compact ? 28 : 34,
          height: compact ? 28 : 34,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(
            icon ?? Icons.dashboard_rounded,
            color: accent,
            size: compact ? 26 : 30,
          ),
        );
      }

      return Container(
        width: compact ? 28 : 32,
        height: compact ? 28 : 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon ?? Icons.dashboard_rounded,
          color: accent,
          size: compact ? 16 : 18,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spaceS : AppTheme.spaceM,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          leadingIcon(),
          SizedBox(width: compact ? AppTheme.spaceS : AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(
                    fontSize: compact ? 15 : 18,
                    color: accent,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    subtitle!,
                    maxLines: compact ? 1 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: compact ? 10.5 : 11.5,
                      color: Colors.white70,
                      isBold: true,
                    ).copyWith(height: 1.30),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spaceS),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ArcRaidersHeroBanner extends StatelessWidget {
  const ArcRaidersHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: AppTheme.tradingCardDecoration(
        radius: 22,
        borderColor: accent.withValues(alpha: 0.32),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 21 : 28,
                  color: accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: AppTheme.bodyTextStyle(
                  fontSize: compact ? 12 : 14,
                  color: Colors.white70,
                  isBold: true,
                ).copyWith(height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ArcRaidersSectionCard extends StatelessWidget {
  const ArcRaidersSectionCard({
    super.key,
    required this.child,
    this.accent = AppTheme.neonCyan,
    this.padding = const EdgeInsets.all(AppTheme.spaceS),
    this.radius = 18,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppTheme.tradingCardDecoration(
        radius: radius,
        borderColor: accent.withValues(alpha: 0.32),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
      ),
      child: child,
    );
  }
}
