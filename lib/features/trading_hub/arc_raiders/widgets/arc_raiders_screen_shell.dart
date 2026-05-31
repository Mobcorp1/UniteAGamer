import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRaidersScreenBackdrop extends StatelessWidget {
  const ArcRaidersScreenBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF040514),
                  Color.lerp(AppTheme.neonCyan, const Color(0xFF050612), 0.86)!,
                  const Color(0xFF020208),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.18),
                    AppTheme.neonPink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  center: const Alignment(0.0, -0.36),
                  radius: 0.92,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.20),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: Opacity(opacity: 0.24, child: StaticWatermark()),
          ),
        ),
      ],
    );
  }
}

class ArcRaidersScreenShell extends StatelessWidget {
  const ArcRaidersScreenShell({
    super.key,
    required this.child,
    this.useSafeArea = false,
  });

  final Widget child;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: child) : child;

    return Stack(
      children: [
        const Positioned.fill(child: ArcRaidersScreenBackdrop()),
        content,
      ],
    );
  }
}

class ArcRaidersResponsiveContent extends StatelessWidget {
  const ArcRaidersResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 920,
    this.padding = AppTheme.pagePadding,
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

class ArcRaidersPageList extends StatelessWidget {
  const ArcRaidersPageList({
    super.key,
    required this.children,
    this.maxWidth = 920,
    this.padding = AppTheme.pagePadding,
    this.bottomPadding = 112,
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
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(
            icon ?? Icons.dashboard_rounded,
            color: accent,
            size: compact ? 26 : 30,
          ),
        );
      }

      return Container(
        width: compact ? 40 : 46,
        height: compact ? 40 : 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
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
          size: compact ? 22 : 24,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(compact ? AppTheme.spaceM : AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: compact ? 24 : 28,
        borderColor: accent.withValues(alpha: 0.32),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.84),
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
                    fontSize: compact ? 20 : 24,
                    color: accent,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    subtitle!,
                    maxLines: compact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: compact ? 12 : 13,
                      color: Colors.white70,
                      isBold: true,
                    ).copyWith(height: 1.30),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spaceM),
            trailing!,
          ],
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
    this.padding = const EdgeInsets.all(AppTheme.spaceL),
    this.radius = 26,
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
        borderColor: accent.withValues(alpha: 0.24),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
      ),
      child: child,
    );
  }
}

class ArcRaidersFilterPanel extends StatelessWidget {
  const ArcRaidersFilterPanel({
    super.key,
    required this.child,
    this.accent = AppTheme.neonCyan,
  });

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcRaidersSectionCard(
      accent: accent,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      radius: 22,
      child: child,
    );
  }
}

class ArcRaidersProgressPanel extends StatelessWidget {
  const ArcRaidersProgressPanel({
    super.key,
    required this.title,
    required this.summary,
    required this.progress,
    this.accent = AppTheme.neonCyan,
    this.onClose,
  });

  final String title;
  final String summary;
  final double progress;
  final Color accent;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return ArcRaidersSectionCard(
      accent: accent,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: accent, size: 24),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.tradingHeading(fontSize: 20, color: accent),
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
