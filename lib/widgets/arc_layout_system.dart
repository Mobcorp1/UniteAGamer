import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

/// Canonical responsive layout tokens used by every user and admin surface.
class ArcLayoutTokens {
  const ArcLayoutTokens._();

  static const double compactBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double wideDesktopBreakpoint = 1600;

  static const double compactContentWidth = 720;
  static const double formContentWidth = 760;
  static const double standardContentWidth = 1180;
  static const double wideContentWidth = 1480;

  static double contentMaxWidth(
    BuildContext context, {
    ArcPageWidth width = ArcPageWidth.standard,
  }) {
    return switch (width) {
      ArcPageWidth.compact => compactContentWidth,
      ArcPageWidth.form => formContentWidth,
      ArcPageWidth.standard => standardContentWidth,
      ArcPageWidth.wide => wideContentWidth,
      ArcPageWidth.fluid => MediaQuery.sizeOf(context).width,
    };
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    if (width >= wideDesktopBreakpoint) {
      return const EdgeInsets.fromLTRB(28, 20, 28, 24);
    }
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.fromLTRB(22, 18, 22, 22);
    }
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.fromLTRB(18, 16, 18, 20);
    }
    if (width >= compactBreakpoint) {
      return const EdgeInsets.fromLTRB(14, 12, 14, 18);
    }
    return EdgeInsets.fromLTRB(12, height < 700 ? 8 : 10, 12, 16);
  }

  static double sectionGap(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint ? 20 : 14;
  }

  static double cardGap(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint ? 16 : 10;
  }

  static int columns(
    BuildContext context, {
    int compact = 1,
    int tablet = 2,
    int desktop = 3,
    int wide = 4,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideDesktopBreakpoint) return wide;
    if (width >= desktopBreakpoint) return desktop;
    if (width >= tabletBreakpoint) return tablet;
    return compact;
  }
}

enum ArcPageWidth { compact, form, standard, wide, fluid }

/// Standard content viewport used by full-screen user and admin routes.
class ArcPageViewport extends StatelessWidget {
  const ArcPageViewport({
    super.key,
    required this.child,
    this.width = ArcPageWidth.standard,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final ArcPageWidth width;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ArcLayoutTokens.contentMaxWidth(context, width: width),
        ),
        child: Padding(
          padding: padding ?? ArcLayoutTokens.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// Standard page heading with responsive trailing actions.
class ArcPageHeader extends StatelessWidget {
  const ArcPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const [],
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.titleTextStyle(
            fontSize: compact ? 22 : 28,
            color: accent,
            isBold: true,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: compact ? 13 : 14,
              color: Colors.white70,
            ).copyWith(height: 1.25),
          ),
        ],
      ],
    );

    if (compact && trailing.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(child: titleBlock),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: trailing),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: titleBlock),
        if (trailing.isNotEmpty) ...[
          const SizedBox(width: 12),
          Wrap(spacing: 8, runSpacing: 8, children: trailing),
        ],
      ],
    );
  }
}

class ArcSection extends StatelessWidget {
  const ArcSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AppTheme.spaceL),
    this.accent = AppTheme.neonCyan,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || trailing != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: AppTheme.titleTextStyle(
                              fontSize: 18,
                              color: accent,
                              isBold: true,
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                  ],
                ],
              ),
            if (title != null || subtitle != null || trailing != null)
              const SizedBox(height: AppTheme.spaceM),
            child,
          ],
        ),
      ),
    );
  }
}

/// Canonical responsive grid that prevents oversized single-column desktop cards.
class ArcAdaptiveGrid extends StatelessWidget {
  const ArcAdaptiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 280,
    this.maxColumns = 4,
    this.spacing,
    this.runSpacing,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = spacing ?? ArcLayoutTokens.cardGap(context);
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final count = ((available + gap) / (minTileWidth + gap)).floor().clamp(
          1,
          maxColumns,
        );
        final tileWidth = (available - gap * (count - 1)) / count;

        return Wrap(
          spacing: gap,
          runSpacing: runSpacing ?? gap,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class ArcResponsiveSplitPane extends StatelessWidget {
  const ArcResponsiveSplitPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 7,
    this.secondaryFlex = 5,
    this.breakpoint = ArcLayoutTokens.tabletBreakpoint,
    this.spacing,
    this.primaryFirstOnCompact = true,
  });

  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double breakpoint;
  final double? spacing;
  final bool primaryFirstOnCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = spacing ?? ArcLayoutTokens.cardGap(context);
        final wide = constraints.maxWidth >= breakpoint;
        if (!wide) {
          final children = primaryFirstOnCompact
              ? [primary, SizedBox(height: gap), secondary]
              : [secondary, SizedBox(height: gap), primary];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: gap),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

class ArcFormGrid extends StatelessWidget {
  const ArcFormGrid({
    super.key,
    required this.children,
    this.minFieldWidth = 300,
    this.spacing,
    this.runSpacing,
  });

  final List<Widget> children;
  final double minFieldWidth;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    return ArcAdaptiveGrid(
      minTileWidth: minFieldWidth,
      maxColumns: 2,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}

class ArcActionSurface extends StatelessWidget {
  const ArcActionSurface({
    super.key,
    required this.child,
    this.active = false,
    this.onTap,
    this.accent = AppTheme.neonCyan,
  });

  final Widget child;
  final bool active;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final surface = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: AnimatedContainer(
          duration: AppTheme.fastAnimation,
          padding: const EdgeInsets.all(AppTheme.spaceL),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: accent.withValues(alpha: active ? 0.82 : 0.30),
              width: active ? 1.6 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ElectricChargeBorder(
      active: active && !disableAnimations,
      radius: AppTheme.cardRadius,
      child: surface,
    );
  }
}

class ArcStatePanel extends StatelessWidget {
  const ArcStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.accent = AppTheme.neonCyan,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ArcSection(
          accent: accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.titleTextStyle(
                  fontSize: 20,
                  color: accent,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}
