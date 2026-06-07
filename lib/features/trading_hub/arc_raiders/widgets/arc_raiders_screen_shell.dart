import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
                  const Color(0xFF02030B),
                  Color.lerp(AppTheme.neonCyan, const Color(0xFF050612), 0.86)!,
                  const Color(0xFF010106),
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
                    AppTheme.neonCyan.withValues(alpha: 0.22),
                    AppTheme.neonPink.withValues(alpha: 0.10),
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
                    Colors.black.withValues(alpha: 0.32),
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
            child: Opacity(opacity: 0.30, child: StaticWatermark()),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ArcCommandGridPainter()),
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
        content,
      ],
    );
  }
}

class ArcRaidersResponsiveContent extends StatelessWidget {
  const ArcRaidersResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1160,
    this.padding = const EdgeInsets.fromLTRB(10, 6, 10, 10),
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
  });

  final Widget child;
  final double maxWidth;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    return ArcRaidersScreenShell(
      useSafeArea: useSafeArea,
      child: ArcRaidersResponsiveContent(maxWidth: maxWidth, child: child),
    );
  }
}

class ArcRaidersPageList extends StatelessWidget {
  const ArcRaidersPageList({
    super.key,
    required this.children,
    this.maxWidth = 1160,
    this.padding = const EdgeInsets.fromLTRB(10, 6, 10, 10),
    this.bottomPadding = 96,
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
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
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
          size: compact ? 19 : 22,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spaceS : AppTheme.spaceM,
        vertical: compact ? AppTheme.spaceXS : AppTheme.spaceS,
      ),
      decoration: AppTheme.tradingCardDecoration(
        radius: compact ? 16 : 18,
        borderColor: accent.withValues(alpha: 0.38),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
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
                    fontSize: compact ? 17 : 21,
                    color: accent,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    subtitle!,
                    maxLines: compact ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: compact ? 11.5 : 12.5,
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

class _ArcCommandGridPainter extends CustomPainter {
  const _ArcCommandGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.030)
      ..strokeWidth = 1;
    final heavyPaint = Paint()
      ..color = AppTheme.neonPink.withValues(alpha: 0.024)
      ..strokeWidth = 1.2;

    const smallStep = 32.0;
    const largeStep = 128.0;

    for (double x = 0; x <= size.width; x += smallStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += smallStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 0; x <= size.width; x += largeStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), heavyPaint);
    }
    for (double y = 0; y <= size.height; y += largeStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), heavyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcCommandGridPainter oldDelegate) => false;
}
