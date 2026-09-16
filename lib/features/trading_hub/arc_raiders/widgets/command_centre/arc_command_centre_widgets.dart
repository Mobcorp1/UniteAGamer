import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

Color arcCommandStatusAccent(ArcCommandStatus status) {
  switch (status) {
    case ArcCommandStatus.critical:
      return ArcUiTokens.danger;
    case ArcCommandStatus.warning:
      return ArcUiTokens.warning;
    case ArcCommandStatus.active:
      return ArcUiTokens.primaryAccent;
    case ArcCommandStatus.ready:
      return ArcUiTokens.secondaryAccent;
    case ArcCommandStatus.neutral:
      return ArcUiTokens.textSecondary;
    case ArcCommandStatus.success:
      return ArcUiTokens.success;
  }
}

class ArcCommandCentreCard extends StatelessWidget {
  const ArcCommandCentreCard({
    super.key,
    required this.child,
    this.accent = ArcUiTokens.primaryAccent,
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
        role: ArcSurfaceRole.panel,
        accent: accent,
        radius: ArcUiTokens.radiusXL,
        borderOpacity: 0.18,
        glow: false,
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
                style: ArcUiTokens.sectionTitle(fontSize: 17, color: accent),
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
        style: ArcUiTokens.label(color: accent),
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
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.arrow_forward_rounded, size: compact ? 14 : 16),
      label: Text(action.label),
      style: ArcUiTokens.textButtonStyle(accent: accent),
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
