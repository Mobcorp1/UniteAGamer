// UAG ARC SHARED ARCHITECTURE LAYER
//
// This file is the official shared ARC Raiders screen architecture layer.
//
// LIVE RESPONSIBILITIES:
// - shared responsive page content helpers
// - shared page list spacing helpers
// - shared section/header/banner card foundations
// - per-screen ad-slot reservation
//
// GLOBAL BACKDROP OWNERSHIP:
// ArcGlobalVisualSystem is mounted once above the Navigator in main.dart and is
// the only normal owner of the cinematic/background layer. ArcRaidersScreenShell
// must not paint a second backdrop over it. This avoids the former doubled
// cinematic image, repeated watermark treatment and inconsistent page contrast.
//
// Keep blueprint grid rendering, portrait carousel logic, ownership/dupe logic,
// _buildGrid, and BlueprintTile structure isolated from architecture cleanup passes.
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

/// Compatibility wrapper for specialist routes/tests that intentionally need
/// direct access to the canonical background. Normal screens should rely on
/// ArcGlobalVisualSystem instead of mounting this themselves.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: content),
        if (shouldReserveAdSlot)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 76),
            child: ArcAdBannerCard(
              tier: adTier,
              showForTraderPro: showAdsForTraderPro,
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
    this.maxWidth = ArcLayoutTokens.standardContentWidth,
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
          child: SizedBox(width: double.infinity, child: child),
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
    this.maxWidth = ArcLayoutTokens.standardContentWidth,
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
    this.maxWidth = ArcLayoutTokens.standardContentWidth,
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
                  style: ArcUiTokens.pageTitle(
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
                    style: ArcUiTokens.body(
                      fontSize: 11,
                      color: ArcUiTokens.textTertiary,
                      weight: FontWeight.w600,
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
        borderOpacity: 0.34,
        glow: false,
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
    this.radius = ArcUiTokens.radiusXL,
    this.selected = false,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: radius,
        accent: accent,
        borderOpacity: 0.28,
        selected: selected,
        glow: selected,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class ArcTacticalStatusPill extends StatelessWidget {
  const ArcTacticalStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.accent = ArcUiTokens.primaryAccent,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: accent, selected: selected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.label(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class ArcTacticalStatTile extends StatelessWidget {
  const ArcTacticalStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent = ArcUiTokens.primaryAccent,
    this.minWidth = 132,
    this.maxWidth = 210,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accent;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.all(ArcUiTokens.gapM),
        decoration: ArcUiTokens.surfaceDecoration(
          role: ArcSurfaceRole.interactive,
          accent: accent,
          borderOpacity: 0.18,
          radius: ArcUiTokens.radiusM,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.label(),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.cardTitle(
                      fontSize: 15,
                      color: ArcUiTokens.textPrimary,
                    ),
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

class ArcRaidersStatePanel extends StatelessWidget {
  const ArcRaidersStatePanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.accent = ArcUiTokens.primaryAccent,
    this.action,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ArcRaidersSectionCard(
      accent: accent,
      padding: EdgeInsets.all(compact ? ArcUiTokens.gapM : ArcUiTokens.gapL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Icon(icon, color: accent, size: compact ? 18 : 22),
          ),
          const SizedBox(width: ArcUiTokens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ArcUiTokens.sectionTitle(
                    fontSize: compact ? 15 : 17,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: ArcUiTokens.body(
                    fontSize: compact ? 12 : 13,
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: ArcUiTokens.gapM),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
