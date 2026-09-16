import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

Color arcCommandStatusAccent(ArcCommandStatus status) {
  switch (status) {
    case ArcCommandStatus.critical:
      return Colors.redAccent;
    case ArcCommandStatus.warning:
      return Colors.amberAccent;
    case ArcCommandStatus.active:
      return AppTheme.neonCyan;
    case ArcCommandStatus.ready:
      return AppTheme.neonPink;
    case ArcCommandStatus.neutral:
      return Colors.white70;
    case ArcCommandStatus.success:
      return Colors.lightGreenAccent;
  }
}

class ArcCommandCentreCard extends StatelessWidget {
  const ArcCommandCentreCard({
    super.key,
    required this.child,
    this.accent = AppTheme.neonCyan,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        radius: ArcUiTokens.radiusXL,
        borderOpacity: 0.26,
        glow: true,
      ),
      child: child,
    );
  }
}

class ArcCommandSectionHeader extends StatelessWidget {
  const ArcCommandSectionHeader({
    super.key,
    required this.title,
    required this.accent,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(fontSize: 18, color: accent),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.bodySmall(),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class ArcCommandStatusPill extends StatelessWidget {
  const ArcCommandStatusPill({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final ArcCommandStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = arcCommandStatusAccent(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: ArcUiTokens.chipDecoration(color: accent),
      child: Text(
        label.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyTextStyle(fontSize: 9, color: accent, isBold: true),
      ),
    );
  }
}

class ArcCommandActionButton extends StatelessWidget {
  const ArcCommandActionButton({
    super.key,
    required this.action,
    required this.accent,
    required this.onPressed,
    this.compact = false,
  });

  final ArcCommandAction action;
  final Color accent;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.arrow_forward_rounded, size: compact ? 14 : 16),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.46)),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 12,
          vertical: compact ? 7 : 10,
        ),
        textStyle: AppTheme.bodyTextStyle(
          fontSize: compact ? 10 : 11,
          color: accent,
          isBold: true,
        ),
      ),
    );
  }
}

class ArcCommandDetailList extends StatelessWidget {
  const ArcCommandDetailList({super.key, required this.details});

  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final detail in details) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Icon(Icons.circle, size: 5, color: Colors.white38),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.bodySmall(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ],
    );
  }
}
