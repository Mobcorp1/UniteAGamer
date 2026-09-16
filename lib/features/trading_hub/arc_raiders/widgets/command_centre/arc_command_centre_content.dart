import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/monetisation_screen.dart';
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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/arc_text_sanitizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
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
  @override
  Widget build(BuildContext context) {
    final commandState = widget.commandState;
    final systemTiles = _systemTiles(commandState);
    final commandMoves = _commandMoves(commandState).take(6).toList();

    return ArcRaidersPageList(
      maxWidth: ArcLayoutTokens.standardContentWidth,
      bottomPadding: 84,
      children: [
        if (widget.fallbackNotice != null) ...[
          ArcCommandCentreCard(
            accent: ArcUiTokens.info,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: ArcUiTokens.info,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.fallbackNotice!,
                    style: ArcUiTokens.bodySmall(
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
        ],
        _commandHero(commandState, commandMoves),
        const SizedBox(height: ArcUiTokens.gapM),
        _snapshotOverview(commandState.snapshots),
        const SizedBox(height: ArcUiTokens.gapM),
        _topCommandDeck(commandState, commandMoves),
        const SizedBox(height: ArcUiTokens.gapM),
        _featuresUtilityDeck(systemTiles),
      ],
    );
  }

  Widget _snapshotOverview(List<ArcCommandSnapshotMetric> snapshots) {
    final metrics = snapshots.take(4).toList(growable: false);
    if (metrics.isEmpty) return const SizedBox.shrink();

    return ArcCommandCentreCard(
      accent: ArcUiTokens.primaryAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Tactical Overview',
            subtitle: 'Live progression and account signals',
            accent: ArcUiTokens.primaryAccent,
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          ArcAdaptiveGrid(
            minTileWidth: 145,
            maxColumns: 4,
            spacing: 8,
            runSpacing: 8,
            children: [for (final metric in metrics) _snapshotMetric(metric)],
          ),
        ],
      ),
    );
  }

  Widget _snapshotMetric(ArcCommandSnapshotMetric metric) {
    final accent = arcCommandStatusAccent(metric.status);
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: accent,
        radius: ArcUiTokens.radiusL,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cleanText(metric.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.numeric(fontSize: 19, color: accent),
          ),
          const SizedBox(height: 4),
          Text(
            _cleanText(metric.label).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.label(color: ArcUiTokens.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            _shortActionText(metric.detail),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.bodySmall(),
          ),
        ],
      ),
    );
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
    final priority = commandState.priority;
    final accent = arcCommandStatusAccent(priority.status);

    return Container(
      constraints: const BoxConstraints(minHeight: 188),
      decoration: _imageDecoration(
        _operationAsset('arc_command_centre_background.webp'),
        accent,
        radius: ArcUiTokens.radiusXXL,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'ARC OPERATIONS',
                    style: ArcUiTokens.label(
                      color: ArcUiTokens.primaryAccent,
                    ).copyWith(letterSpacing: 1.25),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: ArcUiTokens.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: ArcUiTokens.label(color: ArcUiTokens.success),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'COMMAND CENTRE',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.pageTitle(
                  fontSize: compact ? 25 : 31,
                  color: ArcUiTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _cleanText(priority.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.sectionTitle(fontSize: 15, color: accent),
              ),
              const SizedBox(height: 4),
              Text(
                _shortActionText(priority.explanation),
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.body(
                  fontSize: compact ? 12 : 13,
                  color: ArcUiTokens.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => widget.onAction(priority.primaryAction),
                    style: ArcUiTokens.textButtonStyle(
                      accent: accent,
                      primary: true,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(priority.primaryAction.label),
                  ),
                  if (priority.secondaryAction != null)
                    TextButton.icon(
                      onPressed: () =>
                          widget.onAction(priority.secondaryAction!),
                      style: ArcUiTokens.textButtonStyle(accent: accent),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: Text(priority.secondaryAction!.label),
                    ),
                ],
              ),
            ],
          );

          final status = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              ArcCommandStatusPill(
                label: priority.statusTag,
                status: priority.status,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _heroMetric(
                    label: 'NEXT MOVES',
                    value: '${commandMoves.length}',
                    accent: ArcUiTokens.primaryAccent,
                  ),
                  _heroMetric(
                    label: 'DAILY OPEN',
                    value: '$openChecks',
                    accent: openChecks == 0
                        ? ArcUiTokens.success
                        : ArcUiTokens.secondaryAccent,
                  ),
                  _heroMetric(
                    label: 'PROGRESS',
                    value: _cleanText(priority.progressLabel),
                    accent: accent,
                  ),
                ],
              ),
            ],
          );

          return Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [copy, const SizedBox(height: 14), status],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 7, child: copy),
                      const SizedBox(width: 20),
                      Expanded(flex: 5, child: status),
                    ],
                  ),
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
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.overlay,
        accent: accent,
        radius: ArcUiTokens.radiusM,
        borderOpacity: 0.30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.numeric(fontSize: 16, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _topCommandDeck(
    ArcCommandCentreState commandState,
    List<_CommandMoveData> commandMoves,
  ) {
    return ArcResponsiveSplitPane(
      breakpoint: ArcLayoutTokens.tabletBreakpoint,
      spacing: 10,
      primaryFlex: 7,
      secondaryFlex: 5,
      primary: _actionConsole(commandMoves),
      secondary: _dailyChecklist(commandState.checklist),
    );
  }

  Widget _featuresUtilityDeck(List<_CommandTileData> systemTiles) {
    return ArcResponsiveSplitPane(
      breakpoint: 980,
      spacing: 10,
      primaryFlex: 9,
      secondaryFlex: 3,
      primary: _systemLaunchpad(systemTiles),
      secondary: _seasonResetEntry(),
    );
  }

  Widget _seasonResetEntry() {
    final expeditionState = widget.expeditionState;
    final resetSubtitle = expeditionState.resetInProgress
        ? '${expeditionState.currentSeasonId} reset in progress.'
        : '${expeditionState.currentSeasonId} - ${expeditionState.statusLabel}.';

    return _tapSurface(
      action: const ArcCommandAction(
        label: 'Start Expedition Reset',
        routeName: ArcSeasonResetScreen.routeName,
      ),
      child: ArcCommandCentreCard(
        padding: const EdgeInsets.all(12),
        accent: ArcUiTokens.secondaryAccent,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                border: Border.all(
                  color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: ArcUiTokens.secondaryAccent,
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
                    style: ArcUiTokens.sectionTitle(
                      fontSize: 15,
                      color: ArcUiTokens.secondaryAccent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resetSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.bodySmall(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: ArcUiTokens.secondaryAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemLaunchpad(List<_CommandTileData> tiles) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    final visibleTiles = tiles
        .where((tile) => tile.title != 'Tool Deck')
        .take(8)
        .toList(growable: false);

    return ArcCommandCentreCard(
      accent: ArcUiTokens.primaryAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArcCommandSectionHeader(
            title: 'ARC Systems',
            subtitle: 'Core tools and trackers',
            accent: ArcUiTokens.primaryAccent,
            trailing: TextButton.icon(
              onPressed: () => widget.onAction(
                const ArcCommandAction(
                  label: 'Open Tool Deck',
                  intent: ArcCommandActionIntent.toolDeck,
                ),
              ),
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 15),
              label: const Text('ALL SYSTEMS'),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          ArcAdaptiveGrid(
            minTileWidth: 150,
            maxColumns: 4,
            spacing: 8,
            runSpacing: 8,
            children: [for (final tile in visibleTiles) _systemTile(tile)],
          ),
        ],
      ),
    );
  }

  Widget _systemTile(_CommandTileData tile) {
    final accent = arcCommandStatusAccent(tile.status);
    return _tapSurface(
      action: tile.action,
      child: Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(10),
        decoration: _imageDecoration(
          tile.image,
          accent,
          radius: ArcUiTokens.radiusL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(tile.status), color: accent, size: 17),
                const Spacer(),
                ArcCommandStatusPill(label: tile.value, status: tile.status),
              ],
            ),
            const Spacer(),
            Text(
              _cleanText(tile.title).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.cardTitle(fontSize: 12.5, color: accent),
            ),
            const SizedBox(height: 4),
            Text(
              _shortActionText(tile.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.bodySmall(
                color: ArcUiTokens.textSecondary,
              ).copyWith(height: 1.22),
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
      accent: ArcUiTokens.primaryAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Priority Moves',
            subtitle: 'What needs attention now',
            accent: ArcUiTokens.primaryAccent,
          ),
          const SizedBox(height: 8),
          if (moves.isEmpty)
            _quietLine('No active command needs attention.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 820
                    ? 3
                    : (constraints.maxWidth >= 560 ? 2 : 1);
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
        constraints: const BoxConstraints(minHeight: 108),
        padding: const EdgeInsets.all(11),
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
                    style: ArcUiTokens.label(color: move.accent),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _cleanText(move.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.cardTitle(
                fontSize: 12,
                color: ArcUiTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortActionText(move.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.bodySmall(
                color: ArcUiTokens.textTertiary,
              ).copyWith(height: 1.18),
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
            style: ArcUiTokens.label(
              color: ArcUiTokens.textPrimary,
            ).copyWith(fontSize: 7),
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

  List<_CommandTileData> _systemTiles(ArcCommandCentreState state) {
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
      routeTile(
        title: 'Plans & Referrals',
        detail: 'Premium plans, beta and Founder offers, passes and referrals.',
        routeName: MonetisationScreen.routeName,
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
    final completed = items.where((item) {
      return widget.checklistState[item.id] ?? item.doneByDefault;
    }).length;
    final complete = items.isNotEmpty && completed == items.length;

    return ArcCommandCentreCard(
      accent: ArcUiTokens.primaryAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArcCommandSectionHeader(
            title: 'Daily Mission Board',
            subtitle: 'Routine checks without leaving mission control',
            accent: ArcUiTokens.primaryAccent,
            trailing: items.isEmpty
                ? null
                : ArcCommandStatusPill(
                    label: '$completed / ${items.length}',
                    status: complete
                        ? ArcCommandStatus.success
                        : ArcCommandStatus.active,
                  ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          if (items.isEmpty)
            _quietLine('No checklist items are waiting.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760
                    ? 3
                    : (constraints.maxWidth >= 520 ? 2 : 1);
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
      ),
    );
  }

  Widget _checklistTile(ArcCommandChecklistItem item) {
    final checked = widget.checklistState[item.id] ?? item.doneByDefault;
    final accent = checked ? ArcUiTokens.success : ArcUiTokens.primaryAccent;
    return _tapSurface(
      action: item.action,
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.all(9),
        decoration: _imageDecoration(
          _imageForChecklistItem(item),
          accent,
          radius: ArcUiTokens.radiusL,
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
                    size: 16,
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
                fontSize: 10.5,
                color: checked ? ArcUiTokens.success : ArcUiTokens.textPrimary,
                isBold: true,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _shortActionText(item.reason),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
                color: ArcUiTokens.textTertiary,
              ).copyWith(height: 1.05),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        onTap: () => widget.onAction(action),
        child: child,
      ),
    );

    if (!active) return surface;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: ArcUiTokens.primaryAccent,
        radius: ArcUiTokens.radiusL,
        selected: true,
        borderOpacity: 0.30,
      ),
      child: surface,
    );
  }

  Widget _quietLine(String text) {
    return Text(
      text,
      style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
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
    return ArcTextSanitizer.sanitize(value);
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
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ArcUiTokens.surfaceRaised.withValues(alpha: 0.98),
          ArcUiTokens.surfacePanel.withValues(alpha: 0.96),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: accent.withValues(alpha: 0.22)),
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
          Colors.black.withValues(alpha: 0.54),
          BlendMode.darken,
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ArcUiTokens.surfaceOverlay.withValues(alpha: 0.92),
          ArcUiTokens.background.withValues(alpha: 0.76),
          accent.withValues(alpha: 0.07),
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
