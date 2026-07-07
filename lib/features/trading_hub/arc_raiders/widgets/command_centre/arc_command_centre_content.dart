import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCommandCentreContent extends StatefulWidget {
  const ArcCommandCentreContent({
    super.key,
    required this.commandState,
    required this.checklistState,
    required this.onAction,
    required this.onChecklistChanged,
  });

  final ArcCommandCentreState commandState;
  final Map<String, bool> checklistState;
  final ValueChanged<ArcCommandAction> onAction;
  final void Function(String id, bool value) onChecklistChanged;

  @override
  State<ArcCommandCentreContent> createState() =>
      _ArcCommandCentreContentState();
}

class _ArcCommandCentreContentState extends State<ArcCommandCentreContent> {
  @override
  Widget build(BuildContext context) {
    final commandState = widget.commandState;
    final liveTiles = _liveTiles(commandState).take(4).toList(growable: false);
    final carouselTiles = _systemCarouselTiles(commandState);
    final actions = _dedupeObjectives(commandState.objectives).take(3).toList();
    final alerts = _dedupeAlerts(commandState.alerts).take(2).toList();
    final recommendations = commandState.recommendations.take(3).toList();
    final showTrade = _hasTradeSignal(commandState.tradeSummary);

    return ArcRaidersPageList(
      maxWidth: 940,
      bottomPadding: 74,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      children: [
        _missionHero(commandState.priority),
        if (liveTiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          _liveTileGrid(liveTiles),
        ],
        const SizedBox(height: 8),
        _systemCarousel(carouselTiles),
        const SizedBox(height: 8),
        _actionConsole(
          actions,
          alerts,
          showTrade ? commandState.tradeSummary : null,
        ),
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 8),
          _smartPicks(recommendations),
        ],
        const SizedBox(height: 8),
        _detailAccordion(
          title: 'System Detail',
          subtitle: 'Full summaries, checklist and lower-priority intel.',
          accent: AppTheme.neonCyan,
          initiallyExpanded: false,
          children: [
            _summaryPanel(commandState.blueprintSummary),
            _summaryPanel(commandState.operationsSummary),
            _summaryPanel(commandState.questSummary),
            _summaryPanel(commandState.benchSummary),
            _summaryPanel(commandState.resourceSummary),
            _summaryPanel(commandState.weeklyTraderSummary),
            _summaryPanel(commandState.decisionSummary),
            _resourceSummary(commandState.resources),
            _dailyChecklist(commandState.checklist),
          ],
        ),
      ],
    );
  }

  Widget _missionHero(ArcCommandPriority priority) {
    final accent = arcCommandStatusAccent(priority.status);
    return _tapSurface(
      action: priority.primaryAction,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(accent, radius: 22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 42 : 52,
                  height: compact ? 42 : 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.42)),
                  ),
                  child: Icon(
                    _statusIcon(priority.status),
                    color: accent,
                    size: compact ? 22 : 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "TODAY'S MISSION",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              isBold: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ArcCommandStatusPill(
                              label: priority.statusTag,
                              status: priority.status,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        priority.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.tradingHeading(
                          fontSize: compact ? 22 : 28,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cleanText(priority.explanation),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          isBold: true,
                        ).copyWith(height: 1.22),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${_cleanText(priority.progressLabel)} - Tap to continue',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 10,
                          color: accent,
                          isBold: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: accent, size: 28),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_CommandTileData> _liveTiles(ArcCommandCentreState state) {
    final loadout = _snapshotByLabel(state.snapshots, 'Favourite Loadout');
    final trade = _snapshotByLabel(state.snapshots, 'Trade Activity');
    return [
      _tileFromPanel(
        state.benchSummary,
        image: _imageForAction(state.benchSummary.action),
        forceTitle: 'Bench',
      ),
      _tileFromPanel(
        state.resourceSummary,
        image: _imageForAction(state.resourceSummary.action),
        forceTitle: 'Resources',
      ),
      _tileFromPanel(
        state.blueprintSummary,
        image: _imageForAction(state.blueprintSummary.action),
        forceTitle: 'Blueprints',
      ),
      if (trade != null)
        _tileFromMetric(
          trade,
          action: const ArcCommandAction(
            label: 'Open Trades',
            intent: ArcCommandActionIntent.smartTrade,
          ),
          image: 'assets/images/arc_raiders/hub/arc_hub_trading.webp',
          forceTitle: 'Trade',
        )
      else
        _tileFromMetric(
          loadout ??
              const ArcCommandSnapshotMetric(
                label: 'Favourite Loadout',
                value: 'Set up',
                detail: 'Open loadout',
                status: ArcCommandStatus.warning,
              ),
          action: const ArcCommandAction(
            label: 'Open Loadout',
            intent: ArcCommandActionIntent.favouriteLoadout,
          ),
          image: 'assets/images/arc_raiders/hub/arc_hub_loadout.webp',
          forceTitle: 'Loadout',
        ),
    ];
  }

  List<_CommandTileData> _systemCarouselTiles(ArcCommandCentreState state) {
    final loadout = _snapshotByLabel(state.snapshots, 'Favourite Loadout');
    return [
      _tileFromPanel(
        state.blueprintSummary,
        image: 'assets/images/arc_raiders/hub/arc_hub_blueprint_grid.webp',
      ),
      _tileFromPanel(
        state.benchSummary,
        image: 'assets/images/arc_raiders/hub/arc_hub_bench_tracker.webp',
      ),
      _tileFromPanel(
        state.resourceSummary,
        image: 'assets/images/arc_raiders/hub/arc_hub_scrappy_tracker.webp',
      ),
      _tileFromPanel(
        state.questSummary,
        image: 'assets/images/arc_raiders/hub/arc_hub_quest_tracker.webp',
      ),
      _tileFromPanel(
        state.operationsSummary,
        image: 'assets/images/arc_raiders/hub/arc_hub_hunt_targets.webp',
      ),
      _tileFromPanel(
        state.weeklyTraderSummary,
        image: 'assets/images/arc_raiders/hub/arc_nomadic_trader_hero.webp',
      ),
      _tileFromMetric(
        loadout ??
            const ArcCommandSnapshotMetric(
              label: 'Favourite Loadout',
              value: 'Set up',
              detail: 'Open loadout',
              status: ArcCommandStatus.warning,
            ),
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
        image: 'assets/images/arc_raiders/hub/arc_hub_raid_planner.webp',
      ),
      _CommandTileData(
        title: 'Tool Deck',
        value: 'All tools',
        detail: 'Open full ARC launcher',
        status: ArcCommandStatus.active,
        action: const ArcCommandAction(
          label: 'Open Tool Deck',
          intent: ArcCommandActionIntent.toolDeck,
        ),
        image: 'assets/images/arc_raiders/hub/arc_raiders_hub_banner.webp',
      ),
    ];
  }

  Widget _liveTileGrid(List<_CommandTileData> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: _liveTile(tile)),
          ],
        );
      },
    );
  }

  Widget _liveTile(_CommandTileData tile) {
    final accent = arcCommandStatusAccent(tile.status);
    return _tapSurface(
      action: tile.action,
      child: Container(
        height: 102,
        padding: const EdgeInsets.all(9),
        decoration: _imageDecoration(tile.image, accent, radius: 18),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Icon(_statusIcon(tile.status), color: accent, size: 18),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.85),
                size: 20,
              ),
            ),
            Positioned.fill(
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _cleanText(tile.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(fontSize: 16, color: accent),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _cleanText(tile.title).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 9,
                      color: Colors.white70,
                      isBold: true,
                    ),
                  ),
                  Text(
                    _cleanText(tile.detail),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 9,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemCarousel(List<_CommandTileData> tiles) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final tablet = constraints.maxWidth >= 620 && !wide;
          final viewportFraction = wide ? 0.46 : (tablet ? 0.64 : 0.82);
          final deckHeight = wide ? 160.0 : 174.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ArcCommandSectionHeader(
                title: 'Systems',
                subtitle: 'Swipe the command deck. Tap any card to open it.',
                accent: AppTheme.neonCyan,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: deckHeight,
                child: PageView.builder(
                  controller: PageController(
                    viewportFraction: viewportFraction,
                  ),
                  padEnds: false,
                  itemCount: tiles.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      right: index == tiles.length - 1 ? 0 : 10,
                    ),
                    child: _carouselCard(tiles[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _carouselCard(_CommandTileData tile) {
    final accent = arcCommandStatusAccent(tile.status);
    return _tapSurface(
      action: tile.action,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _imageDecoration(tile.image, accent, radius: 21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(tile.status), color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _cleanText(tile.title).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(fontSize: 19, color: accent),
                  ),
                ),
                ArcCommandStatusPill(label: tile.value, status: tile.status),
              ],
            ),
            const Spacer(),
            Text(
              tile.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: Colors.white70,
                isBold: true,
              ).copyWith(height: 1.22),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'TAP TO OPEN',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: accent,
                    isBold: true,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionConsole(
    List<ArcCommandObjective> objectives,
    List<ArcCommandAlert> alerts,
    ArcCommandTradeSummary? tradeSummary,
  ) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Next Moves',
            subtitle: 'Compact command feed. Tap a row to open the right tool.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 8),
          if (objectives.isEmpty && alerts.isEmpty && tradeSummary == null)
            _quietLine('No active command needs attention.')
          else ...[
            for (final objective in objectives) ...[
              _objectiveRow(objective),
              const SizedBox(height: 6),
            ],
            for (final alert in alerts) ...[
              _alertRow(alert),
              const SizedBox(height: 6),
            ],
            if (tradeSummary != null) _tradeStrip(tradeSummary),
          ],
        ],
      ),
    );
  }

  Widget _objectiveRow(ArcCommandObjective objective) {
    final accent = arcCommandStatusAccent(objective.status);
    return _commandRow(
      icon: _statusIcon(objective.status),
      accent: accent,
      title: objective.title,
      detail: objective.progressText.isNotEmpty
          ? objective.progressText
          : objective.reason,
      trailing: objective.statusLabel,
      status: objective.status,
      action: objective.action,
    );
  }

  Widget _alertRow(ArcCommandAlert alert) {
    final accent = arcCommandStatusAccent(alert.status);
    return _commandRow(
      icon: _statusIcon(alert.status),
      accent: accent,
      title: alert.title,
      detail: alert.body,
      trailing: alert.statusLabel,
      status: alert.status,
      action: alert.action,
    );
  }

  Widget _tradeStrip(ArcCommandTradeSummary summary) {
    final action = summary.actions.isNotEmpty
        ? summary.actions.first
        : const ArcCommandAction(
            label: 'Open Trades',
            intent: ArcCommandActionIntent.smartTrade,
          );
    final looking = summary.lookingFor
        .where(_isUsefulSignal)
        .take(2)
        .join(' - ');
    final offering = summary.offering
        .where(_isUsefulSignal)
        .take(2)
        .join(' - ');
    return _commandRow(
      icon: Icons.swap_horiz_rounded,
      accent: AppTheme.neonPink,
      title: 'Trade Opportunity',
      detail: [
        if (looking.isNotEmpty) 'Need: $looking',
        if (offering.isNotEmpty) 'Offer: $offering',
      ].join('   '),
      trailing: 'Trade',
      status: ArcCommandStatus.ready,
      action: action,
    );
  }

  Widget _commandRow({
    required IconData icon,
    required Color accent,
    required String title,
    required String detail,
    required String trailing,
    required ArcCommandStatus status,
    required ArcCommandAction action,
  }) {
    return _tapSurface(
      action: action,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: _innerDecoration(accent),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanText(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      isBold: true,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _cleanText(detail),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ArcCommandStatusPill(label: trailing, status: status),
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _smartPicks(List<ArcCommandRecommendation> recommendations) {
    return _detailAccordion(
      title: 'Smart Picks',
      subtitle: 'Optional recommendations only when you want more direction.',
      accent: Colors.amberAccent,
      children: [
        for (final recommendation in recommendations) ...[
          _commandRow(
            icon: Icons.auto_awesome_rounded,
            accent: Colors.amberAccent,
            title: recommendation.title,
            detail: recommendation.body,
            trailing: 'Pick',
            status: ArcCommandStatus.warning,
            action: recommendation.action,
          ),
          if (recommendation != recommendations.last) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _summaryPanel(ArcCommandSummaryPanel panel) {
    final accent = arcCommandStatusAccent(panel.status);
    return _tapSurface(
      action: panel.action,
      child: ArcCommandCentreCard(
        accent: accent,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArcCommandSectionHeader(
              title: panel.title,
              subtitle: panel.body,
              accent: accent,
              trailing: ArcCommandStatusPill(
                label: panel.statusLabel,
                status: panel.status,
              ),
            ),
            const SizedBox(height: 8),
            ArcCommandDetailList(
              details: panel.details.take(3).toList(growable: false),
            ),
            Text(
              'Tap to open',
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: accent,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceSummary(List<ArcCommandResourceStatus> resources) {
    return ArcCommandCentreCard(
      accent: Colors.lightGreenAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Resource Summary',
            subtitle: 'Key resource readiness without fake stash counts.',
            accent: Colors.lightGreenAccent,
          ),
          const SizedBox(height: 8),
          for (final resource in resources.take(4)) ...[
            _resourceRow(resource),
            if (resource != resources.take(4).last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _resourceRow(ArcCommandResourceStatus resource) {
    final accent = arcCommandStatusAccent(resource.status);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _innerDecoration(accent),
      child: Row(
        children: [
          Icon(_statusIcon(resource.status), color: accent, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              resource.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${resource.ownedLabel} / ${resource.requiredLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _dailyChecklist(List<ArcCommandChecklistItem> checklist) {
    return _detailAccordion(
      title: 'Daily Checklist',
      subtitle: 'Local beta checklist state.',
      accent: AppTheme.neonCyan,
      initiallyExpanded: false,
      children: checklist.isEmpty
          ? [_quietLine('No checklist items are waiting.')]
          : [
              for (final item in checklist) ...[
                _checklistRow(item),
                if (item != checklist.last) const SizedBox(height: 6),
              ],
            ],
    );
  }

  Widget _checklistRow(ArcCommandChecklistItem item) {
    final checked = widget.checklistState[item.id] ?? item.doneByDefault;
    final accent = checked ? Colors.lightGreenAccent : AppTheme.neonCyan;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _innerDecoration(accent),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            activeColor: Colors.lightGreenAccent,
            onChanged: (value) =>
                widget.onChecklistChanged(item.id, value ?? false),
          ),
          Expanded(
            child: _tapSurface(
              action: item.action,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanText(item.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 11,
                      color: checked ? Colors.lightGreenAccent : Colors.white,
                      isBold: true,
                    ),
                  ),
                  Text(
                    _cleanText(item.reason),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: accent, size: 18),
        ],
      ),
    );
  }

  Widget _detailAccordion({
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    return ArcCommandCentreCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('command-centre-accordion-$title'),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: accent,
          collapsedIconColor: Colors.white60,
          title: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.tradingHeading(fontSize: 15, color: accent),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 10, color: Colors.white54),
          ),
          children: children.isEmpty
              ? [_quietLine('No additional detail is waiting.')]
              : [
                  for (final child in children) ...[
                    child,
                    if (child != children.last) const SizedBox(height: 8),
                  ],
                ],
        ),
      ),
    );
  }

  Widget _tapSurface({
    required ArcCommandAction action,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onAction(action),
        child: child,
      ),
    );
  }

  Widget _quietLine(String text) {
    return Text(
      text,
      style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white54),
    );
  }

  _CommandTileData _tileFromPanel(
    ArcCommandSummaryPanel panel, {
    required String image,
    String? forceTitle,
  }) {
    return _CommandTileData(
      title: forceTitle ?? panel.title,
      value: panel.statusLabel,
      detail: _summaryDetail(panel),
      status: panel.status,
      action: panel.action,
      image: image,
    );
  }

  _CommandTileData _tileFromMetric(
    ArcCommandSnapshotMetric metric, {
    required ArcCommandAction action,
    required String image,
    String? forceTitle,
  }) {
    return _CommandTileData(
      title: forceTitle ?? metric.label,
      value: metric.value,
      detail: metric.detail,
      status: metric.status,
      action: action,
      image: image,
    );
  }

  ArcCommandSnapshotMetric? _snapshotByLabel(
    List<ArcCommandSnapshotMetric> snapshots,
    String label,
  ) {
    for (final snapshot in snapshots) {
      if (snapshot.label == label) return snapshot;
    }
    return null;
  }

  List<ArcCommandObjective> _dedupeObjectives(List<ArcCommandObjective> input) {
    final seen = <String>{};
    return [
      for (final objective in input)
        if (seen.add(
          '${objective.title}|${objective.action.intent}|${objective.action.routeName}',
        ))
          objective,
    ];
  }

  List<ArcCommandAlert> _dedupeAlerts(List<ArcCommandAlert> input) {
    final seen = <String>{};
    return [
      for (final alert in input)
        if (seen.add(
          '${alert.title}|${alert.action.intent}|${alert.action.routeName}',
        ))
          alert,
    ];
  }

  String _summaryDetail(ArcCommandSummaryPanel panel) {
    for (final detail in panel.details) {
      if (_isUsefulSummaryDetail(detail)) return detail;
    }
    if (panel.body.isNotEmpty) return panel.body;
    return panel.details.isEmpty ? 'Tap to open' : panel.details.first;
  }

  bool _isUsefulSummaryDetail(String value) {
    final normalized = value.toLowerCase();
    return _isUsefulSignal(value) && !normalized.contains('open ');
  }

  bool _hasTradeSignal(ArcCommandTradeSummary summary) {
    return summary.lookingFor.any(_isUsefulSignal) ||
        summary.offering.any(_isUsefulSignal);
  }

  bool _isUsefulSignal(String value) {
    final normalized = value.toLowerCase();
    return value.trim().isNotEmpty &&
        !normalized.contains('not tracked') &&
        !normalized.contains('no signal') &&
        !normalized.contains('no duplicate') &&
        !normalized.contains('coming online');
  }

  String _cleanText(String value) {
    return value
        .replaceAll('Ã¢â‚¬Â¢', '-')
        .replaceAll('â€¢', '-')
        .replaceAll('Â•', '-')
        .replaceAll('Â·', '-')
        .replaceAll('Â', '')
        .replaceAll('Ã¢', '')
        .replaceAll('â€“', '-')
        .replaceAll('â€”', '-')
        .replaceAll('â€™', "'")
        .replaceAll('â€œ', '"')
        .replaceAll('â€', '"')
        .trim();
  }

  String _imageForAction(ArcCommandAction action) {
    switch (action.intent) {
      case ArcCommandActionIntent.favouriteLoadout:
        return 'assets/images/arc_raiders/hub/arc_hub_raid_planner.webp';
      case ArcCommandActionIntent.smartTrade:
        return 'assets/images/arc_raiders/hub/arc_hub_trading.webp';
      case ArcCommandActionIntent.nomadicTrader:
        return 'assets/images/arc_raiders/hub/arc_nomadic_trader_hero.webp';
      case ArcCommandActionIntent.operations:
        return 'assets/images/arc_raiders/hub/arc_hub_hunt_targets.webp';
      case ArcCommandActionIntent.toolDeck:
        return 'assets/images/arc_raiders/hub/arc_raiders_hub_banner.webp';
      case ArcCommandActionIntent.route:
      case ArcCommandActionIntent.placeholder:
        final route = action.routeName ?? '';
        if (route.contains('blueprint'))
          return 'assets/images/arc_raiders/hub/arc_hub_blueprint_grid.webp';
        if (route.contains('bench'))
          return 'assets/images/arc_raiders/hub/arc_hub_bench_tracker.webp';
        if (route.contains('quest'))
          return 'assets/images/arc_raiders/hub/arc_hub_quest_tracker.webp';
        if (route.contains('resource') || route.contains('scrappy'))
          return 'assets/images/arc_raiders/hub/arc_hub_scrappy_tracker.webp';
        return 'assets/images/arc_raiders/hub/arc_hub_tracking.webp';
    }
  }

  BoxDecoration _cardDecoration(Color accent, {double radius = 20}) {
    return AppTheme.tradingCardDecoration(
      radius: radius,
      borderColor: accent.withValues(alpha: 0.30),
      backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
    ).copyWith(
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.10),
          blurRadius: 22,
          spreadRadius: 1,
        ),
      ],
    );
  }

  BoxDecoration _imageDecoration(
    String image,
    Color accent, {
    double radius = 20,
  }) {
    return _cardDecoration(accent, radius: radius).copyWith(
      image: DecorationImage(
        image: AssetImage(image),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.47),
          BlendMode.darken,
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
          Colors.black.withValues(alpha: 0.58),
          accent.withValues(alpha: 0.10),
        ],
      ),
    );
  }

  BoxDecoration _innerDecoration(Color accent) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accent.withValues(alpha: 0.20)),
    );
  }

  IconData _statusIcon(ArcCommandStatus status) {
    switch (status) {
      case ArcCommandStatus.critical:
        return Icons.priority_high_rounded;
      case ArcCommandStatus.warning:
        return Icons.warning_amber_rounded;
      case ArcCommandStatus.active:
        return Icons.radar_rounded;
      case ArcCommandStatus.ready:
        return Icons.swap_horiz_rounded;
      case ArcCommandStatus.neutral:
        return Icons.circle_outlined;
      case ArcCommandStatus.success:
        return Icons.check_circle_rounded;
    }
  }
}

class _CommandTileData {
  const _CommandTileData({
    required this.title,
    required this.value,
    required this.detail,
    required this.status,
    required this.action,
    required this.image,
  });

  final String title;
  final String value;
  final String detail;
  final ArcCommandStatus status;
  final ArcCommandAction action;
  final String image;
}
