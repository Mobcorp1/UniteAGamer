import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcBlueprintIntelPanel extends StatelessWidget {
  const ArcBlueprintIntelPanel({
    super.key,
    required this.blueprint,
    required this.intel,
    this.maxEntries = 5,
  });

  final ArcBlueprint blueprint;
  final ArcDropIntel intel;
  final int maxEntries;

  String _formatLastConfirmed(DateTime? value) {
    if (value == null) return 'No confirmed reports yet';

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = value.day;
    final month = months[value.month - 1];
    final year = value.year;
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour12:$minute $suffix';
  }

  String _communityConfidenceLabel() {
    if (!intel.hasReports) return 'No Confirmed Data';
    if (intel.totalReports >= 6) return 'High';
    if (intel.totalReports >= 3) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final hintData = ArcBlueprintIntelLibrary.resolve(blueprint);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: intel.hasReports
            ? AppTheme.neonPink.withValues(alpha: 0.22)
            : AppTheme.neonCyan.withValues(alpha: 0.20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (intel.hasReports) ...[
            _buildCommunitySection(),
          ] else ...[
            _buildHintsSection(hintData),
            const SizedBox(height: AppTheme.spaceL),
            const Text(
              'No community reports yet. These hints are starter leads until confirmed finds begin to come in.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHintsSection(ArcBlueprintHintData hintData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hints / Tips',
          style: AppTheme.tradingHeading(
            fontSize: 20,
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              label: 'Confidence',
              value: hintData.confidenceLabel,
              color: AppTheme.neonCyan,
            ),
            _InfoChip(
              label: 'Category',
              value: blueprint.category,
              color: AppTheme.neonPink,
            ),
            _InfoChip(
              label: 'Rarity',
              value: blueprint.rarityLabel,
              color: Colors.amberAccent,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        Text(
          hintData.tip,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        if (hintData.specialSource != null &&
            hintData.specialSource!.trim().isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceM),
          _HintSectionBlock(
            title: 'Special Source',
            accentColor: Colors.amberAccent,
            entries: [hintData.specialSource!],
          ),
        ],
        if (hintData.likelyContainers.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceM),
          _HintSectionBlock(
            title: 'Likely Containers',
            accentColor: AppTheme.neonCyan,
            entries: hintData.likelyContainers,
          ),
        ],
        if (hintData.likelyMaps.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceM),
          _HintSectionBlock(
            title: 'Likely Maps',
            accentColor: Colors.lightGreenAccent,
            entries: hintData.likelyMaps,
          ),
        ],
        if (hintData.bestConditions.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceM),
          _HintSectionBlock(
            title: 'Best Conditions / Events',
            accentColor: Colors.amberAccent,
            entries: hintData.bestConditions,
          ),
        ],
      ],
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Intel',
          style: AppTheme.tradingHeading(
            fontSize: 20,
            color: AppTheme.neonPink,
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              label: 'Reports',
              value: '${intel.totalReports}',
              color: AppTheme.neonCyan,
            ),
            _InfoChip(
              label: 'Confidence',
              value: _communityConfidenceLabel(),
              color: Colors.amberAccent,
            ),
            _InfoChip(
              label: 'Last Confirmed',
              value: _formatLastConfirmed(intel.lastReportedAt),
              color: Colors.lightGreenAccent,
            ),
            if (intel.topMapLabel != null)
              _InfoChip(
                label: 'Top Map',
                value: intel.topMapLabel!,
                color: Colors.lightGreenAccent,
              ),
            if (intel.topAreaLabel != null)
              _InfoChip(
                label: 'Top Area',
                value: intel.topAreaLabel!,
                color: AppTheme.neonPink,
              ),
            if (intel.topContainerLabel != null)
              _InfoChip(
                label: 'Top Container',
                value: intel.topContainerLabel!,
                color: AppTheme.neonCyan,
              ),
            if (intel.topMapEventLabel != null)
              _InfoChip(
                label: 'Top Event',
                value: intel.topMapEventLabel!,
                color: Colors.deepPurpleAccent,
              ),
          ],
        ),
        _buildBreakdownSection(
          title: 'Map Breakdown',
          entries: intel.mapBreakdown,
          color: Colors.lightGreenAccent,
        ),
        _buildBreakdownSection(
          title: 'Area Breakdown',
          entries: intel.areaBreakdown,
          color: AppTheme.neonCyan,
        ),
        _buildBreakdownSection(
          title: 'Container Breakdown',
          entries: intel.containerBreakdown,
          color: Colors.amberAccent,
        ),
        _buildBreakdownSection(
          title: 'Map Event Breakdown',
          entries: intel.mapEventBreakdown,
          color: Colors.deepPurpleAccent,
        ),
        _buildBreakdownSection(
          title: 'Raid Type Breakdown',
          entries: intel.raidTypeBreakdown,
          color: AppTheme.neonPink,
        ),
        _buildBreakdownSection(
          title: 'Time of Day Breakdown',
          entries: intel.timeOfDayBreakdown,
          color: Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildBreakdownSection({
    required String title,
    required List<ArcAreaIntelBreakdown> entries,
    required Color color,
  }) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spaceM),
        Text(title, style: AppTheme.tradingHeading(fontSize: 16, color: color)),
        const SizedBox(height: AppTheme.spaceS),
        ...entries
            .take(maxEntries)
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BreakdownRow(
                  label: entry.label,
                  percentageLabel: entry.percentageLabel,
                  reportCount: entry.reportCount,
                  accentColor: color,
                ),
              ),
            ),
      ],
    );
  }
}

class _HintSectionBlock extends StatelessWidget {
  const _HintSectionBlock({
    required this.title,
    required this.entries,
    required this.accentColor,
  });

  final String title;
  final List<String> entries;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 14,
        borderColor: accentColor.withValues(alpha: 0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 16, color: accentColor),
          ),
          const SizedBox(height: AppTheme.spaceS),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $entry',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceS,
      ),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.percentageLabel,
    required this.reportCount,
    required this.accentColor,
  });

  final String label;
  final String percentageLabel;
  final int reportCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 14,
        borderColor: accentColor.withValues(alpha: 0.16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Text(
            '$reportCount',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Text(
            percentageLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
