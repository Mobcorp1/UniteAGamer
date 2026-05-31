import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_assistant_sheet.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcCompanionBottomDock extends StatelessWidget {
  const ArcCompanionBottomDock({super.key, required this.activeLabel});

  final String activeLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 430;

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(compact ? 12 : 18, 0, compact ? 12 : 18, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 390 : 520),
          child: Container(
            height: compact ? 76 : 78,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppTheme.neonPink.withValues(alpha: 0.10),
                  blurRadius: 34,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _DockStatus(label: activeLabel),
                  ),
                ),
                ElectricChargeBorder(
                  active: true,
                  radius: 999,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => UagVoiceArcAssistantSheet.show(
                      context,
                      autoStart: true,
                    ),
                    child: Container(
                      width: compact ? 60 : 62,
                      height: compact ? 60 : 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.neonPink.withValues(alpha: 0.17),
                        border: Border.all(
                          color: AppTheme.neonPink.withValues(alpha: 0.76),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonPink.withValues(alpha: 0.30),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppTheme.neonPink,
                        size: 31,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _DockIconButton(
                      icon: Icons.dashboard_rounded,
                      tooltip: 'Back to hub',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockStatus extends StatelessWidget {
  const _DockStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTheme.neonTextStyle(
          fontSize: 12,
          color: AppTheme.neonCyan,
          isBold: true,
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.neonCyan.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon, color: AppTheme.neonCyan, size: 22),
        ),
      ),
    );
  }
}
