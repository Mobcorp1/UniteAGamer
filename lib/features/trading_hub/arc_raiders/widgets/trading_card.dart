import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingCard extends StatelessWidget {
  const TradingCard({
    super.key,
    required this.child,
    this.onTap,
    this.trailing,
    this.accent,
    this.padding = AppTheme.sectionCardPadding,
    this.margin,
    this.radius = 16,
    this.selected = false,
    this.compact = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? (accent ?? AppTheme.neonCyan).withValues(alpha: 0.54)
        : (accent?.withValues(alpha: 0.24) ?? AppTheme.tradingCardBorder);

    final content = Container(
      width: double.infinity,
      margin: margin,
      padding: compact ? const EdgeInsets.all(AppTheme.spaceM) : padding,
      decoration: AppTheme.tradingCardDecoration(
        radius: radius,
        borderColor: borderColor,
        backgroundColor: selected
            ? AppTheme.cardBackgroundAlt.withValues(alpha: 0.94)
            : null,
      ),
      child: trailing == null
          ? child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                const SizedBox(width: AppTheme.spaceM),
                trailing!,
              ],
            ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
