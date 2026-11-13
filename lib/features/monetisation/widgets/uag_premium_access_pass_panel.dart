import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_premium_pass_entitlement.dart';

class UagPremiumAccessPassPanel extends StatelessWidget {
  const UagPremiumAccessPassPanel({
    super.key,
    required this.pass,
    this.onSelect,
  });

  final UagPremiumPassEntitlement pass;
  final ValueChanged<UagPremiumPassType>? onSelect;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.timer_outlined,
      title: 'SHORT-TERM PREMIUM',
      subtitle:
          'Need Premium for a raid day, a weekend or a week off? Buy a pass whenever you need one.',
      accent: ArcUiTokens.secondaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pass.active) ...[
            Text(
              '${pass.type!.label} active • Premium access is enabled.',
              style: ArcUiTokens.metadata(color: ArcUiTokens.success),
            ),
            const SizedBox(height: ArcUiTokens.gapM),
          ],
          Wrap(
            spacing: ArcUiTokens.gapM,
            runSpacing: ArcUiTokens.gapM,
            children: [
              _PassButton(
                type: UagPremiumPassType.day24,
                enabled: pass.canPurchase(UagPremiumPassType.day24),
                onPressed: onSelect,
              ),
              _PassButton(
                type: UagPremiumPassType.week7,
                enabled: pass.canPurchase(UagPremiumPassType.week7),
                recommended: true,
                onPressed: onSelect,
              ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Text(
            'Passes are reusable. You can buy another after the current Premium pass or subscription ends. Active passes unlock Premium limits and remove ads.',
            style: ArcUiTokens.bodySmall(),
          ),
        ],
      ),
    );
  }
}

class _PassButton extends StatelessWidget {
  const _PassButton({
    required this.type,
    required this.enabled,
    required this.onPressed,
    this.recommended = false,
  });

  final UagPremiumPassType type;
  final bool enabled;
  final bool recommended;
  final ValueChanged<UagPremiumPassType>? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = recommended
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent;
    final price = '£${(type.pricePence / 100).toStringAsFixed(2)}';
    return Container(
      width: 250,
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        borderOpacity: recommended ? 0.4 : 0.24,
        glow: recommended,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: ArcUiTokens.cardTitle(color: accent)),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(price, style: ArcUiTokens.numeric(fontSize: 22, color: accent)),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            recommended ? 'BEST VALUE FOR A FULL WEEK' : 'FULL PREMIUM FOR 24 HOURS',
            style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: ArcUiTokens.textButtonStyle(accent: accent),
              onPressed: enabled && onPressed != null ? () => onPressed!(type) : null,
              child: Text(enabled ? 'SELECT PASS' : 'PREMIUM ACTIVE'),
            ),
          ),
        ],
      ),
    );
  }
}
