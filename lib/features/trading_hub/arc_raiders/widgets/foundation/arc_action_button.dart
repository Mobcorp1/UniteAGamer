import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

enum ArcActionButtonVariant { primary, secondary, tertiary, destructive }

class ArcActionButton extends StatelessWidget {
  const ArcActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.accent = ArcUiTokens.primaryAccent,
    this.expand = false,
    this.variant = ArcActionButtonVariant.secondary,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accent;
  final bool expand;
  final ArcActionButtonVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == ArcActionButtonVariant.primary;
    final isDestructive = variant == ArcActionButtonVariant.destructive;
    final buttonAccent = isPrimary && accent == ArcUiTokens.primaryAccent
        ? ArcUiTokens.secondaryAccent
        : accent;
    final style =
        ArcUiTokens.textButtonStyle(
          accent: buttonAccent,
          primary: isPrimary,
          destructive: isDestructive,
        ).copyWith(
          padding: WidgetStateProperty.all(
            compact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                : ArcUiTokens.buttonPadding,
          ),
          minimumSize: WidgetStateProperty.all(Size(44, compact ? 36 : 44)),
        );

    final child = icon == null
        ? TextButton(onPressed: onPressed, style: style, child: Text(label))
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: compact ? 16 : 18),
            label: Text(label),
            style: style,
          );

    return expand ? Expanded(child: child) : child;
  }
}
