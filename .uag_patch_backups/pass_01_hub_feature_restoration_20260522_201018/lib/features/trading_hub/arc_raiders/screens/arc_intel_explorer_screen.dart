import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcIntelExplorerScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/intel-explorer';

  const ArcIntelExplorerScreen({super.key});

  @override
  State<ArcIntelExplorerScreen> createState() => _ArcIntelExplorerScreenState();
}

class _ArcIntelExplorerScreenState extends State<ArcIntelExplorerScreen> {
  final ArcBlueprintRepository _repository = ArcBlueprintRepository();
  late final List<ArcBlueprint> _blueprints;
  ArcBlueprint? _selectedBlueprint;

  @override
  void initState() {
    super.initState();
    _blueprints = List<ArcBlueprint>.from(ArcBlueprintSeedData.blueprints)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Intel Explorer',
          style: AppTheme.tradingHeading(
            fontSize: 25,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: ListView(
              padding: AppTheme.pagePadding,
              children: [
                Text(
                  'Pick a blueprint to see the strongest player-confirmed signals instead of scrolling through individual reports.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                _buildBlueprintSelector(context),
                const SizedBox(height: AppTheme.spaceL),
                if (_selectedBlueprint == null)
                  _buildEmptyState(context)
                else
                  StreamBuilder<ArcDropIntel>(
                    stream: _repository.watchIntelForBlueprint(
                      _selectedBlueprint!.id,
                    ),
                    builder: (context, snapshot) {
                      final intel =
                          snapshot.data ??
                          ArcDropIntel.empty(_selectedBlueprint!.id);
                      return _buildIntelBody(
                        context,
                        _selectedBlueprint!,
                        intel,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintSelector(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await _showBlueprintPicker(context);
        if (!mounted || picked == null) return;
        setState(() => _selectedBlueprint = picked);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPink.withValues(alpha: 0.10),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blueprint',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedBlueprint?.name ?? 'Select Blueprint',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.search_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        'Select a blueprint and the app will summarise where players most commonly report finding it, plus the best confirmed combinations.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
      ),
    );
  }

  Widget _buildIntelBody(
    BuildContext context,
    ArcBlueprint blueprint,
    ArcDropIntel intel,
  ) {
    if (!intel.hasReports) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          'No community intel for ${blueprint.name} yet. The first reports will start building the percentages here.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(context, blueprint, intel),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Best Chance',
          initiallyExpanded: true,
          titleColor: AppTheme.neonPink,
          child: _buildBestChanceCard(context, intel),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Top Signals',
          initiallyExpanded: true,
          titleColor: AppTheme.neonCyan,
          child: _buildBreakdownCard(
            context,
            title: 'Top Signals',
            showTitle: false,
            summaryRows: [
              _summaryRow('Most reported map', intel.mapBreakdown),
              _summaryRow('Top Area / POI', intel.areaBreakdown),
              _summaryRow('Most reported container', intel.containerBreakdown),
              _summaryRow('Most reported weather', intel.weatherBreakdown),
              _summaryRow('Most reported map event', intel.mapEventBreakdown),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Map Breakdown',
          initiallyExpanded: false,
          titleColor: AppTheme.neonCyan,
          child: _buildBreakdownCard(
            context,
            title: 'Map',
            showTitle: false,
            items: intel.mapBreakdown,
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Container Breakdown',
          initiallyExpanded: false,
          titleColor: AppTheme.neonCyan,
          child: _buildBreakdownCard(
            context,
            title: 'Container',
            showTitle: false,
            items: intel.containerBreakdown,
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Weather Breakdown',
          initiallyExpanded: false,
          titleColor: AppTheme.neonCyan,
          child: _buildBreakdownCard(
            context,
            title: 'Weather',
            showTitle: false,
            items: intel.weatherBreakdown,
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Best Confirmed Combinations',
          initiallyExpanded: false,
          titleColor: AppTheme.neonPink,
          child: _buildBreakdownCard(
            context,
            title: 'Best Confirmed Combinations',
            showTitle: false,
            combinations: intel.topCombinations,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ArcBlueprint blueprint,
    ArcDropIntel intel,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            blueprint.name,
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on ${intel.totalReports} player confirmation${intel.totalReports == 1 ? '' : 's'}.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaPill(
                label: 'Confidence',
                value: _confidenceLabel(intel),
                valueColor: _confidenceColor(intel),
              ),
              _buildMetaPill(
                label: 'Last Reported',
                value: _lastReportedLabel(intel.lastReportedAt),
                valueColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestChanceCard(BuildContext context, ArcDropIntel intel) {
    final topCombo = intel.topCombinations.isEmpty
        ? null
        : intel.topCombinations.first;

    final mapLabel =
        topCombo?.mapLabel ?? intel.topMapLabel ?? 'No map signal yet';
    final areaLabel =
        topCombo?.areaLabel ?? intel.topAreaLabel ?? 'No Area / POI signal yet';
    final containerLabel =
        topCombo?.containerLabel ??
        intel.topContainerLabel ??
        'No container signal yet';
    final eventLabel =
        topCombo?.eventLabel ??
        intel.topMapEventLabel ??
        'No map event signal yet';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonPink.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fast read of the strongest current signal for this blueprint.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          _buildBestChanceRow(context, 'Map', mapLabel),
          _buildBestChanceRow(context, 'Area / POI', areaLabel),
          _buildBestChanceRow(context, 'Container', containerLabel),
          _buildBestChanceRow(context, 'Event', eventLabel),
          if (topCombo != null) ...[
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Top combo strength: ${topCombo.percentageLabel} • ${topCombo.reportCount} confirmation${topCombo.reportCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBestChanceRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  String _confidenceLabel(ArcDropIntel intel) {
    final topCount = intel.topCombinations.isEmpty
        ? 0
        : intel.topCombinations.first.reportCount;
    final topPercentage = intel.topCombinations.isEmpty
        ? 0.0
        : intel.topCombinations.first.percentage;

    if (intel.totalReports >= 12 && topCount >= 4 && topPercentage >= 30) {
      return 'High';
    }
    if (intel.totalReports >= 5 && topCount >= 2 && topPercentage >= 18) {
      return 'Medium';
    }
    return 'Low';
  }

  Color _confidenceColor(ArcDropIntel intel) {
    switch (_confidenceLabel(intel)) {
      case 'High':
        return AppTheme.neonCyan;
      case 'Medium':
        return Colors.amberAccent;
      case 'Low':
        return AppTheme.neonPink;
      default:
        return Colors.white70;
    }
  }

  String _lastReportedLabel(DateTime? value) {
    if (value == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildBreakdownCard(
    BuildContext context, {
    required String title,
    bool showTitle = true,
    List<ArcAreaIntelBreakdown> items = const [],
    List<_SummaryRowData> summaryRows = const [],
    List<ArcIntelCombination> combinations = const [],
  }) {
    final resolvedSummaryRows = summaryRows.isEmpty
        ? items
              .map(
                (item) => _SummaryRowData(
                  item.label,
                  item.reportCount,
                  item.percentage,
                ),
              )
              .toList()
        : summaryRows;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              title,
              style: AppTheme.tradingHeading(
                fontSize: 20,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
          ],
          if (combinations.isNotEmpty)
            ...combinations.map(
              (combo) => _buildCombinationTile(context, combo),
            )
          else
            ...resolvedSummaryRows
                .take(5)
                .map((row) => _buildSummaryTile(context, row)),
        ],
      ),
    );
  }

  _SummaryRowData _summaryRow(String title, List<ArcAreaIntelBreakdown> items) {
    if (items.isEmpty) {
      return _SummaryRowData('$title: no data yet', 0, 0);
    }
    final top = items.first;
    return _SummaryRowData(
      '$title: ${top.label}',
      top.reportCount,
      top.percentage,
    );
  }

  Widget _buildSummaryTile(BuildContext context, _SummaryRowData row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${row.percentage.toStringAsFixed(0)}% • ${row.count}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.neonPink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinationTile(
    BuildContext context,
    ArcIntelCombination combo,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            combo.summaryLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${combo.percentageLabel} • ${combo.reportCount} confirmation${combo.reportCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.neonPink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<ArcBlueprint?> _showBlueprintPicker(BuildContext context) async {
    final controller = TextEditingController();
    var filtered = List<ArcBlueprint>.from(_blueprints);

    return showModalBottomSheet<ArcBlueprint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFilter(String query) {
              final normalized = query.trim().toLowerCase();
              setModalState(() {
                filtered = _blueprints
                    .where((item) {
                      return item.name.toLowerCase().contains(normalized);
                    })
                    .toList(growable: false);
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      onChanged: updateFilter,
                      decoration: AppTheme.tradingInputDecoration(
                        label: 'Search Blueprints',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Colors.white12),
                        itemBuilder: (context, index) {
                          final blueprint = filtered[index];
                          return ListTile(
                            leading: Icon(
                              blueprint.icon,
                              color: AppTheme.neonCyan,
                            ),
                            title: Text(
                              blueprint.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              blueprint.category,
                              style: const TextStyle(color: Colors.white60),
                            ),
                            onTap: () => Navigator.of(context).pop(blueprint),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData(this.label, this.count, this.percentage);

  final String label;
  final int count;
  final double percentage;
}
