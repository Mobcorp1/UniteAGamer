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
        const Positioned.fill(
          child: IgnorePointer(
            child: Opacity(opacity: 0.30, child: StaticWatermark()),
          ),
        ),
      ],
    );
  }
}

class ArcRaidersScreenShell extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const ArcRaidersScreenShell({
    super.key,
    required this.child,
    this.useSafeArea = false,
  });

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
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 28,
        borderColor: accent.withValues(alpha: 0.32),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
                border: Border.all(color: accent.withValues(alpha: 0.34)),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: AppTheme.spaceM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.tradingHeading(fontSize: 24, color: accent),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    subtitle!,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      isBold: true,
                    ).copyWith(height: 1.30),
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
