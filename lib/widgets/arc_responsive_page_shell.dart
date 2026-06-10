import 'package:flutter/material.dart';
import 'arc_responsive_chrome.dart';

import 'responsive_layout_helper.dart';
import 'theme.dart';

class ArcResponsivePageShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool safeArea;
  final bool scrollable;
  final bool includeDockPadding;
  final ScrollController? controller;
  final Alignment alignment;

  const ArcResponsivePageShell({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.safeArea = true,
    this.scrollable = true,
    this.includeDockPadding = true,
    this.controller,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayoutHelper.isDesktop(context);

    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          ResponsiveLayoutHelper.horizontalPadding(context),
          isDesktop ? AppTheme.spaceM : AppTheme.spaceS,
          ResponsiveLayoutHelper.horizontalPadding(context),
          includeDockPadding ? (isDesktop ? 112 : 118) : AppTheme.spaceL,
        );

    Widget content = Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveLayoutHelper.maxContentWidth(context),
        ),
        child: Padding(
          padding: resolvedPadding.copyWith(
            bottom: ArcResponsiveChrome.bottomSafePadding(context),
          ),
          child: child,
        ),
      ),
    );

    if (safeArea) {
      content = SafeArea(child: content);
    }

    if (!scrollable) {
      return content;
    }

    return Scrollbar(
      controller: controller,
      thumbVisibility: isDesktop,
      interactive: true,
      child: SingleChildScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      ),
    );
  }
}

class ArcResponsiveSliverShell extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool includeDockPadding;
  final ScrollController? controller;

  const ArcResponsiveSliverShell({
    super.key,
    required this.children,
    this.padding,
    this.maxWidth,
    this.includeDockPadding = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayoutHelper.isDesktop(context);
    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          ResponsiveLayoutHelper.horizontalPadding(context),
          isDesktop ? AppTheme.spaceM : AppTheme.spaceS,
          ResponsiveLayoutHelper.horizontalPadding(context),
          includeDockPadding ? (isDesktop ? 112 : 118) : AppTheme.spaceL,
        );

    return SafeArea(
      child: Scrollbar(
        controller: controller,
        thumbVisibility: isDesktop,
        interactive: true,
        child: CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: resolvedPadding.copyWith(
                bottom: ArcResponsiveChrome.bottomSafePadding(context),
              ),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          maxWidth ??
                          ResponsiveLayoutHelper.maxContentWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
