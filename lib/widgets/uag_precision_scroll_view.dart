import 'package:flutter/material.dart';

class UagPrecisionScrollView extends StatefulWidget {
  const UagPrecisionScrollView({
    super.key,
    required this.children,
    this.padding,
    this.scrollScale = 0.5,
    this.showScrollbar = false,
    this.scrollbarThickness = 8,
  }) : assert(scrollScale > 0 && scrollScale <= 1);

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double scrollScale;
  final bool showScrollbar;
  final double scrollbarThickness;

  @override
  State<UagPrecisionScrollView> createState() => _UagPrecisionScrollViewState();
}

class _UagPrecisionScrollViewState extends State<UagPrecisionScrollView> {
  late final _UagPrecisionScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _UagPrecisionScrollController(
      pointerScale: widget.scrollScale,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      controller: _controller,
      padding: widget.padding,
      physics: _UagPrecisionScrollPhysics(
        userOffsetScale: widget.scrollScale,
        parent: const ClampingScrollPhysics(),
      ),
      children: widget.children,
    );

    if (!widget.showScrollbar) return list;

    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: widget.scrollbarThickness,
      radius: const Radius.circular(8),
      child: list,
    );
  }
}

class _UagPrecisionScrollController extends ScrollController {
  _UagPrecisionScrollController({required this.pointerScale});

  final double pointerScale;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _UagPrecisionScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
      pointerScale: pointerScale,
    );
  }
}

class _UagPrecisionScrollPosition extends ScrollPositionWithSingleContext {
  _UagPrecisionScrollPosition({
    required super.physics,
    required super.context,
    required this.pointerScale,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final double pointerScale;

  @override
  void pointerScroll(double delta) {
    super.pointerScroll(delta * pointerScale);
  }
}

class _UagPrecisionScrollPhysics extends ScrollPhysics {
  const _UagPrecisionScrollPhysics({
    required this.userOffsetScale,
    super.parent,
  });

  final double userOffsetScale;

  @override
  _UagPrecisionScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _UagPrecisionScrollPhysics(
      userOffsetScale: userOffsetScale,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset) * userOffsetScale;
  }
}
