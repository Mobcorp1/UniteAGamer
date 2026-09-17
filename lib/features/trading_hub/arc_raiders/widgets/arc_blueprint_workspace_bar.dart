import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcBlueprintWorkspace { tracker, loadout, watches }

extension ArcBlueprintWorkspaceDetails on ArcBlueprintWorkspace {
  String get label {
    switch (this) {
      case ArcBlueprintWorkspace.tracker:
        return 'Tracker';
      case ArcBlueprintWorkspace.loadout:
        return 'Loadout';
      case ArcBlueprintWorkspace.watches:
        return 'Watches';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcBlueprintWorkspace.tracker:
        return Icons.grid_view_rounded;
      case ArcBlueprintWorkspace.loadout:
        return Icons.inventory_2_outlined;
      case ArcBlueprintWorkspace.watches:
        return Icons.add_alert_outlined;
    }
  }

  String get routeName {
    switch (this) {
      case ArcBlueprintWorkspace.tracker:
        return '/trading-hub/arc-raiders/blueprints';
      case ArcBlueprintWorkspace.loadout:
        return '/favourite-loadout';
      case ArcBlueprintWorkspace.watches:
        return '/trading-hub/arc-raiders/blueprint-watches';
    }
  }
}

/// Compact navigation across the Blueprint Intelligence family.
///
/// This intentionally avoids repeating ownership, loadout or market summaries.
/// Those screens retain their existing source-of-truth content while the family
/// is converged structurally ahead of the later screen-by-screen de-duplication
/// audit.
class ArcBlueprintWorkspaceBar extends StatelessWidget {
  const ArcBlueprintWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcBlueprintWorkspace current;
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
            for (final workspace in ArcBlueprintWorkspace.values) ...[
              _BlueprintWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () =>
                          Navigator.of(context).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcBlueprintWorkspace.values.last)
                const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom-anchored secondary navigation for the Blueprint Intelligence family.
///
/// This is intentionally compact so TRACKER / LOADOUT / WATCHES can live at
/// the bottom of Blueprint-family screens without stealing vertical space from
/// the main content viewport.
class ArcBlueprintWorkspaceDock extends StatelessWidget {
  const ArcBlueprintWorkspaceDock({
    super.key,
    required this.current,
    this.safeBottom = false,
  });

  final ArcBlueprintWorkspace current;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ArcUiTokens.background.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(
                color: ArcUiTokens.borderMedium.withValues(alpha: 0.72),
              ),
              bottom: BorderSide(
                color: ArcUiTokens.borderSubtle.withValues(alpha: 0.42),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ArcBlueprintWorkspaceBar(
              current: current,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ),
    );

    if (!safeBottom) return content;
    return SafeArea(top: false, child: content);
  }
}

class _BlueprintWorkspaceButton extends StatelessWidget {
  const _BlueprintWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcBlueprintWorkspace workspace;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: '${workspace.label} blueprint workspace',
      child: InkWell(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.fastAnimation,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: ArcUiTokens.chipDecoration(
            color: accent,
            selected: selected,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(workspace.icon, size: 15, color: accent),
              const SizedBox(width: 6),
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
