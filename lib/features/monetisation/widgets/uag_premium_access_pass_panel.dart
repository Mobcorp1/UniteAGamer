import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PREMIUM ACCESS PASSES', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              pass.active
                  ? '${pass.type!.label} active - Premium access is enabled.'
                  : 'Try every Premium system without starting a subscription.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
            const SizedBox(height: 12),
            const Text(
              'One introductory purchase of each pass per account. Active passes unlock Premium limits and remove ads. Pass purchase value is recorded for a future first-month Premium upgrade credit.',
            ),
          ],
        ),
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
    final price = '£${(type.pricePence / 100).toStringAsFixed(2)}';
    return SizedBox(
      width: 230,
      child: OutlinedButton(
        onPressed: enabled && onPressed != null ? () => onPressed!(type) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(type.label),
              Text(price),
              if (recommended) const Text('BEST WAY TO TRY PREMIUM'),
              if (!enabled) const Text('INTRODUCTORY PASS USED'),
            ],
          ),
        ),
      ),
    );
  }
}
