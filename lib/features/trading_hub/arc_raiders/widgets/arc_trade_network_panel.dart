import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_network_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_intel_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcTradeNetworkPanel extends StatefulWidget {
  const ArcTradeNetworkPanel({
    super.key,
    required this.repository,
    required this.blueprintStates,
    required this.activeListings,
    required this.trackedItemQuantities,
    this.engine = const ArcTradeIntelligenceEngine(),
    this.intelRepository,
  });

  final TradingRepository repository;
  final Map<String, ArcBlueprintState> blueprintStates;
  final List<TradingListing> activeListings;
  final Map<String, int> trackedItemQuantities;
  final ArcTradeIntelligenceEngine engine;
  final ArcBlueprintIntelRepository? intelRepository;

  @override
  State<ArcTradeNetworkPanel> createState() => _ArcTradeNetworkPanelState();
}

class _ArcTradeNetworkPanelState extends State<ArcTradeNetworkPanel> {
  final Set<String> _syncKeys = <String>{};
  bool _creatingWatch = false;

  ArcBlueprintIntelRepository get _intelRepository =>
      widget.intelRepository ?? ArcBlueprintIntelRepository();

  Map<String, int> get _ownedQuantities =>
      widget.engine.buildOwnedItemQuantities(
        blueprintStates: widget.blueprintStates,
        trackedItemQuantities: widget.trackedItemQuantities,
      );

  void _openListing(String? listingId) {
    if (listingId == null || listingId.isEmpty) return;
    final matches = widget.activeListings.where((item) => item.id == listingId);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That listing is no longer active.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TradingListingDetailScreen(listing: matches.first),
      ),
    );
  }

  Future<void> _prepareForTrade(ArcTradeOpportunity opportunity) async {
    final uid = widget.repository.currentUid;
    if (uid == null || uid.isEmpty || _creatingWatch) return;

    setState(() => _creatingWatch = true);
    try {
      final preparation = widget.engine.buildPreparation(
        userId: uid,
        opportunity: opportunity,
        now: DateTime.now(),
      );
      await widget.repository.saveTradePreparation(preparation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade preparation added to Watching.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not watch this trade: $error')),
      );
    } finally {
      if (mounted) setState(() => _creatingWatch = false);
    }
  }

  void _queueReadinessSync(ArcTradePreparation updated) {
    final signature = [
      updated.id,
      updated.status.name,
      _itemsSignature(updated.ownedItems),
      _itemsSignature(updated.remainingItems),
    ].join('|');
    if (!_syncKeys.add(signature)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.repository.updateTradePreparationReadiness(updated);
      } catch (_) {
        // Readiness sync is best effort. The local panel still shows progress.
      }
    });
  }

  bool _needsSync(ArcTradePreparation original, ArcTradePreparation updated) {
    return original.status != updated.status ||
        _itemsSignature(original.ownedItems) !=
            _itemsSignature(updated.ownedItems) ||
        _itemsSignature(original.remainingItems) !=
            _itemsSignature(updated.remainingItems);
  }

  String _itemsSignature(List<ArcTradeItemQuantity> items) {
    return items.map((item) => '${item.id}:${item.quantity}').join(',');
  }

  String? _firstBlueprintId(ArcTradeNetworkSummary summary) {
    for (final opportunity in summary.rankedOpportunities) {
      for (final item in opportunity.currentUserReceives) {
        final match = ArcBlueprintSeedData.blueprints.where(
          (blueprint) =>
              blueprint.id == item.id || blueprint.name == item.label,
        );
        if (match.isNotEmpty) return match.first.id;
      }
    }
    return null;
  }

  String _blueprintName(String blueprintId) {
    final match = ArcBlueprintSeedData.blueprints.where(
      (blueprint) => blueprint.id == blueprintId,
    );
    return match.isEmpty ? blueprintId : match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.engine.buildNetworkSummary(
      blueprintStates: widget.blueprintStates,
      activeListings: widget.activeListings,
      currentUid: widget.repository.currentUid,
      ownedItemQuantities: widget.trackedItemQuantities,
    );

    return Container(
      width: double.infinity,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: summary.hasActionableOpportunities
            ? AppTheme.neonCyan.withValues(alpha: 0.34)
            : AppTheme.tradingSoftBorder,
      ),
      padding: AppTheme.sectionCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(summary: summary),
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TradingBlueprintWatchesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Blueprint Watches'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TradingListingQueuesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.dynamic_feed_outlined),
                label: const Text('Listing Queues'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (!summary.hasActionableOpportunities)
            _EmptyNetworkState(summary: summary)
          else ...[
            _OpportunityStrip(
              title: 'Best Matches',
              icon: Icons.bolt_rounded,
              opportunities: summary.directMatches,
              emptyText:
                  'No direct reciprocal listing yet. Chains and preparation watches can still help.',
              onOpenListing: _openListing,
            ),
            const SizedBox(height: AppTheme.spaceM),
            _OpportunityStrip(
              title: 'Three-Raider Chains',
              icon: Icons.hub_rounded,
              opportunities: summary.threeRaiderChains,
              emptyText:
                  'No safe three-player chain found from active listings yet.',
              onOpenListing: _openListing,
            ),
            const SizedBox(height: AppTheme.spaceM),
            _PrepareStrip(
              opportunities: summary.preparationOpportunities,
              creatingWatch: _creatingWatch,
              onPrepare: _prepareForTrade,
              onOpenListing: _openListing,
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          _WatchingPanel(
            repository: widget.repository,
            engine: widget.engine,
            ownedQuantities: _ownedQuantities,
            onNeedsSync: _queueReadinessSync,
            needsSync: _needsSync,
            onOpenListing: _openListing,
          ),
          const SizedBox(height: AppTheme.spaceM),
          _BlueprintIntelPanel(
            blueprintId: _firstBlueprintId(summary),
            blueprintNameFor: _blueprintName,
            intelRepository: _intelRepository,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final ArcTradeNetworkSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.travel_explore_rounded, color: AppTheme.neonCyan),
        const SizedBox(width: AppTheme.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trade Intelligence Network',
                style: AppTheme.tradingHeading(
                  fontSize: 20,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Matches, chains and trade preparation from live listings.',
                style: TextStyle(color: AppTheme.tradingMutedText, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spaceS),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: [
            _metric('Direct', summary.directMatches.length),
            _metric('Chains', summary.threeRaiderChains.length),
            _metric('Prep', summary.preparationOpportunities.length),
          ],
        ),
      ],
    );
  }

  Widget _metric(String label, int value) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: AppTheme.neonPink),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppTheme.neonPink,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OpportunityStrip extends StatelessWidget {
  const _OpportunityStrip({
    required this.title,
    required this.icon,
    required this.opportunities,
    required this.emptyText,
    required this.onOpenListing,
  });

  final String title;
  final IconData icon;
  final List<ArcTradeOpportunity> opportunities;
  final String emptyText;
  final ValueChanged<String?> onOpenListing;

  @override
  Widget build(BuildContext context) {
    return _Subsection(
      title: title,
      icon: icon,
      child: opportunities.isEmpty
          ? _MutedText(emptyText)
          : Column(
              children: opportunities
                  .take(3)
                  .map(
                    (opportunity) => _OpportunityCard(
                      opportunity: opportunity,
                      primaryActionLabel: opportunity.actionLabel,
                      onPrimaryAction: () =>
                          onOpenListing(opportunity.targetListingId),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PrepareStrip extends StatelessWidget {
  const _PrepareStrip({
    required this.opportunities,
    required this.creatingWatch,
    required this.onPrepare,
    required this.onOpenListing,
  });

  final List<ArcTradeOpportunity> opportunities;
  final bool creatingWatch;
  final ValueChanged<ArcTradeOpportunity> onPrepare;
  final ValueChanged<String?> onOpenListing;

  @override
  Widget build(BuildContext context) {
    return _Subsection(
      title: 'Prepare for Trade',
      icon: Icons.inventory_2_outlined,
      child: opportunities.isEmpty
          ? const _MutedText(
              'No partial-payment trade prep found from live listings.',
            )
          : Column(
              children: opportunities
                  .take(3)
                  .map(
                    (opportunity) => _OpportunityCard(
                      opportunity: opportunity,
                      primaryActionLabel: creatingWatch
                          ? 'Watching...'
                          : opportunity.actionLabel,
                      onPrimaryAction: creatingWatch
                          ? null
                          : () => onPrepare(opportunity),
                      secondaryActionLabel: 'Open listing',
                      onSecondaryAction: () =>
                          onOpenListing(opportunity.targetListingId),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _WatchingPanel extends StatelessWidget {
  const _WatchingPanel({
    required this.repository,
    required this.engine,
    required this.ownedQuantities,
    required this.onNeedsSync,
    required this.needsSync,
    required this.onOpenListing,
  });

  final TradingRepository repository;
  final ArcTradeIntelligenceEngine engine;
  final Map<String, int> ownedQuantities;
  final ValueChanged<ArcTradePreparation> onNeedsSync;
  final bool Function(ArcTradePreparation, ArcTradePreparation) needsSync;
  final ValueChanged<String?> onOpenListing;

  @override
  Widget build(BuildContext context) {
    return _Subsection(
      title: 'Watching',
      icon: Icons.visibility_rounded,
      child: StreamBuilder<List<ArcTradePreparation>>(
        stream: repository.watchTradePreparations(),
        builder: (context, snapshot) {
          final preparations = snapshot.data ?? const <ArcTradePreparation>[];
          final visible = preparations
              .where((item) => !item.status.isTerminal)
              .take(4)
              .toList(growable: false);

          if (snapshot.hasError) {
            return const _MutedText(
              'Trade watch records could not be loaded right now.',
            );
          }
          if (visible.isEmpty) {
            return const _MutedText(
              'No watched trades yet. Use Prepare for this trade to track missing payment items.',
            );
          }

          return Column(
            children: visible
                .map((preparation) {
                  final updated = engine.recalculatePreparationReadiness(
                    preparation: preparation,
                    ownedItemQuantities: ownedQuantities,
                    now: DateTime.now(),
                  );
                  if (needsSync(preparation, updated)) {
                    onNeedsSync(updated);
                  }
                  return _WatchCard(
                    preparation: updated,
                    onOpenListing: () => onOpenListing(updated.targetListingId),
                  );
                })
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _BlueprintIntelPanel extends StatelessWidget {
  const _BlueprintIntelPanel({
    required this.blueprintId,
    required this.blueprintNameFor,
    required this.intelRepository,
  });

  final String? blueprintId;
  final String Function(String blueprintId) blueprintNameFor;
  final ArcBlueprintIntelRepository intelRepository;

  @override
  Widget build(BuildContext context) {
    final id = blueprintId;
    if (id == null || id.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Subsection(
      title: 'Blueprint Intel',
      icon: Icons.map_outlined,
      child: FutureBuilder<List<ArcBlueprintDropReport>>(
        future: intelRepository.getReportsForBlueprint(id, limit: 3),
        builder: (context, snapshot) {
          final reports = snapshot.data ?? const <ArcBlueprintDropReport>[];
          if (snapshot.hasError || reports.isEmpty) {
            return _MutedText(
              'No recent community Intel for ${blueprintNameFor(id)} yet.',
            );
          }

          final top = reports.first;
          final condition = top.conditionLabel;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                blueprintNameFor(id),
                style: AppTheme.tradingHeading(
                  fontSize: 16,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: 4),
              _MutedText(
                'Community-reported, not guaranteed: ${top.acquisitionSource.label} at ${top.mapName}'
                '${top.locationName.isEmpty ? '' : ' / ${top.locationName}'}'
                '${condition == null ? '' : ' / $condition'}'
                ' / ${top.confirmationCount} support signal${top.confirmationCount == 1 ? '' : 's'}.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Subsection extends StatelessWidget {
  const _Subsection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: AppTheme.tradingSoftBorder,
        backgroundColor: AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.neonPink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.tradingHeading(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          child,
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final ArcTradeOpportunity opportunity;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 14,
        borderColor: opportunity.satisfiesTopWanted
            ? AppTheme.neonCyan.withValues(alpha: 0.38)
            : AppTheme.neonPink.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(opportunity.type.label, AppTheme.neonPink),
              _pill('${opportunity.confidence}% confidence', AppTheme.neonCyan),
              if (opportunity.satisfiesTopWanted)
                _pill('Top wanted', Colors.amberAccent),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            opportunity.title,
            style: AppTheme.tradingHeading(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            opportunity.reason,
            style: TextStyle(color: AppTheme.tradingMutedText, height: 1.3),
          ),
          if (opportunity.remainingItems.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Remaining: ${_itemsLabel(opportunity.remainingItems)}',
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: AppTheme.neonCyan,
                isBold: true,
              ),
            ),
          ],
          if (opportunity.progressionHint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              opportunity.progressionHint,
              style: TextStyle(color: AppTheme.tradingFaintText, height: 1.3),
            ),
          ],
          const SizedBox(height: AppTheme.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(primaryActionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  foregroundColor: Colors.white,
                ),
              ),
              if (secondaryActionLabel != null)
                OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(secondaryActionLabel!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.neonCyan,
                    side: const BorderSide(color: AppTheme.neonCyan),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPrimaryAction,
      child: card,
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  String _itemsLabel(List<ArcTradeItemQuantity> items) {
    return items
        .map(
          (item) =>
              item.quantity > 1 ? '${item.quantity} ${item.label}' : item.label,
        )
        .join(', ');
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({required this.preparation, required this.onOpenListing});

  final ArcTradePreparation preparation;
  final VoidCallback onOpenListing;

  @override
  Widget build(BuildContext context) {
    final statusColor = preparation.isReady
        ? Colors.lightGreenAccent
        : AppTheme.neonCyan;

    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  preparation.listingTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(fontSize: 16),
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              Container(
                padding: AppTheme.pillPadding,
                decoration: AppTheme.tradingPillDecoration(color: statusColor),
                child: Text(
                  preparation.isReady ? 'Ready' : preparation.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MutedText(preparation.readinessLabel),
          const SizedBox(height: AppTheme.spaceS),
          OutlinedButton.icon(
            onPressed: onOpenListing,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open listing'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.neonCyan,
              side: const BorderSide(color: AppTheme.neonCyan),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onOpenListing,
      child: card,
    );
  }
}

class _EmptyNetworkState extends StatelessWidget {
  const _EmptyNetworkState({required this.summary});

  final ArcTradeNetworkSummary summary;

  @override
  Widget build(BuildContext context) {
    final fallback = summary.playersNeedingMyItems.isNotEmpty
        ? 'Some players need items you have. Inspect listings to shape a counter-offer.'
        : summary.playersOfferingWantedItems.isNotEmpty
        ? 'Wanted items exist, but no clean payment path is tracked yet.'
        : 'No direct match yet. Add wanted blueprints, duplicate stock, or watch an active listing to keep the market useful.';

    return _MutedText(fallback);
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppTheme.tradingMutedText, height: 1.35),
    );
  }
}
