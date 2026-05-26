import 'package:flutter/material.dart';

import 'theme.dart';

class UagPageCarousel extends StatelessWidget {
  const UagPageCarousel({
    super.key,
    required this.pages,
    this.viewportFraction = 0.92,
    this.padEnds = false,
    this.controller,
    this.physics,
    this.onPageChanged,
  });

  final List<Widget> pages;
  final double viewportFraction;
  final bool padEnds;
  final PageController? controller;
  final ScrollPhysics? physics;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }

    final pageController =
        controller ?? PageController(viewportFraction: viewportFraction);

    return PageView(
      controller: pageController,
      padEnds: padEnds,
      physics: physics,
      onPageChanged: onPageChanged,
      children: pages,
    );
  }
}

class UagCarouselPage extends StatelessWidget {
  const UagCarouselPage({
    super.key,
    required this.children,
    this.padding,
    this.trailingGap = AppTheme.spaceL,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double trailingGap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ?? AppTheme.pagePadding,
      children: [
        ...children,
        SizedBox(height: trailingGap),
      ],
    );
  }
}
