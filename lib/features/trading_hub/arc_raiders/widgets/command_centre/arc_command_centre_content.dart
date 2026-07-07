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
  final Map<String, bool> _expandedPanels = <String, bool>{};
  late final PageController _systemsController = PageController(
    viewportFraction: 0.42,
  );
  int _systemsIndex = 0;

  @override
  void dispose() {
    _systemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commandState = widget.commandState;
    final liveTiles = _liveTiles(commandState).take(4).toList(growable: false);
    final carouselTiles = _systemCarouselTiles(commandState);
    final commandMoves = _commandMoves(commandState).take(6).toList();

    return ArcRaidersPageList(
      maxWidth: 780,
      bottomPadding: 74,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      children: [
        _missionHero(commandState.priority),
        const SizedBox(height: 8),
        _dailyChecklist(commandState.checklist),
        if (liveTiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          _liveTileGrid(liveTiles),
        ],
        const SizedBox(height: 8),
        _systemCarousel(carouselTiles),
        const SizedBox(height: 8),
        _actionConsole(commandMoves),
        const SizedBox(height: 8),
        _detailAccordion(
          title: 'System Detail',
          subtitle: 'Compact lower-priority system checks.',
          accent: AppTheme.neonCyan,
          initiallyExpanded: false,
          children: [
            _systemDetailGrid([
              _summaryPanel(commandState.operationsSummary),
              _summaryPanel(commandState.questSummary),
              _summaryPanel(commandState.weeklyTraderSummary),
              _summaryPanel(commandState.decisionSummary),
              _resourceSummary(commandState.resources),
            ]),
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
                          fontSize: 10,
                          color: Colors.white70,
                          isBold: true,
                        ).copyWith(height: 1.22),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _cleanText(priority.progressLabel),
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
        image: 'assets/images/arc_raiders/hub/arc_hub_operations_missions.webp',
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
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
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
        height: 88,
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
                    style: AppTheme.tradingHeading(fontSize: 13, color: accent),
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
                    _shortActionText(tile.detail),
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
    if (tiles.isEmpty) return const SizedBox.shrink();

    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 760;
          final deckHeight = desktop ? 118.0 : 128.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: ArcCommandSectionHeader(
                      title: 'Systems',
                      subtitle: 'Command deck. Use arrows or swipe.',
                      accent: AppTheme.neonCyan,
                    ),
                  ),
                  _carouselArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: _systemsIndex > 0,
                    onTap: () => _moveSystemsCarousel(-1, tiles.length),
                  ),
                  const SizedBox(width: 6),
                  _carouselArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: _systemsIndex < tiles.length - 1,
                    onTap: () => _moveSystemsCarousel(1, tiles.length),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: deckHeight,
                child: PageView.builder(
                  controller: _systemsController,
                  padEnds: false,
                  itemCount: tiles.length,
                  onPageChanged: (index) =>
                      setState(() => _systemsIndex = index),
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      right: index == tiles.length - 1 ? 0 : 10,
                    ),
                    child: _carouselCard(tiles[index]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < tiles.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _systemsIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color:
                            (i == _systemsIndex
                                    ? AppTheme.neonCyan
                                    : Colors.white24)
                                .withValues(
                                  alpha: i == _systemsIndex ? 0.9 : 0.5,
                                ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _carouselArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.30),
          border: Border.all(
            color: (enabled ? AppTheme.neonCyan : Colors.white24).withValues(
              alpha: enabled ? 0.55 : 0.22,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppTheme.neonCyan : Colors.white24,
          size: 24,
        ),
      ),
    );
  }

  void _moveSystemsCarousel(int delta, int length) {
    if (length <= 0) return;
    final next = (_systemsIndex + delta).clamp(0, length - 1);
    _systemsController.animateToPage(
      next,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _carouselCard(_CommandTileData tile) {
    final accent = arcCommandStatusAccent(tile.status);
    return _tapSurface(
      action: tile.action,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: _imageDecoration(tile.image, accent, radius: 16),
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
                    style: AppTheme.tradingHeading(fontSize: 13, color: accent),
                  ),
                ),
                ArcCommandStatusPill(label: tile.value, status: tile.status),
              ],
            ),
            const Spacer(),
            Text(
              _shortActionText(tile.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white70,
                isBold: true,
              ).copyWith(height: 1.22),
            ),
            const SizedBox(height: 4),
            Text(
              'TAP',
              style: AppTheme.bodyTextStyle(
                fontSize: 8,
                color: accent,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CommandMoveData> _commandMoves(ArcCommandCentreState state) {
    final moves = <_CommandMoveData>[];
    final seen = <String>{};

    void add({
      required String title,
      required String detail,
      required String label,
      required ArcCommandStatus status,
      required ArcCommandAction action,
      required IconData icon,
      required Color accent,
      required String image,
    }) {
      final key = '${title.toLowerCase()}|${action.intent}|${action.routeName}';
      if (!seen.add(key)) return;
      moves.add(
        _CommandMoveData(
          title: title,
          detail: detail,
          label: label,
          status: status,
          action: action,
          icon: icon,
          accent: accent,
          image: image,
        ),
      );
    }

    for (final objective in state.objectives) {
      final detail = objective.progressText.isNotEmpty
          ? objective.progressText
          : objective.reason;
      add(
        title: objective.title,
        detail: detail,
        label: objective.statusLabel,
        status: objective.status,
        action: objective.action,
        icon: _statusIcon(objective.status),
        accent: arcCommandStatusAccent(objective.status),
        image: _imageForAction(objective.action),
      );
    }

    for (final alert in state.alerts) {
      add(
        title: alert.title,
        detail: alert.body,
        label: alert.statusLabel,
        status: alert.status,
        action: alert.action,
        icon: _statusIcon(alert.status),
        accent: arcCommandStatusAccent(alert.status),
        image: _imageForAction(alert.action),
      );
    }

    if (_hasTradeSignal(state.tradeSummary)) {
      final action = state.tradeSummary.actions.isNotEmpty
          ? state.tradeSummary.actions.first
          : const ArcCommandAction(
              label: 'Open Trades',
              intent: ArcCommandActionIntent.smartTrade,
            );
      add(
        title: 'Trade Opportunity',
        detail: _tradeSignalDetail(state.tradeSummary),
        label: 'Trade',
        status: ArcCommandStatus.ready,
        action: action,
        icon: Icons.swap_horiz_rounded,
        accent: AppTheme.neonPink,
        image: _imageForAction(action),
      );
    }

    for (final recommendation in state.recommendations) {
      add(
        title: recommendation.title,
        detail: recommendation.body,
        label: 'Pick',
        status: ArcCommandStatus.warning,
        action: recommendation.action,
        icon: Icons.auto_awesome_rounded,
        accent: Colors.amberAccent,
        image: _imageForAction(recommendation.action),
      );
    }

    return moves;
  }

  Widget _actionConsole(List<_CommandMoveData> moves) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Next Move',
            subtitle: 'Compact action grid. Tap a tile to open the right tool.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 8),
          if (moves.isEmpty)
            _quietLine('No active command needs attention.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 3 : 2;
                const spacing = 8.0;
                final width =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final move in moves)
                      SizedBox(width: width, child: _moveTile(move)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _moveTile(_CommandMoveData move) {
    return _tapSurface(
      action: move.action,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(9),
        decoration: _imageDecoration(move.image, move.accent, radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(move.icon, color: move.accent, size: 15),
                const Spacer(),
                Flexible(
                  child: Text(
                    _cleanText(move.label).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 8,
                      color: move.accent,
                      isBold: true,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _cleanText(move.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: Colors.white,
                isBold: true,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortActionText(move.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
                color: Colors.white54,
              ).copyWith(height: 1.12),
            ),
          ],
        ),
      ),
    );
  }

  String _tradeSignalDetail(ArcCommandTradeSummary summary) {
    final looking = summary.lookingFor.where(_isUsefulSignal).take(1).join('');
    final offering = summary.offering.where(_isUsefulSignal).take(1).join('');
    if (looking.isNotEmpty && offering.isNotEmpty) {
      return 'Need: $looking - Offer: $offering';
    }
    if (looking.isNotEmpty) return 'Need: $looking';
    if (offering.isNotEmpty) return 'Offer: $offering';
    return 'Review trade signals';
  }

  Widget _systemDetailGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : (constraints.maxWidth >= 520 ? 2 : 1);
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }

  Widget _summaryPanel(ArcCommandSummaryPanel panel) {
    final accent = arcCommandStatusAccent(panel.status);
    return _tapSurface(
      action: panel.action,
      child: ArcCommandCentreCard(
        accent: accent,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArcCommandSectionHeader(
              title: panel.title,
              subtitle: _panelSubtitle(panel),
              accent: accent,
              trailing: ArcCommandStatusPill(
                label: panel.statusLabel,
                status: panel.status,
              ),
            ),
            const SizedBox(height: 8),
            ArcCommandDetailList(
              details: _shortDetails(panel).take(2).toList(growable: false),
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
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Resource Summary',
            subtitle: 'Resource readiness.',
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
              _cleanText(resource.name),
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
    final items = checklist.take(9).toList(growable: false);
    return _detailAccordion(
      title: 'Daily Mission Board',
      subtitle: 'Fast daily checks. Tap a tile.',
      accent: AppTheme.neonCyan,
      initiallyExpanded: false,
      children: items.isEmpty
          ? [_quietLine('No checklist items are waiting.')]
          : [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760
                      ? 3
                      : (constraints.maxWidth >= 520 ? 3 : 2);
                  const spacing = 8.0;
                  final width =
                      (constraints.maxWidth - (spacing * (columns - 1))) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final item in items)
                        SizedBox(width: width, child: _checklistTile(item)),
                    ],
                  );
                },
              ),
            ],
    );
  }

  Widget _checklistTile(ArcCommandChecklistItem item) {
    final checked = widget.checklistState[item.id] ?? item.doneByDefault;
    final accent = checked ? Colors.lightGreenAccent : AppTheme.neonCyan;
    return _tapSurface(
      action: item.action,
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(7),
        decoration: _imageDecoration(
          _imageForAction(item.action),
          accent,
          radius: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => widget.onChecklistChanged(item.id, !checked),
                  child: Icon(
                    checked
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: accent,
                    size: 15,
                  ),
                ),
                const Spacer(),
                ArcCommandStatusPill(
                  label: checked ? 'Done' : 'Daily',
                  status: checked
                      ? ArcCommandStatus.success
                      : ArcCommandStatus.active,
                ),
              ],
            ),
            const Spacer(),
            Text(
              _cleanText(item.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
                color: checked ? Colors.lightGreenAccent : Colors.white,
                isBold: true,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortActionText(item.reason),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 8,
                color: Colors.white60,
              ).copyWith(height: 1.08),
            ),
          ],
        ),
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
    final expanded = _expandedPanels.putIfAbsent(
      title,
      () => initiallyExpanded,
    );
    final visibleChildren = children.isEmpty
        ? <Widget>[_quietLine('No additional detail is waiting.')]
        : children;

    return ArcCommandCentreCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() => _expandedPanels[title] = !expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cleanText(title).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cleanText(subtitle),
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
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: accent,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (final child in visibleChildren) ...[
                    child,
                    if (child != visibleChildren.last)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
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

  String _panelSubtitle(ArcCommandSummaryPanel panel) {
    final title = _cleanText(panel.title).toLowerCase();
    if (title.contains('decision')) return 'Primary command signal.';
    if (title.contains('operation')) return 'Operations and vault status.';
    if (title.contains('quest')) return 'Quest tracker state.';
    if (title.contains('nomadic')) return 'Trader reset and stock state.';
    return _shortActionText(panel.body);
  }

  List<String> _shortDetails(ArcCommandSummaryPanel panel) {
    final title = _cleanText(panel.title).toLowerCase();
    if (title.contains('decision')) {
      return panel.details
          .where((detail) => !detail.toLowerCase().contains('ranked from'))
          .map(_shortActionText)
          .toList(growable: false);
    }
    return panel.details.map(_shortActionText).toList(growable: false);
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
      if (snapshot.label == label) {
        return snapshot;
      }
    }
    return null;
  }

  String _summaryDetail(ArcCommandSummaryPanel panel) {
    for (final detail in panel.details) {
      if (_isUsefulSummaryDetail(detail)) {
        return detail;
      }
    }
    if (panel.body.isNotEmpty) {
      return panel.body;
    }
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

  String _shortActionText(String value) {
    final cleaned = _cleanText(value);
    final lower = cleaned.toLowerCase();
    if (lower.contains('farm antiseptic')) {
      return 'Farm antiseptic via Medical POIs before trading it away.';
    }
    if (lower.contains('ranked from')) {
      return cleaned.split(' ranked from').first.trim();
    }
    if (cleaned.length <= 92) return cleaned;
    final firstSentence = cleaned.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length >= 24 && firstSentence.length <= 92) {
      return firstSentence;
    }
    return '${cleaned.substring(0, 89).trim()}...';
  }

  String _cleanText(String value) {
    return value
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢',
          '-',
        )
        .replaceAll('ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â·', '-')
        .replaceAll('ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡', '')
        .replaceAll('ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢', '')
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢',
          "'",
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ',
          '"',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â',
          '"',
        )
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
        return 'assets/images/arc_raiders/hub/arc_hub_operations_missions.webp';
      case ArcCommandActionIntent.toolDeck:
        return 'assets/images/arc_raiders/hub/arc_raiders_hub_banner.webp';
      case ArcCommandActionIntent.route:
      case ArcCommandActionIntent.placeholder:
        final route = action.routeName ?? '';
        if (route.contains('blueprint')) {
          return 'assets/images/arc_raiders/hub/arc_hub_blueprint_grid.webp';
        }
        if (route.contains('bench')) {
          return 'assets/images/arc_raiders/hub/arc_hub_bench_tracker.webp';
        }
        if (route.contains('quest')) {
          return 'assets/images/arc_raiders/hub/arc_hub_quest_tracker.webp';
        }
        if (route.contains('resource') || route.contains('scrappy')) {
          return 'assets/images/arc_raiders/hub/arc_hub_scrappy_tracker.webp';
        }
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

class _CommandMoveData {
  const _CommandMoveData({
    required this.title,
    required this.detail,
    required this.label,
    required this.status,
    required this.action,
    required this.icon,
    required this.accent,
    required this.image,
  });

  final String title;
  final String detail;
  final String label;
  final ArcCommandStatus status;
  final ArcCommandAction action;
  final IconData icon;
  final Color accent;
  final String image;
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
