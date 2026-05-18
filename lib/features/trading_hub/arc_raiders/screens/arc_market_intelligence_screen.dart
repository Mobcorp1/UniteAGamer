import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_traders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcMarketIntelligenceScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/market';

  const ArcMarketIntelligenceScreen({super.key});

  @override
  State<ArcMarketIntelligenceScreen> createState() =>
      _ArcMarketIntelligenceScreenState();
}

class _ArcMarketIntelligenceScreenState
    extends State<ArcMarketIntelligenceScreen> {
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcScrappyRepository _scrappyRepository = ArcScrappyRepository();

  final TextEditingController _prioritySearchController =
      TextEditingController();

  @override
  void dispose() {
    _prioritySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Intel Snapshot',
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
            child: StreamBuilder<List<ArcBlueprintDropReport>>(
              stream: _blueprintRepository.watchRecentReports(limit: 320),
              builder: (context, reportsSnapshot) {
                final reports =
                    reportsSnapshot.data ?? const <ArcBlueprintDropReport>[];

                return StreamBuilder<Map<String, ArcBlueprintState>>(
                  stream: _blueprintRepository.watchMyBlueprintStates(),
                  builder: (context, blueprintStateSnapshot) {
                    final blueprintStates =
                        blueprintStateSnapshot.data ??
                        <String, ArcBlueprintState>{};

                    return StreamBuilder<Map<String, ArcScrappyState>>(
                      stream: _scrappyRepository.watchMyScrappyStates(),
                      builder: (context, scrappySnapshot) {
                        final scrappyStates =
                            scrappySnapshot.data ?? <String, ArcScrappyState>{};

                        return _buildBody(
                          context,
                          reports: reports,
                          blueprintStates: blueprintStates,
                          scrappyStates: scrappyStates,
                          loading:
                              reportsSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              reports.isEmpty,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<ArcBlueprintDropReport> reports,
    required Map<String, ArcBlueprintState> blueprintStates,
    required Map<String, ArcScrappyState> scrappyStates,
    required bool loading,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final blueprints = [...ArcBlueprintSeedData.blueprints]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final List<ArcScrappyItem> scrappyItems =
        ArcScrappySeedData.items.whereType<ArcScrappyItem>().toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final intelByBlueprintId = _buildIntelMap(reports);
    final priorityBlueprints = _resolvePriorityBlueprints(
      blueprints: blueprints,
      states: blueprintStates,
      intelByBlueprintId: intelByBlueprintId,
    );
    final missingBlueprints = _resolveMissingBlueprints(
      blueprints: blueprints,
      states: blueprintStates,
      intelByBlueprintId: intelByBlueprintId,
      priorityIds: priorityBlueprints.map((item) => item.id).toSet(),
    );
    final wantedResources = _resolveWantedResources(
      items: scrappyItems,
      states: scrappyStates,
    );

    final totalMissing = blueprints.where((blueprint) {
      final state =
          blueprintStates[blueprint.id] ??
          ArcBlueprintState.empty(blueprint.id);
      return !state.owned;
    }).length;

    return ListView(
      padding: AppTheme.pagePadding,
      children: [
        _buildHeroCard(
          context,
          totalReports: reports.length,
          totalMissing: totalMissing,
          priorityCount: priorityBlueprints.length,
          wantedResourceCount: wantedResources.length,
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Priority 5 Targets',
          initiallyExpanded: false,
          titleColor: AppTheme.neonCyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pin up to five missing blueprints and this screen will keep the snapshot focused on the items you actually want next.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openPriorityManager(
                        blueprints: blueprints,
                        states: blueprintStates,
                      ),
                      icon: const Icon(Icons.push_pin_outlined),
                      label: const Text('Set Priority 5'),
                    ),
                    if (priorityBlueprints.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _clearPriorities(
                          blueprintStates,
                          priorityBlueprints,
                        ),
                        icon: const Icon(Icons.layers_clear_outlined),
                        label: const Text('Clear Priorities'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (priorityBlueprints.isEmpty)
                _buildEmptyPanel(
                  context,
                  'No manual priorities set yet. Your next best missing blueprints are shown below automatically.',
                )
              else
                ...priorityBlueprints.map(
                  (blueprint) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                    child: _buildBlueprintIntelCard(
                      context,
                      blueprint: blueprint,
                      intel:
                          intelByBlueprintId[blueprint.id] ??
                          ArcDropIntel.empty(blueprint.id),
                      state:
                          blueprintStates[blueprint.id] ??
                          ArcBlueprintState.empty(blueprint.id),
                      reportsForBlueprint: _reportsForBlueprint(
                        reports,
                        blueprint.id,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Best Next Missing Blueprints',
          initiallyExpanded: false,
          titleColor: AppTheme.neonPink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended targets based on your missing collection, wanted priorities and recent community discoveries.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (missingBlueprints.isEmpty)
                _buildEmptyPanel(
                  context,
                  'You have no remaining missing blueprints in the current tracker.',
                )
              else
                ...missingBlueprints
                    .take(5)
                    .map(
                      (blueprint) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                        child: _buildBlueprintIntelCard(
                          context,
                          blueprint: blueprint,
                          intel:
                              intelByBlueprintId[blueprint.id] ??
                              ArcDropIntel.empty(blueprint.id),
                          state:
                              blueprintStates[blueprint.id] ??
                              ArcBlueprintState.empty(blueprint.id),
                          reportsForBlueprint: _reportsForBlueprint(
                            reports,
                            blueprint.id,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Wanted Scrappy Resources',
          initiallyExpanded: false,
          titleColor: AppTheme.warningAmber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resources do not use the same drop-intel report system yet, so this section stays focused on what you still need rather than showing noisy generic map spam.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (wantedResources.isEmpty)
                _buildEmptyPanel(
                  context,
                  'No wanted scrappy resources right now. Your current scrappy tracker looks complete.',
                )
              else
                ...wantedResources
                    .take(6)
                    .map(
                      (resource) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                        child: _buildScrappyCard(context, resource),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        CollapsibleSectionCard(
          title: 'Community Pulse',
          initiallyExpanded: false,
          titleColor: AppTheme.neonCyan,
          child: reports.isEmpty
              ? _buildEmptyPanel(
                  context,
                  'No community blueprint reports have been logged yet, so confidence is still building.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildPulseRows(reports).map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                        child: _buildPulseRow(context, row),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Map<String, ArcDropIntel> _buildIntelMap(
    List<ArcBlueprintDropReport> reports,
  ) {
    final grouped = <String, List<ArcBlueprintDropReport>>{};
    for (final report in reports) {
      grouped
          .putIfAbsent(report.blueprintId, () => <ArcBlueprintDropReport>[])
          .add(report);
    }

    return grouped.map(
      (key, value) => MapEntry(
        key,
        ArcDropIntel.fromReports(blueprintId: key, reports: value),
      ),
    );
  }

  List<ArcBlueprint> _resolvePriorityBlueprints({
    required List<ArcBlueprint> blueprints,
    required Map<String, ArcBlueprintState> states,
    required Map<String, ArcDropIntel> intelByBlueprintId,
  }) {
    final byId = {for (final blueprint in blueprints) blueprint.id: blueprint};
    final prioritized =
        states.values
            .where((state) => state.priorityRank > 0 && !state.owned)
            .toList(growable: false)
          ..sort((a, b) {
            final rankCompare = a.priorityRank.compareTo(b.priorityRank);
            if (rankCompare != 0) return rankCompare;
            final aIntel = intelByBlueprintId[a.blueprintId]?.totalReports ?? 0;
            final bIntel = intelByBlueprintId[b.blueprintId]?.totalReports ?? 0;
            return bIntel.compareTo(aIntel);
          });

    return prioritized
        .map((state) => byId[state.blueprintId])
        .whereType<ArcBlueprint>()
        .take(5)
        .toList(growable: false);
  }

  List<ArcBlueprint> _resolveMissingBlueprints({
    required List<ArcBlueprint> blueprints,
    required Map<String, ArcBlueprintState> states,
    required Map<String, ArcDropIntel> intelByBlueprintId,
    required Set<String> priorityIds,
  }) {
    final missing = blueprints
        .where((blueprint) {
          final state =
              states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
          return !state.owned && !priorityIds.contains(blueprint.id);
        })
        .toList(growable: false);

    missing.sort((a, b) {
      final aIntel = intelByBlueprintId[a.id]?.totalReports ?? 0;
      final bIntel = intelByBlueprintId[b.id]?.totalReports ?? 0;
      final intelCompare = bIntel.compareTo(aIntel);
      if (intelCompare != 0) return intelCompare;
      final rarityCompare = _rarityWeight(
        b.rarity,
      ).compareTo(_rarityWeight(a.rarity));
      if (rarityCompare != 0) return rarityCompare;
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return missing;
  }

  List<_WantedScrappyTarget> _resolveWantedResources({
    required List<ArcScrappyItem> items,
    required Map<String, ArcScrappyState> states,
  }) {
    final targets = <_WantedScrappyTarget>[];

    for (final item in items) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      final remaining = state.remainingNeededFor(item.neededCount);
      if (remaining <= 0) continue;
      targets.add(
        _WantedScrappyTarget(
          item: item,
          state: state,
          remainingNeeded: remaining,
        ),
      );
    }

    targets.sort((a, b) {
      final remainingCompare = b.remainingNeeded.compareTo(a.remainingNeeded);
      if (remainingCompare != 0) return remainingCompare;
      return a.item.sortOrder.compareTo(b.item.sortOrder);
    });

    return targets;
  }

  int _rarityWeight(ArcBlueprintRarity rarity) {
    switch (rarity) {
      case ArcBlueprintRarity.common:
        return 1;
      case ArcBlueprintRarity.uncommon:
        return 2;
      case ArcBlueprintRarity.rare:
        return 3;
      case ArcBlueprintRarity.epic:
        return 4;
      case ArcBlueprintRarity.legendary:
        return 5;
    }
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required int totalReports,
    required int totalMissing,
    required int priorityCount,
    required int wantedResourceCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
        radius: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your personal Arc Raiders intel snapshot.',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          const Text(
            'This replaces the old split between Market Intel and Intel Explorer. It now leads with what you still need, what you most want, and where the community is actually seeing those targets.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatPill(
                'Community Reports',
                '$totalReports',
                AppTheme.neonCyan,
              ),
              _buildStatPill(
                'Missing Blueprints',
                '$totalMissing',
                AppTheme.neonPink,
              ),
              _buildStatPill(
                'Priority Targets',
                '$priorityCount / 5',
                AppTheme.warningAmber,
              ),
              _buildStatPill(
                'Wanted Resources',
                '$wantedResourceCount',
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: RichText(
        text: TextSpan(
          style: AppTheme.bodyTextStyle(
            fontSize: 13,
            color: Colors.white70,
            isBold: true,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: color,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ArcBlueprintDropReport> _reportsForBlueprint(
    List<ArcBlueprintDropReport> reports,
    String blueprintId,
  ) {
    final matches = reports
        .where((report) => report.blueprintId == blueprintId)
        .toList(growable: false);

    return [...matches]..sort((a, b) {
      final aDate = a.lastConfirmedAt ?? a.createdAt ?? a.foundAt;
      final bDate = b.lastConfirmedAt ?? b.createdAt ?? b.foundAt;

      if (aDate == null && bDate == null) {
        return b.confirmationCount.compareTo(a.confirmationCount);
      }

      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });
  }

  Widget _buildBlueprintIntelCard(
    BuildContext context, {
    required ArcBlueprint blueprint,
    required ArcDropIntel intel,
    required ArcBlueprintState state,
    required List<ArcBlueprintDropReport> reportsForBlueprint,
  }) {
    final hasIntel = intel.hasReports;
    final topCombo = intel.topCombinations.isEmpty
        ? null
        : intel.topCombinations.first;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: state.isPrioritized
            ? AppTheme.warningAmber.withValues(alpha: 0.34)
            : AppTheme.neonPink.withValues(alpha: 0.24),
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blueprint.name,
                      style: AppTheme.tradingHeading(
                        fontSize: 20,
                        color: AppTheme.neonPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${blueprint.category} • ${blueprint.rarityLabel}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              if (state.isPrioritized)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: AppTheme.tradingPillDecoration(
                    color: AppTheme.warningAmber,
                  ),
                  child: Text(
                    'Priority ${state.priorityRank}',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: AppTheme.warningAmber,
                      isBold: true,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (hasIntel) ...[
            _buildInfoLine(
              'Best map',
              topCombo?.mapLabel ?? intel.topMapLabel ?? 'No map signal',
            ),
            _buildInfoLine(
              'Best POI / area',
              topCombo?.areaLabel ?? intel.topAreaLabel ?? 'No area signal',
            ),
            _buildInfoLine(
              'Best container',
              topCombo?.containerLabel ??
                  intel.topContainerLabel ??
                  'No container signal',
            ),
            _buildInfoLine(
              'Condition / event',
              _buildConditionLabel(topCombo, intel),
            ),
            _buildInfoLine('Confidence', _buildConfidenceLabel(intel)),
            _buildInfoLine(
              'Last reported',
              _relativeDateLabel(intel.lastReportedAt),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: reportsForBlueprint.isEmpty
                    ? null
                    : () => _showBlueprintReportDrilldown(
                        context,
                        blueprint: blueprint,
                        intel: intel,
                        reports: reportsForBlueprint,
                      ),
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('View report details'),
              ),
            ),
          ] else ...[
            Text(
              blueprint.intelHint,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 10),
            const Text(
              'No community reports yet. This target stays in your snapshot so you can decide what to chase next even before data builds up.',
              style: TextStyle(color: Colors.white54, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showBlueprintReportDrilldown(
    BuildContext context, {
    required ArcBlueprint blueprint,
    required ArcDropIntel intel,
    required List<ArcBlueprintDropReport> reports,
  }) async {
    final latestReports = reports.take(12).toList(growable: false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.94,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: AppTheme.pagePadding,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          blueprint.name,
                          style: AppTheme.tradingHeading(
                            fontSize: 25,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    'Intel drilldown based on community reports for this blueprint.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 14,
                      color: AppTheme.tradingMutedText,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildIntelChip(
                        'Confidence',
                        _buildConfidenceLabel(intel),
                        AppTheme.neonPink,
                      ),
                      _buildIntelChip(
                        'Reports',
                        '${intel.totalReports}',
                        AppTheme.neonCyan,
                      ),
                      _buildIntelChip(
                        'Last seen',
                        _relativeDateLabel(intel.lastReportedAt),
                        AppTheme.warningAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  if (intel.topCombinations.isNotEmpty) ...[
                    Text(
                      'Strongest Reported Conditions',
                      style: AppTheme.tradingHeading(
                        fontSize: 20,
                        color: AppTheme.neonPink,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    ...intel.topCombinations
                        .take(5)
                        .map(
                          (combo) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceS,
                            ),
                            child: _buildCombinationCard(combo),
                          ),
                        ),
                    const SizedBox(height: AppTheme.spaceL),
                  ],
                  Text(
                    'Recent Reports',
                    style: AppTheme.tradingHeading(
                      fontSize: 20,
                      color: AppTheme.neonPink,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  if (latestReports.isEmpty)
                    _buildEmptyPanel(
                      context,
                      'No report records are available for this blueprint yet.',
                    )
                  else
                    ...latestReports.map(
                      (report) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                        child: _buildReportDetailCard(report),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIntelChip(String label, String value, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(fontSize: 12, color: color, isBold: true),
      ),
    );
  }

  Widget _buildCombinationCard(ArcIntelCombination combo) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoLine('Map', combo.mapLabel),
          _buildInfoLine('Area / POI', combo.areaLabel),
          _buildInfoLine('Container', combo.containerLabel),
          _buildInfoLine('Weather', combo.weatherLabel),
          _buildInfoLine('Event', combo.eventLabel),
          _buildInfoLine(
            'Support',
            '${combo.reportCount} weighted reports • ${combo.percentageLabel}',
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetailCard(ArcBlueprintDropReport report) {
    final timestamp =
        report.lastConfirmedAt ?? report.createdAt ?? report.foundAt;
    final showLegacyEntryTime = report.entryTime != ArcEntryTime.unknown;
    final isRaidSpecific =
        report.mapName.trim().isNotEmpty &&
        report.mapName.trim().toLowerCase() != 'not raid specific';

    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildIntelChip(
                'Source',
                report.acquisitionSource.label,
                AppTheme.neonCyan,
              ),
              _buildIntelChip(
                'Confirmed',
                '${report.confirmationCount}',
                AppTheme.neonPink,
              ),
              _buildIntelChip(
                'Seen',
                _relativeDateLabel(timestamp),
                AppTheme.warningAmber,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (isRaidSpecific) ...[
            _buildInfoLine('Map', report.mapName),
            _buildInfoLine('Event', report.eventLabel),
            _buildInfoLine('Area / POI', report.areaLabel),
            _buildInfoLine('Container', report.resolvedContainerLabel),
            _buildInfoLine('Raid Round', report.raidType.label),
            _buildInfoLine('Raider Time', report.timeOfDay.label),
            if (showLegacyEntryTime)
              _buildInfoLine('Legacy Entry Time', report.entryTime.label),
          ] else ...[
            _buildInfoLine('Location', 'Not raid specific'),
          ],
          if (report.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceS),
            _buildInfoLine('Notes', report.notes.trim()),
          ],
        ],
      ),
    );
  }

  Widget _buildScrappyCard(BuildContext context, _WantedScrappyTarget target) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.warningAmber.withValues(alpha: 0.24),
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  target.item.name,
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: AppTheme.warningAmber,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppTheme.tradingPillDecoration(
                  color: AppTheme.warningAmber,
                ),
                child: Text(
                  '${target.state.collectedCount}/${target.item.neededCount}',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.warningAmber,
                    isBold: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Need ${target.remainingNeeded} more • ${target.item.tierLabel}',
            style: const TextStyle(color: Colors.white70),
          ),
          if ((target.item.locationHint?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              target.item.locationHint!.trim(),
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPanel(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.35),
      ),
    );
  }

  Widget _buildPulseRow(BuildContext context, _PulseRow row) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            row.value,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: AppTheme.neonPink,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  List<_PulseRow> _buildPulseRows(List<ArcBlueprintDropReport> reports) {
    final mapCounts = <String, int>{};
    final conditionCounts = <String, int>{};
    final containerCounts = <String, int>{};

    for (final report in reports) {
      mapCounts.update(report.mapName, (value) => value + 1, ifAbsent: () => 1);
      final condition = (report.conditionLabel?.trim().isNotEmpty ?? false)
          ? report.conditionLabel!.trim()
          : 'No Special Condition';
      conditionCounts.update(
        condition,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      containerCounts.update(
        report.resolvedContainerLabel,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String topLabel(Map<String, int> values) {
      if (values.isEmpty) return 'No data';
      final sorted = values.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return '${sorted.first.key} • ${sorted.first.value}';
    }

    return [
      _PulseRow('Most active map', topLabel(mapCounts)),
      _PulseRow('Most active condition', topLabel(conditionCounts)),
      _PulseRow('Most active container', topLabel(containerCounts)),
      _PulseRow(
        'Latest report',
        _relativeDateLabel(
          reports
              .map((e) => e.createdAt ?? e.foundAt)
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (prev, item) =>
                    prev == null || item.isAfter(prev) ? item : prev,
              ),
        ),
      ),
    ];
  }

  String _buildConditionLabel(
    ArcIntelCombination? topCombo,
    ArcDropIntel intel,
  ) {
    final weather =
        topCombo?.weatherLabel ?? intel.topWeatherLabel ?? 'No Special Weather';
    final event =
        topCombo?.eventLabel ?? intel.topMapEventLabel ?? 'No Map Event';
    if (weather == 'No Special Weather' && event == 'No Map Event') {
      return 'No strong special condition yet';
    }
    if (weather == 'No Special Weather') return event;
    if (event == 'No Map Event') return weather;
    return '$weather • $event';
  }

  String _buildConfidenceLabel(ArcDropIntel intel) {
    final total = intel.totalReports;
    final topCount = intel.topCombinations.isEmpty
        ? 0
        : intel.topCombinations.first.reportCount;
    if (total >= 12 && topCount >= 4) return 'High';
    if (total >= 5 && topCount >= 2) return 'Medium';
    if (total > 0) return 'Early';
    return 'None';
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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

  String _relativeDateLabel(DateTime? date) {
    if (date == null) return 'Unknown';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _clearPriorities(
    Map<String, ArcBlueprintState> blueprintStates,
    List<ArcBlueprint> priorityBlueprints,
  ) async {
    final updates = priorityBlueprints
        .map((blueprint) {
          final current =
              blueprintStates[blueprint.id] ??
              ArcBlueprintState.empty(blueprint.id);
          return current.copyWith(priorityRank: 0, updatedAt: DateTime.now());
        })
        .toList(growable: false);

    await _blueprintRepository.saveBlueprintStates(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Priority targets cleared.')));
  }

  Future<void> _openPriorityManager({
    required List<ArcBlueprint> blueprints,
    required Map<String, ArcBlueprintState> states,
  }) async {
    final missingBlueprints = blueprints
        .where((blueprint) {
          final state =
              states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
          return !state.owned;
        })
        .toList(growable: false);

    final initialSelection =
        states.values
            .where((state) => state.priorityRank > 0 && !state.owned)
            .toList(growable: false)
          ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));

    final selectedIds = initialSelection
        .map((state) => state.blueprintId)
        .toList();
    var search = '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final filtered = missingBlueprints
                .where((blueprint) {
                  if (search.trim().isEmpty) return true;
                  final haystack = '${blueprint.name} ${blueprint.category}'
                      .toLowerCase();
                  return haystack.contains(search.trim().toLowerCase());
                })
                .toList(growable: false);

            void toggle(String blueprintId) {
              setModalState(() {
                if (selectedIds.contains(blueprintId)) {
                  selectedIds.remove(blueprintId);
                } else if (selectedIds.length < 5) {
                  selectedIds.add(blueprintId);
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Priority 5',
                      style: AppTheme.tradingHeading(
                        fontSize: 22,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick up to five missing blueprints in the order you want to chase them next.',
                      style: Theme.of(sheetContext).textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _prioritySearchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) => setModalState(() => search = value),
                      decoration: AppTheme.tradingInputDecoration(
                        label: 'Search missing blueprints',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedIds
                          .asMap()
                          .entries
                          .map((entry) {
                            final blueprint = missingBlueprints.firstWhere(
                              (item) => item.id == entry.value,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: AppTheme.tradingPillDecoration(
                                color: AppTheme.warningAmber,
                              ),
                              child: Text(
                                '${entry.key + 1}. ${blueprint.name}',
                                style: AppTheme.bodyTextStyle(
                                  fontSize: 12,
                                  color: AppTheme.warningAmber,
                                  isBold: true,
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
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
                          final isSelected = selectedIds.contains(blueprint.id);
                          final order = isSelected
                              ? selectedIds.indexOf(blueprint.id) + 1
                              : null;
                          return ListTile(
                            onTap: () => toggle(blueprint.id),
                            leading: Icon(
                              blueprint.icon,
                              color: isSelected
                                  ? AppTheme.warningAmber
                                  : AppTheme.neonCyan,
                            ),
                            title: Text(
                              blueprint.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${blueprint.category} • ${blueprint.rarityLabel}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: isSelected
                                ? CircleAvatar(
                                    radius: 13,
                                    backgroundColor: AppTheme.warningAmber,
                                    child: Text(
                                      '$order',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white54,
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final currentPriorityIds = states.values
                                  .where((state) => state.priorityRank > 0)
                                  .map((state) => state.blueprintId)
                                  .toSet();
                              final affectedIds = {
                                ...currentPriorityIds,
                                ...selectedIds,
                              };

                              final updates = <ArcBlueprintState>[];
                              for (final blueprintId in affectedIds) {
                                final current =
                                    states[blueprintId] ??
                                    ArcBlueprintState.empty(blueprintId);
                                final nextRank =
                                    selectedIds.indexOf(blueprintId) + 1;
                                updates.add(
                                  current.copyWith(
                                    priorityRank: nextRank <= 0 ? 0 : nextRank,
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                              }

                              await _blueprintRepository.saveBlueprintStates(
                                updates,
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop(true);
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    _prioritySearchController.clear();

    if (!mounted) return;

    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Priority targets updated.')),
      );
    }
  }
}

class _PulseRow {
  const _PulseRow(this.label, this.value);

  final String label;
  final String value;
}

class _WantedScrappyTarget {
  const _WantedScrappyTarget({
    required this.item,
    required this.state,
    required this.remainingNeeded,
  });

  final ArcScrappyItem item;
  final ArcScrappyState state;
  final int remainingNeeded;
}
