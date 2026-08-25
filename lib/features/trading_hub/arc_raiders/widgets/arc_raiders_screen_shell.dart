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
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcRaidersScreenBackdrop extends StatelessWidget {
  const ArcRaidersScreenBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArcBlueprintGridBackground();
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
                    ArcUiTokens.primaryAccent.withValues(alpha: 0.030),
                    Colors.transparent,
                    ArcUiTokens.secondaryAccent.withValues(alpha: 0.032),
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
    this.padding,
    this.alignTop = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? ArcLayoutTokens.pagePadding(context),
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
    this.padding,
    this.bottomPadding = 38,
    this.physics,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
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
    this.accent = ArcUiTokens.primaryAccent,
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
          width: compact ? 24 : 28,
          height: compact ? 24 : 28,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(
            icon ?? Icons.dashboard_rounded,
            color: accent,
            size: compact ? 22 : 24,
          ),
        );
      }

      return Icon(
        icon ?? Icons.arrow_back_rounded,
        color: accent,
        size: compact ? 20 : 22,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 3 : 5,
        0,
        compact ? 3 : 5,
        compact ? 1 : 2,
      ),
      child: Row(
        children: [
          leadingIcon(),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(
                    fontSize: compact ? 15 : 18,
                    color: accent,
                  ),
                ),
                if (subtitle != null && !compact) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 11,
                      color: ArcUiTokens.textTertiary,
                      isBold: true,
                    ).copyWith(height: 1.15),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(compact ? ArcUiTokens.gapM : ArcUiTokens.gapL),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        radius: ArcUiTokens.radiusL,
        accent: accent,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 44,
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Text(
            title,
            style: ArcUiTokens.sectionTitle(
              fontSize: compact ? 18 : 22,
              color: accent,
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            subtitle,
            style: ArcUiTokens.body(
              fontSize: compact ? 12 : 13,
              color: ArcUiTokens.textSecondary,
              weight: FontWeight.w600,
            ),
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
    this.accent = ArcUiTokens.primaryAccent,
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
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: radius,
        accent: accent,
        borderOpacity: 0.18,
      ),
      child: child,
    );
  }
}
