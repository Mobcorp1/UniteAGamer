import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class DoseSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? titleColor;
  final Color? backgroundColor;

  const DoseSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.padding,
    this.margin,
    this.borderColor,
    this.titleColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? AppTheme.sectionCardPadding;
    final resolvedBorder = AppTheme.sectionCardBorder(borderColor);
    final resolvedTitle = AppTheme.sectionCardTitle(titleColor);
    final resolvedBackground = AppTheme.sectionCardBackground(backgroundColor);

    final card = Container(
      width: double.infinity,
      padding: resolvedPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        color: resolvedBackground,
        border: Border.all(
          color: resolvedBorder,
          width: AppTheme.cardBorderWidth,
        ),
        boxShadow: AppTheme.dualOutlineGlow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: resolvedTitle, size: 20),
                const SizedBox(width: AppTheme.spaceS),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.neonTextStyle(
                    fontSize: 24,
                    color: resolvedTitle,
                    isBold: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
    );

    if (margin == null) {
      return card;
    }

    return Padding(padding: margin!, child: card);
  }
}
