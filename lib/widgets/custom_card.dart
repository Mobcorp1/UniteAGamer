import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final EdgeInsets padding;
  final bool pulse;

  const CustomCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
    this.pulse = true,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _borderAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _borderAnimation = ColorTween(
      begin: AppTheme.cardPulseStartColor,
      end: AppTheme.cardPulseEndColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.96,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CustomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _outerBorderColor => widget.pulse
      ? (_borderAnimation.value ?? AppTheme.cardPulseStartColor)
      : AppTheme.cardPulseStartColor;

  double get _glowStrength => widget.pulse ? _glowAnimation.value : 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final outerColor = _outerBorderColor;
        final glowStrength = _glowStrength;

        return RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: outerColor.withValues(alpha: widget.pulse ? 0.92 : 0.78),
                width: AppTheme.cardOuterBorderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: outerColor.withValues(alpha: 0.16 * glowStrength),
                  blurRadius: 12,
                  spreadRadius: 0.6,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(AppTheme.cardOuterGap),
              decoration: BoxDecoration(
                color: AppTheme.cardFillColor,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius - 3),
                border: Border.all(
                  color: AppTheme.cardInnerBorderColor,
                  width: AppTheme.cardInnerBorderWidth,
                ),
              ),
              child: Padding(
                padding: widget.padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null) ...[
                      Text(
                        widget.title!,
                        textAlign: TextAlign.left,
                        style: AppTheme.titleTextStyle(
                          fontSize: 20,
                          color: AppTheme.neonCyan,
                          isBold: true,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                    ],
                    widget.child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
