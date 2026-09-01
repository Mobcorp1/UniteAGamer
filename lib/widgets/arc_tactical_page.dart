import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_responsive_page_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcTacticalPageBody extends StatelessWidget {
  const ArcTacticalPageBody({
    super.key,
    required this.child,
    this.width = ArcPageWidth.standard,
    this.maxWidth,
    this.padding,
    this.scrollable = true,
    this.safeArea = true,
    this.includeDockPadding = false,
    this.showAdBanner = false,
    this.controller,
  });

  final Widget child;
  final ArcPageWidth width;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool scrollable;
  final bool safeArea;
  final bool includeDockPadding;
  final bool showAdBanner;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ArcRaidersScreenShell(
      showAdBanner: showAdBanner,
      useSafeArea: false,
      child: ArcResponsivePageShell(
        width: width,
        maxWidth: maxWidth,
        padding: padding,
        scrollable: scrollable,
        safeArea: safeArea,
        includeDockPadding: includeDockPadding,
        controller: controller,
        child: child,
      ),
    );
  }
}

class ArcTacticalPageList extends StatelessWidget {
  const ArcTacticalPageList({
    super.key,
    required this.children,
    this.width = ArcPageWidth.standard,
    this.maxWidth,
    this.padding,
    this.spacing,
    this.includeDockPadding = false,
    this.showAdBanner = false,
  });

  final List<Widget> children;
  final ArcPageWidth width;
  final double? maxWidth;
  final EdgeInsets? padding;
  final double? spacing;
  final bool includeDockPadding;
  final bool showAdBanner;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? ArcLayoutTokens.sectionGap(context);
    return ArcTacticalPageBody(
      width: width,
      maxWidth: maxWidth,
      padding: padding,
      includeDockPadding: includeDockPadding,
      showAdBanner: showAdBanner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) SizedBox(height: gap),
            children[index],
          ],
        ],
      ),
    );
  }
}

class ArcTacticalPanel extends StatelessWidget {
  const ArcTacticalPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.accent = ArcUiTokens.primaryAccent,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Color accent;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Container(
      padding:
          padding ??
          EdgeInsets.all(compact ? ArcUiTokens.gapM : ArcUiTokens.gapL),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusL,
        accent: accent,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null || trailing != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accent, size: compact ? 20 : 22),
                  const SizedBox(width: ArcUiTokens.gapS),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: ArcUiTokens.sectionTitle(
                            fontSize: compact ? 15 : 17,
                            color: accent,
                          ),
                        ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: ArcUiTokens.gapXS),
                        Text(
                          subtitle!,
                          style: ArcUiTokens.bodySmall(
                            color: ArcUiTokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: ArcUiTokens.gapS),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: ArcUiTokens.gapM),
          ],
          child,
        ],
      ),
    );
  }
}

class ArcTacticalStatePanel extends StatelessWidget {
  const ArcTacticalStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.accent = ArcUiTokens.primaryAccent,
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
        child: ArcTacticalPanel(
          icon: icon,
          title: title,
          accent: accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: ArcUiTokens.textSecondary,
                ).copyWith(height: 1.35),
              ),
              if (action != null) ...[
                const SizedBox(height: ArcUiTokens.gapL),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
