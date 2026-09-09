import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';

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
            maxWidth: desktop ? 560 : double.infinity,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ArcUiTokens.background.withValues(alpha: 0.98),
              border: Border(
                top: BorderSide(
                  color: ArcUiTokens.borderMedium.withValues(alpha: 0.75),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                landscapeMobile ? 2 : 5,
                8,
                landscapeMobile ? 2 : 3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DockButton(
                      icon: Icons.dashboard_customize_outlined,
                      activeIcon: Icons.dashboard_customize_rounded,
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
                      icon: Icons.hexagon_outlined,
                      activeIcon: Icons.hexagon_rounded,
                      label: 'DISCOVER',
                      active: active == 'discover',
                      compact: landscapeMobile,
                      onTap: () => _go(context, '/trading-hub/arc-raiders'),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.mail_outline_rounded,
                      activeIcon: Icons.mail_rounded,
                      label: 'MESSAGES',
                      active: active == 'messages',
                      compact: landscapeMobile,
                      onTap: () => _go(
                        context,
                        '/trading-hub/arc-raiders/notifications',
                      ),
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
      normalised == 'community intel' ||
      normalised == 'my intel' ||
      normalised == 'intel' ||
      normalised == 'track' ||
      normalised == 'tracking' ||
      normalised == 'progress trackers' ||
      normalised == 'blueprint tracker' ||
      normalised == 'scrappy tracker' ||
      normalised == 'bench tracker' ||
      normalised == 'quest tracker' ||
      normalised == 'loadout' ||
      normalised == 'favourite loadout' ||
      normalised == 'trading' ||
      normalised == 'trading hub' ||
      normalised == 'trader hub' ||
      normalised == 'smart trade' ||
      normalised == 'smart trade assist' ||
      normalised == 'nomadic trader' ||
      normalised == 'operations' ||
      normalised == 'operations command' ||
      normalised == 'report a rat') {
    return 'run';
  }
  if (normalised == 'discover' ||
      normalised == 'discover uag' ||
      normalised == 'systems' ||
      normalised == 'arc systems' ||
      normalised == 'carousel') {
    return 'discover';
  }
  if (normalised == 'messages' ||
      normalised == 'notifications' ||
      normalised == 'inbox' ||
      normalised == 'match raider' ||
      normalised == 'matchmaking' ||
      normalised == 'squad') {
    return 'messages';
  }
  if (normalised == 'profile' ||
      normalised == 'profile & reputation' ||
      normalised == 'raider profile' ||
      normalised == 'raider' ||
      normalised == 'locker' ||
      normalised == 'account' ||
      normalised == 'reputation') {
    return 'profile';
  }
  if (normalised == 'my hub' || normalised == 'hub' || normalised == 'home') {
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
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      decoration: active
          ? BoxDecoration(
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ArcUiTokens.primaryAccent.withValues(alpha: 0.28),
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
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.label(
              color: color,
            ).copyWith(fontSize: compact ? 8 : 8.5),
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
        radius: 10,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
