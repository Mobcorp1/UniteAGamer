import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';

/// Canonical primary navigation for the ARC Operations OS.
///
/// The dock intentionally contains only five durable product families. Messages,
/// help and other utility destinations belong in the top app bar rather than
/// competing with primary product navigation.
class ArcCompanionBottomDock extends StatelessWidget {
  final String activeLabel;

  const ArcCompanionBottomDock({super.key, required this.activeLabel});

  void _go(BuildContext context, String routeName) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) return;
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final active = _normalisedActiveLabel(activeLabel);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final desktop = width >= 900;
    final landscapeMobile =
        media.orientation == Orientation.landscape && !desktop;
    final horizontalInset = desktop ? 18.0 : 0.0;

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 0),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: desktop ? 680 : double.infinity,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ArcUiTokens.background.withValues(alpha: 0.985),
              border: Border(
                top: BorderSide(
                  color: ArcUiTokens.borderMedium.withValues(alpha: 0.72),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                6,
                landscapeMobile ? 2 : 5,
                6,
                landscapeMobile ? 2 : 3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DockButton(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'RUN',
                      active: active == 'run',
                      compact: landscapeMobile,
                      onTap: () => _go(
                        context,
                        '/trading-hub/arc-raiders/command-centre',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore_rounded,
                      label: 'DISCOVER',
                      active: active == 'discover',
                      compact: landscapeMobile,
                      onTap: () => _go(context, '/trading-hub/arc-raiders'),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.track_changes_outlined,
                      activeIcon: Icons.track_changes_rounded,
                      label: 'TRACK',
                      active: active == 'track',
                      compact: landscapeMobile,
                      onTap: () => _go(
                        context,
                        '/trading-hub/arc-raiders/progress-trackers',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.swap_horiz_outlined,
                      activeIcon: Icons.swap_horiz_rounded,
                      label: 'TRADE',
                      active: active == 'trade',
                      compact: landscapeMobile,
                      onTap: () =>
                          _go(context, '/trading-hub/arc-raiders/trader-hub'),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'PROFILE',
                      active: active == 'profile',
                      compact: landscapeMobile,
                      onTap: () =>
                          _go(context, '/trading-hub/arc-raiders/profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _normalisedActiveLabel(String value) {
  final normalised = value.trim().toLowerCase();

  if (normalised == 'run' ||
      normalised == 'run your uag' ||
      normalised == 'command' ||
      normalised == 'command centre' ||
      normalised == 'raid' ||
      normalised == 'raid planner' ||
      normalised == 'raid timeline' ||
      normalised == 'raid intelligence' ||
      normalised == 'hunt targets' ||
      normalised == 'operations' ||
      normalised == 'operations command') {
    return 'run';
  }

  if (normalised == 'discover' ||
      normalised == 'discover uag' ||
      normalised == 'systems' ||
      normalised == 'arc systems' ||
      normalised == 'carousel' ||
      normalised == 'community intel' ||
      normalised == 'community rewards' ||
      normalised == 'wall of legends' ||
      normalised == 'play like a pro' ||
      normalised == 'report a rat') {
    return 'discover';
  }

  if (normalised == 'track' ||
      normalised == 'tracking' ||
      normalised == 'progress trackers' ||
      normalised == 'blueprint tracker' ||
      normalised == 'scrappy tracker' ||
      normalised == 'bench tracker' ||
      normalised == 'quest tracker' ||
      normalised == 'loadout' ||
      normalised == 'favourite loadout' ||
      normalised == 'my intel' ||
      normalised == 'intel') {
    return 'track';
  }

  if (normalised == 'trade' ||
      normalised == 'trading' ||
      normalised == 'trading hub' ||
      normalised == 'trader hub' ||
      normalised == 'smart trade' ||
      normalised == 'smart trade assist' ||
      normalised == 'nomadic trader') {
    return 'trade';
  }

  if (normalised == 'profile' ||
      normalised == 'profile & reputation' ||
      normalised == 'raider profile' ||
      normalised == 'raider' ||
      normalised == 'locker' ||
      normalised == 'account' ||
      normalised == 'reputation' ||
      normalised == 'settings' ||
      normalised == 'plans' ||
      normalised == 'plans & referrals' ||
      normalised == 'help' ||
      normalised == 'help centre' ||
      normalised == 'feedback' ||
      normalised == 'beta feedback' ||
      normalised == 'legal' ||
      normalised == 'legal & privacy' ||
      normalised == 'my hub' ||
      normalised == 'hub' ||
      normalised == 'home' ||
      normalised == 'match raider' ||
      normalised == 'matchmaking' ||
      normalised == 'squad' ||
      normalised == 'messages' ||
      normalised == 'notifications' ||
      normalised == 'inbox') {
    return 'profile';
  }

  return 'discover';
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.active,
    required this.compact,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active ? ArcUiTokens.primaryAccent : ArcUiTokens.textTertiary;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: BoxConstraints(minHeight: compact ? 38 : 42),
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: compact ? 2 : 4),
      decoration: active
          ? BoxDecoration(
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.075),
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
              border: Border.all(
                color: ArcUiTokens.primaryAccent.withValues(alpha: 0.26),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: color,
            size: compact ? 16 : 18,
          ),
          SizedBox(height: compact ? 1 : 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.label(
              color: color,
            ).copyWith(fontSize: compact ? 7.5 : 8.25),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: ElectricChargeBorder(
        active: active,
        radius: ArcUiTokens.radiusM,
        child: InkWell(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
