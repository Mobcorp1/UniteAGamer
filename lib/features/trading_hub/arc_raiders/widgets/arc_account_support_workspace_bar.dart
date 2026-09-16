import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcAccountSupportWorkspace { plans, settings, help, feedback, legal }

extension ArcAccountSupportWorkspaceDetails on ArcAccountSupportWorkspace {
  String get label {
    switch (this) {
      case ArcAccountSupportWorkspace.plans:
        return 'Plans';
      case ArcAccountSupportWorkspace.settings:
        return 'Settings';
      case ArcAccountSupportWorkspace.help:
        return 'Help';
      case ArcAccountSupportWorkspace.feedback:
        return 'Feedback';
      case ArcAccountSupportWorkspace.legal:
        return 'Legal';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcAccountSupportWorkspace.plans:
        return Icons.workspace_premium_outlined;
      case ArcAccountSupportWorkspace.settings:
        return Icons.tune_rounded;
      case ArcAccountSupportWorkspace.help:
        return Icons.support_agent_rounded;
      case ArcAccountSupportWorkspace.feedback:
        return Icons.bug_report_outlined;
      case ArcAccountSupportWorkspace.legal:
        return Icons.policy_outlined;
    }
  }

  String get routeName {
    switch (this) {
      case ArcAccountSupportWorkspace.plans:
        return '/monetisation';
      case ArcAccountSupportWorkspace.settings:
        return '/profile-settings';
      case ArcAccountSupportWorkspace.help:
        return '/trading-hub/arc-raiders/help';
      case ArcAccountSupportWorkspace.feedback:
        return '/arc-raiders/closed-beta-feedback';
      case ArcAccountSupportWorkspace.legal:
        return '/legal';
    }
  }
}

/// Compact navigation across account, access and support surfaces.
///
/// This bar is navigation-only. Subscription entitlements, checkout,
/// personalisation, notification preferences, help content, beta feedback and
/// legal policy authority remain owned by their existing services and screens.
class ArcAccountSupportWorkspaceBar extends StatelessWidget {
  const ArcAccountSupportWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcAccountSupportWorkspace current;
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
            for (final workspace in ArcAccountSupportWorkspace.values) ...[
              _AccountSupportWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcAccountSupportWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountSupportWorkspaceButton extends StatelessWidget {
  const _AccountSupportWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcAccountSupportWorkspace workspace;
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
      label: '${workspace.label} account and support workspace',
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
