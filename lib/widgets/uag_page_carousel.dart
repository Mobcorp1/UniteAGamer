import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class UagPageCarousel extends StatefulWidget {
  const UagPageCarousel({
    super.key,
    required this.pages,
    this.viewportFraction = 0.92,
    this.padEnds = false,
    this.controller,
    this.physics,
    this.onPageChanged,
    this.showIndicator = true,
    this.indicatorPadding = const EdgeInsets.only(bottom: AppTheme.spaceS),
    this.enableHaptics = true,
  });

  final List<Widget> pages;
  final double viewportFraction;
  final bool padEnds;
  final PageController? controller;
  final ScrollPhysics? physics;
  final ValueChanged<int>? onPageChanged;
  final bool showIndicator;
  final EdgeInsetsGeometry indicatorPadding;
  final bool enableHaptics;

  @override
  State<UagPageCarousel> createState() => _UagPageCarouselState();
}

class _UagPageCarouselState extends State<UagPageCarousel> {
  PageController? _ownedController;
  int _currentPage = 0;

  PageController get _controller {
    final supplied = widget.controller;
    if (supplied != null) return supplied;

    return _ownedController ??= PageController(
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant UagPageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller ||
        oldWidget.viewportFraction != widget.viewportFraction) {
      _ownedController?.dispose();
      _ownedController = null;
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    if (_currentPage != index && widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentPage = index;
    });

    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.pages.length == 1) {
      return widget.pages.first;
    }

    return Column(
      children: [
        if (widget.showIndicator)
          Padding(
            padding: widget.indicatorPadding,
            child: _UagCarouselIndicator(
              count: widget.pages.length,
              currentIndex: _currentPage.clamp(0, widget.pages.length - 1),
            ),
          ),
        Expanded(
          child: PageView(
            controller: _controller,
            padEnds: widget.padEnds,
            physics: widget.physics ?? const BouncingScrollPhysics(),
            onPageChanged: _handlePageChanged,
            children: widget.pages,
          ),
        ),
      ],
    );
  }
}

class _UagCarouselIndicator extends StatelessWidget {
  const _UagCarouselIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: active ? 22 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      }),
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
      physics: const BouncingScrollPhysics(),
      children: [
        ...children,
        SizedBox(height: trailingGap),
      ],
    );
  }
}
