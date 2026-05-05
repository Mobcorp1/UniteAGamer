import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

enum DoseActionButtonVariant {
  primary,
  secondary,
  danger,
}

class DoseActionButton extends StatelessWidget {
  const DoseActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = DoseActionButtonVariant.primary,
    this.active = false,
    this.enabled = true,
    this.width,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final DoseActionButtonVariant variant;
  final bool active;
  final bool enabled;
  final double? width;

  Color _borderColor(bool isEnabled) {
    switch (variant) {
      case DoseActionButtonVariant.primary:
        return AppTheme.primaryButtonBorder(isEnabled);
      case DoseActionButtonVariant.secondary:
        return AppTheme.secondaryButtonBorder(isEnabled);
      case DoseActionButtonVariant.danger:
        return AppTheme.dangerButtonBorder(isEnabled);
    }
  }

  Color _fillColor(bool isEnabled) {
    switch (variant) {
      case DoseActionButtonVariant.primary:
        return AppTheme.primaryButtonFill(isEnabled);
      case DoseActionButtonVariant.secondary:
        return AppTheme.secondaryButtonFill(isEnabled);
      case DoseActionButtonVariant.danger:
        return AppTheme.dangerButtonFill(isEnabled);
    }
  }

  Color _textColor(bool isEnabled) {
    switch (variant) {
      case DoseActionButtonVariant.primary:
        return AppTheme.primaryButtonText(isEnabled);
      case DoseActionButtonVariant.secondary:
        return AppTheme.secondaryButtonText(isEnabled);
      case DoseActionButtonVariant.danger:
        return AppTheme.dangerButtonText(isEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;
    final borderColor = _borderColor(isEnabled);
    final fillColor = _fillColor(isEnabled);
    final textColor = _textColor(isEnabled);

    final child = SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          onTap: isEnabled ? onPressed : null,
          child: Ink(
            padding: AppTheme.buttonPadding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              border: Border.all(
                color: borderColor,
                width: AppTheme.buttonBorderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: AppTheme.spaceS),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.buttonTextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return ElectricChargeBorder(
      active: active,
      radius: AppTheme.buttonRadius,
      child: child,
    );
  }
}
