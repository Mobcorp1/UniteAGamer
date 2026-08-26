import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;
    final horizontalInset = desktop ? 18.0 : 10.0;

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: desktop ? 520 : 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ArcUiTokens.background.withValues(alpha: 0.94),
              border: Border(
                top: BorderSide(
                  color: ArcUiTokens.borderMedium.withValues(alpha: 0.75),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
              child: Row(
                children: [
                  Expanded(
                    child: _DockButton(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'MY HUB',
                      active: active == 'my hub',
                      onTap: () => _go(context, '/my-hub'),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.hexagon_outlined,
                      activeIcon: Icons.hexagon_rounded,
                      label: 'SYSTEMS',
                      active: active == 'systems',
                      onTap: () => _go(context, '/trading-hub/arc-raiders'),
                    ),
                  ),
                  Expanded(
                    child: _DockButton(
                      icon: Icons.mail_outline_rounded,
                      activeIcon: Icons.mail_rounded,
                      label: 'MESSAGES',
                      active: active == 'messages',
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
  if (normalised == 'my hub' ||
      normalised == 'hub' ||
      normalised == 'home' ||
      normalised == 'command' ||
      normalised == 'command centre') {
    return 'my hub';
  }
  if (normalised == 'messages' ||
      normalised == 'notifications' ||
      normalised == 'inbox') {
    return 'messages';
  }
  if (normalised == 'profile' ||
      normalised == 'account' ||
      normalised == 'reputation') {
    return 'profile';
  }
  return 'systems';
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? ArcUiTokens.primaryAccent : ArcUiTokens.textTertiary;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 17),
            const SizedBox(height: 2),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.label(color: color).copyWith(fontSize: 8.5),
            ),
          ],
        ),
      ),
    );
  }
}
