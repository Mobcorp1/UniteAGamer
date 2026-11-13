import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcPlayLikeAProWorkspace { guides, routine, coach }

extension ArcPlayLikeAProWorkspaceDetails on ArcPlayLikeAProWorkspace {
  String get label {
    switch (this) {
      case ArcPlayLikeAProWorkspace.guides:
        return 'Guides';
      case ArcPlayLikeAProWorkspace.routine:
        return 'Pro Routine';
      case ArcPlayLikeAProWorkspace.coach:
        return 'Session Coach';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcPlayLikeAProWorkspace.guides:
        return Icons.auto_stories_outlined;
      case ArcPlayLikeAProWorkspace.routine:
        return Icons.sports_esports_rounded;
      case ArcPlayLikeAProWorkspace.coach:
        return Icons.psychology_alt_rounded;
    }
  }
}

/// Compact navigation across the Play Like A Pro guidance family.
///
/// The bar only switches existing Play Like A Pro workspaces. Guidance,
/// routine generation and Session Coach state remain owned by their existing
/// repositories and engines until the later screen-by-screen de-dup audit.
class ArcPlayLikeAProWorkspaceBar extends StatelessWidget {
  const ArcPlayLikeAProWorkspaceBar({
    super.key,
    required this.current,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcPlayLikeAProWorkspace current;
  final ValueChanged<ArcPlayLikeAProWorkspace> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final workspace in ArcPlayLikeAProWorkspace.values) ...[
              _PlayLikeAProWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () => onSelected(workspace),
              ),
              if (workspace != ArcPlayLikeAProWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayLikeAProWorkspaceButton extends StatelessWidget {
  const _PlayLikeAProWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcPlayLikeAProWorkspace workspace;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: '${workspace.label} Play Like A Pro workspace',
      child: InkWell(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.fastAnimation,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: ArcUiTokens.chipDecoration(
            color: accent,
            selected: selected,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(workspace.icon, size: 16, color: accent),
              const SizedBox(width: 7),
              Text(
                workspace.label.toUpperCase(),
                style: ArcUiTokens.label(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
