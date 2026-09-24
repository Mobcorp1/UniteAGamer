import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcProgressionWorkspace {
  overview,
  scrappy,
  bench,
  quest,
  crafting,
  research,
  hunts,
}

extension ArcProgressionWorkspaceDetails on ArcProgressionWorkspace {
  String get label {
    switch (this) {
      case ArcProgressionWorkspace.overview:
        return 'Trackers';
      case ArcProgressionWorkspace.scrappy:
        return 'Scrappy';
      case ArcProgressionWorkspace.bench:
        return 'Bench';
      case ArcProgressionWorkspace.quest:
        return 'Quests';
      case ArcProgressionWorkspace.crafting:
        return 'Crafting';
      case ArcProgressionWorkspace.research:
        return 'Research';
      case ArcProgressionWorkspace.hunts:
        return 'Hunt Targets';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcProgressionWorkspace.overview:
        return Icons.track_changes_rounded;
      case ArcProgressionWorkspace.scrappy:
        return Icons.egg_alt_rounded;
      case ArcProgressionWorkspace.bench:
        return Icons.build_rounded;
      case ArcProgressionWorkspace.quest:
        return Icons.assignment_rounded;
      case ArcProgressionWorkspace.crafting:
        return Icons.handyman_rounded;
      case ArcProgressionWorkspace.research:
        return Icons.science_rounded;
      case ArcProgressionWorkspace.hunts:
        return Icons.my_location_rounded;
    }
  }

  String get routeName {
    switch (this) {
      case ArcProgressionWorkspace.overview:
        return '/trading-hub/arc-raiders/progress-trackers';
      case ArcProgressionWorkspace.scrappy:
        return '/trading-hub/arc-raiders/scrappy';
      case ArcProgressionWorkspace.bench:
        return '/trading-hub/arc-raiders/bench';
      case ArcProgressionWorkspace.quest:
        return '/trading-hub/arc-raiders/quests';
      case ArcProgressionWorkspace.crafting:
        return '/trading-hub/arc-raiders/crafting';
      case ArcProgressionWorkspace.research:
        return '/trading-hub/arc-raiders/research-workstation';
      case ArcProgressionWorkspace.hunts:
        return '/trading-hub/arc-raiders/raid-planner/hunt-targets';
    }
  }
}

/// Compact navigation across the progression and tracker family.
///
/// This bar is intentionally navigation-only. It does not duplicate resource,
/// bench, quest, crafting, Blueprint hunt or progression summaries; those stay
/// on their source-of-truth screens.
class ArcProgressionWorkspaceBar extends StatelessWidget {
  const ArcProgressionWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcProgressionWorkspace current;
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
            for (final workspace in ArcProgressionWorkspace.values) ...[
              _ProgressionWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcProgressionWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressionWorkspaceButton extends StatelessWidget {
  const _ProgressionWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcProgressionWorkspace workspace;
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
      label: '${workspace.label} progression workspace',
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
