import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

enum DoseActionButtonVariant { primary, secondary, danger }

class DoseActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DoseActionButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool expand;

  const DoseActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DoseActionButtonVariant.primary,
    this.padding,
    this.borderRadius,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = _variantColors(variant, enabled);
    final resolvedPadding = padding ?? AppTheme.buttonPadding;
    final resolvedRadius = borderRadius ?? AppTheme.buttonRadius;
    final innerRadius = (resolvedRadius - 2).clamp(0.0, resolvedRadius);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colors.text),
          const SizedBox(width: 6),
        ],
        if (expand)
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.buttonTextStyle(color: colors.text, fontSize: 16),
            ),
          )
        else
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.buttonTextStyle(color: colors.text, fontSize: 16),
          ),
      ],
    );

    final button = AnimatedContainer(
      duration: AppTheme.fastAnimation,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedRadius),
        color: colors.fill,
        border: Border.all(
          color: colors.border,
          width: AppTheme.buttonBorderWidth,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: colors.glow,
                  blurRadius: AppTheme.glowMedium + 2,
                  spreadRadius: 0.45,
                ),
              ]
            : const [],
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(innerRadius),
          border: Border.all(color: colors.innerBorder, width: 0.9),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.topFill, colors.bottomFill],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: enabled ? 0.12 : 0.04),
                        Colors.white.withValues(alpha: enabled ? 0.04 : 0.01),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.28, 0.65],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 1,
              left: 8,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(
                      alpha: enabled ? 0.18 : 0.05,
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(innerRadius),
                onTap: onPressed,
                splashColor: colors.border.withValues(
                  alpha: enabled ? 0.14 : 0.04,
                ),
                highlightColor: colors.border.withValues(
                  alpha: enabled ? 0.08 : 0.02,
                ),
                child: Padding(padding: resolvedPadding, child: content),
              ),
            ),
          ],
        ),
      ),
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }

  _DoseActionButtonColors _variantColors(
    DoseActionButtonVariant variant,
    bool enabled,
  ) {
    switch (variant) {
      case DoseActionButtonVariant.secondary:
        return _DoseActionButtonColors(
          border: AppTheme.secondaryButtonBorder(enabled),
          innerBorder: AppTheme.neonCyan.withValues(
            alpha: enabled ? 0.58 : 0.18,
          ),
          text: AppTheme.secondaryButtonText(enabled),
          glow: AppTheme.secondaryButtonGlow(enabled),
          fill: AppTheme.cardBackgroundDeep.withValues(
            alpha: enabled ? 0.92 : 0.86,
          ),
          topFill: enabled
              ? AppTheme.neonCyan.withValues(alpha: 0.14)
              : AppTheme.cardBackgroundAlt.withValues(alpha: 0.10),
          bottomFill: enabled
              ? AppTheme.secondaryButtonFill(enabled).withValues(alpha: 0.88)
              : AppTheme.secondaryButtonFill(enabled),
        );
      case DoseActionButtonVariant.danger:
        return _DoseActionButtonColors(
          border: AppTheme.dangerButtonBorder(enabled),
          innerBorder: AppTheme.dangerRed.withValues(
            alpha: enabled ? 0.52 : 0.18,
          ),
          text: AppTheme.dangerButtonText(enabled),
          glow: AppTheme.dangerButtonGlow(enabled),
          fill: AppTheme.cardBackgroundDeep.withValues(
            alpha: enabled ? 0.92 : 0.86,
          ),
          topFill: enabled
              ? AppTheme.dangerRed.withValues(alpha: 0.12)
              : AppTheme.cardBackgroundAlt.withValues(alpha: 0.10),
          bottomFill: enabled
              ? AppTheme.dangerButtonFill(enabled).withValues(alpha: 0.90)
              : AppTheme.dangerButtonFill(enabled),
        );
      case DoseActionButtonVariant.primary:
        return _DoseActionButtonColors(
          border: AppTheme.primaryButtonBorder(enabled),
          innerBorder: Colors.white.withValues(alpha: enabled ? 0.30 : 0.12),
          text: AppTheme.primaryButtonText(enabled),
          glow: AppTheme.primaryButtonGlow(enabled),
          fill: AppTheme.cardBackgroundDeep.withValues(
            alpha: enabled ? 0.92 : 0.86,
          ),
          topFill: enabled
              ? AppTheme.neonPink.withValues(alpha: 0.16)
              : AppTheme.cardBackgroundAlt.withValues(alpha: 0.10),
          bottomFill: enabled
              ? AppTheme.primaryButtonFill(enabled).withValues(alpha: 0.92)
              : AppTheme.primaryButtonFill(enabled),
        );
    }
  }
}

class _DoseActionButtonColors {
  final Color border;
  final Color innerBorder;
  final Color text;
  final Color glow;
  final Color fill;
  final Color topFill;
  final Color bottomFill;

  const _DoseActionButtonColors({
    required this.border,
    required this.innerBorder,
    required this.text,
    required this.glow,
    required this.fill,
    required this.topFill,
    required this.bottomFill,
  });
}
