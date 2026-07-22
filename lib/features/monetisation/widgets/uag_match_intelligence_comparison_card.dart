import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_match_intelligence_copy.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagMatchIntelligenceComparisonCard extends StatelessWidget {
  const UagMatchIntelligenceComparisonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.26),
        radius: 20,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match Intelligence',
                style: AppTheme.tradingHeading(
                  fontSize: 24,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Every tier shows a match percentage. Paid tiers unlock deeper analysis and stronger ranking without exposing private player data.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: AppTheme.tradingMutedText,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (wide) _wideTable() else _compactRows(),
            ],
          );
        },
      ),
    );
  }

  Widget _wideTable() {
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.45),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _tableRow(const <String>[
          'Feature',
          'Free',
          'Essential',
          'Premium',
        ], header: true),
        for (final row in UagMatchIntelligenceCopy.comparisonRows)
          _tableRow(<String>[
            row.feature,
            row.free,
            row.essential,
            row.premium,
          ]),
      ],
    );
  }

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Text(
              cell,
              style: AppTheme.bodyTextStyle(
                fontSize: header ? 13 : 12,
                color: header ? AppTheme.neonPink : Colors.white70,
                isBold: header,
              ),
            ),
          ),
      ],
    );
  }

  Widget _compactRows() {
    return Column(
      children: [
        for (final row in UagMatchIntelligenceCopy.comparisonRows)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(AppTheme.spaceM),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
              radius: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.feature,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill('Free', row.free, AppTheme.tradingMutedText),
                    _pill('Essential', row.essential, AppTheme.neonCyan),
                    _pill('Premium', row.premium, AppTheme.neonPink),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(fontSize: 11, color: color, isBold: true),
      ),
    );
  }
}
