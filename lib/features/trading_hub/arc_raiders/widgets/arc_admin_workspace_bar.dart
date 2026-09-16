import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcAdminWorkspace { console, mapIntel, mapIcons }

extension ArcAdminWorkspaceDetails on ArcAdminWorkspace {
  String get label {
    switch (this) {
      case ArcAdminWorkspace.console:
        return 'Console';
      case ArcAdminWorkspace.mapIntel:
        return 'Map Intel';
      case ArcAdminWorkspace.mapIcons:
        return 'Map Icons';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcAdminWorkspace.console:
        return Icons.admin_panel_settings_outlined;
      case ArcAdminWorkspace.mapIntel:
        return Icons.edit_location_alt_outlined;
      case ArcAdminWorkspace.mapIcons:
        return Icons.grid_view_rounded;
    }
  }

  String get routeName {
    switch (this) {
      case ArcAdminWorkspace.console:
        return '/admin-console';
      case ArcAdminWorkspace.mapIntel:
        return '/admin-map-intel-editor';
      case ArcAdminWorkspace.mapIcons:
        return '/admin-map-filter-icons';
    }
  }
}

/// Navigation-only bridge across the existing admin control surfaces.
///
/// Admin/dev access checks, feature-access persistence, rollout controls,
/// map marker authoring and icon taxonomy remain owned by their existing
/// screens and repositories.
class ArcAdminWorkspaceBar extends StatelessWidget {
  const ArcAdminWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcAdminWorkspace current;
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
            for (final workspace in ArcAdminWorkspace.values) ...[
              _AdminWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcAdminWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminWorkspaceButton extends StatelessWidget {
  const _AdminWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcAdminWorkspace workspace;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? ArcUiTokens.admin : ArcUiTokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: '${workspace.label} admin workspace',
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
