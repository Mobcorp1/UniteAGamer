import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcCompanionBottomDock extends StatelessWidget {
  final String activeLabel;

  const ArcCompanionBottomDock({super.key, required this.activeLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.12),
              blurRadius: 26,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppTheme.neonPink.withValues(alpha: 0.08),
              blurRadius: 38,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _DockNavButton(
              icon: Icons.groups_rounded,
              label: 'Match',
              isActive: _matches(activeLabel, 'match'),
              onTap: () => _push(context, ArcMatchRiderScreen.routeName),
            ),
            _DockNavButton(
              icon: Icons.route_rounded,
              label: 'Raid',
              isActive: _matches(activeLabel, 'raid'),
              onTap: () => _push(context, RaidPlannerScreen.routeName),
            ),
            ElectricChargeBorder(
              active: true,
              radius: 999,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    UagVoiceArcAssistantSheet.show(context, autoStart: true),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.neonPink.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppTheme.neonPink.withValues(alpha: 0.76),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonPink.withValues(alpha: 0.28),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppTheme.neonPink,
                    size: 34,
                  ),
                ),
              ),
            ),
            _DockNavButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Trade',
              isActive:
                  _matches(activeLabel, 'trade') ||
                  _matches(activeLabel, 'trading'),
              onTap: () => _push(context, TraderHubScreen.routeName),
            ),
            _DockNavButton(
              icon: Icons.radar_rounded,
              label: 'Intel',
              isActive: _matches(activeLabel, 'intel'),
              onTap: () => _push(context, ArcIntelExplorerScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(String source, String value) {
    return source.toLowerCase().contains(value.toLowerCase());
  }

  void _push(BuildContext context, String routeName) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) return;
    Navigator.of(context).pushNamed(routeName);
  }
}

class _DockNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockNavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.neonPink : AppTheme.neonCyan;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: isActive ? AppTheme.neonPink : Colors.white70,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
