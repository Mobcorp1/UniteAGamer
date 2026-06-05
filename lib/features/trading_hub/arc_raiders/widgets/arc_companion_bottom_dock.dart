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
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceS,
          vertical: AppTheme.spaceS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.13),
              blurRadius: 22,
              spreadRadius: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceS),
      child: ElectricChargeBorder(
        active: true,
        radius: 999,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonPink.withValues(alpha: 0.22),
              border: Border.all(
                color: AppTheme.neonPink.withValues(alpha: 0.78),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPink.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppTheme.neonPink,
              size: 32,
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
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
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
