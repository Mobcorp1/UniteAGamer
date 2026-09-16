import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcTradingWorkspace { market, smartTrade, traders, activity, sessions }

extension ArcTradingWorkspaceDetails on ArcTradingWorkspace {
  String get label {
    switch (this) {
      case ArcTradingWorkspace.market:
        return 'Market';
      case ArcTradingWorkspace.smartTrade:
        return 'Smart Trade';
      case ArcTradingWorkspace.traders:
        return 'Find Raiders';
      case ArcTradingWorkspace.activity:
        return 'Activity';
      case ArcTradingWorkspace.sessions:
        return 'Sessions';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcTradingWorkspace.market:
        return Icons.storefront_outlined;
      case ArcTradingWorkspace.smartTrade:
        return Icons.auto_awesome_rounded;
      case ArcTradingWorkspace.traders:
        return Icons.manage_search_rounded;
      case ArcTradingWorkspace.activity:
        return Icons.swap_horiz_rounded;
      case ArcTradingWorkspace.sessions:
        return Icons.handshake_outlined;
    }
  }

  String get routeName {
    switch (this) {
      case ArcTradingWorkspace.market:
        return '/trading-hub/arc-raiders/trader-hub';
      case ArcTradingWorkspace.smartTrade:
        return '/trading-hub/arc-raiders/smart-trade-assist';
      case ArcTradingWorkspace.traders:
        return '/arc-trader-search';
      case ArcTradingWorkspace.activity:
        return '/trading-hub/arc-raiders/activity';
      case ArcTradingWorkspace.sessions:
        return '/trading-hub/arc-raiders/sessions';
    }
  }
}

/// Compact navigation across the trading workspace family.
///
/// The workspace bar is intentionally navigation-only. It does not duplicate
/// listing, offer, trader, session or Smart Trade summaries; those remain on
/// their existing source-of-truth screens until the later de-duplication audit.
class ArcTradingWorkspaceBar extends StatelessWidget {
  const ArcTradingWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcTradingWorkspace current;
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
            for (final workspace in ArcTradingWorkspace.values) ...[
              _TradingWorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcTradingWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _TradingWorkspaceButton extends StatelessWidget {
  const _TradingWorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcTradingWorkspace workspace;
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
      label: '${workspace.label} trading workspace',
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
