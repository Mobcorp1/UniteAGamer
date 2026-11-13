import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcRaiderNetworkWorkspace { community, matchRaider, contracts }

extension ArcRaiderNetworkWorkspaceDetails on ArcRaiderNetworkWorkspace {
  String get label {
    switch (this) {
      case ArcRaiderNetworkWorkspace.community:
        return 'Community Intel';
      case ArcRaiderNetworkWorkspace.matchRaider:
        return 'Match Raider';
      case ArcRaiderNetworkWorkspace.contracts:
        return 'Report / Contracts';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcRaiderNetworkWorkspace.community:
        return Icons.groups_2_outlined;
      case ArcRaiderNetworkWorkspace.matchRaider:
        return Icons.person_search_outlined;
      case ArcRaiderNetworkWorkspace.contracts:
        return Icons.shield_outlined;
    }
  }

  String get routeName {
    switch (this) {
      case ArcRaiderNetworkWorkspace.community:
        return '/trading-hub/arc-raiders/market';
      case ArcRaiderNetworkWorkspace.matchRaider:
        return '/trading-hub/arc-raiders/match-a-raider';
      case ArcRaiderNetworkWorkspace.contracts:
        return '/raider-contracts';
    }
  }
}

/// Compact cross-feature navigation for the Raider network and trust family.
///
/// The bar is deliberately navigation-only. Community summaries, Match Raider
/// compatibility data, reports, contracts, evidence and rewards stay on their
/// existing source-of-truth screens until the later screen-by-screen audit.
class ArcRaiderNetworkWorkspaceBar extends StatelessWidget {
  const ArcRaiderNetworkWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcRaiderNetworkWorkspace current;
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
            for (final workspace in ArcRaiderNetworkWorkspace.values) ...[
              _RaiderNetworkWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcRaiderNetworkWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _RaiderNetworkWorkspaceButton extends StatelessWidget {
  const _RaiderNetworkWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcRaiderNetworkWorkspace workspace;
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
      label: '${workspace.label} Raider network workspace',
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
