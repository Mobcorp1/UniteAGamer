import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class UagAdaptiveCardDeck extends StatefulWidget {
  const UagAdaptiveCardDeck({
    super.key,
    required this.cards,
    required this.height,
    this.phonePortraitBreakpoint = 700,
    this.horizontalPhoneViewportFraction = 0.82,
    this.tabletViewportFraction = 0.48,
    this.desktopViewportFraction = 0.34,
    this.verticalViewportFraction = 0.72,
    this.showHint = true,
    this.onPageChanged,
  });

  final List<Widget> cards;
  final double height;
  final double phonePortraitBreakpoint;
  final double horizontalPhoneViewportFraction;
  final double tabletViewportFraction;
  final double desktopViewportFraction;
  final double verticalViewportFraction;
  final bool showHint;
  final ValueChanged<int>? onPageChanged;

  @override
  State<UagAdaptiveCardDeck> createState() => _UagAdaptiveCardDeckState();
}

class _UagAdaptiveCardDeckState extends State<UagAdaptiveCardDeck> {
  PageController? _controller;
  Axis? _axis;
  double? _viewportFraction;
  int _activeIndex = 0;

  bool _usesVerticalBarrel(BuildContext context) {
    final media = MediaQuery.of(context);
    return media.orientation == Orientation.portrait &&
        media.size.width < widget.phonePortraitBreakpoint;
  }

  double _resolveViewportFraction(BuildContext context, Axis axis) {
    if (axis == Axis.vertical) return widget.verticalViewportFraction;
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return widget.desktopViewportFraction;
    if (width >= 700) return widget.tabletViewportFraction;
    return widget.horizontalPhoneViewportFraction;
  }

  void _syncController(BuildContext context) {
    final nextAxis = _usesVerticalBarrel(context)
        ? Axis.vertical
        : Axis.horizontal;
    final nextFraction = _resolveViewportFraction(context, nextAxis);

    if (_controller != null &&
        _axis == nextAxis &&
        _viewportFraction == nextFraction) {
      return;
    }

    final initialPage = widget.cards.isEmpty
        ? 0
        : _activeIndex.clamp(0, widget.cards.length - 1).toInt();
    _controller?.dispose();
    _axis = nextAxis;
    _viewportFraction = nextFraction;
    _controller = PageController(
      initialPage: initialPage,
      viewportFraction: nextFraction,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController(context);
  }

  @override
  void didUpdateWidget(covariant UagAdaptiveCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.isEmpty) {
      _activeIndex = 0;
    } else if (_activeIndex >= widget.cards.length) {
      _activeIndex = widget.cards.length - 1;
    }
    _syncController(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    final controller = _controller;
    if (controller == null || widget.cards.isEmpty) return;
    final target = index.clamp(0, widget.cards.length - 1).toInt();
    await controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index != _activeIndex) HapticFeedback.selectionClick();
    setState(() => _activeIndex = index);
    widget.onPageChanged?.call(index);
  }

  Widget _buildCard(int index, Axis axis) {
    final selected = index == _activeIndex;
    final distance = (index - _activeIndex).abs().clamp(0, 2);
    final scale = selected ? 1.0 : (distance == 1 ? 0.92 : 0.84);
    final opacity = selected ? 1.0 : (distance == 1 ? 0.62 : 0.34);
    final angle = selected ? 0.0 : (index < _activeIndex ? -0.16 : 0.16);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: scale,
        child: Padding(
          padding: axis == Axis.vertical
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
              : const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(axis == Axis.vertical ? angle : 0)
              ..rotateY(axis == Axis.horizontal ? -angle : 0),
            child: widget.cards[index],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    if (widget.cards.length == 1) return widget.cards.first;

    _syncController(context);
    final axis = _axis ?? Axis.horizontal;
    final vertical = axis == Axis.vertical;
    final controller = _controller!;
    final canGoBack = _activeIndex > 0;
    final canGoForward = _activeIndex < widget.cards.length - 1;
    final deckHeight = vertical
        ? math.max(widget.height + 74, 250).toDouble()
        : widget.height;

    final pageView = ScrollConfiguration(
      behavior: const _UagAdaptiveDeckScrollBehavior(),
      child: PageView.builder(
        controller: controller,
        scrollDirection: axis,
        padEnds: true,
        physics: const PageScrollPhysics(),
        itemCount: widget.cards.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => _buildCard(index, axis),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: deckHeight,
          child: vertical
              ? Column(
                  children: [
                    _DeckArrow(
                      icon: Icons.keyboard_arrow_up_rounded,
                      tooltip: 'Previous card',
                      enabled: canGoBack,
                      onPressed: () => _goTo(_activeIndex - 1),
                    ),
                    Expanded(child: pageView),
                    _DeckArrow(
                      icon: Icons.keyboard_arrow_down_rounded,
                      tooltip: 'Next card',
                      enabled: canGoForward,
                      onPressed: () => _goTo(_activeIndex + 1),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _DeckArrow(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Previous card',
                      enabled: canGoBack,
                      onPressed: () => _goTo(_activeIndex - 1),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: pageView),
                    const SizedBox(width: 4),
                    _DeckArrow(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Next card',
                      enabled: canGoForward,
                      onPressed: () => _goTo(_activeIndex + 1),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        _DeckIndicator(
          count: widget.cards.length,
          selectedIndex: _activeIndex,
          onSelected: _goTo,
        ),
        if (widget.showHint) ...[
          const SizedBox(height: 5),
          Text(
            vertical
                ? 'Swipe up or down, or use the arrows'
                : 'Swipe, drag or use the arrows',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _DeckArrow extends StatelessWidget {
  const _DeckArrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? AppTheme.neonCyan.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        side: BorderSide(
          color: enabled
              ? AppTheme.neonCyan.withValues(alpha: 0.52)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      icon: Icon(
        icon,
        color: enabled ? AppTheme.neonCyan : Colors.white24,
        size: 30,
      ),
    );
  }
}

class _DeckIndicator extends StatelessWidget {
  const _DeckIndicator({
    required this.count,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int count;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.neonCyan
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.38),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _UagAdaptiveDeckScrollBehavior extends MaterialScrollBehavior {
  const _UagAdaptiveDeckScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
