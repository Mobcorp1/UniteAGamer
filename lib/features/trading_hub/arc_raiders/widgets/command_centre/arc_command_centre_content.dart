import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_season_reset_screen.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCommandCentreContent extends StatefulWidget {
  const ArcCommandCentreContent({
    super.key,
    required this.expeditionState,
    required this.commandState,
    required this.checklistState,
    required this.onAction,
    required this.onChecklistChanged,
    this.fallbackNotice,
  });

  final ArcExpeditionStateSnapshot expeditionState;
  final ArcCommandCentreState commandState;
  final Map<String, bool> checklistState;
  final ValueChanged<ArcCommandAction> onAction;
  final void Function(String id, bool value) onChecklistChanged;
  final String? fallbackNotice;

  @override
  State<ArcCommandCentreContent> createState() =>
      _ArcCommandCentreContentState();
}

class _ArcCommandCentreContentState extends State<ArcCommandCentreContent> {
  final Map<String, bool> _expandedPanels = <String, bool>{};
  int _systemsIndex = 0;

  @override
  Widget build(BuildContext context) {
    final commandState = widget.commandState;
    final carouselTiles = _systemCarouselTiles(commandState);
    final commandMoves = _commandMoves(commandState).take(6).toList();

    return ArcRaidersPageList(
      maxWidth: 1220,
      bottomPadding: 74,
      children: [
        if (widget.fallbackNotice != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.neonCyan,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.fallbackNotice!,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        _commandHero(commandState, commandMoves),
        const SizedBox(height: 8),
        _topCommandDeck(commandState, commandMoves, carouselTiles),
        const SizedBox(height: 8),
        _featuresUtilityDeck(carouselTiles),
      ],
    );
  }

  int _safeSystemIndex(int tileCount) {
    if (tileCount <= 0) return 0;
    return _systemsIndex.clamp(0, tileCount - 1).toInt();
  }

  Widget _commandHero(
    ArcCommandCentreState commandState,
    List<_CommandMoveData> commandMoves,
  ) {
    final checklist = commandState.checklist.take(9).toList(growable: false);
    final completedChecks = checklist.where((item) {
      return widget.checklistState[item.id] ?? item.doneByDefault;
    }).length;
    final openChecks = checklist.length - completedChecks;
    final focus = commandMoves.isEmpty ? null : commandMoves.first;

    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(18),
      decoration: _imageDecoration(
        _operationAsset('claim_operations_card.webp'),
        AppTheme.neonCyan,
        radius: 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          const title = 'RAIDER COMMAND CENTRE';
          final subtitle = focus == null
              ? 'Live ARC intelligence, priorities and daily operations in one place.'
              : 'Priority: ${_cleanText(focus.title)}';

          final copy = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARC OPERATIONS',
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: AppTheme.neonCyan,
                  isBold: true,
                ).copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 22 : 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: compact ? 11 : 12,
                  color: Colors.white70,
                ),
              ),
            ],
          );

          final status = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _heroMetric(
                label: 'NEXT MOVES',
                value: '${commandMoves.length}',
                accent: AppTheme.neonCyan,
              ),
              _heroMetric(
                label: 'DAILY OPEN',
                value: '$openChecks',
                accent: openChecks == 0
                    ? Colors.lightGreenAccent
                    : AppTheme.neonPink,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: status),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 18),
              status,
            ],
          );
        },
      ),
    );
  }

  Widget _heroMetric({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.tradingHeading(fontSize: 19, color: accent),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTheme.bodyTextStyle(
              fontSize: 8,
              color: Colors.white60,
              isBold: true,
            ).copyWith(letterSpacing: .7),
          ),
        ],
      ),
    );
  }

  Widget _topCommandDeck(
    ArcCommandCentreState commandState,
    List<_CommandMoveData> commandMoves,
    List<_CommandTileData> carouselTiles,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final primary = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_actionConsole(commandMoves)],
        );
        final secondary = _dailyChecklist(commandState.checklist);

        if (!desktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [primary, const SizedBox(height: 8), secondary],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: primary),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: secondary),
          ],
        );
      },
    );
  }

  Widget _featuresUtilityDeck(List<_CommandTileData> carouselTiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _systemCarousel(carouselTiles),
              const SizedBox(height: 8),
              _seasonResetEntry(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 9, child: _systemCarousel(carouselTiles)),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: _seasonResetEntry()),
          ],
        );
      },
    );
  }

  Widget _seasonResetEntry() {
    final expeditionState = widget.expeditionState;
    final resetSubtitle = expeditionState.resetInProgress
        ? '${expeditionState.currentSeasonId} reset is in progress. Review state before continuing.'
        : '${expeditionState.currentSeasonId} - ${expeditionState.statusLabel}. Preview what resets, what persists, and archive only after confirmation.';

    return _tapSurface(
      action: const ArcCommandAction(
        label: 'Start Expedition Reset',
        routeName: ArcSeasonResetScreen.routeName,
      ),
      child: ArcCommandCentreCard(
        padding: const EdgeInsets.all(12),
        accent: AppTheme.neonPink,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.36),
                ),
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: AppTheme.neonPink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPEDITION RESET',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(
                      fontSize: 15,
                      color: AppTheme.neonPink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resetSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.neonPink),
          ],
        ),
      ),
    );
  }

  Widget _systemCarousel(List<_CommandTileData> tiles) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    final activeIndex = _safeSystemIndex(tiles.length);

    void rotate(int delta) {
      if (tiles.length <= 1) return;
      setState(() {
        _systemsIndex = (_systemsIndex + delta) % tiles.length;
        if (_systemsIndex < 0) _systemsIndex += tiles.length;
      });
    }

    final previousIndex = tiles.length <= 1
        ? activeIndex
        : (activeIndex - 1 + tiles.length) % tiles.length;
    final nextIndex = tiles.length <= 1
        ? activeIndex
        : (activeIndex + 1) % tiles.length;

    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final ringHeight = compact ? 150.0 : 172.0;

          Widget sideCard(_CommandTileData tile) {
            return Opacity(
              opacity: 0.54,
              child: Transform.scale(
                scale: compact ? 0.78 : 0.82,
                child: _carouselCard(tile, active: false),
              ),
            );
          }

          final ring = SizedBox(
            height: ringHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 120) return;
                rotate(velocity < 0 ? 1 : -1);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: compact ? 2 : 3,
                    child: sideCard(tiles[previousIndex]),
                  ),
                  const SizedBox(width: 2),
                  _featureArrow(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous feature',
                    onPressed: () => rotate(-1),
                  ),
                  SizedBox(width: compact ? 3 : 6),
                  Expanded(
                    flex: compact ? 5 : 6,
                    child: Transform.scale(
                      scale: compact ? 1.02 : 1.08,
                      child: _carouselCard(tiles[activeIndex], active: true),
                    ),
                  ),
                  SizedBox(width: compact ? 3 : 6),
                  _featureArrow(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next feature',
                    onPressed: () => rotate(1),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: compact ? 2 : 3,
                    child: sideCard(tiles[nextIndex]),
                  ),
                ],
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ArcCommandSectionHeader(
                title: 'FEATURES',
                subtitle: 'Rotate through your ARC systems.',
                accent: AppTheme.neonCyan,
              ),
              const SizedBox(height: 7),
              ring,
              const SizedBox(height: 5),
              _featureRingIndicator(tiles.length, activeIndex),
            ],
          );
        },
      ),
    );
  }

  Widget _featureRingIndicator(int count, int activeIndex) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.42),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _featureArrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 27),
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        backgroundColor: Colors.black.withValues(alpha: 0.52),
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.52)),
        minimumSize: const Size(42, 42),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _carouselCard(_CommandTileData tile, {required bool active}) {
    final accent = arcCommandStatusAccent(tile.status);
    return _tapSurface(
      action: tile.action,
      active: active,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: _imageDecoration(tile.image, accent, radius: 10),
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
                    style: AppTheme.tradingHeading(fontSize: 12, color: accent),
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ArcCommandStatusPill(
                      label: tile.value,
                      status: tile.status,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _shortActionText(tile.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
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
      int? progressPercent,
    }) {
      final resolvedProgress =
          progressPercent ??
          _progressForMove(status: status, label: label, detail: detail);
      if (resolvedProgress >= 100 || status == ArcCommandStatus.success) {
        return;
      }
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
          progressPercent: resolvedProgress,
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
        image: _imageForCommandTitle(
          objective.title,
          fallback: _imageForAction(objective.action),
        ),
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
        image: _imageForCommandTitle(
          alert.title,
          fallback: _imageForAction(alert.action),
        ),
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
        image: _imageForCommandTitle(
          'Trade Opportunity',
          fallback: _imageForAction(action),
        ),
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
        image: _imageForCommandTitle(
          recommendation.title,
          fallback: _imageForAction(recommendation.action),
        ),
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
            subtitle: 'Tap a tile to move.',
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
        height: 108,
        padding: const EdgeInsets.all(9),
        decoration: _imageDecoration(move.image, move.accent, radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _moveProgressIndicator(move),
                const SizedBox(width: 7),
                Expanded(
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

  Widget _moveProgressIndicator(_CommandMoveData move) {
    final progress = (move.progressPercent.clamp(0, 100)) / 100;
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.black.withValues(alpha: 0.36),
            color: move.accent,
          ),
          Text(
            '${move.progressPercent.clamp(0, 100)}',
            style: AppTheme.bodyTextStyle(
              fontSize: 7,
              color: Colors.white.withValues(alpha: 0.90),
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  int _progressForMove({
    required ArcCommandStatus status,
    required String label,
    required String detail,
  }) {
    final text = '$label $detail'.toLowerCase();
    final percentMatch = RegExp(r'(\d{1,3})\s*%').firstMatch(text);
    if (percentMatch != null) {
      return (int.tryParse(percentMatch.group(1) ?? '') ?? 0).clamp(0, 100);
    }
    final fractionMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(text);
    if (fractionMatch != null) {
      final current = int.tryParse(fractionMatch.group(1) ?? '') ?? 0;
      final target = int.tryParse(fractionMatch.group(2) ?? '') ?? 0;
      if (target > 0) return ((current / target) * 100).round().clamp(0, 100);
    }
    return switch (status) {
      ArcCommandStatus.success => 100,
      ArcCommandStatus.ready => 86,
      ArcCommandStatus.active => 62,
      ArcCommandStatus.warning => 38,
      ArcCommandStatus.critical => 18,
      ArcCommandStatus.neutral => 24,
    };
  }

  List<_CommandTileData> _systemCarouselTiles(ArcCommandCentreState state) {
    final loadout = _snapshotByLabel(state.snapshots, 'Favourite Loadout');

    _CommandTileData routeTile({
      required String title,
      required String detail,
      required String routeName,
      required String image,
      String value = 'Open',
      ArcCommandStatus status = ArcCommandStatus.active,
    }) {
      return _CommandTileData(
        title: title,
        value: value,
        detail: detail,
        status: status,
        action: ArcCommandAction(label: 'Open $title', routeName: routeName),
        image: image,
      );
    }

    return [
      _tileFromPanel(
        state.blueprintSummary,
        image: _operationAsset('complete_blueprint_collection_card.webp'),
      ),
      routeTile(
        title: 'Scrappy Tracker',
        detail: 'Track Scrappy upgrade resources and requirements.',
        routeName: ScrappyGridScreen.routeName,
        image: _operationAsset('missing_resources_card.webp'),
      ),
      _tileFromPanel(
        state.benchSummary,
        image: _operationAsset('upgrade_gunsmith_card.webp'),
      ),
      _tileFromPanel(
        state.questSummary,
        image: _operationAsset('track_quests_card.webp'),
      ),
      _tileFromPanel(
        state.raidIntelligenceSummary,
        image: _imageForAction(state.raidIntelligenceSummary.action),
      ),
      routeTile(
        title: 'Raid Planner',
        detail: 'Plan raid objectives, routes and targets.',
        routeName: RaidPlannerScreen.routeName,
        image: _operationAsset('weekly_raid_card.webp'),
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
        image: _operationAsset('finish_favourite_loadout_card.webp'),
      ),
      routeTile(
        title: 'Trading Hub',
        detail: 'Listings, offers, watches and trade sessions.',
        routeName: TraderHubScreen.routeName,
        image: _operationAsset('review_trade_activity_card.webp'),
      ),
      routeTile(
        title: 'Smart Trade Assist',
        detail: 'Turn inventory needs into smarter trade decisions.',
        routeName: SmartTradeAssistScreen.routeName,
        image: _operationAsset('review_trade_activity_card.webp'),
      ),
      routeTile(
        title: 'Match Raider',
        detail: 'Find compatible Raiders and squad connections.',
        routeName: ArcMatchRiderScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Report a Rat',
        detail: 'Community reports, evidence and Raider contracts.',
        routeName: ArcRaiderContractsScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Play Like a Pro',
        detail: 'Expert tactics, guidance and advanced play.',
        routeName: PlayLikeAProScreen.routeName,
        image: _operationAsset('weekly_raid_card.webp'),
      ),
      routeTile(
        title: 'Communications',
        detail: 'Notifications, invites and trading updates.',
        routeName: TradingNotificationsScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Wall of Legends',
        detail: 'Community recognition and Raider achievements.',
        routeName: WallOfLegendsScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      _tileFromPanel(
        state.operationsSummary,
        image: _operationAsset('claim_operations_card.webp'),
      ),
      routeTile(
        title: 'Nomadic Trader',
        detail: 'Review the current weekly trader rotation.',
        routeName: NomadicTraderScreen.routeName,
        image: _operationAsset('check_nomadic_trader_card.webp'),
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
        image: _operationAsset('arc_tool_deck_background.webp'),
      ),
    ];
  }

  Widget _dailyChecklist(List<ArcCommandChecklistItem> checklist) {
    final items = checklist.take(9).toList(growable: false);
    return _detailAccordion(
      title: 'Daily Mission Board',
      subtitle: 'Fast daily checks. Tap a tile.',
      accent: AppTheme.neonCyan,
      initiallyExpanded: true,
      children: items.isEmpty
          ? [_quietLine('No checklist items are waiting.')]
          : [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760
                      ? 3
                      : (constraints.maxWidth >= 430 ? 2 : 1);
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
        height: 68,
        padding: const EdgeInsets.all(7),
        decoration: _imageDecoration(
          _imageForChecklistItem(item),
          accent,
          radius: 14,
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
                    size: 14,
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
                fontSize: 8,
                color: checked ? Colors.lightGreenAccent : Colors.white,
                isBold: true,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _shortActionText(item.reason),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 7,
                color: Colors.white60,
              ).copyWith(height: 1.05),
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
    bool active = false,
  }) {
    final surface = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onAction(action),
        child: child,
      ),
    );

    if (!active) return surface;

    return ArcElectricActionBorder(active: active, radius: 20, child: surface);
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

  String _tradeSignalDetail(ArcCommandTradeSummary summary) {
    final lookingFor = summary.lookingFor.where(_isUsefulSignal).toList();
    if (lookingFor.isNotEmpty) {
      return 'Looking for ${lookingFor.first}.';
    }
    final offering = summary.offering.where(_isUsefulSignal).toList();
    if (offering.isNotEmpty) {
      return 'Offering ${offering.first}.';
    }
    return 'Open Smart Trade for current opportunities.';
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
    if (lower.contains('primary mission is')) {
      return cleaned
          .split(RegExp(r' ranked from|\. Ranked from', caseSensitive: false))
          .first
          .trim();
    }
    if (lower.contains('medical pois') || lower.contains('med crates')) {
      return 'Farm via Medical POIs before trading it away.';
    }
    if (cleaned.length <= 68) return cleaned;
    final firstSentence = cleaned.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length >= 18 && firstSentence.length <= 68) {
      return firstSentence;
    }
    return '${cleaned.substring(0, 65).trim()}...';
  }

  String _cleanText(String value) {
    return value
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â·',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡',
          '',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          '',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â',
          '-',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
          "'",
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ',
          '"',
        )
        .replaceAll(
          'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â',
          '"',
        )
        .trim();
  }

  String _operationAsset(String fileName) =>
      'assets/arc_raiders/operations/$fileName';

  String _imageForChecklistItem(ArcCommandChecklistItem item) {
    return _imageForCommandTitle(
      item.label,
      fallback: _imageForAction(item.action),
    );
  }

  String _imageForCommandTitle(String title, {required String fallback}) {
    final key = title.toLowerCase();
    if (key.contains('upgrade gunsmith') || key.contains('upgrade bench')) {
      return _operationAsset('upgrade_gunsmith_card.webp');
    }
    if (key.contains('missing resources') ||
        key.contains('secure antiseptic')) {
      return _operationAsset('missing_resources_card.webp');
    }
    if (key.contains('protect resources')) {
      return _operationAsset('protect_resources_card.webp');
    }
    if (key.contains('complete blueprint')) {
      return _operationAsset('complete_blueprint_collection_card.webp');
    }
    if (key.contains('blueprint')) {
      return _operationAsset('complete_blueprint_collection_card.webp');
    }
    if (key.contains('review trade') ||
        key.contains('trade activity') ||
        key.contains('trade opportunity')) {
      return _operationAsset('review_trade_activity_card.webp');
    }
    if (key.contains('clearer skies') || key.contains('progress clearer')) {
      return _operationAsset('progress_clearer_skies_card.webp');
    }
    if (key.contains('track quests') || key.contains('quest progress')) {
      return _operationAsset('track_quests_card.webp');
    }
    if (key.contains('finish favourite loadout')) {
      return _operationAsset('finish_favourite_loadout_card.webp');
    }
    if (key.contains('review favourite loadout')) {
      return _operationAsset('review_favourite_loadout_card.webp');
    }
    if (key.contains('favourite loadout') || key.contains('loadout')) {
      return _operationAsset('finish_favourite_loadout_card.webp');
    }
    if (key.contains('clear inventory')) {
      return _operationAsset('clear_inventory_card.webp');
    }
    if (key.contains('weekly raid')) {
      return _operationAsset('weekly_raid_card.webp');
    }
    if (key.contains('nomadic trader')) {
      return _operationAsset('check_nomadic_trader_card.webp');
    }
    if (key.contains('claim operations')) {
      return _operationAsset('claim_operations_card.webp');
    }
    if (key.contains('operations') || key.contains('reward vault')) {
      return _operationAsset('claim_operations_card.webp');
    }
    if (key.contains('search')) {
      return _operationAsset('search_app_card.webp');
    }
    return fallback;
  }

  String _imageForAction(ArcCommandAction action) {
    switch (action.intent) {
      case ArcCommandActionIntent.favouriteLoadout:
        return _operationAsset('finish_favourite_loadout_card.webp');
      case ArcCommandActionIntent.smartTrade:
        return _operationAsset('review_trade_activity_card.webp');
      case ArcCommandActionIntent.nomadicTrader:
        return _operationAsset('check_nomadic_trader_card.webp');
      case ArcCommandActionIntent.operations:
        return _operationAsset('claim_operations_card.webp');
      case ArcCommandActionIntent.comingSoon:
        return _operationAsset('arc_command_centre_background.webp');
      case ArcCommandActionIntent.toolDeck:
        return _operationAsset('arc_tool_deck_background.webp');
      case ArcCommandActionIntent.route:
      case ArcCommandActionIntent.placeholder:
        final route = action.routeName ?? '';
        if (route.contains('raid-intelligence') ||
            route.contains('raid-planner')) {
          return _operationAsset('weekly_raid_card.webp');
        }
        if (route.contains('blueprint')) {
          return _operationAsset('complete_blueprint_collection_card.webp');
        }
        if (route.contains('bench')) {
          return _operationAsset('upgrade_gunsmith_card.webp');
        }
        if (route.contains('quest')) {
          return _operationAsset('track_quests_card.webp');
        }
        if (route.contains('resource') || route.contains('scrappy')) {
          return _operationAsset('missing_resources_card.webp');
        }
        return _operationAsset('arc_command_centre_background.webp');
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
    required this.progressPercent,
  });

  final String title;
  final String detail;
  final String label;
  final ArcCommandStatus status;
  final ArcCommandAction action;
  final IconData icon;
  final Color accent;
  final String image;
  final int progressPercent;
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
