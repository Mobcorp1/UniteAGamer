import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcBottomActionDock extends StatelessWidget {
  const ArcBottomActionDock({
    super.key,
    required this.actions,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final List<ArcDockAction> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.overlay,
      padding: const EdgeInsets.symmetric(
        horizontal: ArcUiTokens.gapS,
        vertical: ArcUiTokens.gapM,
      ),
      radius: ArcUiTokens.radiusXXL,
      child: Row(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: actions[index].onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ArcUiTokens.gapS,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        actions[index].icon,
                        color: actions[index].accent,
                        size: 24,
                      ),
                      const SizedBox(height: ArcUiTokens.gapXS),
                      Text(
                        actions[index].label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: ArcUiTokens.label(
                          color: ArcUiTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (index != actions.length - 1)
              Container(width: 1, height: 42, color: ArcUiTokens.borderSubtle),
          ],
        ],
      ),
    );
  }
}

class ArcDockAction {
  const ArcDockAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
}
