import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

enum ArcPageBackgroundMode {
  solid,
  cinematic,
}

class ArcPageShell extends StatelessWidget {
  const ArcPageShell({
    super.key,
    required this.title,
    required this.body,
    required this.activeDockLabel,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.backgroundMode = ArcPageBackgroundMode.solid,
    this.cinematicAsset,
    this.cinematicAlignment = Alignment.center,
    this.showBottomDock = true,
    this.safeArea = true,
    this.maxContentWidth = 1180,
    this.contentPadding,
    this.extendBodyBehindHeader = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final String activeDockLabel;
  final Widget? leading;
  final List<Widget> actions;
  final ArcPageBackgroundMode backgroundMode;
  final String? cinematicAsset;
  final Alignment cinematicAlignment;
  final bool showBottomDock;
  final bool safeArea;
  final double maxContentWidth;
  final EdgeInsets? contentPadding;
  final bool extendBodyBehindHeader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArcUiTokens.background,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _ArcPageBackground(
            mode: backgroundMode,
            cinematicAsset: cinematicAsset,
            cinematicAlignment: cinematicAlignment,
          ),
          _ArcAmbientLighting(mode: backgroundMode),
          _buildForeground(context),
        ],
      ),
      bottomNavigationBar: showBottomDock
          ? ArcCompanionBottomDock(activeLabel: activeDockLabel)
          : null,
    );
  }

  Widget _buildForeground(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final desktop = width >= 900;
    final horizontal = desktop ? 24.0 : 12.0;
    final resolvedPadding = contentPadding ??
        EdgeInsets.fromLTRB(
          horizontal,
          extendBodyBehindHeader ? 8 : 12,
          horizontal,
          showBottomDock ? 16 : 20,
        );

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Column(
          children: <Widget>[
            if (!extendBodyBehindHeader)
              _ArcPageHeader(
                title: title,
                subtitle: subtitle,
                leading: leading,
                actions: actions,
              ),
            Expanded(
              child: Padding(
                padding: resolvedPadding,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );

    return safeArea ? SafeArea(bottom: false, child: content) : content;
  }
}

class ArcSectionPanel extends StatelessWidget {
  const ArcSectionPanel({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(12),
    this.radius = ArcUiTokens.radiusL,
    this.selected = false,
    this.glow = false,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsets padding;
  final double radius;
  final bool selected;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: accent,
        radius: radius,
        borderOpacity: accent == null ? 0.18 : 0.32,
        selected: selected,
        glow: glow,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class ArcSectionHeader extends StatelessWidget {
  const ArcSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 3,
          height: subtitle == null ? 22 : 34,
          margin: const EdgeInsets.only(right: 10, top: 1),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 0.4,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: ArcUiTokens.sectionTitle()),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(subtitle!, style: ArcUiTokens.bodySmall()),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class _ArcPageHeader extends StatelessWidget {
  const _ArcPageHeader({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: EdgeInsets.fromLTRB(desktop ? 20 : 10, 8, desktop ? 20 : 10, 8),
      decoration: BoxDecoration(
        color: ArcUiTokens.background.withValues(alpha: 0.78),
        border: Border(
          bottom: BorderSide(
            color: ArcUiTokens.primaryAccent.withValues(alpha: 0.20),
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ArcUiTokens.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.pageTitle(
                    fontSize: desktop ? 20 : 17,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.bodySmall(
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final action in actions) ...<Widget>[
            const SizedBox(width: 6),
            action,
          ],
        ],
      ),
    );
  }
}

class _ArcPageBackground extends StatelessWidget {
  const _ArcPageBackground({
    required this.mode,
    required this.cinematicAsset,
    required this.cinematicAlignment,
  });

  final ArcPageBackgroundMode mode;
  final String? cinematicAsset;
  final Alignment cinematicAlignment;

  @override
  Widget build(BuildContext context) {
    if (mode == ArcPageBackgroundMode.cinematic && cinematicAsset != null) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            cinematicAsset!,
            fit: BoxFit.cover,
            alignment: cinematicAlignment,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x6602060A),
                  Color(0xB303060A),
                  Color(0xF203060A),
                ],
                stops: <double>[0, 0.58, 1],
              ),
            ),
          ),
        ],
      );
    }

    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF061018),
            Color(0xFF03070B),
            Color(0xFF020406),
          ],
        ),
      ),
    );
  }
}

class _ArcAmbientLighting extends StatelessWidget {
  const _ArcAmbientLighting({required this.mode});

  final ArcPageBackgroundMode mode;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(
            alignment: const Alignment(0.0, -1.15),
            child: Container(
              width: 520,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: ArcUiTokens.primaryAccent.withValues(
                      alpha: mode == ArcPageBackgroundMode.cinematic ? 0.10 : 0.15,
                    ),
                    blurRadius: 120,
                    spreadRadius: 26,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(1.15, -0.15),
            child: Container(
              width: 280,
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.10),
                    blurRadius: 140,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
