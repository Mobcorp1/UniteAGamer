import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
      extendBody: true,
      bottomNavigationBar: const ArcCompanionBottomDock(
        activeLabel: 'Community Intel',
      ),
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Intel Explorer',
          style: ArcUiTokens.sectionTitle(
            fontSize: 20,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
          children: [
            const ArcRaidersHeroBanner(
              title: 'INTEL EXPLORER',
              subtitle:
                  'Pick a blueprint and collapse community reports into the strongest current map, area, container and event signals.',
              accent: ArcUiTokens.primaryAccent,
            ),
            const SizedBox(height: AppTheme.spaceM),
            _buildBlueprintSelector(context),
            const SizedBox(height: AppTheme.spaceM),
            if (_selectedBlueprint == null)
              _buildEmptyState(context)
            else
              StreamBuilder<ArcDropIntel>(
                stream: _repository.watchIntelForBlueprint(
                  _selectedBlueprint!.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const ArcRaidersStatePanel(
                      title: 'Community intel unavailable',
                      message:
                          'Player-confirmed signals could not load right now.',
                      icon: Icons.cloud_off_rounded,
                      accent: ArcUiTokens.warning,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return ArcRaidersStatePanel(
                      title: 'Building intel picture',
                      message:
                          'Checking community reports for ${_selectedBlueprint!.name}.',
                      icon: Icons.sync_rounded,
                      compact: true,
                    );
                  }

                  final intel =
                      snapshot.data ??
                      ArcDropIntel.empty(_selectedBlueprint!.id);
                  return _buildIntelBody(context, _selectedBlueprint!, intel);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintSelector(BuildContext context) {
    return ArcRaidersSectionCard(
      accent: ArcUiTokens.primaryAccent,
      radius: ArcUiTokens.radiusL,
      padding: const EdgeInsets.all(16),
      selected: _selectedBlueprint != null,
      onTap: () async {
        final picked = await _showBlueprintPicker(context);
        if (!mounted || picked == null) return;
        setState(() => _selectedBlueprint = picked);
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
              border: Border.all(
                color: ArcUiTokens.primaryAccent.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: ArcUiTokens.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BLUEPRINT SIGNAL', style: ArcUiTokens.label()),
                const SizedBox(height: 5),
                Text(
                  _selectedBlueprint?.name ?? 'Select a blueprint',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.cardTitle(
                    fontSize: 16,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.expand_more_rounded,
            color: ArcUiTokens.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const ArcRaidersStatePanel(
      title: 'Choose a blueprint',
      message:
          'UAG will summarise where players most often report finding it and surface the strongest confirmed combinations.',
      icon: Icons.radar_rounded,
      accent: ArcUiTokens.primaryAccent,
    );
  }

  Widget _buildIntelBody(
    BuildContext context,
    ArcBlueprint blueprint,
    ArcDropIntel intel,
  ) {
    if (!intel.hasReports) {
      return ArcRaidersStatePanel(
        title: 'No community intel yet',
        message:
            'No confirmed reports exist for ${blueprint.name} yet. The first submissions will begin building the signal picture here.',
        icon: Icons.travel_explore_rounded,
        accent: ArcUiTokens.secondaryAccent,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(context, blueprint, intel),
        const SizedBox(height: AppTheme.spaceM),
        CollapsibleSectionCard(
          title: 'Best Chance',
          initiallyExpanded: true,
          titleColor: AppTheme.neonPink,
          child: _buildBestChanceCard(context, intel),
        ),
        const SizedBox(height: AppTheme.spaceM),
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
        const SizedBox(height: AppTheme.spaceM),
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
        const SizedBox(height: AppTheme.spaceM),
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
        const SizedBox(height: AppTheme.spaceM),
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
        const SizedBox(height: AppTheme.spaceM),
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
    return ArcRaidersSectionCard(
      accent: ArcUiTokens.secondaryAccent,
      radius: ArcUiTokens.radiusL,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            blueprint.name,
            style: ArcUiTokens.sectionTitle(
              fontSize: 24,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on ${intel.totalReports} player confirmation${intel.totalReports == 1 ? '' : 's'}.',
            style: ArcUiTokens.body(),
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
                valueColor: ArcUiTokens.textPrimary,
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

    return ArcRaidersSectionCard(
      accent: ArcUiTokens.secondaryAccent,
      radius: ArcUiTokens.radiusL,
      padding: const EdgeInsets.all(18),
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fast read of the strongest current signal for this blueprint.',
            style: ArcUiTokens.bodySmall(),
          ),
          const SizedBox(height: AppTheme.spaceM),
          _buildBestChanceRow(context, 'Map', mapLabel),
          _buildBestChanceRow(context, 'Area / POI', areaLabel),
          _buildBestChanceRow(context, 'Container', containerLabel),
          _buildBestChanceRow(context, 'Event', eventLabel),
          if (topCombo != null) ...[
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Top combo strength: ${topCombo.percentageLabel} - ${topCombo.reportCount} confirmation${topCombo.reportCount == 1 ? '' : 's'}',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
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
            child: Text(label, style: ArcUiTokens.metadata()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: ArcUiTokens.body(
                color: ArcUiTokens.textPrimary,
                weight: FontWeight.w700,
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
      decoration: ArcUiTokens.chipDecoration(color: valueColor),
      child: RichText(
        text: TextSpan(
          style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
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
        return ArcUiTokens.primaryAccent;
      case 'Medium':
        return ArcUiTokens.attentionAccent;
      case 'Low':
        return ArcUiTokens.secondaryAccent;
      default:
        return ArcUiTokens.textSecondary;
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

    return ArcRaidersSectionCard(
      accent: ArcUiTokens.primaryAccent,
      radius: ArcUiTokens.radiusL,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              title,
              style: ArcUiTokens.sectionTitle(
                fontSize: 20,
                color: ArcUiTokens.primaryAccent,
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
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.08,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: ArcUiTokens.body(
                color: ArcUiTokens.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${row.percentage.toStringAsFixed(0)}% - ${row.count}',
            style: ArcUiTokens.label(color: ArcUiTokens.secondaryAccent),
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
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            combo.summaryLabel,
            style: ArcUiTokens.body(
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${combo.percentageLabel} ${combo.reportCount} confirmation${combo.reportCount == 1 ? '' : 's'}',
            style: ArcUiTokens.label(color: ArcUiTokens.secondaryAccent),
          ),
        ],
      ),
    );
  }

  Future<ArcBlueprint?> _showBlueprintPicker(BuildContext context) async {
    final controller = TextEditingController();
    var filtered = List<ArcBlueprint>.from(_blueprints);

    final picked = await showModalBottomSheet<ArcBlueprint>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ArcUiTokens.radiusXL),
        ),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          color: ArcUiTokens.primaryAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SELECT BLUEPRINT SIGNAL',
                            style: ArcUiTokens.sectionTitle(
                              fontSize: 16,
                              color: ArcUiTokens.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                      onChanged: updateFilter,
                      decoration: ArcUiTokens.inputDecoration(
                        labelText: 'Search Blueprints',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const ArcRaidersStatePanel(
                              title: 'No blueprint matches',
                              message:
                                  'Try a shorter or different blueprint name.',
                              icon: Icons.search_off_rounded,
                              accent: ArcUiTokens.warning,
                              compact: true,
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final blueprint = filtered[index];
                                return ArcRaidersSectionCard(
                                  accent: ArcUiTokens.primaryAccent,
                                  radius: ArcUiTokens.radiusM,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(blueprint),
                                  child: Row(
                                    children: [
                                      Icon(
                                        blueprint.icon,
                                        color: ArcUiTokens.primaryAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              blueprint.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: ArcUiTokens.body(
                                                color: ArcUiTokens.textPrimary,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              blueprint.category,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: ArcUiTokens.bodySmall(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: ArcUiTokens.textTertiary,
                                      ),
                                    ],
                                  ),
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

    controller.dispose();
    return picked;
  }
}

class _SummaryRowData {
  const _SummaryRowData(this.label, this.count, this.percentage);

  final String label;
  final int count;
  final double percentage;
}
