import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
    final active = activeLabel.trim().toLowerCase();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Container(
        clipBehavior: Clip.none,
        margin: const EdgeInsets.symmetric(horizontal: 58),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.13),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _DockButton(
                icon: Icons.groups_rounded,
                label: 'Match',
                active: active == 'match',
                onTap: () =>
                    _go(context, '/trading-hub/arc-raiders/match-a-raider'),
              ),
            ),
            Expanded(
              child: _DockButton(
                icon: Icons.route_rounded,
                label: 'Raid',
                active: active == 'raid',
                onTap: () =>
                    _go(context, '/trading-hub/arc-raiders/raid-planner'),
              ),
            ),
            _ArcMicButton(onTap: () => UagVoiceArcAssistantSheet.show(context)),
            Expanded(
              child: _DockButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Trade',
                active: active == 'trade',
                onTap: () =>
                    _go(context, '/trading-hub/arc-raiders/trader-hub'),
              ),
            ),
            Expanded(
              child: _DockButton(
                icon: Icons.radar_rounded,
                label: 'Intel',
                active: active == 'intel',
                onTap: () => _go(context, '/trading-hub/arc-raiders/market'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcMicButton extends StatelessWidget {
  const _ArcMicButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.translate(
        offset: const Offset(0, -7),
        child: ElectricChargeBorder(
          active: true,
          radius: 999,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              clipBehavior: Clip.hardEdge,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonPink.withValues(alpha: 0.22),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.78),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonPink.withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: AppTheme.neonPink,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.neonPink : AppTheme.neonCyan;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 0),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 8,
                color: active ? AppTheme.neonPink : Colors.white70,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
