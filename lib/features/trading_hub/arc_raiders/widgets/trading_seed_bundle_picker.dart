import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingSeedBundlePicker extends StatelessWidget {
  const TradingSeedBundlePicker({
    super.key,
    required this.smallBundles,
    required this.mediumBundles,
    required this.largeBundles,
    required this.onSmallChanged,
    required this.onMediumChanged,
    required this.onLargeChanged,
  });

  final int smallBundles;
  final int mediumBundles;
  final int largeBundles;
  final ValueChanged<int> onSmallChanged;
  final ValueChanged<int> onMediumChanged;
  final ValueChanged<int> onLargeChanged;

  int get total => smallBundles * 10 + mediumBundles * 50 + largeBundles * 100;

  @override
  Widget build(BuildContext context) {
    return TradingCard(
      compact: true,
      accent: AppTheme.tradingWarning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grain_rounded, color: AppTheme.tradingWarning),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  'Seed Bundles',
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: AppTheme.tradingWarning,
                  ),
                ),
              ),
              Text(
                '$total',
                style: AppTheme.tradingHeading(
                  fontSize: 22,
                  color: total > 0
                      ? AppTheme.tradingWarning
                      : AppTheme.tradingFaintText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          _SeedBundleStepper(
            label: '10 Seeds',
            value: smallBundles,
            onChanged: onSmallChanged,
          ),
          _SeedBundleStepper(
            label: '50 Seeds',
            value: mediumBundles,
            onChanged: onMediumChanged,
          ),
          _SeedBundleStepper(
            label: '100 Seeds',
            value: largeBundles,
            onChanged: onLargeChanged,
          ),
        ],
      ),
    );
  }
}

class _SeedBundleStepper extends StatelessWidget {
  const _SeedBundleStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
                isBold: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove $label bundle',
            onPressed: value <= 0 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppTheme.tradingFaintText,
            disabledColor: AppTheme.tradingFaintText.withValues(alpha: 0.32),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTheme.tradingHeading(
                fontSize: 18,
                color: value > 0
                    ? AppTheme.tradingWarning
                    : AppTheme.tradingFaintText,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add $label bundle',
            onPressed: value >= 999 ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppTheme.neonCyan,
            disabledColor: AppTheme.tradingFaintText.withValues(alpha: 0.32),
          ),
        ],
      ),
    );
  }
}
