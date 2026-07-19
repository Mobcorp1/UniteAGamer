import 'package:flutter/material.dart';

import 'arc_layout_system.dart';
import 'arc_responsive_chrome.dart';

class ArcResponsivePageShell extends StatelessWidget {
  const ArcResponsivePageShell({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.width = ArcPageWidth.standard,
    this.safeArea = true,
    this.scrollable = true,
    this.includeDockPadding = true,
    this.controller,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final ArcPageWidth width;
  final bool safeArea;
  final bool scrollable;
  final bool includeDockPadding;
  final ScrollController? controller;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ArcResponsiveChrome.isDesktop(context);
    final base = padding ?? ArcLayoutTokens.pagePadding(context);
    final resolvedPadding = base.copyWith(
      bottom: includeDockPadding
          ? ArcResponsiveChrome.bottomSafePadding(context)
          : base.bottom,
    );

    Widget content = Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              maxWidth ??
              ArcLayoutTokens.contentMaxWidth(context, width: width),
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );

    if (safeArea) content = SafeArea(child: content);
    if (!scrollable) return content;

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
  const ArcResponsiveSliverShell({
    super.key,
    required this.children,
    this.padding,
    this.maxWidth,
    this.width = ArcPageWidth.standard,
    this.includeDockPadding = true,
    this.controller,
  });

  final List<Widget> children;
  final EdgeInsets? padding;
  final double? maxWidth;
  final ArcPageWidth width;
  final bool includeDockPadding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final base = padding ?? ArcLayoutTokens.pagePadding(context);
    final resolvedPadding = base.copyWith(
      bottom: includeDockPadding
          ? ArcResponsiveChrome.bottomSafePadding(context)
          : base.bottom,
    );

    return SafeArea(
      child: Scrollbar(
        controller: controller,
        thumbVisibility: ArcResponsiveChrome.isDesktop(context),
        interactive: true,
        child: CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: resolvedPadding,
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          maxWidth ??
                          ArcLayoutTokens.contentMaxWidth(
                            context,
                            width: width,
                          ),
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
