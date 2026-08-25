import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingRiskBadge extends StatelessWidget {
  const TradingRiskBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  final TradingRiskLevel level;
  final bool compact;

  Color get _color {
    return switch (level) {
      TradingRiskLevel.low => AppTheme.tradingSuccess,
      TradingRiskLevel.medium => AppTheme.tradingWarning,
      TradingRiskLevel.high => AppTheme.tradingDanger,
    };
  }

  IconData get _icon {
    return switch (level) {
      TradingRiskLevel.low => Icons.verified_user_outlined,
      TradingRiskLevel.medium => Icons.report_problem_outlined,
      TradingRiskLevel.high => Icons.gpp_maybe_outlined,
    };
  }

  String get _label {
    return switch (level) {
      TradingRiskLevel.low => 'Low risk',
      TradingRiskLevel.medium => 'Moderate risk',
      TradingRiskLevel.high => 'Caution',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 13 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: AppTheme.bodyTextStyle(
              fontSize: compact ? 10 : 11,
              color: color,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}
