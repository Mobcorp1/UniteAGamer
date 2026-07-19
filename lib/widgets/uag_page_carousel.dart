import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class UagPageCarousel extends StatefulWidget {
  const UagPageCarousel({
    super.key,
    required this.pages,
    this.viewportFraction = 0.76,
    this.webViewportFraction = 0.46,
    this.tabletViewportFraction = 0.58,
    this.padEnds = true,
    this.controller,
    this.physics,
    this.onPageChanged,
    this.showIndicator = true,
    this.indicatorPadding = const EdgeInsets.only(bottom: AppTheme.spaceS),
    this.enableHaptics = true,
    this.enable3d = true,
    this.sideScale = 0.82,
    this.outerScale = 0.64,
    this.sideOpacity = 0.72,
    this.outerOpacity = 0.38,
    this.maxSideRotation = 0.24,
    this.maxSideLift = 18,
  });

  final List<Widget> pages;
  final double viewportFraction;
  final double webViewportFraction;
  final double tabletViewportFraction;
  final bool padEnds;
  final PageController? controller;
  final ScrollPhysics? physics;
  final ValueChanged<int>? onPageChanged;
  final bool showIndicator;
  final EdgeInsetsGeometry indicatorPadding;
  final bool enableHaptics;
  final bool enable3d;
  final double sideScale;
  final double outerScale;
  final double sideOpacity;
  final double outerOpacity;
  final double maxSideRotation;
  final double maxSideLift;

  @override
  State<UagPageCarousel> createState() => _UagPageCarouselState();
}

class _UagPageCarouselState extends State<UagPageCarousel> {
  PageController? _ownedController;
  double? _ownedViewportFraction;
  double _currentPage = 0;

  PageController get _controller {
    final supplied = widget.controller;
    if (supplied != null) return supplied;

    final viewportFraction = _ownedViewportFraction ?? widget.viewportFraction;
    return _ownedController ??= PageController(
      viewportFraction: viewportFraction,
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerTick);
  }

  @override
  void didUpdateWidget(covariant UagPageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerTick);
      widget.controller?.addListener(_handleControllerTick);
      _disposeOwnedController();
      _currentPage = 0;
    }

    if (oldWidget.viewportFraction != widget.viewportFraction ||
        oldWidget.webViewportFraction != widget.webViewportFraction ||
        oldWidget.tabletViewportFraction != widget.tabletViewportFraction) {
      _disposeOwnedController();
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerTick);
    _disposeOwnedController();
    super.dispose();
  }

  void _disposeOwnedController() {
    _ownedController?.dispose();
    _ownedController = null;
    _ownedViewportFraction = null;
  }

  void _handleControllerTick() {
    final controller = _controller;
    if (!controller.hasClients) return;

    final page = controller.page ?? controller.initialPage.toDouble();
    if ((page - _currentPage).abs() < 0.001) return;

    setState(() {
      _currentPage = page;
    });
  }

  void _handlePageChanged(int index) {
    if (_currentPage.round() != index && widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentPage = index.toDouble();
    });

    widget.onPageChanged?.call(index);
  }

  double _effectiveViewportFraction(double width) {
    if (!widget.enable3d) return widget.viewportFraction;
    if (width >= 1000) return widget.webViewportFraction;
    if (width >= 650) return widget.tabletViewportFraction;
    return widget.viewportFraction;
  }

  void _syncOwnedControllerForWidth(double width) {
    if (widget.controller != null) return;

    final nextViewportFraction = _effectiveViewportFraction(width);
    if (_ownedController != null &&
        _ownedViewportFraction == nextViewportFraction) {
      return;
    }

    final initialPage = _currentPage.round().clamp(0, widget.pages.length - 1);
    _disposeOwnedController();
    _ownedViewportFraction = nextViewportFraction;
    _ownedController = PageController(
      initialPage: initialPage,
      viewportFraction: nextViewportFraction,
    )..addListener(_handleControllerTick);
  }

  Widget _buildTransformedPage(BuildContext context, int index) {
    final delta = (_currentPage - index).clamp(-2.0, 2.0);
    final distance = delta.abs().clamp(0.0, 2.0);

    final scale = distance <= 1
        ? 1 - ((1 - widget.sideScale) * distance)
        : widget.sideScale -
              ((widget.sideScale - widget.outerScale) * (distance - 1));

    final opacity = distance <= 1
        ? 1 - ((1 - widget.sideOpacity) * distance)
        : widget.sideOpacity -
              ((widget.sideOpacity - widget.outerOpacity) * (distance - 1));

    final rotation = -delta * widget.maxSideRotation;
    final lift = distance * widget.maxSideLift;
    final translateX = delta * -14;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.pages[index],
      builder: (context, child) {
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(translateX, lift),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(rotation)
                ..scaleByDouble(scale, scale, scale, 1),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.pages.length == 1) {
      return widget.pages.first;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _syncOwnedControllerForWidth(constraints.maxWidth);

        return Column(
          children: [
            if (widget.showIndicator)
              Padding(
                padding: widget.indicatorPadding,
                child: _UagCarouselIndicator(
                  count: widget.pages.length,
                  currentIndex: _currentPage.round().clamp(
                    0,
                    widget.pages.length - 1,
                  ),
                  compact: widget.pages.length > 7,
                ),
              ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _controller,
                      padEnds: widget.padEnds,
                      physics: widget.physics ?? const BouncingScrollPhysics(),
                      onPageChanged: _handlePageChanged,
                      itemCount: widget.pages.length,
                      itemBuilder: widget.enable3d
                          ? _buildTransformedPage
                          : (context, index) => widget.pages[index],
                    ),
                  ),
                  if (constraints.maxWidth >= 900) ...[
                    Positioned(
                      left: 4,
                      child: _UagCarouselArrow(
                        icon: Icons.chevron_left_rounded,
                        enabled: _currentPage.round() > 0,
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: _UagCarouselArrow(
                        icon: Icons.chevron_right_rounded,
                        enabled: _currentPage.round() < widget.pages.length - 1,
                        onPressed: () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UagCarouselArrow extends StatelessWidget {
  const _UagCarouselArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: IconButton.filledTonal(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
          foregroundColor: AppTheme.neonCyan,
          disabledForegroundColor: Colors.white24,
          side: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: enabled ? 0.42 : 0.12),
          ),
        ),
      ),
    );
  }
}

class _UagCarouselIndicator extends StatelessWidget {
  const _UagCarouselIndicator({
    required this.count,
    required this.currentIndex,
    required this.compact,
  });

  final int count;
  final int currentIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dotSize = compact ? 5.0 : 7.0;
    final activeWidth = compact ? 18.0 : 22.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: active ? activeWidth : dotSize,
          height: dotSize,
          margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 3),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.42),
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
